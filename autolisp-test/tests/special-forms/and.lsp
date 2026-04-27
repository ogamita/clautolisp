;;;; tests/special-forms/and.lsp -- AND special form
;;;;
;;;; AutoLISP `and' returns T or nil only, NOT the last truthy value.
;;;; This is a documented divergence from Common Lisp and is the
;;;; rule on both AutoCAD and BricsCAD; see clautolisp PLAN.md
;;;; (BricsCAD V26 / macOS Phase-5 probe run).

(deftest "and-empty-returns-T"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and)
  T)

(deftest "and-single-true"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and t)
  T)

(deftest "and-single-nil"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and nil)
  nil)

(deftest "and-all-true-returns-T-not-last-value"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and 1 2 3)
  T)

(deftest "and-first-nil-short-circuits"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and nil 'never-evaluated)
  nil)

(deftest "and-short-circuit-side-effect"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(progn (setq and-trace 0)
          (and nil (setq and-trace 1))
          and-trace)
  0)

(deftest "and-evaluation-order"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(progn (setq and-order "")
          (and (progn (setq and-order (strcat and-order "a")) t)
               (progn (setq and-order (strcat and-order "b")) t)
               (progn (setq and-order (strcat and-order "c")) t))
          and-order)
  "abc")

(deftest "and-with-zero-truthy"
  '((operator . "AND") (area . "special-forms") (profile . strict))
  '(and 0 0 0)
  T)
