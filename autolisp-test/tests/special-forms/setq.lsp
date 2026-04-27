;;;; tests/special-forms/setq.lsp -- SETQ special form

(deftest "setq-single-binding"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-x 42) atest-x)
  42)

(deftest "setq-returns-value"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(setq atest-y 17)
  17)

(deftest "setq-multiple-pairs"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-a 1 atest-b 2 atest-c 3) (list atest-a atest-b atest-c))
  '(1 2 3))

(deftest "setq-multiple-pairs-returns-last-value"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(setq atest-a 1 atest-b 2 atest-c 99)
  99)

(deftest "setq-overwrite"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-z 1) (setq atest-z 2) atest-z)
  2)

(deftest "setq-evaluates-rhs"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-w (+ 3 4)) atest-w)
  7)

(deftest "setq-zero-pairs"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(setq)
  nil)

(deftest "setq-nil-binding"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-nilbound nil) atest-nilbound)
  nil)

(deftest "setq-string-binding"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-strbound "abc") atest-strbound)
  "abc")

(deftest "setq-list-binding"
  '((operator . "SETQ") (area . "special-forms") (profile . strict))
  '(progn (setq atest-listbound (list 1 2)) atest-listbound)
  '(1 2))
