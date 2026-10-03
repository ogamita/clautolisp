(defun cad-probe-foreach--global ()
  ;; The name is a GLOBAL. binding => OUTER ; assignment => 2
  (setq cad-probe-foreach-g 'outer)
  (cad-probe-foreach--global-loop)
  cad-probe-foreach-g)

