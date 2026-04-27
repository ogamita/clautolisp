;;;; tests/error/vl-catch-all.lsp -- VL-CATCH-ALL-APPLY / VL-CATCH-ALL-ERROR-P / VL-CATCH-ALL-ERROR-MESSAGE

(deftest "vl-catch-all-apply-no-error-returns-value"
  '((operator . "VL-CATCH-ALL-APPLY") (area . "error") (profile . strict))
  '(vl-catch-all-apply '+ '(1 2 3))
  6)

(deftest-pred "vl-catch-all-apply-error-returns-error-object"
  '((operator . "VL-CATCH-ALL-APPLY") (area . "error") (profile . strict))
  '(vl-catch-all-apply 'car '(7))
  '(vl-catch-all-error-p *result*))

(deftest-pred "vl-catch-all-apply-error-has-message"
  '((operator . "VL-CATCH-ALL-APPLY") (area . "error") (profile . strict))
  '(vl-catch-all-apply 'car '(7))
  '(eq (type (vl-catch-all-error-message *result*)) 'str))

(deftest "vl-catch-all-error-p-of-non-error-is-nil"
  '((operator . "VL-CATCH-ALL-ERROR-P") (area . "error") (profile . strict))
  '(vl-catch-all-error-p 42)
  nil)

(deftest "vl-catch-all-error-p-of-list-is-nil"
  '((operator . "VL-CATCH-ALL-ERROR-P") (area . "error") (profile . strict))
  '(vl-catch-all-error-p '(a b))
  nil)

(deftest-pred "vl-catch-all-apply-with-lambda-form"
  '((operator . "VL-CATCH-ALL-APPLY") (area . "error") (profile . strict))
  '(vl-catch-all-apply '(lambda () (/ 1 0)) nil)
  '(vl-catch-all-error-p *result*))
