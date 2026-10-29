;; Equal must apply numeric fuzz recursively to point coordinates.
(setq near-number (+ 5.0 1e-15))
(princ "\nScalar comparison (expected T): ")
(prin1 (equal 5.0 near-number 1e-9))
(princ "\nList comparison (expected T): ")
(prin1 (equal '(5.0) (list near-number) 1e-9))
(princ "\nOutside tolerance (expected nil): ")
(prin1 (equal '(5.0) '(5.01) 1e-9))
(princ "\n")
