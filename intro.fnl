(local editor (require :polywell))
(local text (love.graphics.newImage "assets/title.png"))
(local lakota (love.graphics.newImage "assets/lakota.png"))

(fn draw [tick]
  (let [x (math.fmod (* tick 20) 320)]
    (love.graphics.draw lakota x 90))
  (love.graphics.draw text)
  (love.graphics.print "press space" ; the final frontier
                       25 160))

{:name "intro"
 :parent "cutscene"
 :map {;; for jumping straight to the game
       "\\" #(editor.open "*energize*" "energize" {:no-file true})}
 :props {:draw-callback draw
         :destination ["*briefing*" "briefing"]}}
