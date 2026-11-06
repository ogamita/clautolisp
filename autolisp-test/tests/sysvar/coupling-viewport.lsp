;;;; tests/sysvar/coupling-viewport.lsp
;;;;
;;;; TILEMODE / CVPORT steer viewport-aware access (vports / setview).
;;;; Headlessly vports reports the documented single-viewport sentinel
;;;; (viewport number 1) and setview is a no-op returning nil; the
;;;; sysvars themselves round-trip through getvar / setvar.

(deftest "sysvar-tilemode-round-trips"
  '((operator . "TILEMODE") (area . "sysvar") (profile . strict))
  '(progn (setvar "TILEMODE" 0)
          (let ((result (getvar "TILEMODE")))
            (setvar "TILEMODE" 1)          ;; restore model-space default
            result))
  0)

(deftest "sysvar-cvport-round-trips"
  '((operator . "CVPORT") (area . "sysvar") (profile . strict))
  '(progn (setvar "CVPORT" 3)
          (let ((result (getvar "CVPORT")))
            (setvar "CVPORT" 2)            ;; restore
            result))
  3)

(deftest "sysvar-vports-reports-viewport-one"
  '((operator . "CVPORT") (area . "sysvar") (profile . strict))
  '(car (car (vports)))
  1)

(deftest "sysvar-setview-headless-noop-returns-nil"
  '((operator . "TILEMODE") (area . "sysvar") (profile . strict))
  '(setview (list 0.0 0.0 0.0) 1)
  nil)
