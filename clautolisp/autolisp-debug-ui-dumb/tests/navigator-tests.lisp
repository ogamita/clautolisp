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

(test nav-let-nested-binding-roles
  ;; context-aware grammar: in (let ((v1 e1) (v2 e2)) body) the binding
  ;; variables are :non-code even though nested two lists deep, the inits are
  ;; :code, and the body is :code (BricsCAD LET).
  (let ((nav (clautolisp.debug.ui:make-navigator
              '(let ((a 1) (b (g 2))) (h a b)))))
    ;; arg 1 is the binding list (a group)
    (setf (clautolisp.debug.ui:navigator-path nav) '(1))
    (is (eq :group (clautolisp.debug.ui:nav-selected-role nav)))
    ;; first binding (a 1) is a group
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 0))
    (is (eq :group (clautolisp.debug.ui:nav-selected-role nav)))
    ;; the binding variable a — NON-code, two lists deep
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 0 0))
    (is (eq :non-code (clautolisp.debug.ui:nav-selected-role nav)))
    (is (not (clautolisp.debug.ui:nav-code-p nav)))
    ;; the init expression 1 — code position
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 0 1))
    (is (eq :code (clautolisp.debug.ui:nav-selected-role nav)))
    ;; the second binding's init (g 2) — code
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 1 1))
    (is (eq :code (clautolisp.debug.ui:nav-selected-role nav)))
    ;; the body (h a b) — code (arg index 2 of let)
    (setf (clautolisp.debug.ui:navigator-path nav) '(2))
    (is (eq :code (clautolisp.debug.ui:nav-selected-role nav)))))

(test nav-cond-clause-nested-roles
  ;; a COND clause is a :group; its test and body are :code
  (let ((nav (clautolisp.debug.ui:make-navigator '(cond ((p x) (g x)) (t 0)))))
    (setf (clautolisp.debug.ui:navigator-path nav) '(1))     ; clause ((p x) (g x))
    (is (eq :group (clautolisp.debug.ui:nav-selected-role nav)))
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 0))   ; test (p x)
    (is (eq :code (clautolisp.debug.ui:nav-selected-role nav)))
    (setf (clautolisp.debug.ui:navigator-path nav) '(1 1)))) ; body (g x)

;;; --- code-aware motions: skip non-expression sub-forms (aldo-pre-debug) ---

(test nav-code-motions-skip-non-code-parts
  (let ((nav (clautolisp.debug.ui:make-navigator '(defun fact (x) (if (= 1 x) 1 (* x y))))))
    ;; down from the root skips defun / the name / the arg-list -> first body form
    (clautolisp.debug.ui:nav-code-down nav)
    (is (equal '(if (= 1 x) 1 (* x y)) (clautolisp.debug.ui:nav-selected nav)))
    ;; down into the IF skips the IF operator -> the test expression
    (clautolisp.debug.ui:nav-code-down nav)
    (is (equal '(= 1 x) (clautolisp.debug.ui:nav-selected nav)))
    ;; forward steps through the code siblings (then / else)
    (clautolisp.debug.ui:nav-code-forward nav)
    (is (eql 1 (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-forward nav)
    (is (equal '(* x y) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-forward nav)          ; clamp at the last code sibling
    (is (equal '(* x y) (clautolisp.debug.ui:nav-selected nav)))
    ;; first / last / backward are code-aware too
    (clautolisp.debug.ui:nav-code-first nav)
    (is (equal '(= 1 x) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-last nav)
    (is (equal '(* x y) (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-backward nav)
    (is (eql 1 (clautolisp.debug.ui:nav-selected nav)))))

(test nav-code-down-noop-when-no-code-child
  ;; a bare call (just the operator) has no navigable child -> stay put
  (let ((nav (clautolisp.debug.ui:make-navigator '(foo))))
    (clautolisp.debug.ui:nav-code-down nav)
    (is (equal '(foo) (clautolisp.debug.ui:nav-selected nav)))))

(test nav-code-skip-is-code-aware
  (let ((nav (clautolisp.debug.ui:make-navigator '(if a b c))))
    (clautolisp.debug.ui:nav-code-down nav)             ; -> a (index 1, skipping IF)
    (is (eq 'a (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-skip nav 2)           ; a -> c (over b)
    (is (eq 'c (clautolisp.debug.ui:nav-selected nav)))
    (clautolisp.debug.ui:nav-code-skip nav -1)          ; c -> b
    (is (eq 'b (clautolisp.debug.ui:nav-selected nav)))))
