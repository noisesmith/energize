(local editor (require :polywell))
(local lume (require :polywell.lib.lume))
(var tick 0)

(local img (love.graphics.newImage "probe.png"))

(fn update []
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
  (love.graphics.draw img)
  (love.graphics.setShader))

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.clear)
  (love.graphics.stencil stencil)
  (love.graphics.setStencilTest :greater 0)
  (love.graphics.setColor 0.1 0.3 0.8 (math.min (/ tick 255) 0.6))
  (love.graphics.rectangle :fill 38 50 104 114)
  (love.graphics.setStencilTest))

{:name "energize"
 :map {"space" #(set tick 0)}
 :parent "base"
 :ctrl {"q" editor.cmd.quit
        "r" #(lume.hotswap :config.beam)}
 :props {:full-draw draw :update update :read-only true}}
