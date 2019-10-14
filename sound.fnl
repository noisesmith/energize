(local lume (require :polywell.lib.lume))

(local sound (love.sound.newSoundData 4096 8000 16 1))

(local source (love.audio.newSource sound))

(love.audio.play source)

;; checking out sfxr https://github.com/nucular/sfxrlua - probably worth
;; including

{:sound sound
 :source source}
