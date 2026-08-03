(defun c:listpick (/ id status pick)
  ;; Relative name: run from this directory (clautolisp resolves a relative
  ;; load_dialog against the cwd; in AutoCAD/BricsCAD put it on the support
  ;; path). Keeps an absolute path out of the committed file.
  (setq id (load_dialog "listpick.dcl"))
  (cond
    ((< id 0) (princ "\nCould not load listpick.dcl"))
    (T
     (new_dialog "listpick" id)
     (start_list "colour")
     (add_list "Red")
     (add_list "Green")
     (add_list "Blue")
     (add_list "Yellow")
     (add_list "Magenta")
     (end_list)
     (action_tile "colour" "(setq pick $value)")
     (action_tile "accept" "(setq pick (get_tile \"colour\")) (done_dialog 1)")
     (action_tile "cancel" "(done_dialog 0)")
     (setq status (start_dialog))
     (unload_dialog id)
     (cond
       ((= status 1)
        (princ (strcat "\nYou picked index " (if pick pick "(none)"))))
       (T (princ "\nCancelled.")))))
  (princ))
(c:listpick)
(exit)
