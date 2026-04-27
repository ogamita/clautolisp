;;;; tests/list/assoc.lsp -- ASSOC

(deftest "assoc-found-symbol-key"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc 'b '((a 1) (b 2) (c 3)))
  '(b 2))

(deftest "assoc-found-integer-key"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc 2 '((1 . one) (2 . two) (3 . three)))
  '(2 . two))

(deftest "assoc-not-found"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc 'z '((a 1) (b 2)))
  nil)

(deftest "assoc-empty-list"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc 'a nil)
  nil)

(deftest "assoc-first-match-wins"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc 'a '((a 1) (a 2)))
  '(a 1))

(deftest "assoc-string-key-uses-equal"
  '((operator . "ASSOC") (area . "list") (profile . strict))
  '(assoc "k" '(("k" . 1) ("j" . 2)))
  '("k" . 1))
