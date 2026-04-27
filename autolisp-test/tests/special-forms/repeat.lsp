;;;; tests/special-forms/repeat.lsp -- REPEAT special form

(deftest "repeat-zero-times-returns-nil"
  '((operator . "REPEAT") (area . "special-forms") (profile . strict))
  '(repeat 0 'never)
  nil)

(deftest "repeat-counts-iterations"
  '((operator . "REPEAT") (area . "special-forms") (profile . strict))
  '(progn (setq rep-count 0)
          (repeat 5 (setq rep-count (+ rep-count 1)))
          rep-count)
  5)

(deftest "repeat-evaluates-each-pass"
  '((operator . "REPEAT") (area . "special-forms") (profile . strict))
  '(progn (setq rep-acc 0)
          (repeat 3 (setq rep-acc (+ rep-acc 7)))
          rep-acc)
  21)

(deftest "repeat-multi-form-body"
  '((operator . "REPEAT") (area . "special-forms") (profile . strict))
  '(progn (setq rep-x 0) (setq rep-y 0)
          (repeat 4
            (setq rep-x (+ rep-x 1))
            (setq rep-y (+ rep-y 2)))
          (list rep-x rep-y))
  '(4 8))

(deftest "repeat-returns-last-body-value"
  '((operator . "REPEAT") (area . "special-forms") (profile . strict))
  '(progn (setq rep-tag 'init)
          (repeat 1 (setq rep-tag 'final))
          rep-tag)
  'final)
