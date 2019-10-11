;; Private module; do not load this directly!
(local lume (require :polywell.lib.lume))
(local utf8 (require :polywell.lib.utf8))
(local editor (require :polywell.old))
(local state (require :polywell.state))
(local frontend (require :polywell.frontend))

(local undo-history-max 64)

(fn find-binding [key mode]
  (fn find-map [mode ctrl? alt?]
    (if (and ctrl? alt?) mode.ctrl-alt
        ctrl? mode.ctrl
        alt? mode.alt
        (or mode.map {})))

  (fn map-merge [a b]
    (let [ctrl (lume.merge (or a.ctrl {}) (or b.ctrl {}))
          alt (lume.merge (or a.alt {}) (or b.alt {}))
          ctrl-alt (lume.merge (or a.ctrl-alt {}) (or b.ctrl-alt {}))]
      (lume.merge a b {:ctrl ctrl :alt alt :ctrl-alt ctrl-alt})))

  (fn merge-parent-prefix-maps [prefix-map mode key ctrl? alt?]
    (if (not mode)
        prefix-map
        (let [map (find-map mode ctrl? alt?)]
          (if (= (type (. map key)) :table)
              (merge-parent-prefix-maps (map-merge prefix-map (. map key))
                                        (. state.modes mode.parent) key ctrl? alt?)

              (= (. map key) nil) ; keep going
              (merge-parent-prefix-maps prefix-map (. state.modes mode.parent)
                                        key ctrl? alt?)
              ;; else
              prefix-map))))

  (let [mode (or state.active-prefix mode
                 (. state.modes (editor.current-mode-name)))
        ctrl? (frontend.key-down? "lctrl" "rctrl" "capslock")
        alt? (frontend.key-down? "lalt" "ralt")
        map (or (find-map mode ctrl? alt?) {})]

    (if (= (type (. map key)) :table)
        (merge-parent-prefix-maps (. map key) (. state.modes mode.parent)
                                  key ctrl? alt?)

        (. map key)
        (. map key)

        map.__any
        (partial map.__any key)

        (. state.modes mode.parent)
        (find-binding key (. state.modes mode.parent)))))

;; all edits (commands and insertions) run inside this function; it handles
;; tracking undo status as well as enforcing certain rules.
(fn wrap [f ...]
  (fn get-state []
    {:lines (lume.clone state.b.lines)
     :point state.b.point :point_line state.b.point_line})

  (set state.b.dirty false)
  (let [last-state (get-state)]
    (when (not= f editor.cmd.undo)
      (set state.b.undo_at 0))
    (f ...)

    (if state.echo-message-new
        (set state.echo-message-new false)
        (set state.echo-message nil))

    (when state.b.dirty
      (table.insert state.b.history last-state)
      (editor.internal.run_on_change))
    (when (> (# state.b.history) undo-history-max)
      (table.remove state.b.history 1))
    ;; if a buffer got dropped, remove it from the window list
    (each [_ window (pairs (or state.windows {}))]
      (when (not (lume.find state.buffers (. window 2)))
        (tset window 2 state.b)))
    (assert (or (lume.find state.buffers state.b) (= state.b.path "minibuffer"))
            (.. "Current buffer not found! " state.b.path))
    (editor.internal.bounds_check)))

(fn handler-for [event-name mode-override]
  (fn [...]
    (let [f (find-binding event-name mode-override)]
      (when f
        (editor.with-traceback (editor.get-prop :wrap wrap) f)))))

{:keypressed (fn keypressed [key]
               (let [f (find-binding key)]
                 (if (= (type f) :function)
                     (do (editor.with-traceback (editor.get-prop :wrap wrap) f)
                         (set state.active-prefix-deactivate true))
                     (= (type f) :table)
                     (set (state.active-prefix state.active-prefix-deactivate)
                          (values f false))
                     ;; else
                     (set state.active-prefix-deactivate true))))

 :keyreleased (fn []
                (when state.active-prefix-deactivate
                  (set state.active-prefix nil)))
 :textinput (fn [text allow-long?]
              (let [(_ len) (pcall utf8.len text)
                    wrap (editor.get-prop :wrap wrap)]
                (when (and (not (find-binding text))
                           (or (= len 1) allow-long?))
                  (editor.with-traceback wrap editor.insert [text] true))))
 :wheelmoved (fn [x y]
               (let [f (or (find-binding "wheel-moved")
                           (find-binding (if (< x 0) :wheel-left
                                             (> x 0) :wheel-right
                                             (< y 0) :wheel-down
                                             (> y 0) :wheel-up)))]
                 (when f
                   (editor.with-traceback (editor.get-prop :wrap wrap) f))))
 :mousemoved (handler-for "mouse-moved")
 :mousepressed (handler-for "mouse-pressed")
 :mousereleased (handler-for "mouse-released")
 :mousefocus (handler-for "mouse-focus")
 :resize frontend.resize
 :invoke (fn [mode-name event ...]
           ((handler-for event (. state.modes mode-name)) ...))
 :update (fn [dt]
           (let [f (editor.get-prop :update)]
             (when f
               (editor.with-traceback (editor.get-prop :wrap wrap) f dt))
             (each [_ c (pairs state.coroutines)]
               (let [(ok val) (coroutine.resume c dt)]
                 (when (not ok) (print val))))
             (each [i c (lume.ripairs state.coroutines)]
               (when (= (coroutine.status c) :dead)
                 (table.remove state.coroutines i)))))
 ;; currently has to be exposed for fuzz testing, but that's ... not ideal
 :internal___wrap wrap}
