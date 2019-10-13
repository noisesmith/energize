(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/cmdr.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

(local text (love.filesystem.read "briefings/1.txt"))
(local footer "\n\n  [press enter]")

(var offset 0)

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (love.graphics.setScissor 194 24 126 176)
  (love.graphics.printf (.. text footer) font 194 (+ 24 offset) 124)
  (love.graphics.setScissor))

(fn continue []
  (editor.kill-buffer)
  (editor.open "*tutorial*" "tutorial" {:no-file true}))

(fn scroll [dir]
  (set offset (+ offset dir)))

{:name "briefing"
 :parent "base"
 :map {"escape" continue
       "return" continue
       "space" (partial scroll -25)
       "up" (partial scroll 10)
       "down" (partial scroll -10)}
 :props {:full-draw draw
         :read-only true}}
