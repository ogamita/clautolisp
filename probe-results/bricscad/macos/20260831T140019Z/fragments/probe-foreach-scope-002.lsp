(defun cad-probe-foreach--own-local ( / e)
  ;; The loop variable is a /-local OF THE SAME FUNCTION.
  ;; binding semantics => BEFORE ; assignment semantics => 3
  (setq e 'before)
  (foreach e (list 1 2 3) nil)
  e)

