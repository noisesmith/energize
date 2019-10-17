(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/cmdr.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(local texts [(love.filesystem.read "text/1.txt")
              (love.filesystem.read "text/2.txt")
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

(fn draw-cutscene-2 [tick]
                           (love.graphics.draw planet 20 35)
                           (let [x (- (* tick 35) 190)]
                             (love.graphics.draw lakota x 90)))
(local cutscenes
       {2 {:draw-callback draw-cutscene-2
           :star-dx 0
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
