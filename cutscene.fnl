(local editor (require :polywell))

(local stars [])

(var tick 0)

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
  (let [draw-callback (editor.get-prop :draw-callback)]
    (when draw-callback
      (draw-callback tick))))

(fn update [dt]
  (set tick (+ tick dt))
  (each [_ s (pairs stars)]
    (set s.x (math.fmod (+ s.x (* s.dx dt)) 320))))

(fn skip []
  (editor.kill-buffer)
  (let [[buffer-name mode-name] (editor.get-prop :destination)]
    (editor.open buffer-name mode-name {:no-file true})))

{:name "cutscene"
 :parent "base"
 :map {"escape" skip
       "return" skip
       "space" skip}
 :props {:full-draw draw
         :update update
         :read-only true}}
