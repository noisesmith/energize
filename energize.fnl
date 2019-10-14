(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))
(local sparkle (require :sparkle))
(local draw (require :draw))

(local state {:tick 0
              :particle nil
              :particles []
              :particle-count 0
              :missed 0

              :beam-x 40
              :beam-w 12

              ;; how many particles have landed successfully?
              :integrity 0
              ;; once we're to 100% integrity, how materialized is it?
              :progress 0

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
  (set state.particle-missed 0)
  (set state.progress 0)
  (lume.clear state.particles)
  (phase.reset)
  (sparkle.reset state.img))

(fn drop-particle [particle]
  (set particle.y (+ particle.y particle.dy))
  (set particle.x (+ particle.x particle.dx))
  (set particle.dy (let [zeroed (- particle.dy 1)]
                     (+ 1 (* zeroed 0.8))))
  (if (< particle.x state.beam-x)
      (set particle.dx (math.abs particle.dx))
      (< (+ state.beam-w state.beam-x) particle.x)
      (set particle.dx (- (math.abs particle.dx))))
  (if (<= (+ state.field.oy state.field.h) particle.y)
      (make-particle)
      particle))

(fn move [dir]
  ;; TODO: temporarily widen beam when moving?
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
    (phase.update state.tick state.progress)
    (set state.tick (+ state.tick 1))
    (when state.particle
      (set state.particle (drop-particle state.particle))))
  (when (love.keyboard.isDown "tab") ; debug
    (set state.integrity (math.min (+ 1 state.integrity) 100)))
  (when (and (= 100 state.integrity) (< state.progress 100))
    (set state.progress (+ state.progress 1)))
  (when (love.keyboard.isDown "left") (move -1))
  (when (love.keyboard.isDown "right") (move 1))
  (when (< step t)
    (update (- dt step))))

(fn bump [dir]
  (when state.particle
    (set state.particle.dy dir)))

(fn find-chunk [{: x : y} img]
  ;; TODO: support other shapes
  (and (<= (+ state.field.ox 6) x (+ state.field.ox 92))
       (<= (+ state.field.oy 70) y (+ state.field.ox 112))))

(fn lock-success [particle chunk]
  ;; TODO: fill nearest subject chunk
  (set particle.w (* particle.w 2))
  (set particle.h (* particle.h 2))
  (table.insert state.particles particle)
  (set state.integrity (math.min (+ (math.random 10) state.integrity) 100)))

(fn lock []
  (when (and state.particle (< (phase.get) 0.5))
    (let [chunk (find-chunk state.particle state.img)]
      (if chunk
          (lock-success state.particle chunk)
          (set state.particle-missed (+ state.particle-missed 1))))
    (set state.particle (and (< state.integrity 100) (make-particle)))))

;; for reloadability
(fn full-draw [] (draw.draw state))

{:name "energize"
 :map {"up" (partial bump -2)
       "down" (partial bump 3)
       "space" lock
       ;; for debugging:
       "backspace" reset
       "`" #(set state.img (love.graphics.newImage "assets/klingon.png"))}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw full-draw :update update
         :read-only true :activate reset}}
