;;;; tests/equality/zerop.lsp -- ZEROP

(deftest "zerop-of-zero-int"
  '((operator . "ZEROP") (area . "equality") (profile . strict))
  '(zerop 0)
  T)

(deftest "zerop-of-zero-float"
  '((operator . "ZEROP") (area . "equality") (profile . strict))
  '(zerop 0.0)
  T)

(deftest "zerop-of-positive-int"
  '((operator . "ZEROP") (area . "equality") (profile . strict))
  '(zerop 1)
  nil)

(deftest "zerop-of-negative-int"
  '((operator . "ZEROP") (area . "equality") (profile . strict))
  '(zerop -7)
  nil)

(deftest "zerop-of-small-positive-float"
  '((operator . "ZEROP") (area . "equality") (profile . strict))
  '(zerop 0.001)
  nil)
