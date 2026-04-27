;;;; tests/special-forms/quote.lsp -- QUOTE special form

(deftest "quote-symbol"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote a)
  'a)

(deftest "quote-list"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote (1 2 3))
  '(1 2 3))

(deftest "quote-nested-list"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote ((a b) (c (d e))))
  '((a b) (c (d e))))

(deftest "quote-of-integer"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote 42)
  42)

(deftest "quote-of-string"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote "hello")
  "hello")

(deftest "quote-of-nil"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote nil)
  nil)

(deftest "tick-shorthand-symbol"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  ''abc
  'abc)

(deftest "tick-shorthand-list"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  ''(1 2)
  '(1 2))

(deftest "quote-does-not-evaluate"
  '((operator . "QUOTE") (area . "special-forms") (profile . strict))
  '(quote (+ 1 2))
  '(+ 1 2))
