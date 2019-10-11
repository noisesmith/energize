;; This module contains all the state for the whole editor.
;; It shouldn't be considered part of the public API; to change the
;; state, use the functions in the polywell module.
(local frontend (require :polywell.frontend))

{:kill-ring {}

 :activate-patterns {}

 ;; allows for multi-step key bindings a la Emacs ctrl-x ctrl-s
 :active-prefix nil
 :active-prefix-deactivate nil

 :windows []
 :window 1

 :coroutines []

 ;; echo messages show feedback while in the editor, until a new key is pressed
 :echo-message nil
 :echo-message-new false

 ;; for the default value in interactive buffer switching
 :last-buffer nil ; TODO: use a buffer history ring

 ;; where does print go? (essentially used as dynamic scope)
 :output nil

 ;; current buffer
 :b nil
 ;; all buffers, indexed by path
 :buffers {}

 ;; if you want to write to a filesystem that isn't the disk, provide a new
 ;; table with these three elements as a 4th arg to polywell.init.
 :fs {:read frontend.read :write frontend.write
      :type frontend.type :ls frontend.ls}

 :cwd (os.getenv "PWD")

 ;; colors! you can change these; themeing I guess?
 :colors {
  :mark (frontend.normalize_color [0 125 0])
  :point (frontend.normalize_color [0 125 0])
  :point_line (frontend.normalize_color [0 50 0 190])
  :minibuffer_bg (frontend.normalize_color [0 200 0])
  :minibuffer_fg (frontend.normalize_color [0 0 0])
  :scroll_bar (frontend.normalize_color [0 150 0])
  :text (frontend.normalize_color [0 175 0])
  :background (frontend.normalize_color [0 0 0 240])
  ;; for programming
  :keyword (frontend.normalize_color [0 255 0])
  :str (frontend.normalize_color [200 100 0])
  :number (frontend.normalize_color [50 175 120])
  :comment (frontend.normalize_color [0 100 0])
  }

 ;; added thru the add-mode function, defined in config/
 :modes {}
 }
