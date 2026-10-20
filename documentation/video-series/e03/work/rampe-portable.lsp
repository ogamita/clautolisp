;;; rampe-portable.lsp -- meme calcul, sans TAN
(defun pente (degres / a)
  (setq a (* pi (/ degres 180.0)))
  (* 100.0 (/ (sin a) (cos a))))
(princ (strcat "Pente a 5 degres : " (rtos (pente 5) 2 2) " %\n"))
