(defun c:greet (/ id status name shout)
  (setq id (load_dialog "~/src/public/clautolisp/clautolisp/examples/greet/greet.dcl"))
  (cond
    ((< id 0)
     (princ "\nCould not load greet.dcl"))
    (T
     (new_dialog "greet" id)
     (set_tile "name" "World")
     (action_tile "name"
                   "(setq name $value)")
     (action_tile "shout"
                   "(setq shout $value)")
     (action_tile "accept"
                   "(setq name (get_tile \"name\")
                          shout (get_tile \"shout\"))
                    (done_dialog 1)")
     (action_tile "cancel" "(done_dialog 0)")
     (setq status (start_dialog))
     (unload_dialog id)
     (cond
       ((= status 1)
        (princ (strcat "\nHello, "
                       (if (= shout "1")
                           (xstrcase name :upper)
                           name)
                       "!")))
       (T (princ "\nCancelled.")))))
  (princ))

(c:greet)
;; (exit)

