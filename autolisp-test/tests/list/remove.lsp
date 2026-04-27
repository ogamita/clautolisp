;;;; tests/list/remove.lsp -- REMOVE

(deftest "remove-found-element"
  '((operator . "REMOVE") (area . "list") (profile . strict))
  '(remove 'b '(a b c))
  '(a c))

(deftest "remove-multiple-occurrences"
  '((operator . "REMOVE") (area . "list") (profile . strict))
  '(remove 'b '(a b c b d))
  '(a c d))

(deftest "remove-not-found"
  '((operator . "REMOVE") (area . "list") (profile . strict))
  '(remove 'z '(a b c))
  '(a b c))

(deftest "remove-empty-list"
  '((operator . "REMOVE") (area . "list") (profile . strict))
  '(remove 'a nil)
  nil)

(deftest "remove-only-element"
  '((operator . "REMOVE") (area . "list") (profile . strict))
  '(remove 'x '(x))
  nil)
