(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))
(local sparkle (require :sparkle))
(local draw (require :draw))

(local (field-offset-x field-offset-y) (values 38 50))
(local (field-width field-height) (values 100 114))

(local state {:tick 0
              :particle-count 0
              :integrity 0
              :particle nil
              :particles []
              :img (love.graphics.newImage "assets/box.png")})
(global s state) ; for debugging in the repl

(fn make-particle []
  (set state.particle-count (+ state.particle-count 1))
  {:x (math.random (/ field-width 3)) :y 0 :w 2 :h 2 :dy 1})

(fn reset []
  (set state.tick 0)
  (set state.integrity 0)
  (set state.particle (make-particle))
  (set state.particle-count 0)
  (lume.clear state.particles)
  (phase.reset)
  (sparkle.reset state.img))

(local step 0.05)
(var t 0)
(fn update [dt]
  (set t (+ t dt))
  (when (< step t)
    (set t (- t step))
    (phase.update state.tick state.integrity)
    (set state.tick (+ state.tick 1))
    (when state.particle
      (set state.particle.y (+ state.particle.y state.particle.dy))
      (set state.particle.dy (math.min 1 (+ state.particle.dy 0.3)))
      (when (<= (+ field-offset-y field-height) state.particle.y)
        (set state.particle (make-particle)))))
  (when (love.keyboard.isDown "space") ; debug
    (set state.integrity (math.min (+ 1 state.integrity) 100)))
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

;; for reloadability
(fn full-draw [] (draw.draw state))

{:name "energize"
 :map {"left" (partial move -1)
       "right" (partial move 1)
       "up" up
       "down" lock
       ;; for debugging:
       "backspace" reset}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw full-draw :update update
         :read-only true :activate reset}}
