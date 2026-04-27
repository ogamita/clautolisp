;;;; tests/string/atof.lsp -- ATOF
;;;; Strict subset shared between AutoCAD and BricsCAD per the 2026-04-26
;;;; BricsCAD V26 / macOS Phase-5 probe run. C99 hex-float behaviour
;;;; is in tests/divergent/ as a vendor-specific twin set.

(deftest "atof-basic"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "3.5") 3.5)

(deftest "atof-leading-dot"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof ".5") 0.5)

(deftest "atof-trailing-dot"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "1.") 1.0)

(deftest "atof-exponent"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "1e3") 1000.0)

(deftest "atof-leading-zero"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "017") 17.0)

(deftest "atof-leading-whitespace-skipped"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof " 3.5") 3.5)

(deftest "atof-comma-as-junk"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "3,5") 3.0)

(deftest "atof-empty-string"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "") 0.0)

(deftest "atof-non-numeric"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "abc") 0.0)

(deftest "atof-negative"
  '((operator . "ATOF") (area . "string") (profile . strict))
  '(atof "-2.5") -2.5)
