(local phase (require :phase))
(local sparkle (require :sparkle))

(local (field-offset-x field-offset-y) (values 38 50))

(local bg (love.graphics.newImage "assets/bg.png"))

(fn draw-particle [{: x : y : w : h}]
  (love.graphics.rectangle :fill (+ x field-offset-x) (+ y field-offset-y) w h))

(local integrity-font (love.graphics.newFont "assets/Trek TNG Monitors.ttf" 18))

(fn draw-integrity [state]
  (let [old-font (love.graphics.getFont)
        count (tostring state.particle-count)]
    (love.graphics.setColor 1 1 1)
    (love.graphics.printf "PATTERN\nINTEGRITY" integrity-font 264 105 100 "left")
    (love.graphics.printf (.. (or state.complete 0) "%") integrity-font 259 152
                         50 "right")
    (love.graphics.printf count old-font 290 77 22 "right")
    (love.graphics.printf "3210" old-font 290 86 22 "right")
    (love.graphics.printf "238" old-font 290 95 22 "right")))

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
  (love.graphics.setShader mask-shader)
  (love.graphics.draw state.img 38 50)
  (love.graphics.setShader))

(fn draw [state]
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (when (< (or state.complete 0) 100)
    (love.graphics.stencil (partial stencil state))
    (love.graphics.setStencilTest :greater 0)
    (love.graphics.setColor 0.1 0.3 0.8 (math.min (/ state.tick 255) 0.6))
    (love.graphics.rectangle :fill 38 50 104 114)
    (sparkle.draw 38 50 state.img)
    (love.graphics.setColor 0.1 0.1 0.1 (- 0.5 (/ (or 0 state.complete) 100)))
    (love.graphics.rectangle :fill 38 50 104 114)
    (love.graphics.setStencilTest))
  (when state.complete
    (love.graphics.setColor 1 1 1 (math.min (/ state.complete 100) 1))
    (love.graphics.draw state.img 38 50))
  (when state.particle
    (love.graphics.setColor 0.9 0.9 0.2)
    (draw-particle state.particle)
    (love.graphics.setColor 0.9 0.9 0.2 0.5)
    (each [_ p (pairs state.particles)]
      (draw-particle p)))
  (draw-integrity state)
  (phase.draw))

{:draw draw}