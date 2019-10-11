(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))
(local sparkle (require :sparkle))

(var tick 0)
(var complete nil)

(local bg (love.graphics.newImage "bg.png"))
(local img (love.graphics.newImage "probe.png"))

(fn update []
  (phase.update tick complete)
  (set tick (+ tick 1))
  (when complete (set complete (+ complete 1))))

(local mask-shader
       (love.graphics.newShader "vec4 effect(vec4 color, Image texture,
                                             vec2 texture_coords, vec2 _) {
      if (Texel(texture, texture_coords).a == 0.0) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }"))

(fn stencil []
  (love.graphics.setShader mask-shader)
  (love.graphics.draw img 38 50)
  (love.graphics.setShader))

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (when (< (or complete 0) 255)
    (love.graphics.stencil stencil)
    (love.graphics.setStencilTest :greater 0)
    (love.graphics.setColor 0.1 0.3 0.8 (math.min (/ tick 255) 0.6))
    (love.graphics.rectangle :fill 38 50 104 114)
    (sparkle.draw 38 50 img)
    (love.graphics.setColor 0.1 0.1 0.1 (- 0.5 (/ (or 0 complete) 255)))
    (love.graphics.rectangle :fill 38 50 104 114)
    (love.graphics.setStencilTest))
  (when complete
    (love.graphics.setColor 1 1 1 (math.min (/ complete 255) 1))
    (love.graphics.draw img 38 50))
  (phase.draw))

(fn activate []
  (phase.reset)
  (sparkle.reset img))

{:name "energize"
 :map {"space" #(do (set tick 0) (set complete nil) (phase.reset))
       "return" #(set complete 0)}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw draw :update update :read-only true :activate activate}}
