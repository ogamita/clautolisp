(defun cad-probe-vlax-for--show (v)
  (if (= (type v) 'VLA-OBJECT)
    (strcat "layer:" (vla-get-name v))
    v))

