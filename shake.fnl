(local shake-chance 64)

(var state nil)

(fn shake [force]
  (when state
    (love.graphics.translate state.x state.y)
    (set state.x (+ state.x state.dx))
    (set state.y (+ state.x state.dy))
    (when (not (< state.nmx state.x state.mx))
      (set state.dx (* state.dx -0.9)))
    (when (not (< state.nmx state.y state.mx))
      (set state.dy (* state.dy -0.9)))
    (if (< 0 state.ttl)
        (set state.ttl (- state.ttl 1))
        (set state nil)))
  (when (and (not state) (or force
                             (= 1 (love.math.random shake-chance))))
    (let [bounds (math.floor (love.math.randomNormal 8 0))]
      (set state {:x 0 :y 0 :ttl (love.math.random 64)
                  :dx (love.math.randomNormal 9 0)
                  :dy (love.math.randomNormal 9 0)
                  :mx bounds :my bounds
                  :nmx (- bounds) :nmy (- bounds)}))))
