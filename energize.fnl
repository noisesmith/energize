(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(local phase (require :phase))

(var tick 0)

(local bg (love.graphics.newImage "bg.png"))
(local img (love.graphics.newImage "probe.png"))

(fn update []
  (phase.update tick)
  (set tick (+ tick 1)))

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
  (love.graphics.stencil stencil)
  (love.graphics.setStencilTest :greater 0)
  (love.graphics.setColor 0.1 0.3 0.8 (math.min (/ tick 255) 0.6))
  (love.graphics.rectangle :fill 38 50 104 114)
  (love.graphics.setStencilTest)
  (phase.draw))

(fn activate []
  (phase.reset))

{:name "energize"
 :map {"space" #(do (set tick 0) (phase.reset))}
 :parent "base"
 :ctrl {"r" #(lume.hotswap :energize)}
 :props {:full-draw draw :update update :read-only true :activate activate}}
