(local editor (require :polywell))

(assert (not= 0 love._version_major)
        (.. "This game requires LOVE 11.x or greater!\n\n"
            "Please download it from https://love2d.org."))

(editor.add-mode {:name "base"
                  :map {"f11" editor.cmd.toggle-fullscreen}
                  :ctrl {"x" {:ctrl {"f" editor.cmd.find-file}
                              :map {"1" editor.cmd.split
                                    "2" (partial editor.cmd.split "vertical")
                                    "3" (partial editor.cmd.split "horizontal")
                                    "4" (partial editor.cmd.split "triple")
                                    "b" editor.cmd.switch-buffer
                                    "k" editor.cmd.close
                                    "r" (partial editor.change-buffer "*repl*")
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
(editor.add-mode (require :cutscene))
(editor.add-mode (require :intro))
(editor.add-mode (require :briefing))
(editor.add-mode (require :tutorial))

(editor.init "*repl*" "repl" ["This is the repl. Enter code to run." ">> "])
(editor.open "*intro*" "intro" true)
