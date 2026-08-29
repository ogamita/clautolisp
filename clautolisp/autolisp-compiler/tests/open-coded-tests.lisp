(in-package #:clautolisp.autolisp-compiler.tests)

(in-suite autolisp-compiler-suite)

;;;; Open-coded operators, and the guard that keeps them honest.
;;;;
;;;; A handful of operators get an inline fast path, because calling them
;;;; through the full protocol costs far more than the operation: an
;;;; argument list, a call-stack entry, two HANDLER-CASEs and two APPLYs to
;;;; add two integers.
;;;;
;;;; The design claim is that this is a FAST PATH and not a second
;;;; implementation of `+'. Two things have to hold for that, and both are
;;;; tested here rather than asserted:
;;;;
;;;;   1. Everything outside the narrow case -- other types, out-of-range
;;;;      results, other arities -- reaches the SAME builtin, and therefore
;;;;      the same value, the same error and the same message.
;;;;
;;;;   2. If the name no longer means that builtin, the fast path does not
;;;;      run. `+' can be redefined with DEFUN, assigned with SETQ, and
;;;;      shadowed by a `/'-local; all three work in AutoLISP, and all
;;;;      three must reach the user's definition from COMPILED code.
;;;;
;;;; The second is the one worth having. An open-coded `+' that ignored a
;;;; user's redefinition would be a compiler that silently computes
;;;; something other than what the program says.

(defparameter *open-coded-corpus*
  '(;; the narrow case itself
    "(+ 2 3)" "(- 9 4)" "(* 6 7)"
    "(< 1 2)" "(< 2 1)" "(> 3 1)" "(<= 2 2)" "(>= 1 2)"
    ;; boundaries of the 32-bit range the fast path is limited to
    "(+ 2147483646 1)" "(- -2147483647 1)"
    "(< -2147483648 2147483647)"
    ;; ... and just outside it, where AutoLISP signals rather than
    ;; returning a bignum. The fast path must decline, not compute.
    "(vl-catch-all-error-message (vl-catch-all-apply (function +) (list 2147483647 1)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function *) (list 100000 100000)))"
    ;; floats: not the fast path's case, and the promotion rules are the
    ;; builtin's business
    "(+ 1.5 2)" "(- 1 0.25)" "(* 2 0.5)" "(< 1.0 2)" "(>= 2.0 2)"
    ;; the relational fold: a NON-NUMBER makes < yield nil, NOT an error.
    ;; Loop guards depend on it, so the fast path must not "improve" it.
    "(< 1 nil)" "(< nil 1)" "(> \"a\" 1)" "(<= nil nil)"
    ;; arities the fast path is not written for
    "(+ 1 2 3)" "(+ 1)" "(+)" "(- 5)" "(* 2 3 4)" "(< 1 2 3)" "(< 1)"
    ;; and a type error, which must still be an error
    "(vl-catch-all-error-message (vl-catch-all-apply (function +) (list 1 \"a\")))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function -) (list nil 1)))"
    ;; nested, so the fast path's own operands are fast paths
    "(+ (* 2 3) (- 10 4))"
    "(if (< (+ 1 1) (* 1 3)) 'yes 'no)")
  "Expressions whose compiled and interpreted values must agree. Most of
them are deliberately OUTSIDE the fast path: that is where a second
implementation would show, because the fast path either declines or it
does not.")

(test open-coded-operators-agree-with-the-interpreter
  (dolist (text *open-coded-corpus*)
    (let ((interpreted (%run-interpreted text))
          (compiled (%run-with-compiled-bodies text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled ~S" text interpreted compiled))))

;;; --- the guard ------------------------------------------------------

(defun %compiled-value (text)
  "Run TEXT with every function body compiled on its first call."
  (%run-with-compiled-bodies text))

(test a-user-defun-of-an-open-coded-operator-wins
  "`+' can be redefined. A compiled body that calls it must reach the
user's function, not the inline fast path -- which is exactly what the
per-call-site tag check is for. The function is called BEFORE the
redefinition too, so its body is already compiled when `+' changes: a
guard that were only checked at compile time would pass the first call
and fail this one."
  (let ((result (%compiled-value
                 "(progn (defun use (a b) (+ a b))
                         (setq before (use 1 2))
                         (defun + (a b) 999)
                         (list before (use 1 2)))")))
    (is (equal '(3 999) (mapcar (lambda (v) v) result))
        "compiled code ignored a redefinition of + (got ~S)" result)))

(test a-setq-of-an-open-coded-operator-wins
  "The other way to redefine it: AutoLISP is a lisp-1, so SETQ of a lambda
replaces the function too."
  (let ((result (%compiled-value
                 "(progn (defun use (a b) (* a b))
                         (setq before (use 3 4))
                         (setq * (lambda (a b) 777))
                         (list before (use 3 4)))")))
    (is (equal '(12 777) result)
        "compiled code ignored a SETQ over * (got ~S)" result)))

(test a-local-shadow-of-an-open-coded-operator-wins
  "A `/'-local holding a function shadows the builtin in operator position
for the duration of the call, and the fast path must not see through it."
  (let ((result (%compiled-value
                 "(progn (defun use (a b) (- a b))
                         (defun shadowed (a b / -)
                           (setq - (lambda (x y) 42))
                           (- a b))
                         (list (use 9 4) (shadowed 9 4) (use 9 4)))")))
    (is (equal '(5 42 5) result)
        "a local shadow of - did not reach compiled code (got ~S)" result)))

(test the-fast-path-declines-an-out-of-range-result
  "AutoLISP `+' is not CL `+': it signals INTEGER-OVERFLOW outside the
32-bit range. The inline path adds two in-range integers and then checks
the RESULT, handing an overflow to the builtin so the error is the
builtin's error. Silently returning a bignum here would be the worst kind
of compiler bug -- a right-looking wrong answer."
  (let* ((text "(vl-catch-all-error-message
                  (vl-catch-all-apply (function +) (list 2147483647 1)))")
         (compiled (%run-with-compiled-bodies text))
         (interpreted (%run-interpreted text)))
    ;; The MESSAGE, not the error object: two runs raise two distinct
    ;; condition objects, and it is the diagnosis that has to match.
    (is (%same-value-p interpreted compiled))
    (is (search "32-bit integer range"
                (autolisp-string-value compiled))
        "an out-of-range sum did not report an overflow: ~S" compiled)
    ;; and the sum really did not slip through as a bignum
    (is (null (numberp compiled))
        "an out-of-range sum came back as a number: ~S" compiled)))

(test the-fast-path-declines-a-non-integer-and-keeps-the-fold
  "`<' folds a non-numeric argument to nil instead of signalling, which
loop idioms depend on. The fast path covers two integers only; everything
else is the builtin's, including that rule."
  (is (null (%run-with-compiled-bodies "(< 1 nil)")))
  (is (null (%run-with-compiled-bodies "(< nil nil)")))
  (is (%same-value-p (%run-interpreted "(< 1.5 2)")
                     (%run-with-compiled-bodies "(< 1.5 2)"))))
