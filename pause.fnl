(local editor (require :polywell))

(fn unpause []
  (editor.change-buffer "*energize*"))

(fn draw []
  (love.graphics.print "press escape to resume." 110 100))

{:name "pause"
 :map {"escape" unpause}
 :parent "cutscene"
 :props {:draw-callback draw
         :level "pause" :read-only true :star-dx 2}}
