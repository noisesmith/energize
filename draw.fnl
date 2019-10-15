(local phase (require :phase))
(local sparkle (require :sparkle))

(local lg love.graphics)
(local bg (lg.newImage "assets/bg.png"))

(fn draw-particle [{: x : y : w : h}]
  (lg.rectangle :fill x y w h))

(fn draw-beam [state]
  (lg.setColor 0.8 0.8 0.15 0.5)
  (let [y 17 h 153]
    (lg.rectangle :fill state.beam-x y state.beam-w h)
    (lg.rectangle :fill (- state.beam-x 2) y 4 h)
    (lg.rectangle :fill (+ state.beam-x state.beam-w -2) y 4 h)))

(local integrity-font (lg.newFont "assets/Trek TNG Monitors.ttf" 18))
(local font (lg.getFont "assets/Anonymous Pro.ttf" 10))

(fn draw-integrity [{: particle-count : integrity : particle-missed : max}]
  (lg.setColor 1 1 1)
  (lg.printf "PATTERN\nINTEGRITY" integrity-font 264 105 100 "left")
  (lg.printf (.. (math.floor (or integrity 0)) "%")
             integrity-font 259 152 50 "right")
  (lg.printf (tostring (or particle-count "lock"))
             font 290 77 22 "right")
  (lg.printf (tostring (or particle-missed "lost"))
             font 290 86 22 "right")
  (lg.printf (tostring (or max "max"))
             font 290 95 22 "right"))

(local mask-shader
       (lg.newShader "vec4 effect(vec4 color, Image texture,
                                             vec2 texture_coords, vec2 _) {
      if (Texel(texture, texture_coords).a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }"))

(fn stencil [state]
  (when state.img
    (lg.setShader mask-shader)
    (lg.draw state.img state.field.ox state.field.oy)
    (lg.setShader)))

(fn draw [state]
  (lg.setColor 1 1 1)
  (lg.draw bg)
  (let [{: ox : oy : w : h} state.field]
    (when (< (or state.progress 0) 100)
      (lg.stencil (partial stencil state))
      (lg.setStencilTest :greater 0)
      (lg.setColor 0.1 0.3 0.8 (math.min (/ state.tick 255) 0.6))
      (lg.rectangle :fill ox oy w h)
      (sparkle.draw ox oy state.img)
      (lg.setColor 0.1 0.1 0.1 (- 0.5 (/ (or state.progress 0) 100)))
      (lg.rectangle :fill ox oy w h)
      (lg.setStencilTest))
    (when state.progress
      (lg.setColor 1 1 1 (math.min (/ state.progress 100) 1))
      (lg.draw state.img ox oy)))
  (when (and state.particle (< state.integrity 100))
    (draw-beam state)
    (lg.setColor 0.9 0.9 0.2)
    (draw-particle state.particle)
    (lg.setStencilTest :greater 0)
    (each [_ c (pairs state.chunks)]
      (when (and (love.keyboard.isDown "y") (not c.on)) ; debug
        (lg.setColor 0.8 0.2 0.2 0.5)
        (lg.setStencilTest)
        (draw-particle c)
        (lg.setStencilTest :greater 0))
      (when c.on
        (lg.setColor 0.9 0.9 0.2 0.5)
        (draw-particle c)))
    (lg.setStencilTest))
  (draw-integrity state)
  (phase.draw))

{:draw draw}
