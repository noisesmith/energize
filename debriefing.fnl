(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/bg.png"))
(local padd-right (love.graphics.newImage "assets/padd-right.png"))
(local benteen (love.graphics.newImage "assets/benteen.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

;; the level is incremented when you win, so the end of level 2 is treated as 3
(local texts {3 (love.filesystem.read "text/db3.txt")})

(local subjects {3 (love.graphics.newImage "assets/darael.png")})

(local footer "\n\n  [press enter]")

(var offset 0)

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (love.graphics.draw padd-right 158 0)
  (love.graphics.draw benteen 109 100)
  (let [level (editor.get-prop :level 1)]
    (let [subject (. subjects level)]
      (love.graphics.draw subject 38 48))
    (love.graphics.setScissor 194 24 126 176)
    (let [text (. texts level)]
      (love.graphics.printf (.. text footer) font 194 (+ 24 offset) 124))
    (love.graphics.setScissor)))

(fn continue []
  (set offset 0)
  (editor.kill-buffer)
  (let [level (editor.get-prop :level 1)]
    (editor.open "*briefing*" "briefing" true {:level level})))

(fn scroll [dir] (set offset (+ offset dir)))

{:name "debriefing"
 :parent "base"
 :map {"escape" continue
       "return" continue
       "space" (partial scroll -25)
       "up" (partial scroll 10)
       "down" (partial scroll -10)}
 :props {:full-draw draw
         :read-only true}}
