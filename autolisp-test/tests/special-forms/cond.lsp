;;;; tests/special-forms/cond.lsp -- COND special form

(deftest "cond-empty-returns-nil"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond)
  nil)

(deftest "cond-first-true"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond (t 'first) (t 'second))
  'first)

(deftest "cond-skips-false-clauses"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond (nil 'a) (nil 'b) (t 'c))
  'c)

(deftest "cond-no-true-clause-returns-nil"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond (nil 'a) (nil 'b))
  nil)

(deftest "cond-clause-without-body-returns-test-value"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond ((= 1 1)))
  T)

(deftest "cond-multiple-body-forms-returns-last"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond (t 1 2 3))
  3)

(deftest "cond-evaluates-only-matching-clause"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(progn (setq cond-trace 0)
          (cond (nil (setq cond-trace 1))
                (t   (setq cond-trace 2))
                (t   (setq cond-trace 3)))
          cond-trace)
  2)

(deftest "cond-evaluates-condition-in-order"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(progn (setq cond-order "")
          (cond ((progn (setq cond-order (strcat cond-order "a")) nil) 'x)
                ((progn (setq cond-order (strcat cond-order "b")) nil) 'y)
                ((progn (setq cond-order (strcat cond-order "c")) t)   'z))
          cond-order)
  "abc")

(deftest "cond-T-final-fallback"
  '((operator . "COND") (area . "special-forms") (profile . strict))
  '(cond ((= 0 1) 'wrong) (t 'fallback))
  'fallback)
