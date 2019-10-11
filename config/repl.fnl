(local editor (require :polywell))
(local fennel (require :polywell.lib.fennel))
(local view (require :polywell.lib.fennelview))

(fn activate []
  (let [buf (editor.current-buffer-name)
        out (fn [xs]
              (editor.with-output-to
               buf (partial editor.print (table.concat xs " "))))
        options {:readChunk coroutine.yield
                 :onValues out
                 :onError (fn [kind ...] (out [kind "Error:" ...]))
                 :pp view
                 ;; use Fennel's macro-aware completer
                 :registerCompleter #(editor.set-prop :completer $1)
                 :env (setmetatable {:print editor.print}
                                    {:__index _G})}
        coro (coroutine.create fennel.repl)]
    (editor.set-prompt ">> ")
    (editor.print-prompt)
    (editor.set-prop :eval (doto coro (coroutine.resume options)))))

(fn handle [input]
  (coroutine.resume (editor.get-prop :eval) (.. input "\n")))

(local enter (editor.handle-input-with handle))

{:name "repl"
 :parent "line"
 :map {"return" enter
       "tab" editor.cmd.complete}
 :ctrl {"m" enter
        "i" editor.cmd.complete}
 :props {:activate activate}}
