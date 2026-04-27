;;;; tests/string/atoi.lsp -- ATOI
;;;; Strict subset shared between AutoCAD and BricsCAD as confirmed
;;;; by the 2026-04-26 BricsCAD V26 / macOS Phase-5 probe run.
;;;; The 0x-prefix divergence is captured under tests/divergent/.

(deftest "atoi-basic-positive"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "17") 17)

(deftest "atoi-leading-plus"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "+17") 17)

(deftest "atoi-leading-minus"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "-17") -17)

(deftest "atoi-leading-zero-decimal"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "017") 17)

(deftest "atoi-trailing-junk-truncates"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "17x") 17)

(deftest "atoi-leading-whitespace-skipped"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi " 17") 17)

(deftest "atoi-empty-string"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "") 0)

(deftest "atoi-non-numeric-string"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "abc") 0)

(deftest "atoi-decimal-truncates"
  '((operator . "ATOI") (area . "string") (profile . strict))
  '(atoi "3.9") 3)
