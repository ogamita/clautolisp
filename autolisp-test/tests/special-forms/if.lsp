;;;; tests/special-forms/if.lsp -- IF special form

(deftest "if-true-then-branch"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if t 'yes 'no)
  'yes)

(deftest "if-nil-else-branch"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if nil 'yes 'no)
  'no)

(deftest "if-no-else-branch-returns-nil"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if nil 'yes)
  nil)

(deftest "if-non-nil-truthy"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if 0 'yes 'no)
  'yes)

(deftest "if-empty-string-truthy"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if "" 'yes 'no)
  'yes)

(deftest "if-list-truthy"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if (list 1) 'yes 'no)
  'yes)

(deftest "if-empty-list-is-nil"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if (list) 'yes 'no)
  'no)

(deftest "if-evaluates-condition-only"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(progn (setq if-trace 0)
          (if t (setq if-trace 1) (setq if-trace 2))
          if-trace)
  1)

(deftest "if-non-eval-of-skipped-branch"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(progn (setq if-trace 0)
          (if nil (setq if-trace 1) (setq if-trace 2))
          if-trace)
  2)

(deftest "if-with-arithmetic-condition"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(if (= 1 1) 'eq 'neq)
  'eq)

(deftest "if-without-then-evaluates-condition-side-effect"
  '((operator . "IF") (area . "special-forms") (profile . strict))
  '(progn (setq if-cond-trace 0)
          (if (progn (setq if-cond-trace 5) nil) 'a 'b)
          if-cond-trace)
  5)
