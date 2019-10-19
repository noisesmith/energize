;; cutscenes show exterior shots of a starfield plus other things.
(local editor (require :polywell))

(local stars [])

(var tick 0)

(fn make-star []
  {:x (math.random 320) :y (math.random 200) :dx (math.random 16)})

(for [_ 1 64]
  (table.insert stars (make-star)))

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
(local nebula (love.graphics.newImage "assets/nebula.png"))

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

(local scenes
       {2 draw-cutscene-planet
        3 draw-cutscene-runabout
        4 draw-cutscene-miranda})

(fn draw []
  (love.graphics.clear)
  (each [_ {: x : y : dx} (pairs stars)]
    (love.graphics.setColor 1 1 1 (/ dx 16))
    (love.graphics.circle :fill x y 1))
  (love.graphics.setColor 1 1 1)
  (let [scene (or (. scenes (editor.get-prop :level))
                  (editor.get-prop :draw-callback))]
    (when scene
      (scene tick))))

(local star-speeds [nil 0 -0.3 -0.3 0.1])

(fn update [dt]
  (set tick (+ tick dt))
  (let [star-dx (or (. star-speeds (editor.get-prop :level)) -2)]
    (each [_ s (pairs stars)]
      (set s.x (math.fmod (+ s.x (* s.dx star-dx dt)) 320)))))

(fn skip []
  (let [[buffer-name buffer-mode] (editor.get-prop :destination
                                                   ["*energize*" "energize"])]
    (editor.kill-buffer)
    (editor.open buffer-name buffer-mode {:no-file true})))

{:name "cutscene"
 :parent "base"
 :map {"escape" skip
       "return" skip
       "space" skip}
 :props {:full-draw draw
         :update update
         :activate #(set tick 0)
         :read-only true}}
