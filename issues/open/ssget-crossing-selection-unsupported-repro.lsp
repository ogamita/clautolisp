;; Minimal CAD-host reproducer: actual entities, no SCHMS or mock primitives.
(vl-load-com)
((lambda (/ first second result message)
   (setq first
         (entmakex '((0 . "LINE") (100 . "AcDbEntity") (100 . "AcDbLine")
                     (10 1000000.0 1000000.0 0.0) (11 1000010.0 1000000.0 0.0)))
         second
         (entmakex '((0 . "LINE") (100 . "AcDbEntity") (100 . "AcDbLine")
                     (10 1000000.0 1000010.0 0.0) (11 1000010.0 1000010.0 0.0))))
   (setq result
         (vl-catch-all-apply 'ssget
           '("_C" (999999.0 999999.0 0.0) (1000011.0 1000011.0 0.0))))
   (setq message
         (cond
           ((vl-catch-all-error-p result) (vl-catch-all-error-message result))
           ((and result (= 2 (sslength result))
                 (ssmemb first result) (ssmemb second result)) "PASS")
           (T "FAIL: crossing selection must contain both fixture entities")))
   (if (and first (entget first)) (entdel first))
   (if (and second (entget second)) (entdel second))
   (princ (strcat "\n" message "\n"))))
(princ)
