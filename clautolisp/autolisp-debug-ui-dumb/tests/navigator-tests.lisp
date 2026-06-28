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

(test nav-special-operator-roles
  ;; child-role classifies each direct child by the operator's table (0 = op)
  (flet ((role (form i) (clautolisp.debug.ui:child-role form i)))
    ;; operator / function position is non-code
    (is (eq :non-code (role '(foo a b) 0)))
    ;; ordinary call: all args code
    (is (eq :code (role '(foo a b) 1)))
    (is (eq :code (role '(foo a b) 2)))
    ;; quote: the datum is non-code
    (is (eq :non-code (role '(quote (a b)) 1)))
    ;; setq: variables (odd) non-code, values (even) code
    (is (eq :non-code (role '(setq x 1 y 2) 1)))
    (is (eq :code     (role '(setq x 1 y 2) 2)))
    (is (eq :non-code (role '(setq x 1 y 2) 3)))
    (is (eq :code     (role '(setq x 1 y 2) 4)))
    ;; defun: name + arglist non-code, body code
    (is (eq :non-code (role '(defun f (a b) (g a)) 1)))
    (is (eq :non-code (role '(defun f (a b) (g a)) 2)))
    (is (eq :code     (role '(defun f (a b) (g a)) 3)))
    ;; lambda: arglist non-code, body code
    (is (eq :non-code (role '(lambda (x) x) 1)))
    (is (eq :code     (role '(lambda (x) x) 2)))
    ;; foreach: var non-code, list + body code
    (is (eq :non-code (role '(foreach v lst (g v)) 1)))
    (is (eq :code     (role '(foreach v lst (g v)) 2)))
    (is (eq :code     (role '(foreach v lst (g v)) 3)))
    ;; function designator non-code
    (is (eq :non-code (role '(function foo) 1)))
    ;; cond clauses are groups
    (is (eq :group    (role '(cond (a 1) (b 2)) 1)))
    ;; all-code special operators (no table entry): default code
    (is (eq :code     (role '(if a b c) 1)))
    (is (eq :code     (role '(progn a b) 2)))
    (is (eq :code     (role '(while a b) 1)))))

(test nav-code-p-tracks-position
  ;; navigate (defun f (a) (g a)): name/arglist non-code, body code
  (let ((nav (clautolisp.debug.ui:make-navigator '(defun f (a) (g a)))))
    (is (clautolisp.debug.ui:nav-code-p nav))          ; whole form: code
    (clautolisp.debug.ui:nav-down nav)                 ; → defun (the operator)
    (is (not (clautolisp.debug.ui:nav-code-p nav)))
    (clautolisp.debug.ui:nav-forward nav)              ; → f (name)
    (is (not (clautolisp.debug.ui:nav-code-p nav)))
    (clautolisp.debug.ui:nav-forward nav)              ; → (a) arglist
    (is (not (clautolisp.debug.ui:nav-code-p nav)))
    (clautolisp.debug.ui:nav-forward nav)              ; → (g a) body
    (is (clautolisp.debug.ui:nav-code-p nav))
    (is (eq :code (clautolisp.debug.ui:nav-selected-role nav)))))
