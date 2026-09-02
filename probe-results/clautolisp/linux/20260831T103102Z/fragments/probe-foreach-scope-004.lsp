(defun cad-probe-foreach--callers-local ( / e)
  ;; The loop variable is a /-local OF THE CALLER, reachable only because
  ;; AutoLISP is dynamically scoped. binding => BEFORE ; assignment => 3
  (setq e 'before)
  (cad-probe-foreach--callee (list 1 2 3))
  e)

