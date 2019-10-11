local utf8 = require("polywell.lib.utf8")
local lume = require("polywell.lib.lume")
local colorize = require("polywell.colorize")
local completion = require("polywell.completion")
local frontend = require("polywell.frontend")
local state = require("polywell.state")

local dprint = os.getenv("DEBUG") and print or function() end

-- constants
local kill_ring_max = 32
local mark_ring_max = 32

-- This is the structure of a buffer table. However, the fields it contains
-- should be considered an internal implementation detail of the editor.
-- We expose functions to make changes to a buffer, but we don't let user code
-- make any changes directly; otherwise we will not be able to change the
-- structure of the table without breaking user code.
local make_buffer = function(path, lines, props)
   return { path=path, mode = "edit", lines = lines,
            point = 0, point_line = 1, mark = nil, mark_line = nil,
            last_yank = nil, mark_ring = {}, history = {}, undo_at = 0,
            -- dirty is a per-cycle change flag (for undo tracking) while
            -- needs_save is an overall change flag.
            dirty = false, needs_save = false,
            -- repl-style modes need input history tracking and a prompt
            input_history = {}, input_history_pos = 0, input_history_max = 64,
            prompt = nil,
            -- arbitrary key/value storage
            props = props or {},
            -- TODO: this leaks buffer structure to userspace.
            modeline = function(b)
               return utf8.format(" %s  %s  (%s/%s)  %s",
                                  b.needs_save and "*" or "-",
                                  b.path, b.point_line, #b.lines, b.mode)
            end
   }
end

local behind_minibuffer = function() return state.windows[state.window][2] end

local get_current_mode = function(buffer)
   buffer = buffer or state.b
   return state.modes[buffer and buffer.mode]
end

local set_prop = function(prop, value) state.b.props[prop] = value return value end

local function get_prop(prop, default, buffer, mode)
   buffer = buffer or state.b
   mode = mode or get_current_mode(buffer)
   if(buffer and buffer.props[prop]) then
      return buffer and buffer.props[prop]
   elseif(mode.props and mode.props[prop] ~= nil) then
      return mode.props[prop]
   elseif(mode.parent) then
      return get_prop(prop, default, buffer,
                      assert(state.modes[mode.parent], "no mode " .. mode.parent))
   else return default end
end

local get_main_prop = function(prop)
   if(state.b.path == "minibuffer") then
      return get_prop(prop, nil, behind_minibuffer())
   else
      return get_prop(prop)
   end
end

local vary_prop = function(prop, f, ...)
   return set_prop(prop, f(get_prop(prop), ...))
end

local function get_mode_prop(mode_name, prop)
   local mode = assert(state.modes[mode_name], mode_name)
   local parent = mode and mode.parent
   return mode.props and mode.props[prop] or
      parent and get_mode_prop(parent, prop)
end

local run_on_change = function()
   local on_change = get_prop("on-change")
   if(type(on_change) == "function") then
      on_change()
   elseif(type(on_change) == "table") then
      for _,f in pairs(on_change) do f() end
   end
end

local undo = function()
   local prev = state.b.history[#state.b.history-state.b.undo_at]
   if(state.b.undo_at < #state.b.history) then
      state.b.undo_at = state.b.undo_at + 1
   end
   if(prev) then
      state.b.lines, state.b.point, state.b.point_line =
         prev.lines, prev.point, prev.point_line
      run_on_change()
   end
end

local dbg = function(arg)
   if(arg == "modes") then return state.modes end
   if(arg == "lines") then return state.b.lines end
   if(not (arg or os.getenv("DEBUG"))) then return end
   print("---------------", state.b.path, state.b.point_line, state.b.point, state.b.mark_line, state.b.mark)
   for _,line in ipairs(state.b.lines) do
      print(line)
   end
   print("---------------")
end

local out_of_bounds = function(line, point)
   return not (state.b.lines[line] and point >= 0 and point <= #state.b.lines[line])
end

local bounds_check = function()
   -- The first one is a normal occurance; the second two should never happen,
   -- but let's be forgiving instead of asserting.
   if(state.b.point_line > #state.b.lines) then
      state.b.point_line = #state.b.lines
   elseif(#state.b.lines[state.b.point_line] and state.b.point > #state.b.lines[state.b.point_line]) then
      state.b.point = #state.b.lines[state.b.point_line]
   elseif(state.b.mark_line and state.b.mark and out_of_bounds(state.b.mark_line, state.b.mark)) then
      dprint("Mark out of bounds!", state.b.mark_line, #state.b.lines)
      dbg()
      state.b.mark, state.b.mark_line = nil, nil
   end
   if(out_of_bounds(state.b.point_line, state.b.point)) then
      dprint("Point out of bounds!", state.b.point_line, state.b.point,
             #state.b.lines, state.b.lines[state.b.point_line] and #state.b.lines[state.b.point_line])
      dbg()
      state.b.point, state.b.point_line = 0, 1
   end
end

local get_buffer = function(path)
   return lume.match(state.buffers, function(b) return b.path == path end)
end

local with_current_buffer = function(nb, f, ...)
   if(type(nb) == "string") then
      nb = get_buffer(nb)
   end
   local old_b = state.b
   state.b = nb
   local val = f(...)
   state.b = old_b
   return val
end

local region = function()
   state.b.mark = math.min(utf8.len(state.b.lines[state.b.mark_line]), state.b.mark)

   if(state.b.point_line == state.b.mark_line) then
      local start, finish = math.min(state.b.point, state.b.mark), math.max(state.b.point, state.b.mark)
      local r = {utf8.sub(state.b.lines[state.b.point_line], start + 1, finish)}
      return r, state.b.point_line, start, state.b.point_line, finish
   elseif(state.b.mark == nil or state.b.mark_line == nil) then
      return {}, state.b.point_line, state.b.point, state.b.point_line, state.b.point
   else
      local start_line, start, finish_line, finish
      if(state.b.point_line < state.b.mark_line) then
         start_line, start, finish_line,finish =
            state.b.point_line, state.b.point, state.b.mark_line, state.b.mark
      else
         start_line, start, finish_line,finish =
            state.b.mark_line, state.b.mark, state.b.point_line, state.b.point
      end
      local r = {utf8.sub(state.b.lines[start_line], start + 1, -1)}
      for i = start_line+1, finish_line-1 do
         table.insert(r, state.b.lines[i])
      end
      table.insert(r, utf8.sub(state.b.lines[finish_line], 0, finish))
      return r, start_line, start, finish_line, finish
   end
end

local in_prompt = function(line, point, line2)
   if(state["printing-prompt"] or not state.b.prompt) then return false end
   if((line2 or line) == line and line ~= #state.b.lines) then return false end
   if(line == #state.b.lines and point >= utf8.len(state.b.prompt)) then return false end
   return true
end

local edit_disallowed = function(line, point, line2, point2)
   if(state["inhibit-read-only"]) then return false end
   local ro = get_prop("read-only", in_prompt(line, point, line2, point2))
   if(type(ro) == "function") then
      return ro(line, point, line2, point2)
   else
      return ro
   end
end

local echo = function(...)
   state["echo-message"], state["echo-message-new"] = table.concat({...}, " "), true
end

local insert = function(text, point_to_end)
   if(in_prompt(state.b.point_line, state.b.point)) then
      state.b.point = #state.b.prompt
   end
   if(edit_disallowed(state.b.point_line, state.b.point)) then
      return echo("Read-only.")
   end
   if(out_of_bounds(state.b.point_line, state.b.point)) then
      dprint("Inserting out of bounds!", state.b.point_line, state.b.point)
      return
   end

   if(type(text) == "string") then text = lume.split(text, "\n") end
   state.b.dirty, state.b.needs_save = true, true
   text = lume.map(text, function(s) return utf8.gsub(s, "\t", "  ") end)
   if(not text or #text == 0) then return end
   local this_line = state.b.lines[state.b.point_line] or ""
   local before = utf8.sub(this_line, 0, state.b.point)
   local after = utf8.sub(this_line, state.b.point + 1)
   local first_line = text[1]

   if(#text == 1) then
      state.b.lines[state.b.point_line] = (before or "") .. (first_line or "") .. (after or "")
      if(point_to_end) then
         state.b.point = utf8.len(before) + utf8.len(first_line)
      end
   else
      state.b.lines[state.b.point_line] = (before or "") .. (first_line or "")
      for i,l in ipairs(text) do
         if(i > 1 and i < #text) then
            table.insert(state.b.lines, i+state.b.point_line-1, l)
         end
      end
      table.insert(state.b.lines, state.b.point_line+#text-1, text[#text] .. (after or ""))
      if(point_to_end) then
         state.b.point = #text[#text]
         state.b.point_line = state.b.point_line+#text-1
      end
   end
end

local delete = function(start_line, start, finish_line, finish)
   start_line = math.min(start_line, finish_line)
   finish_line = math.max(start_line, finish_line)
   if(start_line == finish_line) then
      start, finish = math.min(start, finish), math.max(start, finish)
   end
   if(edit_disallowed(start_line, start, finish_line, finish)) then return end
   if(out_of_bounds(start_line, start) or
      out_of_bounds(finish_line, finish)) then
      dprint("Deleting out of bounds!")
      return
   end

   state.b.dirty, state.b.needs_save = true, true
   if(start_line == finish_line) then
      local line = state.b.lines[start_line]
      state.b.lines[start_line] = utf8.sub(line, 0, start)..utf8.sub(line, finish + 1)
      if(state.b.point_line == start_line and start <= state.b.point) then
         state.b.point = start
      elseif(state.b.point_line == start_line and state.b.point <= finish) then
         state.b.point = state.b.point - (finish - start)
      end
   else
      local after = utf8.sub(state.b.lines[finish_line], finish+1, -1)
      for i = finish_line, start_line + 1, -1 do
         table.remove(state.b.lines, i)
      end
      state.b.lines[start_line] = utf8.sub(state.b.lines[start_line], 0, start) .. after
      if(state.b.point_line > start_line and state.b.point_line <= finish_line) then
         state.b.point, state.b.point_line = start, start_line
      elseif(state.b.point_line > finish_line) then
         state.b.point_line = state.b.point_line - (finish_line - start_line)
      end
   end
end

local push = function(ring, item, max)
   table.insert(ring, item)
   if(#ring > max) then table.remove(ring, 1) end
end

local yank = function()
   local text = state["kill-ring"][#state["kill-ring"]]
   if(text) then
      state.b.last_yank = {state.b.point_line, state.b.point,
                     state.b.point_line + #text - 1, utf8.len(text[#text])}
      insert(text, true)
   end
end

local system_yank = function ()
   -- don't crash in headless mode
   local text = frontend.get_clipboard()
   if(text) then
      insert(lume.split(text, "\n"), true)
   end
end

local is_beginning_of_buffer = function()
   bounds_check()
   return state.b.point == 0 and state.b.point_line == 1
end

local is_end_of_buffer = function()
   bounds_check()
   return state.b.point == #state.b.lines[state.b.point_line] and state.b.point_line == #state.b.lines
end

local forward_char = function(n) -- lameness: n must be 1 or -1
   n = n or 1
   if((is_end_of_buffer() and n > 0) or
      is_beginning_of_buffer() and n < 0) then return
   elseif(state.b.point >= #state.b.lines[state.b.point_line] and n > 0) then
      state.b.point, state.b.point_line = 0, state.b.point_line+1
   elseif(state.b.point <= 0 and n < 0) then
      state.b.point = #state.b.lines[state.b.point_line-1]
      state.b.point_line = state.b.point_line-1
   else
      state.b.point = state.b.point + n
   end
end

local point_over = function()
   return utf8.sub(state.b.lines[state.b.point_line], state.b.point + 1, state.b.point + 1) or " "
end

-- state of very limited scope; OK to keep inline
local moved_last_point, moved_last_line
local point_moved = function()
   local lp, ll = moved_last_point, moved_last_line
   moved_last_point, moved_last_line = state.b.point, state.b.point_line
   return not (lp == state.b.point and ll == state.b.point_line)
end

local word_break = "[%s%p]"

local forward_word = function(n)
   moved_last_point, moved_last_line = nil, nil
   if(utf8.find(point_over(), word_break)) then
      while(point_moved() and utf8.find(point_over(), word_break)) do
         forward_char(n)
      end
   end
   forward_char(n)
   while(point_moved() and not utf8.find(point_over(), word_break)) do
      forward_char(n)
   end
end

local backward_word = function()
   forward_char(-1)
   forward_word(-1)
   forward_char()
end

local newline = function(n)
   local t = {""}
   for _=1,(n or 1) do table.insert(t, "") end
   insert(t, true)
end

local save_excursion = function(f)
   local old_b, p, pl = state.b, state.b.point, state.b.point_line
   local m, ml = state.b.mark, state.b.mark_line
   local val, err = pcall(f)
   state.b = old_b
   if(state.b) then
      state.b.point, state.b.point_line, state.b.mark, state.b.mark_line = p, pl, m, ml
   end
   if(not val) then error(err) end
   return val
end

-- write to the current point in the current buffer
local write = function(...)
   local lines = lume.split(table.concat({...}, " "), "\n")
   local read_only = state["inhibit-read-only"]
   state["inhibit-read-only"] = true
   insert(lines, true)
   state["inhibit-read-only"] = read_only
   return lume.last(lines), #lines
end

-- write to the end of the output buffer right before the prompt
local io_write = function(...)
   local prev_b = state.b
   state.b = assert(state.output, "no output!")
   local old_point, old_point_line, old_lines = state.b.point, state.b.point_line, #state.b.lines
   if(#state.b.lines > 1) then
      state.b.point, state.b.point_line = #state.b.lines[#state.b.lines - 1], #state.b.lines - 1
   else
      state.b.point, state.b.point_line = 0, 1
   end
   local _, line_count = write(...)
   if(old_point_line == old_lines) then
      state.b.point, state.b.point_line = old_point, #state.b.lines
   end
   state.b = prev_b
   if(state.b == state.output) then
      state.b.point_line = old_point_line + line_count - 1
   end
end

local the_print = function(...)
   local texts, read_only = {...}, state["inhibit-read-only"]
   if(texts[1] == nil) then return end
   state["inhibit-read-only"] = true
   texts[1] = "\n" .. texts[1]
   io_write(unpack(lume.map(texts, tostring)))
   state["inhibit-read-only"] = read_only
end

local doubleprint = function(...)
   print(...)
   the_print(...)
end

local with_traceback = function(f, ...)
   local args = {...}
   -- TODO: sandboxed traceback which trims out irrelevant layers
   return xpcall(function() return f(unpack(args)) end, function(e)
         echo(e)
         doubleprint(e)
         doubleprint(debug.traceback())
   end)
end

local get_input = function(tb)
   tb = tb or state.b
   assert(tb.prompt, "Buffer does not have a prompt.")
   return utf8.sub(tb.lines[#tb.lines], #tb.prompt+1)
end

local exit_minibuffer -- mutual recursion

local reset_minibuffer_keys = function(exit)
   state.modes.minibuffer.ctrl = { g = lume.fn(exit, true),
                                   m = exit_minibuffer }
   state.modes.minibuffer.alt, state.modes.minibuffer["ctrl-alt"] = {}, {}
end

exit_minibuffer = function(cancel)
   local input, callback = get_input(), state.b.callback
   local completer = state.b.props and state.b.props.completer
   reset_minibuffer_keys(exit_minibuffer)

   if(completer and not cancel) then
      local target = completer(input)[1]
      if((utf8.sub((target or ""), -1, -1) == "/")) then
         state.b.lines[#state.b.lines] = state.b.prompt .. target
         state.b.point = #state.b.lines[#state.b.lines]
      else
         state.b = behind_minibuffer()
         if(not cancel or state.b.props["cancelable?"]) then
            callback(target or input, cancel)
         end
      end
   else
      state.b = behind_minibuffer()
      if(not cancel or state.b.props["cancelable?"]) then
         callback(input, cancel)
      end
   end
end

local delete_backwards = function()
   if(is_beginning_of_buffer()) then return end
   local line, point = state.b.point_line, state.b.point
   local line2, point2
   save_excursion(function()
         forward_char(-1)
         line2, point2 = state.b.point_line, state.b.point
   end)
   delete(line2, point2, line, point)
end

local complete = function()
   if(state.b.props.completer) then
      local completions = state.b.props.completer(get_input())
      if(completions and #completions == 1) then
         state.b.lines[#state.b.lines] = state.b.prompt .. completions[1]
         state.b.point = #state.b.lines[#state.b.lines]
      else
         local common = completion["longest-common-prefix"](completions)
         state.b.lines[#state.b.lines] = state.b.prompt .. (common or "")
         state.b.point = #state.b.lines[#state.b.lines]
      end
   end
end

state.modes.minibuffer = {
   name = "minibuffer",
   map = {
      ["return"] = exit_minibuffer,
      escape = lume.fn(exit_minibuffer, true),
      backspace = delete_backwards,
      tab = complete,
   }
}

-- This uses a callback; you probably want read_input
local read_line = function(prompt, callback, props)
   -- without this, the key which activated the minibuffer triggers a
   -- call to textinput, inserting it into the input
   -- TODO: move love-specific bits to frontend module
   local old_released = love.keyreleased
   love.keyreleased = function()
      love.keyreleased = old_released
      props = props or {}
      if(not state.b or state.b.path ~= "minibuffer") then
         props["no-file"] = true
         state.b = make_buffer("minibuffer", {prompt}, props)
      end
      state.b.mode = "minibuffer"
      state.b.prompt, state.b.callback, state.b.point = prompt, callback, #prompt
      if(props.completer) then
         local last_input, completions = nil, {}
         state.b.render = function(mini)
            local input = get_input(mini)
            if(input ~= last_input) then
               completions, last_input = props.completer(input), input
            end
            return mini.lines[1] .. " " .. table.concat(completions, " | ")
         end
      else
         state.b.render = function(mini) return mini.lines[1] end
      end
      if(props["initial-input"]) then
         insert(props["initial-input"])
         state.b.point = #state.b.lines[state.b.point_line]
      end
      for map_name, keys in pairs(props.bind or {}) do
         local map = state.modes.minibuffer[map_name]
         for key, f in pairs(keys) do
            map[key] = f
         end
      end
   end
   -- mouse-activated reads don't have this problem; trigger key release.
   if(props and props.moused) then love.keyreleased() end
end

-- good version which runs in a coroutine instead of using callbacks
local read_input = function(prompt, props)
   assert(coroutine.running(), "Must call read_input from a coroutine.")
   read_line(prompt, lume.fn(coroutine.resume, coroutine.running()), props)
   return coroutine.yield()
end

local activate_mode = function(mode_name)
   if(not state.b) then return end
   assert(state.modes[mode_name], mode_name .. " mode does not exist.")
   local current_mode = get_current_mode()
   local new_mode = state.modes[mode_name]
   if(current_mode and get_prop("deactivate")) then
      get_prop("deactivate")()
   end
   frontend.set_cursor(new_mode.props.cursor)
   state.b.mode = mode_name
   local read_only = state["inhibit-read-only"]
   state["inhibit-read-only"] = true
   if(get_prop("activate")) then get_prop("activate")() end
   state["inhibit-read-only"] = read_only
end

local auto_activate_mode = function(path)
   for pat, mode in pairs(state["activate-patterns"]) do
      if(path:find(pat)) then
         activate_mode(mode)
         return true
      end
   end
end

local change_buffer = function(path, create_if_missing)
   local new = get_buffer(path)
   if not new and create_if_missing then
      new = make_buffer(path)
   end
   state.b = assert(new, "Buffer not found: " .. path)
   state.windows[state.window][2] = state.b
end

local relativize_path = function(path)
   if(path:sub(1, 1) == "/") then
      return path:gsub(state.cwd, ""):gsub("^/", "")
   else
      return path
   end
end

local function open(path, mode, no_file, props)
   path = relativize_path(path)
   state["last-buffer"] = state.b
   state.b = get_buffer(path)
   if(state.b) then
      if(mode) then activate_mode(mode) end
   else
      if no_file then
         state.b = make_buffer(path, {""}, {["no-file"] = no_file})
         table.insert(state.buffers, state.b)
      elseif(state.fs.type(path) == nil) then
         local make_file = function(input)
            if input:lower():match("^y") or input == "" then
               frontend.write(path, "")
               open(path, mode, no_file, props)
            end
         end
         state.b = state["last-buffer"]
         return read_line("File does not exist; create? [Y/n] ", make_file)
      elseif(state.fs.type(path) ~= "file" and not no_file) then
         echo("Tried to open a directory or something.")
      else
         local lines = lume.split(state.fs.read(path), "\n")
         state.b = make_buffer(path, lines, {})
         table.insert(state.buffers, state.b)
      end

      for k,v in pairs(props or {}) do set_prop(k, v) end

      local parts = lume.split(state.b.lines[1], "-*-")
      local auto_mode = mode or (parts[2] and lume.trim(parts[2]))
      if(auto_mode) then
         activate_mode(auto_mode)
      elseif(not auto_activate_mode(path)) then
         activate_mode("edit")
      end
   end

   change_buffer(path)

   state.windows[state.window][2] = state.b
end

-- TODO: organize these better
-- * buffer manipulation
-- * UI stuff (prompt, modeline, echo, print, etc)
-- * meta
-- * misc
return {
   open = open,

   ["file-type"] = function(path) return state.fs.type(path) end,

   -- all end-user commands to be bound to a keystroke or invokable should
   -- be in this table, but they're getting ported to commands.fnl
   cmd = {
      ["open-in-split"] = function(...)
         local current_b, w,h = state.b, frontend.get_wh()
         open(...)
         state.window = 1
         state.windows = {{{10,10,w/2-10,h}, current_b},
            {{w/2+10,10,w/2,h}, state.b},}
      end,

      ["exit-minibuffer"] = exit_minibuffer,

      ["delete-backwards"] = delete_backwards,

      ["delete-forwards"] = function(n)
         if(is_end_of_buffer()) then return end
         local line, point = state.b.point_line, state.b.point
         local line2, point2
         save_excursion(function()
               forward_char(n)
               line2, point2 = state.b.point_line, state.b.point
         end)
         delete(line, point, line2, point2)
      end,
      ["kill-line"] = function()
         local remainder = utf8.sub(state.b.lines[state.b.point_line], state.b.point+1)
         if(utf8.find(remainder, "[^%s]")) then
            save_excursion(function()
                  state.b.mark, state.b.mark_line = state.b.point, state.b.point_line
                  state.b.point = #state.b.lines[state.b.point_line]
                  push(state["kill-ring"], region(), kill_ring_max)
            end)
            delete(state.b.point_line, state.b.point, state.b.point_line, #state.b.lines[state.b.point_line])
         elseif(state.b.point_line < #state.b.lines) then
            delete(state.b.point_line, state.b.point, state.b.point_line+1, 0)
         end
      end,

      ["beginning-of-line"] = function()
         state.b.point = 0
      end,

      ["end-of-line"] = function()
         state.b.point = #state.b.lines[state.b.point_line]
      end,

      ["prev-line"] = function()
         if(state.b.point_line > 1) then
            state.b.point_line = state.b.point_line - 1
         else
            state.b.point = 0
         end
      end,

      ["next-line"] = function()
         if(state.b.point_line < #state.b.lines) then
            state.b.point_line = state.b.point_line + 1
         else
            state.b.point = #state.b.lines[state.b.point_line]
         end
      end,

      ["forward-char"] = forward_char,
      ["backward-char"] = lume.fn(forward_char, -1),
      ["forward-word"] = forward_word,
      ["backward-word"] = backward_word,

      ["backward-kill-word"] = function()
         local original_point_line, original_point = state.b.point_line, state.b.point
         backward_word()
         delete(state.b.point_line, state.b.point, original_point_line, original_point)
      end,

      ["forward-kill-word"] = function()
         local original_point_line, original_point = state.b.point_line, state.b.point
         forward_word()
         delete(original_point_line, original_point, state.b.point_line, state.b.point)
      end,

      ["beginning-of-buffer"] = function()
         state.b.point, state.b.point_line = 0, 1
         return state.b.point, state.b.point_line
      end,

      ["end-of-buffer"] = function()
         state.b.point, state.b.point_line = #state.b.lines[#state.b.lines], #state.b.lines
         return state.b.point, state.b.point_line
      end,

      ["beginning-of-input"] = function()
         if(state.b.point_line == #state.b.lines and state.b.prompt) then
            state.b.point = #state.b.prompt
         else
            state.b.point = 0
         end
      end,

      newline = newline,

      mark = function()
         push(state.b.mark_ring, {state.b.point, state.b.point_line}, mark_ring_max)
         state.b.mark, state.b.mark_line = state.b.point, state.b.point_line
      end,

      ["jump-to-mark"] = function()
         state.b.point, state.b.point_line = state.b.mark or state.b.point, state.b.mark_line or state.b.point_line
         if(#state.b.mark_ring > 0) then
            table.insert(state.b.mark_ring, 1, table.remove(state.b.mark_ring))
            state.b.mark, state.b.mark_line = unpack(state.b.mark_ring[1])
         end
      end,

      ["no-mark"] = function()
         state.b.mark, state.b.mark_line, state["active-prefix"] = nil, nil, nil
      end,

      ["kill-ring-save"] = function()
         if(state.b.mark == nil or state.b.mark_line == nil) then return end
         push(state["kill-ring"], region(), kill_ring_max)
      end,

      ["kill-region"] = function()
         if(state.b.mark == nil or state.b.mark_line == nil) then return end
         local _, start_line, start, finish_line, finish = region()
         push(state["kill-ring"], region(), kill_ring_max)
         delete(start_line, start, finish_line, finish)
      end,

      ["system-copy-region"] = function()
         if(state.b.mark == nil or state.b.mark_line == nil) then return end
         frontend.set_clipboard(table.concat(region(), "\n"))
      end,

      yank = yank,

      ["yank-pop"] = function()
         if(state.b.last_yank) then
            table.insert(state["kill-ring"], 1, table.remove(state["kill-ring"]))
            local ly_line1, ly_point1, ly_line2, ly_point2 = unpack(state.b.last_yank)
            delete(ly_line1, ly_point1, ly_line2, ly_point2)
            yank()
         end
      end,

      ["system-yank"] = system_yank,

      undo = undo,

      ["word-wrap"] = function()
         while(state.b.lines[state.b.point_line-1] ~= "" and state.b.point_line > 1) do
            state.b.point_line = state.b.point_line - 1
         end
         local column = get_prop("wrap_column", 78)
         local join = function()
            state.b.point, state.b.point_line = 0, state.b.point_line+1
            delete_backwards()
            if(not utf8.find(point_over(), word_break)) then
               insert({" "}, true)
            end
         end
         local has_room = function()
            return save_excursion(function()
                  local room = column - #state.b.lines[state.b.point_line]
                  state.b.point, state.b.point_line = 0, state.b.point_line+1
                  forward_word()
                  return state.b.point < room
            end)
         end
         while(state.b.lines[state.b.point_line+1] ~= "" and state.b.point_line < #state.b.lines or
               #state.b.lines[state.b.point_line] > column) do
            if(#state.b.lines[state.b.point_line] < column and has_room()) then
               join()
            elseif(#state.b.lines[state.b.point_line] > column) then
               state.b.point = column
               if(not utf8.find(point_over(), word_break)) then
                  backward_word()
               end
               newline()
               forward_char()
               delete_backwards()
            else
               state.b.point_line = state.b.point_line + 1
            end
         end
      end,

      quit = function()
         require("polywell").cmd.save()
         frontend.quit()
      end,
   },

   draw = function()
      frontend.wrap(function()
            if(get_main_prop("under-draw")) then get_main_prop("under-draw")() end
            if(get_prop("full-draw")) then
               get_prop("full-draw")()
            elseif(state.b.path == "minibuffer" and
                   get_prop("full-draw", nil, behind_minibuffer())) then
               get_prop("full-draw", nil, behind_minibuffer())()
               frontend.draw(state.b, {}, state["echo-message"], state.colors,
                             get_prop)
            else
               local buffers_where = {}
               for i,bufpos in ipairs(state.windows) do
                  buffers_where[bufpos[1]] = bufpos[2]
                  bufpos[1].current = i == state.window
               end
               frontend.draw(state.b, buffers_where, state["echo-message"],
                             state.colors, get_prop)
            end
            if(get_main_prop("over-draw")) then get_main_prop("over-draw")() end
      end)
   end,

   ["read-line"] = read_line, -- callback-using version
   ["read-input"] = read_input, -- coroutine-using version

   -- caller is responsible for setting last-buffer
   ["change-buffer"] = change_buffer,

   ["last-buffer"] = function()
      return state["last-buffer"] and state["last-buffer"].path
   end,

   insert = insert,
   region = region,
   delete = delete,

   ["current-mode-name"] = function() return state.b.mode end,

   ["current-buffer-name"] = function() return state.b.path end,

   print = the_print,

   ["raw-write"] = write,
   write = io_write,

   ["end-of-buffer?"] = is_end_of_buffer,
   ["beginning-of-buffer?"] = is_beginning_of_buffer,

   ["get-lines"] = function() return lume.clone(state.b.lines) end,

   ["get-line"] = function(n)
      if(not state.b) then return end
      if(not n) then return state.b.lines[state.b.point_line] end
      if(n < 1) then n = #state.b.lines + n end
      return state.b.lines[n]
   end,

   ["get-line-number"] = function() return state.b.point_line end,

   ["get-max-line"] = function() return #state.b.lines end,

   point = function() return state.b.point, state.b.point_line end,

   ["set-line"] = function(line, number, path)
      local buffer = get_buffer(path) or state.b
      buffer.lines[number] = line
   end,

   ["suppress-read-only"] = function(f, ...)
      local read_only = state["inhibit-read-only"]
      state["inhibit-read-only"] = true
      local val = f(...)
      state["inhibit-read-only"] = read_only
      return val
   end,

   ["get-prop"] = get_prop,
   ["set-prop"] = set_prop,
   ["vary-prop"] = vary_prop,
   ["get-mode-prop"] = get_mode_prop,

   ["save-excursion"] = save_excursion,

   prompt = function() return state.b.prompt or "> " end,
   ["get-prompt"] = function() return state.b.prompt or "> " end,
   ["set-prompt"] = function(p)
      if(not state.b) then return end
      if(state.b.prompt) then
         local line = state.b.lines[#state.b.lines]
         state.b.lines[#state.b.lines] = p .. utf8.sub(line, utf8.len(state.b.prompt) + 1)
      end
      if(state.b.point_line == #state.b.lines) then state.b.point = utf8.len(p) end
      state.b.prompt = p
   end,
   ["print-prompt"] = function()
      local read_only = state["inhibit-read-only"]
      state["printing-prompt"], state["inhibit-read-only"] = true, true
      state.b.mark, state.b.mark_line = nil, nil
      delete(#state.b.lines, 0, #state.b.lines, #state.b.lines[#state.b.lines])
      write(state.b.prompt)
      state.b.point, state.b.point_line = #state.b.lines[#state.b.lines], #state.b.lines
      state["printing-prompt"], state["inhibit-read-only"] = false, read_only
   end,
   -- you probably don't want this; consider using handle-input-with instead.
   ["get-input"] = get_input,

   -- this is for feedback within the editor where print wouldn't make sense;
   -- shows in the minibuffer.
   echo = echo,

   ["history-push"] = function(input)
      if(not input:match("%S")) then return end
      state.b.input_history_pos = 0
      table.insert(state.b.input_history, input)
      if(#state.b.input_history > state.b.input_history_max) then
         table.remove(state.b.input_history, 1)
      end
   end,

   ["set-modeline"] = function(modeline_function)
      state.b.modeline = modeline_function
   end,

   ["with-current-buffer"] = with_current_buffer,
   ["with-output-to"] = function(nb, f)
      if(type(nb) == "string") then
         nb = get_buffer(nb)
      end
      local old_b = state.output
      state.output = assert(nb, "no output buffer!")
      local val = f()
      state.output = old_b
      return val
   end,
   ["with-traceback"] = with_traceback,

   ["write-to"] = function(buffer_name, ...)
      local old_b = state.output
      state.output = get_buffer(buffer_name)
      io_write(...)
      state.output = old_b
   end,

   ["buffer-names"] = function()
      return lume.map(state.buffers, function(bu) return bu.path end)
   end,

   ["kill-buffer"] = function(buffer_name)
      local b = buffer_name and get_buffer(buffer_name) or state.b
      assert(#state.buffers > 1, "Can't kill last buffer")
      lume.remove(state.buffers, b)
      if state["last-buffer"] then
         state.b, state["last-buffer"] = state["last-buffer"], nil
      else
         state.b = lume.last(state.buffers)
      end
   end,

   ["go-to"] = function(line, point, buffer_name)
      local buffer = get_buffer(buffer_name) or state.b
      if(type(point) == "number" and point >= 0 and
         point <= #buffer.lines[buffer.point_line]) then
         buffer.point = point
      end
      if(type(line) == "number" and line > 0 and line <= #buffer.lines) then
         buffer.point_line = line
      end
   end,

   ["activate-mode"] = activate_mode,

   colorize = function(keywords)
      local mode_colors = (state.b.mode and state.colors[state.b.mode]) or
         state.colors
      local color = get_prop("colorize", colorize)
      state.b.render_lines = color(keywords, mode_colors, state.b.lines, colorize)
   end,

   debug = dbg,

   start = function(f)
      if(type(f) == "function") then f = coroutine.create(f) end
      table.insert(state.coroutines, f)
      return f
   end,

   ["set-wh"] = frontend.set_wh,
   ["get-wh"] = frontend.get_wh,
   ["get-buffer-wh"] = frontend.get_buffer_wh,
   ["set-scale"] = frontend.set_scale,

   ["current-split"] = function() return state.window end,

   ["enforce-max-lines"] = function(max_lines)
      for _=1,(#state.b.lines - max_lines) do
         table.remove(state.b.lines, 1)
         if(state.b.point_line >= 1) then
            state.b.point_line = state.b.point_line - 1
         end
         if(state.b.mark_line) then
            state.b.mark_line = state.b.mark_line - 1
         end
      end
   end,

   init = function(init_buffer_name, mode_name, contents, fs)
      local buffer = make_buffer(init_buffer_name, contents, {["no-file"]=true})
      state.fs = fs or state.fs
      buffer.point, buffer.point_line = #contents[math.max(#contents-1, 1)], #contents
      state.b, state["last-buffer"], state.output = buffer, buffer, buffer
      state.windows[1] = {{}, state.b}
      table.insert(state.buffers, buffer)
      activate_mode(mode_name)
      reset_minibuffer_keys(exit_minibuffer)
      frontend.init()
   end,

   -- TODO: these are added to the public API in order to facilitate porting
   -- functionality out of this module but shouldn't be considered part of the
   -- stable API
   internal = {
      run_on_change = run_on_change,
      bounds_check = bounds_check,
      behind = behind_minibuffer,

      dump_buffer = function(name)
         local to_dump = lume.pick(get_buffer(name), "prompt",
                                   "path", "mode", "lines", "point", "mark",
                                   "point_line", "mark_line", "input_history")
         return lume.serialize(to_dump)
      end,

      load_buffer = function(dumped)
         local loaded = lume.deserialize(dumped)
         local buffer = get_buffer(loaded.path) or make_buffer(loaded.path)
         lume.extend(buffer, loaded)
         buffer.input_history = lume.clone(loaded.input_history)
      end,
   },
}

