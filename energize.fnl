(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))
(local sparkle (require :sparkle))
(local draw (require :draw))

(local (field-offset-x field-offset-y) (values 38 50))
(local (field-height field-width) (values 80 112))

(local state {:tick 0
              :particle-count 0
              :complete nil
              :particle nil
              :particles []
              :img (love.graphics.newImage "assets/klingon.png")})
(global s state) ; for debugging in the repl

(fn make-particle []
  (set state.particle-count (+ state.particle-count 1))
  {:x (math.random (/ field-width 3)) :y 0 :w 2 :h 2 :dy 1})

(fn reset []
  (set state.tick 0)
  (set state.complete nil)
  (set state.particle (make-particle))
  (lume.clear state.particles)
  (phase.reset)
  (sparkle.reset state.img))

(local step 0.05)
(var t 0)
(fn update [dt]
  (set t (+ t dt))
  (when (< step t)
    (set t (- t step))
    (phase.update state.tick state.complete)
    (set state.tick (+ state.tick 1))
    (when state.particle
      (set state.particle.y (+ state.particle.y state.particle.dy))
      (set state.particle.dy (math.min 1 (+ state.particle.dy 0.3)))
      (when (<= (+ field-offset-y field-height) state.particle.y)
        (set state.particle (make-particle)))))
    (when (and state.complete (< state.complete 100))
      (set state.complete (+ state.complete 1)))
    (when (< step t)
      (update (- dt step))))

(fn move [dir]
  (when state.particle
    (set state.particle.x (-> (+ state.particle.x dir)
                              (math.min (- field-width state.particle.w))
                              (math.max 0)))))

(fn up []
  (when state.particle
    (set state.particle.dy -2)))

(fn lock []
  (when (and state.particle (< (phase.get) 0.5))
    (table.insert state.particles state.particle)
    (set state.particle.w (* state.particle.w 2))
    (set state.particle.h (* state.particle.h 2))
    (set state.particle (make-particle))))

(fn full-draw [] (draw.draw state))

{:name "energize"
 :map {"left" (partial move -1)
       "right" (partial move 1)
       "up" up
       "down" lock
       ;; for debugging:
       "backspace" reset
       "space" #(set (state.complete state.particle) 0)}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw full-draw :update update
         :read-only true :activate reset}}
