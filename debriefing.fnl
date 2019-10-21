;; debriefings happen with Captain Benteen in the transporter room
;; after you finish a level.

(local editor (require :polywell))
(local bg (love.graphics.newImage "assets/bg.png"))
(local padd-right (love.graphics.newImage "assets/padd-right.png"))
(local benteen (love.graphics.newImage "assets/benteen.png"))

(local font (love.graphics.newFont "assets/Anonymous Pro.ttf" 10))

;; the level is incremented when you win, so the end of level 2 is treated as 3
(local texts {3 (love.filesystem.read "text/db3.txt")
              4 (love.filesystem.read "text/db4.txt")
              5 (love.filesystem.read "text/db5.txt")})

(local subjects {3 (love.graphics.newImage "assets/darael.png")
                 4 (love.graphics.newImage "assets/klingon.png")
                 5 (love.graphics.newImage "assets/cunningham.png")})

(local footer "\n\n  [press enter]")

(var offset 0)

(fn draw []
  (love.graphics.setColor 1 1 1)
  (love.graphics.draw bg)
  (love.graphics.draw padd-right 158 0)
  (let [level (editor.get-prop :level 1)]
    (let [subject (. subjects level)]
      (when subject
        (love.graphics.draw subject 38 48)))
    (love.graphics.setScissor 194 24 126 176)
    (let [text (. texts level)]
      (love.graphics.printf (.. (or text "") footer)
                            font 194 (+ 24 offset) 124))
    (love.graphics.setScissor)
    (love.graphics.draw benteen (if (or (= level 4) (= level 5))
                                    123 109) 100)))

(fn continue []
  (set offset 0)
  (let [level (editor.get-prop :level 1)]
    (editor.kill-buffer)
    (if (= level 5)
        (editor.open "*cutscene*" "cutscene" true {:level level})
        (editor.open "*briefing*" "briefing" true {:level level}))))

(local maxes [nil nil -160 -170 -40])

(fn scroll [dir]
  (set offset (-> (+ offset dir)
                  (math.min 0)
                  (math.max (or (. maxes (editor.get-prop :level)) -500)))))

{:name "debriefing"
 :parent "base"
 :map {"escape" continue
       "return" continue
       "space" (partial scroll -25)
       "up" (partial scroll 10)
       "down" (partial scroll -10)}
 :props {:full-draw draw
         :read-only true}}
