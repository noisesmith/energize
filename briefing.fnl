;; briefings show Commander T'Ral explaining the next mission.
(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/cmdr.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(local texts [(love.filesystem.read "text/1.txt")
              (love.filesystem.read "text/2.txt")
              (love.filesystem.read "text/3.txt")
              (love.filesystem.read "text/4.txt")])

(local retry-text (.. "I am afraid that is not an acceptable level of pattern"
                      " degradation.\n\nWe will have to recover the subject"
                      " from the pattern buffer to reverse the effects."))

(local footer "\n\n  [press enter]")

(var seen-tutorial? false)
(var offset 0)

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (love.graphics.setScissor 194 24 126 176)
  (let [text (if (editor.get-prop :lost?)
                 retry-text
                 (. texts (editor.get-prop :level 1)))]
    (love.graphics.printf (.. text footer) font 194 (+ 24 offset) 124))
  (love.graphics.setScissor))

(fn continue []
  (set offset 0)
  (let [level (editor.get-prop :level 1)]
    (editor.kill-buffer)
    (if (< 1 level)
        (editor.open "*cutscene*" "cutscene" true {:level level})
        seen-tutorial?
        (editor.open "*energize*" "energize" true)
        (do (set seen-tutorial? true)
            (editor.open "*tutorial*" "tutorial" true)))))

(local maxes [-80 -100 -10 -80])

(fn scroll [dir]
  (set offset (-> (+ offset dir)
                  (math.min 0)
                  (math.max (or (. maxes (editor.get-prop :level)) -500)))))

{:name "briefing"
 :parent "base"
 :map {"escape" continue
       "return" continue
       "space" (partial scroll -25)
       "up" (partial scroll 10)
       "down" (partial scroll -10)}
 :props {:full-draw draw
         :read-only true}}
