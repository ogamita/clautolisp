;;;; tests/printer/terpri.lsp -- TERPRI
;;;; Strict: zero-arity. Confirmed by the BricsCAD V26 / macOS Phase-5
;;;; probe run (terpri with a file-desc argument errored).

(deftest "terpri-no-arg-returns-nil"
  '((operator . "TERPRI") (area . "printer") (profile . strict))
  '(terpri) nil)

(deftest-error "terpri-with-file-desc-argument-errors"
  '((operator . "TERPRI") (area . "printer") (profile . strict))
  '(terpri 42)
  'argument)
