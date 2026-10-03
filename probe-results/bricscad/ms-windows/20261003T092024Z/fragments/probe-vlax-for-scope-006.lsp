(defun cad-probe-vlax-for--callers-local ( / x)
  ;; x is a /-local of the CALLER, reachable only by dynamic scope.
  ;; binding => (BEFORE n) ; assignment => ("layer:<last>" n)
  (setq x 'before)
  (cad-probe-vlax-for--callee)
  (list (cad-probe-vlax-for--show x) cad-probe-vlax-for-n))

