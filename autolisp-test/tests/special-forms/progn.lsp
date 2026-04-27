;;;; tests/special-forms/progn.lsp -- PROGN special form

(deftest "progn-empty"
  '((operator . "PROGN") (area . "special-forms") (profile . strict))
  '(progn)
  nil)

(deftest "progn-returns-last"
  '((operator . "PROGN") (area . "special-forms") (profile . strict))
  '(progn 1 2 3)
  3)

(deftest "progn-evaluates-all-in-order"
  '((operator . "PROGN") (area . "special-forms") (profile . strict))
  '(progn (setq progn-test-trace 0)
          (setq progn-test-trace (+ progn-test-trace 1))
          (setq progn-test-trace (+ progn-test-trace 10))
          progn-test-trace)
  11)

(deftest "progn-single-form"
  '((operator . "PROGN") (area . "special-forms") (profile . strict))
  '(progn 99)
  99)

(deftest "progn-nested"
  '((operator . "PROGN") (area . "special-forms") (profile . strict))
  '(progn (progn 1 2) (progn 3 4))
  4)
