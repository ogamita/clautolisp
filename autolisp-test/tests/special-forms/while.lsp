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

;;; The VALUE of WHILE is the last body value of the last iteration, nil
;;; when the body never runs (spec, WHILE Return Values); it was nil always
;;; until while-repeat-return-nil.
(deftest "while-returns-last-body-value"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-k 0)
          (while (< while-k 3) (setq while-k (1+ while-k)) (* while-k 100)))
  300)

(deftest "while-returns-string-body-value"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-k 0)
          (while (< while-k 2) (setq while-k (1+ while-k)) "s"))
  "s")

;;; No body at all: nil (BricsCAD V26 measured nil, control-flow probe,
;;; job 17396028047).
(deftest "while-test-only-returns-nil"
  '((operator . "WHILE") (area . "special-forms") (profile . strict))
  '(progn (setq while-k 0)
          (while (< (setq while-k (1+ while-k)) 3)))
  nil)
