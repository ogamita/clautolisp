;;;; tests/variables/nil.lsp -- NIL

(deftest "nil-evaluates-to-nil"
  '((operator . "NIL") (area . "variable") (profile . strict))
  'nil nil)

(deftest "nil-eq-nil"
  '((operator . "NIL") (area . "variable") (profile . strict))
  '(eq nil nil) T)

(deftest "nil-is-falsy"
  '((operator . "NIL") (area . "variable") (profile . strict))
  '(if nil 'yes 'no) 'no)

(deftest "nil-is-empty-list"
  '((operator . "NIL") (area . "variable") (profile . strict))
  '(equal nil (list)) T)
