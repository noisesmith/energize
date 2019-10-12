(local editor (require :polywell))

(editor.add-mode {:name "base"
                  :map {"f11" editor.cmd.toggle-fullscreen}
                  :ctrl {"x" {:ctrl {"f" editor.cmd.find-file}
                              :map {"1" editor.cmd.split
                                    "2" (partial editor.cmd.split "vertical")
                                    "3" (partial editor.cmd.split "horizontal")
                                    "4" (partial editor.cmd.split "triple")
                                    "b" editor.cmd.switch-buffer
                                    "k" editor.cmd.close
                                    "o" editor.cmd.focus-next
                                    "=" editor.cmd.scale
                                    "-" (partial editor.cmd.scale -1)}}
                         "q" editor.cmd.quit
                         "pageup" editor.cmd.next-buffer
                         "pagedown" editor.cmd.prev-buffer}
                  :alt {"x" editor.cmd.execute
                        "return" editor.cmd.toggle-fullscreen}
                  :ctrl-alt {"b" editor.cmd.switch-buffer}})

(editor.add-mode (require :config.line))
(editor.add-mode (require :config.edit-mode))
(editor.add-mode (require :config.fennel-mode))
(editor.add-mode (require :config.repl)) ; for fennel code
(editor.add-mode (require :energize))
(editor.add-mode (require :intro))

(editor.init "*repl*" "repl" ["This is the repl. Enter code to run." ">> "])
(editor.open "*intro*" "intro" {:no-file true})
