(defun c:greet (/ id status name shout)
  ;; Relative name: run from this directory (clautolisp resolves a relative
  ;; load_dialog against the cwd; in AutoCAD/BricsCAD put it on the support
  ;; path). Keeps an absolute path out of the committed file -- the one that
  ;; was here named a directory on the author's own machine, so the example
  ;; printed "Could not load greet.dcl" for everybody else.
  (setq id (load_dialog "greet.dcl"))
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
                           (strcase name)
                           name)
                       "!")))
       (T (princ "\nCancelled.")))))
  (princ))

(c:greet)
;; (sleep 60)
;; (exit)


