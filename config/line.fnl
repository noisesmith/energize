;; a base mode to inherit from when building interactive shell/repl-type modes
(local editor (require :polywell))

{:name "line"
 :parent "edit"
 :map {:tab editor.cmd.complete}
 :ctrl {:a editor.cmd.beginning-of-input
        :up editor.cmd.history-prev
        :down editor.cmd.history-next
        :i editor.cmd.complete}
 :alt {:p editor.cmd.history-prev
       :n editor.cmd.history-next}}
