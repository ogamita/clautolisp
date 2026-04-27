;;;; tests/symbol/atoms-family.lsp -- ATOMS-FAMILY

(deftest "atoms-family-format-0-returns-list"
  '((operator . "ATOMS-FAMILY") (area . "symbol") (profile . strict))
  '(listp (atoms-family 0))
  T)

(deftest "atoms-family-format-1-returns-list-of-strings"
  '((operator . "ATOMS-FAMILY") (area . "symbol") (profile . strict))
  '(listp (atoms-family 1))
  T)

(deftest-pred "atoms-family-with-name-list-returns-bound-or-nil"
  '((operator . "ATOMS-FAMILY") (area . "symbol") (profile . strict))
  '(atoms-family 0 (list "CAR" "TOTALLY-NOT-A-FUNCTION"))
  '(and (listp *result*) (= 2 (length *result*))))
