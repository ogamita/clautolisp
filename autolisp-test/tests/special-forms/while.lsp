;;;; tests/special-forms/while.lsp -- WHILE special form

(deftest "while-test-false-immediately"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-iter 0)
          (while nil (setq while-iter (+ while-iter 1)))
          while-iter)
  0)

(deftest "while-counts-to-three"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-i 0)
          (while (< while-i 3) (setq while-i (+ while-i 1)))
          while-i)
  3)

(deftest "while-accumulates"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-i 0) (setq while-acc 0)
          (while (< while-i 5)
            (setq while-acc (+ while-acc while-i))
            (setq while-i   (+ while-i 1)))
          while-acc)
  10)

(deftest "while-with-multiple-body-forms"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-i 0) (setq while-marker nil)
          (while (< while-i 2)
            (setq while-marker (cons while-i while-marker))
            (setq while-i (+ while-i 1)))
          (length while-marker))
  2)

(deftest "while-returns-nil"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(while nil 'never)
  nil)
