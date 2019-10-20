(local editor (require :polywell))

(fn unpause []
  (editor.kill-buffer)
  (editor.change-buffer "*energize*"))

(local text (love.filesystem.read "text/pause.txt"))

(fn draw []
  (love.graphics.print text 60 80))

{:name "pause"
 :map {"escape" unpause}
 :parent "cutscene"
 :props {:draw-callback draw
         :level "pause" :read-only true :star-dx 2}}
