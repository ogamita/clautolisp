(defun cad-probe-vlax-for--own-local ( / x n)
  ;; binding => (BEFORE n) ; assignment => ("layer:<last>" n)
  (setq x 'before n 0)
  (vlax-for x (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show x) n))

