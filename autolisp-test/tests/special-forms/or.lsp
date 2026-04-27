;;;; tests/special-forms/or.lsp -- OR special form
;;;;
;;;; AutoLISP `or' returns T or nil only, NOT the first truthy value.
;;;; Documented divergence from Common Lisp; rule on both AutoCAD and
;;;; BricsCAD per the BricsCAD V26 / macOS Phase-5 probe run.

(deftest "or-empty-returns-nil"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(or)
  nil)

(deftest "or-single-nil"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(or nil)
  nil)

(deftest "or-single-truthy"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(or 1)
  T)

(deftest "or-first-truthy-returns-T-not-value"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(or 'first 'second)
  T)

(deftest "or-all-nil-returns-nil"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(or nil nil nil)
  nil)

(deftest "or-short-circuit-side-effect"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(progn (setq or-trace 0)
          (or t (setq or-trace 1))
          or-trace)
  0)

(deftest "or-evaluation-order"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(progn (setq or-order "")
          (or (progn (setq or-order (strcat or-order "a")) nil)
              (progn (setq or-order (strcat or-order "b")) nil)
              (progn (setq or-order (strcat or-order "c")) t))
          or-order)
  "abc")

(deftest "or-stops-at-first-truthy"
  '((operator . "OR") (area . "special-forms") (profile . strict))
  '(progn (setq or-stop "")
          (or (progn (setq or-stop (strcat or-stop "a")) t)
              (progn (setq or-stop (strcat or-stop "b")) t))
          or-stop)
  "a")
