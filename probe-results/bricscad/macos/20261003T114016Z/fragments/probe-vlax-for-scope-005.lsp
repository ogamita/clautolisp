(defun cad-probe-vlax-for--callee ()
  (setq cad-probe-vlax-for-n 0)
  (vlax-for x (cad-probe-vlax-for--layers)
    (setq cad-probe-vlax-for-n (1+ cad-probe-vlax-for-n))))

