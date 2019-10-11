(local editor (require :polywell.old))
(local state (require :polywell.state))
(local lume (require :polywell.lib.lume))

(set editor.handlers (require :polywell.handlers))

;; be reload-friendly on the new stuff
(let [old-cmds editor.cmd]
  (set editor.cmd (require :polywell.commands))
  (each [name f (pairs old-cmds)]
    (tset editor.cmd name f)))

(fn editor.add-mode [mode]
  (each [_ k (ipairs [:map :ctrl :alt :ctrl-alt :props])]
    (when (not (. mode k))
      (tset mode k {})))
  (each [_ pattern (ipairs (or mode.activate-patterns []))]
    (tset state.activate-patterns pattern mode.name))
  (tset state.modes (assert mode.name "Missing mode name!") mode)
  (when (= :table (type mode.parent))
    (set mode.parent mode.parent.name))
  ;; auto-define a mode-activating command
  (tset editor.cmd (.. mode.name "-mode")
        (partial editor.activate-mode mode.name)))

(fn editor.define-key [mode-name map-name key command]
  (let [mode (assert (. state.modes mode-name) (.. "Mode " mode-name " not found."))
        _ (assert (. {:map true :ctrl true :alt true :ctrl-alt true} map-name)
                    (.. "Invalid key map name: " map-name))
        map (. mode map-name)]
    (when (not (. mode map-name))
      (tset mode map-name map))
    (tset map key command)))

(fn editor.clear []
  (when state.b.lines
    (lume.clear state.b.lines)
    (table.insert state.b.lines "")
    (set state.b.point 0)
    (set state.b.point_line 1)))

;; for things like repls where you want history tracking
(fn editor.handle-input-with [handle]
  (fn handle-input []
    (editor.enforce-max-lines (editor.get-prop :max-lines 512))
    (let [input (editor.get-input)]
      (editor.history-push input)
      (editor.cmd.end-of-line)
      (editor.cmd.newline)
      (editor.cmd.no-mark)
      (handle input)
      (editor.print-prompt))))

(editor.add-mode {:name :default})

editor
