;;;; tests/list/nth.lsp -- NTH

(deftest "nth-zero-first-element"
  '((operator . "NTH") (area . "list") (profile . strict))
  '(nth 0 '(a b c))
  'a)

(deftest "nth-one-second-element"
  '((operator . "NTH") (area . "list") (profile . strict))
  '(nth 1 '(a b c))
  'b)

(deftest "nth-two-third-element"
  '((operator . "NTH") (area . "list") (profile . strict))
  '(nth 2 '(a b c))
  'c)

(deftest "nth-out-of-bounds-returns-nil"
  '((operator . "NTH") (area . "list") (profile . strict))
  '(nth 10 '(a b c))
  nil)

(deftest "nth-empty-list-returns-nil"
  '((operator . "NTH") (area . "list") (profile . strict))
  '(nth 0 nil)
  nil)
