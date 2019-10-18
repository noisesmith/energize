(local sfxr (require :lib.sfxr))
(local lume (require :polywell.lib.lume))

(local sound (love.sound.newSoundData 4096 8000 16 1))

(local source (love.audio.newSource sound))

(print "playing" source)
(love.audio.play source)
(print "played" source)



(fn make [x]
  (let [sound (sfxr.newSound)]
    (: sound :randomize x)
    (love.audio.newSource (: sound :generateSoundData))))

(local sounds
       {;:temple (love.audio.newSource "assets/GalacticTemple.ogg" "stream")
        ;:pressure (love.audio.newSource "assets/Pressure.ogg" "stream")
        :chirp (make 38577)
        :door (make 57560)})

(set sounds.laser (let [s (sfxr.newSound)]
                    (: s :randomize 65505)
                    (set s.envelope.decay 0.1)
                    (set s.envelope.punch 0.1)
                    (set s.volume.master 0.15)
                    (love.audio.newSource (: s :generateSoundData))))

(: sounds.laser :setLooping true)
(: sounds.door :setLooping true)
(: sounds.chirp :setLooping true)
;(: sounds.temple :setLooping true)

;; checking out sfxr https://github.com/nucular/sfxrlua - probably worth
;; including

(print "playing chirp")
(: sounds.chirp :play)
(print "played chirp")

{:sound sound
 :source source}
