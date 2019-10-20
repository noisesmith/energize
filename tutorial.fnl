(local editor (require :polywell))
(local draw (require :draw))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(var step 1)

(local rects [[21 17 133 150]
              [207 95 54 80]
              [200 3 116 38]
              [263 108 56 70]
              [262 78 58 28]])

(local msgs [[(.. "Incoming particles get assembled on the pad."
                  " Space engages particle lock.") 26 168 150]
             [(.. "Use the arrow keys to direct the annular"
                  " confinement beam.") 262 99 55]
             [(.. "This is the phase discriminator. You cannot engage"
                  " particle lock unless it is in high phase.") 208 48 116]
             ["When the pattern integrity hits 100, materialization will begin."
              168 110 95]
             [(.. "On most missions only a limited number of particles may be "
                  "used before pattern degradation sets in.")
              160 68 100]])

(fn continue []
  (set step (+ step 1))
  (when (not (. msgs step))
    (editor.kill-buffer)
    (editor.open "*energize*" "energize" {:no-file true})))

(fn draw-tutorial []
  (draw.draw {:tick 0 :field {:ox 38 :oy 48 :w 100 :h 114}})
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
       "return" continue
       "up" #(set step (math.max 1 (- step 1)))
       "down" continue
       "escape" #(editor.open "*energize*" "energize" {:no-file true})}
 :props {:full-draw draw-tutorial
         :read-only true}}
