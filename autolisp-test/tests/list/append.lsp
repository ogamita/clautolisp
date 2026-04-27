;;;; tests/list/append.lsp -- APPEND

(deftest "append-empty"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append)
  nil)

(deftest "append-single-list"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append '(1 2 3))
  '(1 2 3))

(deftest "append-two-lists"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append '(1 2) '(3 4))
  '(1 2 3 4))

(deftest "append-three-lists"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append '(a) '(b) '(c))
  '(a b c))

(deftest "append-with-nil-skips"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append nil '(1 2) nil '(3))
  '(1 2 3))

(deftest "append-of-nested-lists"
  '((operator . "APPEND") (area . "list") (profile . strict))
  '(append '((a)) '((b c)))
  '((a) (b c)))
