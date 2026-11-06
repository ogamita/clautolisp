;;;; tests/divergent/printer-no-argument.lsp -- (princ) / (prin1) / (print)
;;;;
;;;; What the printers return called with NO argument -- measured 2026-10-04
;;;; (probes/sources/probe-printer.lsp): AutoCAD 2022 returns the void symbol
;;;; (the empty-named symbol, what the spec says) from all three (job
;;;; 16921381038); BricsCAD V26 returns nil from PRINC and PRINT and the
;;;; STRING "nil" from PRIN1 (job 16921381039). The strict tests in
;;;; tests/printer/ pin the spec; these pin each vendor.

(deftest "autocad-princ-no-arg-returns-the-void-symbol"
  '((operator . "PRINC") (area . "printer") (profile . autocad)
    (authority . tested-autocad))
  '(vl-symbol-name (princ)) "")

(deftest "autocad-prin1-no-arg-returns-the-void-symbol"
  '((operator . "PRIN1") (area . "printer") (profile . autocad)
    (authority . tested-autocad))
  '(vl-symbol-name (prin1)) "")

(deftest "autocad-print-no-arg-returns-the-void-symbol"
  '((operator . "PRINT") (area . "printer") (profile . autocad)
    (authority . tested-autocad))
  '(vl-symbol-name (print)) "")

(deftest "bricscad-princ-no-arg-returns-nil"
  '((operator . "PRINC") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(princ) nil)

(deftest "bricscad-prin1-no-arg-returns-the-string-nil"
  '((operator . "PRIN1") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(prin1) "nil")

(deftest "bricscad-print-no-arg-returns-nil"
  '((operator . "PRINT") (area . "printer") (profile . bricscad)
    (authority . tested-bricscad))
  '(print) nil)
