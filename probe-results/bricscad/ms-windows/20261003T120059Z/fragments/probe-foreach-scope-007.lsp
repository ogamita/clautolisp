(defun cad-probe-foreach--unbound ()
  ;; The name is bound NOWHERE before the loop. Both semantics agree the
  ;; loop variable should not survive; a non-nil answer would mean FOREACH
  ;; leaks a global, which is a third possibility worth ruling out.
  (cad-probe-foreach--unbound-loop)
  cad-probe-foreach-fresh)

