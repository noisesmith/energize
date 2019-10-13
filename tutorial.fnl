(local editor (require :polywell))
(local draw (require :draw))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(var step 1)

(local rects [[21 17 133 153]
              [207 95 54 80]
              [263 108 56 70]
              [200 3 116 38]])

(local msgs [["Incoming particles get assembled on the pad." 22 171 150]
             [(.. "Use the arrow keys to direct particles; down"
                  " arrow engages particle lock.") 262 99 55]
             [(.. "When the pattern integrity reaches 100, you can materialize"
                  " by pressing space.")
              168 110 90]
             [(.. "This is the phase discriminator. You cannot engage"
                  " particle lock unless it is in high phase.") 210 47 116]])

(fn continue []
  (set step (+ step 1))
  (when (not (. msgs step))
    (editor.open "*energize*" "energize" {:no-file true})))

(fn draw-tutorial []
  (draw.draw {:tick 0})
  (love.graphics.stencil #(love.graphics.rectangle :fill (unpack (. rects step))))
  (love.graphics.setStencilTest :less 1)
  (love.graphics.setColor 0 0 0 0.8)
  (love.graphics.rectangle :fill 0 0 320 200)
  (love.graphics.setStencilTest)
  (love.graphics.setColor 1 1 1)
  (let [[msg x y w] (. msgs step)]
    (love.graphics.printf msg font x y w)))

{:name "tutorial"
 :parent "energize"
 :map {"space" continue
       "return" continue}
 :props {:full-draw draw-tutorial
         :read-only true}}
