(local phase (require :phase))
(local sparkle (require :sparkle))

(local bg (love.graphics.newImage "assets/bg.png"))

(fn draw-particle [{: x : y : w : h}]
  (love.graphics.rectangle :fill x y w h))

(fn draw-beam [state]
  (love.graphics.setColor 0.8 0.8 0.15 0.5)
  (let [y 17 h 153]
    (love.graphics.rectangle :fill state.beam-x y state.beam-w h)
    (love.graphics.rectangle :fill (- state.beam-x 2) y 4 h)
    (love.graphics.rectangle :fill (+ state.beam-x state.beam-w -2) y 4 h)))

(local integrity-font (love.graphics.newFont "assets/Trek TNG Monitors.ttf" 18))
(local font (love.graphics.getFont "assets/Anonymous Pro.ttf" 10))

(fn draw-integrity [{: particle-count : integrity : particle-missed}]
  (love.graphics.setColor 1 1 1)
  (love.graphics.printf "PATTERN\nINTEGRITY" integrity-font 264 105 100 "left")
  (love.graphics.printf (.. (math.floor (or integrity 0)) "%")
                        integrity-font 259 152 50 "right")
  (love.graphics.printf (tostring (or particle-count 0)) font 290 77 22 "right")
  (love.graphics.printf "3210" font 290 86 22 "right")
  (love.graphics.printf (tostring (or particle-missed 0))
                        font 290 95 22 "right"))

(local mask-shader
       (love.graphics.newShader "vec4 effect(vec4 color, Image texture,
                                             vec2 texture_coords, vec2 _) {
      if (Texel(texture, texture_coords).a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }"))

(fn stencil [state]
  (when state.img
    (love.graphics.setShader mask-shader)
    (love.graphics.draw state.img state.field.ox state.field.oy)
    (love.graphics.setShader)))

(fn draw [state]
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (let [{: ox : oy : w : h} state.field]
    (when (< (or state.progress 0) 100)
      (love.graphics.stencil (partial stencil state))
      (love.graphics.setStencilTest :greater 0)
      (love.graphics.setColor 0.1 0.3 0.8 (math.min (/ state.tick 255) 0.6))
      (love.graphics.rectangle :fill ox oy w h)
      (sparkle.draw ox oy state.img)
      (love.graphics.setColor 0.1 0.1 0.1 (- 0.5 (/ (or state.progress 0) 100)))
      (love.graphics.rectangle :fill ox oy w h)
      (love.graphics.setStencilTest))
    (when state.progress
      (love.graphics.setColor 1 1 1 (math.min (/ state.progress 100) 1))
      (love.graphics.draw state.img ox oy)))
  (when state.particle
    (draw-beam state)
    (when (< state.integrity 100)
      (love.graphics.setColor 0.9 0.9 0.2)
      (draw-particle state.particle)
      (love.graphics.setStencilTest :greater 0)
      (each [_ c (pairs state.chunks)]
        (when (and (love.keyboard.isDown "y") (not c.on)) ; debug
          (love.graphics.setColor 0.8 0.2 0.2 0.5)
          (love.graphics.setStencilTest)
          (draw-particle c)
          (love.graphics.setStencilTest :greater 0))
        (when c.on
          (love.graphics.setColor 0.9 0.9 0.2 0.5)
          (draw-particle c)))
      (love.graphics.setStencilTest)))
  (draw-integrity state)
  (phase.draw))

{:draw draw}
