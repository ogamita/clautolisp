;;;; tests/variables/t.lsp -- T

(deftest "T-evaluates-to-T"
  '((operator . "T") (area . "variable") (profile . strict))
  'T T)

(deftest "T-eq-T"
  '((operator . "T") (area . "variable") (profile . strict))
  '(eq T T) T)

(deftest "T-is-truthy"
  '((operator . "T") (area . "variable") (profile . strict))
  '(if T 'yes 'no) 'yes)

(deftest "T-is-not-nil"
  '((operator . "T") (area . "variable") (profile . strict))
  '(eq T nil) nil)
