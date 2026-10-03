(defun cad-probe-vlax-for--layers ()
  (vl-load-com)
  (vla-get-layers (vla-get-activedocument (vlax-get-acad-object))))

