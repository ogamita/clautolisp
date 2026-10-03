(defun cad-probe-vlax-for--unbound ( / n)
  ;; Bound NOWHERE before the loop. Both rules say it does not survive; a
  ;; layer left in it would mean VLAX-FOR leaks a global.
  (setq n 0)
  (vlax-for cad-probe-vlax-for-fresh (cad-probe-vlax-for--layers) (setq n (1+ n)))
  (list (cad-probe-vlax-for--show cad-probe-vlax-for-fresh) n))

