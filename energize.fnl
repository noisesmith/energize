(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))
(local sparkle (require :sparkle))
(local draw (require :draw))

(local state {:tick 0
              :particle-count 0
              :beam-x 40
              :beam-w 12
              :integrity 0
              :particle nil
              :particles []
              :field {:ox 38 :oy 50 :w 100 :h 114}
              :img (love.graphics.newImage "assets/box.png")})
(global s state) ; for debugging in the repl

(fn make-particle []
  (set state.particle-count (+ state.particle-count 1))
  {:x (+ state.beam-x (math.random state.beam-w)) :y state.field.oy
   :w 2 :h 2 :dy 1 :dx 2})

(fn reset []
  (set state.tick 0)
  (set state.integrity 0)
  (set state.particle (make-particle))
  (set state.particle-count 0)
  (lume.clear state.particles)
  (phase.reset)
  (sparkle.reset state.img))

(fn drop-particle [particle]
  (set particle.y (+ particle.y particle.dy))
  (set particle.x (+ particle.x particle.dx))
  (set particle.dy (math.min 1 (+ particle.dy 0.3)))
  (if (< particle.x state.beam-x)
      (set particle.dx (math.abs particle.dx))
      (< (+ state.beam-w state.beam-x) particle.x)
      (set particle.dx (- (math.abs particle.dx))))
  (if (<= (+ state.field.oy state.field.h) particle.y)
      (make-particle)
      particle))

(fn move [dir]
  (set state.beam-x (lume.clamp (+ state.beam-x dir)
                                state.field.ox
                                (- (+ state.field.w state.field.ox)
                                     state.beam-w))))

(local step 0.05)
(var t 0)
(fn update [dt]
  (set t (+ t dt))
  (when (< step t)
    (set t (- t step))
    (phase.update state.tick state.integrity)
    (set state.tick (+ state.tick 1))
    (when state.particle
      (set state.particle (drop-particle state.particle))))
  (when (love.keyboard.isDown "tab") ; debug
    (set state.integrity (math.min (+ 1 state.integrity) 100)))
  (when (love.keyboard.isDown "left") (move -1))
  (when (love.keyboard.isDown "right") (move 1))
  (when (< step t)
    (update (- dt step))))

(fn up []
  (when state.particle
    (set state.particle.dy -2)))

(fn in-bounds? [{: x : y}]
  (and (< (+ state.field.ox 6) x (+ state.field.ox 92))
       (< (+ state.field.oy 70) y (+ state.field.ox 112))))

(fn lock []
  (when (and state.particle (< (phase.get) 0.5))
    (table.insert state.particles state.particle)
    (set state.particle.w (* state.particle.w 2))
    (set state.particle.h (* state.particle.h 2))
    (when (in-bounds? state.particle)
      (set state.integrity (math.min (+ 7 state.integrity) 100)))
    (set state.particle (and (< state.integrity 100) (make-particle)))))

;; for reloadability
(fn full-draw [] (draw.draw state))

{:name "energize"
 :map {"up" up
       "space" lock
       ;; for debugging:
       "backspace" reset}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw full-draw :update update
         :read-only true :activate reset}}
