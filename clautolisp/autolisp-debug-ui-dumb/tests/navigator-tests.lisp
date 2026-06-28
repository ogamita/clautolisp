;;;; FiveAM tests for the structural sexp navigator
;;;; (clautolisp.debug.ui navigator, command reference §3).

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(test nav-basic-motions
  (let ((nav (clautolisp.debug.ui:make-navigator '(a (b c) d))))
    (is (equal '(a (b c) d) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-down nav)
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-forward nav)
    (is (equal '(b c) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-down nav)
    (is (eq 'b (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-up nav)
    (is (equal '(b c) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-forward nav)
    (is (eq 'd (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-forward nav)            ; clamp at the last sibling
    (is (eq 'd (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-backward nav)
    (is (equal '(b c) (clautolisp.debug.ui:nav-selected nav)))))

(test nav-first-last-skip
  (let ((nav (clautolisp.debug.ui:make-navigator '(a b c d e))))
    (clautolisp.debug.ui:nav-down nav)               ; → a
    (clautolisp.debug.ui:nav-last nav)
    (is (eq 'e (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-first nav)
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-skip nav 2)
    (is (eq 'c (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-skip nav -10)           ; clamp low
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-skip nav 99)            ; clamp high
    (is (eq 'e (clautolisp.debug.ui:nav-selected nav)))))

(test nav-render-marks-selection
  (let ((nav (clautolisp.debug.ui:make-navigator '(a (b c) d))))
    (is (string= "【(A (B C) D)】" (clautolisp.debug.ui:nav-render nav)))
    (clautolisp.debug.ui:nav-down nav)
    (clautolisp.debug.ui:nav-forward nav)
    (is (string= "(A 【(B C)】 D)" (clautolisp.debug.ui:nav-render nav)))
    ;; custom brackets (the ascii selection decoration)
    (is (string= "(A [(B C)] D)" (clautolisp.debug.ui:nav-render nav "[" "]")))))

(test nav-edges-are-safe
  (let ((nav (clautolisp.debug.ui:make-navigator '(a))))
    (clautolisp.debug.ui:nav-up nav)                 ; no-op at the root
    (is (equal '(a) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-down nav)               ; → a
    (clautolisp.debug.ui:nav-down nav)               ; atom: no-op
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-backward nav)           ; first sibling: clamp
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))))
