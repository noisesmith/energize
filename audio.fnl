(local sounds
       {:music (doto (love.audio.newSource "assets/energize-theme.ogg" "stream")
                 (: :setLooping true))
        ;; placeholders for now
        :phaser (doto (love.audio.newSource "assets/playerLaser.wav" "stream")
                  (: :setLooping true))
        :beam (love.audio.newSource "assets/sfx_18b.ogg" "stream")})

{:toggle (fn toggle [name]
           (if (love.filesystem.getInfo "mute")
               (do (love.filesystem.remove "mute")
                   (: (. sounds (or name :music)) :play))
               (do (love.filesystem.write "mute" "true")
                   (each [_ sound (pairs sounds)]
                     (: sound :pause)))))
 :play (fn play [name]
         (when (and (not (: (. sounds name) :isPlaying))
                    (not (love.filesystem.getInfo "mute")))
           (: (. sounds name) :play)))
 :stop (fn stop [name] (: (. sounds name) :stop))}
