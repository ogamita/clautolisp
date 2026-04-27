;;;; tests/error/vl-exit.lsp -- VL-EXIT-WITH-ERROR / VL-EXIT-WITH-VALUE
;;;;
;;;; Both exit through vl-catch-all-apply: with-error sets the catch
;;;; object to an error, with-value sets it to the value passed.

(deftest-pred "vl-exit-with-error-is-caught"
  '((operator . "VL-EXIT-WITH-ERROR") (area . "error") (profile . strict))
  '(vl-catch-all-apply
    '(lambda () (vl-exit-with-error "custom-error"))
    nil)
  '(vl-catch-all-error-p *result*))

(deftest "vl-exit-with-value-returns-value"
  '((operator . "VL-EXIT-WITH-VALUE") (area . "error") (profile . strict))
  '(vl-catch-all-apply
    '(lambda () (vl-exit-with-value 99))
    nil)
  99)
