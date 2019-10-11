(local editor (require :polywell))

{:name "edit"
 :parent "base"
 :map {"backspace" editor.cmd.delete-backwards
       "delete" editor.cmd.delete-forwards
       "down" editor.cmd.next-line
       "end" editor.cmd.end-of-line
       "home" editor.cmd.beginning-of-line
       "left" editor.cmd.backward-char
       "pagedown" editor.cmd.scroll-down
       "pageup" editor.cmd.scroll-up
       "return" editor.cmd.newline-and-indent
       "right" editor.cmd.forward-char
       "up" editor.cmd.prev-line
       "wheeldown" editor.cmd.next-line
       "wheelup" editor.cmd.prev-line
       "home" editor.cmd.beginning-of-line
       "end" editor.cmd.end-of-line
       "tab" editor.cmd.indent}

 :ctrl {" " editor.cmd.mark
        "space" editor.cmd.mark
        "a" editor.cmd.beginning-of-line
        "b" editor.cmd.backward-char
        "backspace" editor.cmd.backward-kill-word
        "d" editor.cmd.delete-forwards
        "e" editor.cmd.end-of-line
        "f" editor.cmd.forward-char
        "g" editor.cmd.no-mark
        "h" editor.cmd.delete-backwards
        "k" editor.cmd.kill-line
        "m" editor.cmd.newline-and-indent
        "n" editor.cmd.next-line
        "p" editor.cmd.prev-line
        "i" editor.cmd.indent
        "r" (partial editor.cmd.search -1)
        "s" editor.cmd.search
        "v" editor.cmd.scroll-down
        "w" editor.cmd.kill-region
        "x" {;; TODO: prompt to save buffers before quitting
             :ctrl {"c" (fn [] (editor.cmd.save) (os.exit 0))
                    "s" editor.cmd.save
                    ;; force close
                    "k" (partial editor.cmd.close true)}}
        "y" editor.cmd.yank
        "/" editor.cmd.undo
        "z" editor.cmd.undo}

 :alt {"," editor.cmd.beginning-of-buffer
       "." editor.cmd.end-of-buffer
       "<" editor.cmd.beginning-of-buffer
       ">" editor.cmd.end-of-buffer
       "5" editor.cmd.replace
       "b" editor.cmd.backward-word
       "d" editor.cmd.forward-kill-word
       "f" editor.cmd.forward-word
       "v" editor.cmd.scroll-up
       "w" editor.cmd.kill-ring-save
       "y" editor.cmd.yank-pop}

 :ctrl-alt {"r" editor.cmd.reload
            "b" editor.cmd.switch-buffer
            "h" editor.cmd.backward-kill-word}}
