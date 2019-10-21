(local editor (require :polywell))
(local audio (require :audio))

(assert (not= 0 love._version_major)
        (.. "This game requires LOVE 11.x or greater!\n\n"
            "Please download it from https://love2d.org."))

(fn warp [level]
  (let [progress-str (love.filesystem.read "progress")
        progress (tonumber progress-str)]
    (when (<= level (or progress 0))
      (editor.kill-buffer "*energize*")
      (editor.open "*briefing*" "briefing" true {:lost? false
                                                 :level level}))))

(editor.add-mode {:name "base"
                  :map {"f11" editor.cmd.toggle-fullscreen
                        "f2" #(editor.open "energize.fnl")
                        "m" audio.toggle}
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
                        "return" editor.cmd.toggle-fullscreen
                        "1" (partial warp 1)
                        "2" (partial warp 2)
                        "3" (partial warp 3)
                        "4" (partial warp 4)}
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
(editor.add-mode (require :debriefing))
(editor.add-mode (require :pause))

(editor.init "*repl*" "repl" ["This is the repl. Enter code to run." ">> "])
(editor.open "*intro*" "intro" true)
