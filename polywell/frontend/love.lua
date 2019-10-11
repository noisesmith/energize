-- This file contains all the love2d-specific code; in theory replacing this
-- could allow polywell to run on another lua-based framework.

local lume = require("polywell.lib.lume")
local row_height, scroll_rows, em, w, h
local padding, buffer_padding, offset = 10, 0, 0
local _, lfs = pcall(require, "lfs")
local canvas, fixed_w, fixed_h
local scale = 1

local exists = love.filesystem.getInfo or love.filesystem.exists -- 0.10.x

local reset_canvas = function()
   love.graphics.setCanvas()
   local rw, rh = love.graphics.getDimensions()
   if fixed_w and fixed_h then
      w, h = fixed_w, fixed_h
      scale = math.floor(math.min(rw/w,rh/h))
      canvas = love.graphics.newCanvas(rw, rh)
      canvas:setFilter("nearest", "nearest")
   else
      canvas = love.graphics.newCanvas(rw, rh)
      canvas:setFilter("nearest", "nearest")
      w, h = rw/scale, rh/scale
   end
end

local render_line = function(ln2, y)
   if(ln2 == "\f\n" or ln2 == "\f") then
      love.graphics.line(0, y + 0.5 * row_height, w, y + 0.5 * row_height)
   else
      love.graphics.print(ln2, buffer_padding, y)
   end
end

local normalize_color = function(c)
   -- support for old-style 255-based colors in love 0.x
   if(love._version_major > 0) then
      local new = {}
      for i,n in pairs(c) do new[i] = n/255 end
      return new
   else
      return c
   end
end

local scroll_offset = function(old_offset, point_line, display_rows)
   local bottom = display_rows - 2
   local relative = point_line - old_offset
   local chunk = display_rows / 2

   if 2 < relative and relative < bottom then return old_offset
   elseif relative < 2 then return math.max(0, old_offset - chunk)
   elseif bottom < relative then return math.min(point_line, old_offset + chunk)
   else return old_offset
   end
end

local render_buffer = function(b, colors, bh, focused)
   local display_rows = math.floor(bh / row_height)
   offset = scroll_offset(offset, b.point_line, display_rows)
   if(focused or not scroll_rows) then scroll_rows = display_rows end
   for i,line in ipairs(b.render_lines or b.lines) do
      if(i >= offset) then
         local row_y = row_height * (i - offset)
         if(row_y >= h - row_height) then break end

         if(i == b.mark_line) then -- mark
            love.graphics.setColor(colors.mark)
            love.graphics.rectangle("line", b.mark*em, row_y, em, row_height)
         end
         if(i == b.point_line) then -- point and point line
            love.graphics.setColor(colors.point_line)
            love.graphics.rectangle("fill", 0, row_y, w, row_height)
            love.graphics.setColor(colors.point)
            love.graphics.rectangle(focused and "fill" or "line",
                                    buffer_padding+b.point*em, row_y,
                                    em, row_height)
         end

         if(b.render_lines) then -- fancy colors get ANDed w base colors
            love.graphics.setColor(normalize_color({255, 255, 255}))
         else
            love.graphics.setColor(colors.text)
         end
         render_line(line, row_y)
      end
   end
end

local draw_scroll_bar = function(b, colors)
   -- this only gives you an estimate since it uses the amount of
   -- lines entered rather than the lines drawn, but close enough

   -- height is percentage of the possible lines
   local bar_height = math.min(100, (scroll_rows * 100) / #b.lines)
   -- convert to pixels (percentage of screen height, minus 10px padding)
   local bar_height_pixels = (bar_height * (h - 10)) / 100

   local sx = w - 5
   love.graphics.setColor(colors.scroll_bar)
   -- Handle the case where there are less actual lines than display rows
   if bar_height_pixels >= h - 10 then
      love.graphics.line(sx, 5, sx, h - 5)
   else
      -- now determine location on the screen by taking the offset in
      -- history and converting it first to a percentage of total
      -- lines and then a pixel offset on the screen
      local bar_end = (b.point_line * 100) / #b.lines
      bar_end = ((h - 10) * bar_end) / 100

      local bar_begin = bar_end - bar_height_pixels
      -- Handle overflows
      if bar_begin < 5 then
         love.graphics.line(sx, 5, sx, bar_height_pixels)
      elseif bar_end > h - 5 then
         love.graphics.line(sx, h - 5 - bar_height_pixels, sx, h - 5)
      else
         love.graphics.line(sx, bar_begin, sx, bar_end)
      end
   end
end

local draw = function(b, buffers_where, echo_message, colors, get_prop)
   row_height = love.graphics.getFont():getHeight()
   em = love.graphics.getFont():getWidth('a')

   -- Draw background
   if(#buffers_where > 0) then
      love.graphics.setColor(colors.background)
      love.graphics.rectangle("fill", 0, 0, w, h)
   end

   for pos,buf in pairs(buffers_where) do
      local x,y,bw,bh = unpack(pos)
      if #pos == 0 then
         x,y,bw,bh = padding,0,w-padding,h-row_height
         lume.extend(pos, {x,y,bw,bh})
      end
      love.graphics.push()
      love.graphics.translate(x, y)
      love.graphics.setScissor(x, y, bw, bh)
      if(get_prop("draw", nil, buf)) then
         get_prop("draw", nil, buf)()
      else
         render_buffer(buf, colors, bh, pos.current)
      end
      love.graphics.pop()
      love.graphics.setScissor()
   end

   love.graphics.setColor(colors.minibuffer_bg)
   love.graphics.rectangle("fill", 0, h - row_height - 1, w, row_height + 1)
   love.graphics.setColor(colors.minibuffer_fg)

   local minibuffer_h = math.floor(h - row_height - 1)
   if(b.path == "minibuffer") then
      love.graphics.print(b:render(), padding, minibuffer_h)
      love.graphics.setColor(colors.point)
      love.graphics.rectangle("fill", padding+b.point*em,
                              minibuffer_h, em, row_height + 1)
   elseif(echo_message) then
      love.graphics.print(echo_message, padding, minibuffer_h)
   else
      love.graphics.print(b:modeline(), padding, minibuffer_h)
   end

   if(b.path ~= "minibuffer" and #b.lines > 1) then
      draw_scroll_bar(b, colors)
   end
end

local wrap = function(f, ...)
   if(not canvas) then reset_canvas() end
   love.graphics.setCanvas({canvas, stencil=true})
   love.graphics.clear()
   love.graphics.setColor(normalize_color({255, 255, 255}))
   f(...)
   love.graphics.setCanvas()
   love.graphics.setColor(normalize_color({255, 255, 255}))
   love.graphics.draw(canvas, 0, 0, 0, scale, scale)
end

local resolve = function(path)
   if(lfs and not path:find("^/")) then
      return lfs.currentdir() .. "/" .. path
   else
      return path
   end
end

local get_wh = function() return canvas:getDimensions() end

return {
   write = function(path, contents)
      if not contents then return end
      local f = assert(io.open(resolve(path), "w"))
      f:write(contents)
      f:close()
   end,
   read = function(path)
      return(table.concat(lume.array(io.lines(resolve(path))), "\n"))
   end,
   ["type"] = lfs and function(path)
      return (lfs.attributes(resolve(path)) or {}).mode
   end,
   ls = lfs and function(path)
      local parts = lume.split(path, "/")
      path = table.concat(parts, "/")
      if path == "" then path = "." end
      local t = {}
      pcall(function() for f in lfs.dir(resolve(path)) do
               if f ~= "." and f ~= ".." then
                  if path ~= "." then f = path .. "/" .. f end
                  table.insert(t, f)
               end
      end end)
      return t
   end,

   ["key-down?"] = love.keyboard.isScancodeDown or love.keyboard.isDown,
   set_cursor = function(cursor)
      if(cursor == nil) then return end
      if(type(cursor) == "table") then
         return love.mouse.newCursor("assets/" .. cursor[1] .. ".png",
                                     cursor[2], cursor[3])
      else
         return love.mouse.getSystemCursor(cursor)
      end
   end,

   get_clipboard = function()
      return love.window and love.system.getClipboardText()
   end,
   set_clipboard = function(contents)
      if love.window then love.system.setClipboardText(contents) end
   end,

   get_wh = get_wh,

   get_buffer_wh = function()
      local _,_,sw,sh = love.graphics.getScissor()
      if(sw and sh) then return sw, sh end
      return get_wh()
   end,

   set_wh = function(nw, nh)
      fixed_w, fixed_h = nw, nh
      reset_canvas()
   end,

   set_scale = function(s) scale = s reset_canvas() end,
   scale = function(s)
      s = s or 1
      scale = math.max(1, math.min(scale+s, 4))
      reset_canvas()
   end,

   toggle_fullscreen = function()
      if(not love.window) then return end
      if(exists("fullscreen")) then
         local dimensions = love.filesystem.read("window")
         local new_w, new_h = dimensions:match("(%d+) (%d+)")
         w, h = tonumber(new_w), tonumber(new_h)
         love.window.setMode(w, h)
         love.filesystem.remove("fullscreen")
         reset_canvas()
         return false
      else
         love.filesystem.write("window", w .. " " .. h)
         love.filesystem.write("fullscreen", "true")
         local dw, dh = love.window.getDesktopDimensions()
         love.window.setMode(dw, dh, {fullscreen=true,
                                      fullscreentype="desktop",
                                      resizable=false})
         reset_canvas()
         return true
      end
   end,

   init = function()
      if(exists("fullscreen")) then
         if not love.window then return end
         local dw, dh = love.window.getDesktopDimensions()
         love.window.setMode(dw, dh, {fullscreen=true,
                                      fullscreentype="desktop",
                                      resizable=false})
      end
   end,

   normalize_color = normalize_color,

   draw = draw,

   wrap = wrap,

   quit = love.event.quit,

   ["line-height"] = function() return row_height or 1 end,

   resize = function() reset_canvas() end,
}
