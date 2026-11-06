(defun cad-probe-vlax-for--global ( / n)
  ;; The name is a GLOBAL. binding => (OUTER n) ; assignment => ("layer:.." n)
  (setq cad-probe-vlax-for-g 'outer n 0)
  (vlax-for cad-probe-vlax-for-g (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show cad-probe-vlax-for-g) n))

