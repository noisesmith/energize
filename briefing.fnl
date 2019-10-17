;; briefings show Commander T'Ral explaining the next mission.
(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/cmdr.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(local texts [(love.filesystem.read "text/1.txt")
              (love.filesystem.read "text/2.txt")
              (love.filesystem.read "text/3.txt")
              "It appears you have gotten farther than the game has been written."])

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

(local planet (love.graphics.newImage "assets/planet.png"))
(local lakota (love.graphics.newImage "assets/lakota.png"))

(fn draw-cutscene-planet [tick]
  (love.graphics.draw planet 20 35)
  (let [x (- (* tick 35) 190)]
    (love.graphics.draw lakota x 90)))

(local runabout (love.graphics.newImage "assets/runabout-damage.png"))

(fn draw-cutscene-runabout [tick]
  (love.graphics.draw runabout (+ (* tick 5) 150) 100)
  (love.graphics.draw lakota (- (* tick 35) 19) 50))

(local miranda (love.graphics.newImage "assets/miranda.png"))

(fn draw-cutscene-miranda [tick]
  (love.graphics.draw lakota (+ 120 (* tick 5)) 110)
  (when (< 1 tick 3)
    (love.graphics.setColor 0.8 0.8 0.15 0.9)
    (love.graphics.line (+ 230 (* tick 5)) 130
                        (+ 130 (* tick 30)) (+ 63 (* tick 15)))
    (love.graphics.line (+ 230 (* tick 5)) 130
                        (+ 110 (* tick 30)) (+ 60 (* tick 15)))
    (love.graphics.setColor 1 1 1))
  (love.graphics.draw miranda (+ 5 (* tick 30)) (* tick 15)))

(local cutscenes
       {2 {:draw-callback draw-cutscene-planet
           :star-dx 0
           :destination ["*energize*" "energize"]}
        3 {:draw-callback draw-cutscene-runabout
           :star-dx -0.3
           :destination ["*energize*" "energize"]}
        4 {:draw-callback draw-cutscene-miranda
           :star-dx 0.3
           :destination ["*energize*" "energize"]}})

(fn continue []
  (set offset 0)
  (editor.kill-buffer)
  (let [level (editor.get-prop :level 1)
        cutscene (. cutscenes level)]
    (if cutscene
        (editor.open "*cutscene*" "cutscene" true cutscene)
        seen-tutorial?
        (editor.open "*energize*" "energize" true)
        (do (set seen-tutorial? true)
            (editor.open "*tutorial*" "tutorial" true)))))

(fn scroll [dir]
  (set offset (+ offset dir)))

{:name "briefing"
 :parent "base"
 :map {"escape" continue
       "return" continue
       "space" (partial scroll -25)
       "up" (partial scroll 10)
       "down" (partial scroll -10)}
 :props {:full-draw draw
         :read-only true}}
