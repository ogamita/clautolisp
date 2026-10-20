;;; rampe.lsp -- pente d'une rampe, en pourcentage
(defun pente (degres)
  (* 100.0 (tan (* pi (/ degres 180.0)))))
(princ (strcat "Pente a 5 degres : " (rtos (pente 5) 2 2) " %\n"))
