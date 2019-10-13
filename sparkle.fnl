(fn make-line [img]
  (let [(w h) (img:getDimensions)]
    [(math.random w) (math.random h) (math.random 32)]))

(fn make-dot [img]
  (let [(w h) (img:getDimensions)]
    [(math.random w) (math.random h) (math.random 16)]))

(local lines [])
(local dots [])

(fn reset [img]
  (lume.clear lines)
  (lume.clear dots)
  (for [_ 1 128]
    (table.insert lines (make-line img))
    (table.insert dots (make-dot img))))

(fn draw [x y img]
  (when img
    (love.graphics.rectangle :fill x y (img:getDimensions))
    (love.graphics.setColor 1 1 1 0.3)
    (let [h (img:getHeight)]
      (each [i [lx ly len] (pairs lines)]
        (love.graphics.line (+ x lx) (+ y ly) (+ x lx) (+ y ly len))
        (tset (. lines i) 2 (math.fmod (+ ly 3) h)))
      (each [i [dx dy s] (pairs dots)]
        (love.graphics.circle :fill (+ x dx) (+ y dy)
                              (/ (- 16 (math.abs s)) 8))
        (tset (. dots i) 3 (- s 1))
        (when (< s -16)
          (tset dots i (make-dot img)))))))

{:draw draw :reset reset}
