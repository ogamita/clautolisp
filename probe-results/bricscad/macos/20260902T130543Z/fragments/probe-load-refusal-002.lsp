(defun cad-probe-lr--expression-position ()
  ;; FOREACH as an ARGUMENT to another call. Loaded fine in round 1;
  ;; kept so a future BricsCAD version cannot change that unnoticed.
  (list (foreach e (list 1 2 3) (* e 10))))

