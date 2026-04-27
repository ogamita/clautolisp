;;;; tests/reader/quote-syntax.lsp -- Quote reader syntax

(deftest "quote-syntax-tick-equiv-quote"
  '((operator . "Quote") (area . "reader") (profile . strict))
  '(equal ''abc '(quote abc))
  T)

(deftest "quote-syntax-tick-list"
  '((operator . "Quote") (area . "reader") (profile . strict))
  '(equal ''(1 2) '(quote (1 2)))
  T)

(deftest "quote-syntax-nested"
  '((operator . "Quote") (area . "reader") (profile . strict))
  '(car ''abc)
  'quote)
