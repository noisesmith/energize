;; cutscenes show exterior shots of a starfield plus other things.
(local editor (require :polywell))
(local shake (require :shake))

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
(local nebula (love.graphics.newImage "assets/nebula.png"))

(fn draw-cutscene-runabout [tick]
  (love.graphics.draw nebula 125 50)
  (love.graphics.draw runabout (+ (* tick 5) 150) 100)
  (love.graphics.draw lakota (- (* tick 35) 19) 30))

(local miranda (love.graphics.newImage "assets/miranda.png"))

(fn firing? [tick]
  (or (< 0.7 tick 1.8)
      (< 6.5 tick 7.5)))

(fn draw-cutscene-miranda [tick]
  (when (firing? tick)
    (shake true))
  (love.graphics.draw lakota (+ 120 (* tick 5)) 110)
  (when (firing? tick)
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

(fn skip []
  (let [[buffer-name buffer-mode] (editor.get-prop :destination
                                                   ["*energize*" "energize"])]
    (editor.kill-buffer)
    (editor.open buffer-name buffer-mode true {:no-file true
                                               :level (editor.get-prop :level)})))

(local durations {2 11
                  3 6
                  4 8})

(fn update [dt]
  (set tick (+ tick dt))
  (let [level (editor.get-prop :level)
        star-dx (or (. star-speeds level) -2)
        duration (. durations level)]
    (each [_ s (pairs stars)]
      (set s.x (math.fmod (+ s.x (* s.dx star-dx dt)) 320)))
    (when (and duration (< duration tick))
      (skip))))

{:name "cutscene"
 :parent "base"
 :map {"escape" skip
       "return" skip
       "space" skip}
 :props {:full-draw draw
         :update update
         :activate #(set tick 0)
         :read-only true}}
