;;;; tests/list/cdr.lsp -- CDR

(deftest "cdr-of-three-list"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr '(1 2 3))
  '(2 3))

(deftest "cdr-of-singleton-is-nil"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr '(only))
  nil)

(deftest "cdr-of-nil-is-nil"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr nil)
  nil)

(deftest "cdr-of-dotted-pair"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr '(1 . 2))
  2)

(deftest "cdr-of-two-list"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr '(a b))
  '(b))

(deftest-error "cdr-of-integer-signals-error"
  '((operator . "CDR") (area . "list") (profile . strict))
  '(cdr 7)
  'argument)
