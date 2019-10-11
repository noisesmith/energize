;; Private module; do not load this directly!
(local lume (require :polywell.lib.lume))
(local completion (require :polywell.completion))
(local utf8 (require :polywell.lib.utf8))
(local editor (require :polywell.old))
(local state (require :polywell.state))
(local frontend (require :polywell.frontend))

;;; buffers, files, and windows

(fn find-file []
  "Prompt for a filename and open it in a new buffer.
If it's already open, switch to the existing buffer."
  (let [keep-backspacing? (fn []
                            (let [input (editor.get-input)]
                              (and (< 0 (# input))
                                   (not= "/" (: input :sub -1 -1)))))
        maybe-backspace-dir (fn []
                              (let [input (editor.get-input)]
                                (if (= "/" (: input :sub -1 -1))
                                  (do (editor.cmd.delete-backwards)
                                      (while (keep-backspacing?)
                                        (editor.cmd.delete-backwards)))
                                  (editor.cmd.delete-backwards))))
        completer          ; offer live feedback as you type
        (fn [input]
          (let [parts (lume.split input "/")
                file-part (table.remove parts)
                dir-part (table.concat parts "/")
                completions (completion.for (state.fs.ls dir-part) input)
                ;; different types should be distinct
                decorate (λ [path]
                           (if (= :file (state.fs.type path))
                               path
                               (.. path "/")))]
            ;; if it's not a table/string, we shouldn't see it
            (lume.sort (lume.filter (lume.map completions decorate))
                       (λ [s1 s2] (< (# s1) (# s2))))))
        dir (-> (editor.current-buffer-name)
                (lume.split "/")
                (doto (table.remove))
                (table.concat "/"))]
    (editor.read-line "Open: " editor.open
                      {:completer completer
                       :bind {:map {"backspace" maybe-backspace-dir}}
                       :initial-input (if (= (# dir) 0)
                                          dir
                                          (.. dir "/"))})))

(fn close [confirm]
  "Close the current buffer, unless it has unsaved changes."
  (if (and state.b.needs_save (not confirm) (not state.b.props.no-file))
      (editor.echo "Unsaved changes!")
      (editor.kill-buffer)))

(fn switch-buffer []
  "Prompt for an already-open buffer to switch to."
  (let [last-buffer (or (editor.last-buffer) "*repl*")
        callback (fn [b]
                   (when (and b (lume.find (editor.buffer-names) b))
                     (let [b (if (= b "") last-buffer b)]
                       (set state.last-buffer state.b)
                       (editor.change-buffer b))))
        completer (partial completion.for (editor.buffer-names))]
    (editor.read-line "Switch to buffer: " callback {:completer completer})))

(fn next-buffer [n]
  "Switch to the next buffer."
  (let [current (- (lume.find state.buffers state.b) 1)
        target (+ (% (+ current (or n 1)) (# state.buffers)) 1)
        target-path (. (editor.buffer-names) target)]
    (set state.last-buffer state.b)
    (editor.change-buffer target-path)))

(fn focus-next [n]
  "Change focus to the next window, if more than one window is visible."
  (set state.last-buffer state.b)
  (set state.window (math.max 1 (+ (or state.window 1) (or n 1))))
  (when (< (# state.windows) state.window)
    (set state.window 1))
  (set state.b (. state.windows state.window 2)))

(var last-split nil)

(fn split [style]
  "Split the screen.
Takes a style arg which can be :vertical, :horizontal, :triple, or nil."
  (let [(w h) (editor.get-wh)
        hw (/ w 2) hh (/ h 2)
        second (or state.last-buffer state.b)]
    (set state.windows (if (= style :triple)
                           [[[10 10 hw h] state.b]
                            [[(+ hw 10) 10 hw (- hh 10)] second]
                            [[(+ hw 10) hh hw hh] second]]
                           (= style :horizontal)
                           [[[10 10 (- hw 10) h] state.b]
                            [[(+ hw 10) 10 hw h] second]]
                           (= style :vertical)
                           [[[10 10 (- w 10) (- hh 10)] state.b]
                            [[10 (- hh 10) w h] second]]
                           :else
                           [[[10 10 (- w 10) (- h 10)] state.b]]))
    (set last-split style)
    (set state.window 1)))

(fn reload []
  "Prompt for an already-loaded module, and reload it."
  (let [completer #(completion.for (lume.keys package.loaded) $1)]
    (editor.read-line "Module: " lume.hotswap {:completer completer})))

(fn save []
  "Save the file associated with the current buffer, if applicable."
  (let [b (if (= state.b.path "minibuffer") (editor.internal.behind) state.b)]
    (when (and b.needs_save (not b.props.no-file))
      (state.fs.write b.path (.. (table.concat b.lines "\n") "\n"))
      (set b.needs_save false))))

(fn revert []
  "Revert the buffer to the contents of the file on disk without saving."
  (let [contents (state.fs.read state.b.path)]
    (when contents
      (set state.b.lines (lume.split contents "\n"))
      (set state.b.point 0)
      (when (> state.b.point_line (# state.b.lines))
        (set state.b.point_line (# state.b.lines)))
      (when (> state.b.mark (# state.b.lines))
        (set state.b.mark (# state.b.lines))))))

(fn echo-prop []
  "Look up a buffer property and echo to the minibuffer. Useful for debugging."
  (let [prop-names (lume.keys state.b.props)]
    (editor.read-line "Echo prop: "
                      (λ [prop]
                        (editor.echo (tostring (editor.get-prop prop))))
                      {:completer (partial completion.for prop-names)})))

;;; movement

;; backward_char
;; backward_word
;; beginning_of_buffer
;; beginning_of_input
;; beginning_of_line
;; end_of_buffer
;; end_of_line
;; forward-char
;; forward_word
;; jump_to_mark
;; next_line
;; prev_line
;; scroll_down
;; scroll_up

(fn go-to-line []
  "Prompt for a line number and jump to it."
  (editor.read-line "Go to line: " (fn [l] (editor.go-to (tonumber l)))))

;;; edits and clipboard

;; delete_backwards
;; delete_forwards
;; forward_kill_word
;; kill_line
;; kill_region
;; kill_ring_save
;; backward_kill_word
;; newline
;; newline_and_indent
;; mark
;; no_mark
;; system_copy_region
;; system_yank
;; yank
;; yank_pop

;;; search

(fn search [original-dir]
  "Prompt for a string and search down thru the buffer for it.
While the prompt is open, ctrl-f finds the next occurrence, and ctrl-r
finds the previous."
  (local (point point-line) (editor.point))
  (var continue-from point-line)
  (let [lines (editor.get-lines)
        path (editor.current-buffer-name)
        on-change (fn [find-next new-dir]
                    (let [input (editor.get-input)
                          direction (or new-dir original-dir 1)
                          start (if find-next
                                    continue-from
                                    point-line)]
                      (var i start)
                      (var hit nil)
                      (while (and (not (= input "")) (not hit)
                                  (> i 0) (<= i (# lines)))
                        (set hit (utf8.find (. lines i) input))
                        (when hit
                          (set continue-from (+ i direction))
                          (editor.go-to i (- hit 1) path))
                        (set i (+ i direction)))))
        callback (fn [_ cancel]
                   (when cancel
                     (editor.go-to point-line point)))
        cancel (partial editor.cmd.exit-minibuffer true)]
    (editor.read-line "Search: " callback
                      {:on-change on-change
                       :cancelable? true
                       :bind {:map {"escape" cancel
                                    "up" (partial on-change true -1)
                                    "down" (partial on-change true 1)}
                              :ctrl {"g" cancel
                                     "n" cancel
                                     "p" cancel
                                     "f" (partial on-change true)
                                     "s" (partial on-change true 1)
                                     "r" (partial on-change true -1)}}})))

(fn replace []
  "Prompt for a string and replacement, walk thru the buffer making the change."
  (let [lines (editor.get-lines)
        (point point-line) (editor.point)
        path (editor.current-buffer-name)
        actually-replace (fn [replace i with replacer y]
                           (when (or (= y "") (= y "y")
                                     (= (string.lower y) "yes"))
                             (let [new (string.gsub (. lines i)
                                                    replace with)]
                               (editor.set-line new i path)
                               (replacer with false (+ i 1)))))
        replacer
        (fn replacer [replace with cancel continue-from]
          (if cancel
              (editor.go-to point-line point)
              (do
                (var hit-point nil)
                (var i (or continue-from point-line))
                (while (and (not hit-point)
                            (< i (# lines)))
                  (let [hit-point (utf8.find (. lines i) replace)]
                    (when hit-point
                      (editor.go-to i (- hit-point 1) path)
                      (editor.read-line "Replace? [Y/n]"
                                        (partial actually-replace
                                                 replace i with replacer)))
                    (set i (+ i 1)))))))]
    (editor.read-line "Replace: "
                      (fn [replace-text]
                        (editor.read-line (.. "Replace " replace-text " with: ")
                                          (partial replacer replace-text)
                                          {:cancelable? true})))))

;;; other

(fn complete []
  "Try to complete the word at the point, based on mode-specific logic."
  (let [(_ point-line) (editor.point)
        line (editor.get-line point-line)
        input (or (lume.last (lume.array (string.gmatch line "[._%a0-9]+")))
                    "")]
    (when (>= (# input) 1)
      (let [completer (assert (editor.get-prop :completer) "no completer known")
            completions (completer input)]
        (if (= (# completions) 1)
            (editor.handlers.textinput (utf8.sub (. completions 1)
                                                 (+ (# input) 1)) true)
            (> (# completions) 0)
            (let [common (completion.longest-common-prefix completions)]
              (if (= common input)
                  (editor.echo (table.concat completions " "))
                  (editor.handlers.textinput (utf8.sub common (+ (# input) 1))
                                             true))))))))
(fn execute []
  "Prompt for a command by name, and execute it."
  (editor.read-line "Command: "
                    (fn [cmd-name]
                      (let [cmd (. editor.cmd cmd-name)]
                        (if cmd
                            (cmd)
                            (editor.echo "Command not found: " cmd-name))))
                    {:completer (partial completion.for editor.cmd)}))

(fn replace-input [input]
  (tset state.b.lines (# state.b.lines) (.. state.b.prompt input))
  (set state.b.point_line (# state.b.lines))
  (set state.b.point (# (lume.last state.b.lines))))

(fn history-prev []
  "Cycle the current input thru past input history."
  (when (< state.b.input_history_pos (# state.b.input_history))
    (set state.b.input_history_pos (+ state.b.input_history_pos 1))
    (let [n (+ (- (# state.b.input_history) state.b.input_history_pos) 1)]
      (replace-input (or (. state.b.input_history n) "")))))

(fn history-next []
  "Cycle the current input forward thru input history."
  (if (>= state.b.input_history_pos 0)
      (do (set state.b.input_history_pos (- state.b.input_history_pos 1))
          (let [n (+ (- (# state.b.input_history) state.b.input_history_pos) 1)]
            (replace-input (or (. state.b.input_history n) ""))))
      (do (set state.b.input_history_pos 0)
          (replace-input ""))))

(fn default-indent [lines prev-line-number]
  (# (: (or (. lines prev-line-number) "") :match "^ *")))

(fn indent []
  "Indent the current line according to mode-specific rules.
If the mode doesn't provide an indenter, indent to match the previous line."
  ;; various modes can override indentation by setting the :indentation prop
  (let [get-indentation (editor.get-prop :indentation default-indent)
        indentation (get-indentation state.b.lines (- state.b.point_line 1))
        current (# (: (editor.get-line (editor.get-line-number)) :match "^ *"))
        (point line) (editor.point)]
    (editor.cmd.beginning-of-line)
    (editor.cmd.delete-forwards current)
    (editor.insert (: " " :rep indentation))
    (editor.go-to line (math.max indentation (+ point (- indentation current))))))

(fn window-lines []
  (let [[_ _ _ h] (. state.windows state.window 1)]
    (math.floor (- (/ (or h 0) (frontend.line-height)) 1))))

(fn scroll [n]
  (set state.b.point_line (-> (+ state.b.point_line (* (window-lines) (or n 1)))
                              (math.max 1)
                              (math.min (# state.b.lines)))))

(fn describe []
  "Prompt for the name of a command and display docs for that command."
  (editor.read-line "Command: "
                    (fn [cmd-name]
                      (let [cmd (. editor.cmd cmd-name)]
                        (if cmd
                            (let [oldprint print]
                              (set _G.print editor.print)
                              (doc cmd)
                              (set _G.print oldprint))
                            (editor.echo "Command not found: " cmd-name))))
                    {:completer (partial completion.for editor.cmd)}))

(fn toggle-fullscreen []
  (frontend.toggle_fullscreen)
  ;; recalculate screen split sizes
  ;; TODO: bug; when disabling full-screen with a split active, it makes the new
  ;; split too small
  (split last-split))

;; undo

{:find-file find-file :close close :search search :replace replace
 :next-buffer next-buffer :prev-buffer (partial next-buffer -1)
 :switch-buffer switch-buffer :echo-prop echo-prop
 :focus-next focus-next :split split
 :save save :reload reload :revert revert :complete complete
 :go-to-line go-to-line :execute execute
 :toggle-fullscreen toggle-fullscreen :scale frontend.scale
 :history-prev history-prev :history-next history-next
 :indent indent :newline-and-indent #(do (editor.cmd.newline) (indent))
 :scroll-up (partial scroll -1) :scroll-down scroll
 :describe describe}
