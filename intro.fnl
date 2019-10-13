(local editor (require :polywell))
(local text (love.graphics.newImage "assets/title.png"))
(local lakota (love.graphics.newImage "assets/lakota.png"))

(local stars [])

(var x 5)

(fn make-star []
  {:x (math.random 320) :y (math.random 200) :dx (math.random 16)})

(for [_ 1 64]
  (table.insert stars (make-star)))

(fn draw []
  (love.graphics.clear)
  (each [_ {: x : y : dx} (pairs stars)]
    (love.graphics.setColor 1 1 1 (/ dx 16))
    (love.graphics.circle :fill x y 1))
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw lakota x 90)
  (love.graphics.draw text))

(fn update [dt]
  (set x (+ x (* dt 20)))
  (when (< 440 x) (set x -190))
  (each [_ s (pairs stars)]
    (set s.x (math.fmod (+ s.x (* s.dx dt)) 320))))

(fn skip []
  (editor.kill-buffer)
  (editor.open "*briefing*" "briefing" {:no-file true}))

{:name "intro"
 :parent "base"
 :map {"escape" skip
       "return" skip
       "space" skip
       ;; for jumping straight to the game
       "\\" #(editor.open "*energize*" "energize" {:no-file true})}
 :props {:full-draw draw
         :update update
         :read-only true}}
