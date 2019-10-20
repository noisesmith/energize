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
      (< 6 tick 7.5)))

(fn draw-cutscene-miranda [tick]
  (when (firing? tick)
    (shake true))
  (love.graphics.draw lakota (+ 120 (* tick 5)) 80)
  (when (firing? tick)
    (love.graphics.setColor 0.8 0.8 0.15 0.9)
    (love.graphics.line (+ 230 (* tick 5)) 100
                        (+ 130 (* tick 30)) (+ 93 (* tick 15)))
    (love.graphics.line (+ 230 (* tick 5)) 100
                        (+ 110 (* tick 30)) (+ 90 (* tick 15)))
    (love.graphics.setColor 1 1 1))
  (love.graphics.draw miranda (+ 5 (* tick 30)) (+ 30 (* tick 15))))

(local win-font (love.graphics.newFont "assets/Trek TNG Monitors.ttf" 44))
(local win (love.graphics.newImage "assets/win.png"))

(fn draw-cutscene-win [tick]
  (love.graphics.draw win)
  (love.graphics.printf "YOU\nWIN" win-font 245 46 100 "left"))

(local credits (love.filesystem.read "text/credits.txt"))

(fn draw-cutscene-credits [tick]
  (love.graphics.print credits 20 (math.floor (- 100 (* tick 5)))))

(local scenes
       {2 draw-cutscene-planet
        3 draw-cutscene-runabout
        4 draw-cutscene-miranda
        5 draw-cutscene-win
        6 draw-cutscene-credits})

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

(local star-speeds [nil 0 -0.3 -0.3 0.5])

(fn skip []
  (let [level (editor.get-prop :level 1)
        [buffer-name buffer-mode] (editor.get-prop :destination
                                                   ["*energize*" "energize"])]
    (if (= level 5)
        (editor.set-prop :level 6)
        (< level 6)
        (do (editor.kill-buffer)
            (editor.open buffer-name buffer-mode true
                         {:no-file true :level level})))))

(local durations {2 11
                  3 6
                  4 8})

(fn update [dt]
  (set tick (+ tick dt))
  (let [level (editor.get-prop :level)
        star-dx (or (. star-speeds level) -2)
        duration (. durations level)]
    (each [_ s (pairs stars)]
      (if (= level 5)
          ;; credits have vertical scroll
          (set s.y (math.fmod (+ s.y (* s.dx star-dx dt)) 320))
          (set s.x (math.fmod (+ s.x (* s.dx star-dx dt)) 320))))
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
