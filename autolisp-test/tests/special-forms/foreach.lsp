;;;; tests/special-forms/foreach.lsp -- FOREACH special form

(deftest "foreach-empty-list"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(progn (setq fe-count 0)
          (foreach x nil (setq fe-count (+ fe-count 1)))
          fe-count)
  0)

(deftest "foreach-three-elements"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(progn (setq fe-acc 0)
          (foreach x '(1 2 3) (setq fe-acc (+ fe-acc x)))
          fe-acc)
  6)

(deftest "foreach-binds-loop-variable"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(progn (setq fe-collected nil)
          (foreach el '(a b c)
            (setq fe-collected (cons el fe-collected)))
          (reverse fe-collected))
  '(a b c))

(deftest "foreach-multi-form-body"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(progn (setq fe-x 0) (setq fe-y 0)
          (foreach n '(10 20 30)
            (setq fe-x (+ fe-x n))
            (setq fe-y (+ fe-y 1)))
          (list fe-x fe-y))
  '(60 3))

(deftest "foreach-returns-last-body-value"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(foreach el '(1 2 3) (* el el))
  9)

(deftest "foreach-iterates-in-order"
  '((operator . "FOREACH") (area . "special-forms") (profile . strict))
  '(progn (setq fe-trace "")
          (foreach el '("a" "b" "c") (setq fe-trace (strcat fe-trace el)))
          fe-trace)
  "abc")
