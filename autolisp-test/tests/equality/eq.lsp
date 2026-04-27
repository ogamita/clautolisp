;;;; tests/equality/eq.lsp -- EQ

(deftest "eq-same-symbol"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq 'a 'a)
  T)

(deftest "eq-different-symbols"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq 'a 'b)
  nil)

(deftest "eq-nil-eq-nil"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq nil nil)
  T)

(deftest "eq-T-eq-T"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq T T)
  T)

(deftest "eq-small-integers"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq 5 5)
  T)

(deftest "eq-different-numbers-nil"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq 5 6)
  nil)

(deftest "eq-of-fresh-conses-may-differ"
  '((operator . "EQ") (area . "equality") (profile . strict))
  '(eq (cons 1 nil) (cons 1 nil))
  nil)
