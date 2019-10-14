;; right now this is purely decorative, but maybe it will affect the particle
;; lock once we get that in place?
(local lume (require :polywell.lib.lume))
(local (cox coy) (values 200 22))
(local phase [])

(fn reset []
  (lume.clear phase)
  (for [_ 1 120] (table.insert phase 0)))

(fn update [tick progress]
  (table.remove phase)
  ;; TODO: add ability to control phase frequency?
  (let [v (* 18 (math.sin (math.rad (* tick 6))))
        v (/ v (math.max 1 (/ (or progress 0) 8)))]
    (table.insert phase 1 v)))

(fn draw []
  (love.graphics.setColor 0.5 0.5 0.5 0.5)
  (let [y (- coy (* 18 0.5))]
    (love.graphics.line cox y (+ cox 200) y))
  (love.graphics.setColor 0.7 0.7 1)
  (each [x y (ipairs phase)]
    (love.graphics.points (+ x cox) (+ y coy -1))
    (love.graphics.points (+ x cox) (+ y coy))))

(fn get [] (. phase 1))

{:update update :draw draw
 :get get :reset reset}
