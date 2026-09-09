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

;;;; The second batch of open-coded operators (2.0.15): the one-argument
;;;; list and predicate operators, and EQ.
;;;;
;;;; Same discipline as above. What is worth testing is not that (car '(1))
;;;; is 1 -- it would be hard to get that wrong -- but the edges where the
;;;; fast path has to DECLINE and let the builtin answer, because that is
;;;; the only place a fast path can quietly become a second implementation.

(defparameter *open-coded-unary-corpus*
  '(;; car / cdr: nil and a cons are the whole non-error domain
    "(car '(1 2 3))" "(cdr '(1 2 3))" "(car nil)" "(cdr nil)"
    "(car '(1))" "(cdr '(1))" "(car '(1 . 2))" "(cdr '(1 . 2))"
    "(car (cdr (cdr '(1 2 3))))"
    ;; ... and anything else is an error, which must stay an error
    "(vl-catch-all-error-message (vl-catch-all-apply (function car) (list 5)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function cdr) (list \"s\")))"
    ;; total predicates: no guard, so every kind of object must agree
    "(null nil)" "(null 0)" "(null '(1))" "(null \"\")"
    "(not nil)" "(not 1)"
    "(atom nil)" "(atom 5)" "(atom '(1))" "(atom \"s\")"
    "(listp nil)" "(listp '(1))" "(listp 5)" "(listp \"s\")"
    ;; zerop DOES signal on a non-number, and accepts floats
    "(zerop 0)" "(zerop 5)" "(zerop 0.0)" "(zerop -0.0)"
    "(vl-catch-all-error-message (vl-catch-all-apply (function zerop) (list nil)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function zerop) (list \"s\")))"
    ;; 1+ / 1- including the range edges, where AutoLISP signals
    "(1+ 5)" "(1- 5)" "(1+ 2.5)" "(1- 2.5)"
    "(1+ 2147483646)" "(1- -2147483647)"
    "(vl-catch-all-error-message (vl-catch-all-apply (function 1+) (list 2147483647)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function 1-) (list -2147483648)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function 1+) (list \"s\")))"
    ;; unary minus negates; and the one value whose negation overflows
    "(- 5)" "(- -5)" "(- 2.5)"
    "(vl-catch-all-error-message (vl-catch-all-apply (function -) (list -2147483648)))"
    ;; eq: identity, plus the documented string rule the fast path declines
    "(eq 'a 'a)" "(eq 'a 'b)" "(eq nil nil)" "(eq 1 1)" "(eq 1 2)"
    "(eq \"abc\" \"abc\")" "(eq \"abc\" \"abd\")" "(eq \"a\" 'a)"
    "(eq '(1) '(1))"
    ;; nested, so an open-coded operand feeds an open-coded operator
    "(null (cdr '(1)))" "(1+ (car '(5 6)))" "(zerop (1- 1))")
  "Expressions whose compiled and interpreted values must agree. Most are
deliberately outside the fast paths.")

(test open-coded-unary-operators-agree-with-the-interpreter
  (dolist (text *open-coded-unary-corpus*)
    (let ((interpreted (%run-interpreted text))
          (compiled (%run-with-compiled-bodies text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled ~S" text interpreted compiled))))

(test eq-on-two-strings-goes-to-the-builtin
  "AutoLISP EQ says two strings with equal contents are EQ, because the
host interns literals. The inline path is EQL, which is NOT that -- so it
must decline whenever either argument is a string. This is the one place
in the second batch where a plausible-looking fast path would be wrong."
  (is (%same-value-p (%run-interpreted "(eq \"abc\" \"abc\")")
                     (%run-with-compiled-bodies "(eq \"abc\" \"abc\")")))
  ;; and the answer really is truth, not the nil that bare EQL would give
  (is (not (null (%run-with-compiled-bodies "(eq \"abc\" \"abc\")")))
      "compiled (eq \"abc\" \"abc\") gave nil; the fast path did not decline"))

(test car-of-a-non-list-still-signals
  "CAR's fast path covers nil and conses -- CL's CAR of NIL is NIL, so
that is the builtin's whole non-error domain. A number must still reach
the builtin and still signal, rather than returning something."
  (let ((text "(vl-catch-all-error-message
                 (vl-catch-all-apply (function car) (list 5)))"))
    (is (%same-value-p (%run-interpreted text) (%run-with-compiled-bodies text)))
    (is (search "CAR" (autolisp-string-value (%run-with-compiled-bodies text)))
        "car of a number did not report a CAR error")))

(test a-user-defun-of-a-unary-open-coded-operator-wins
  "The guard is per call site and per operator, so it has to hold for the
one-argument fast paths too, not just the arithmetic ones it was first
written for."
  (let ((result (%compiled-value
                 "(progn (defun use (l) (car l))
                         (setq before (use '(1 2)))
                         (defun car (l) 'redefined)
                         (list before (use '(1 2))))")))
    (is (equal 2 (length result)) "unexpected shape: ~S" result)
    (is (eql 1 (first result)))
    (is (string= "REDEFINED" (autolisp-symbol-name (second result)))
        "compiled code ignored a redefinition of car (got ~S)" result)))

(test the-total-predicates-have-no-guard-and-still-track-a-redefinition
  "NULL cannot signal, so its fast path has no type test at all -- it is
the whole function. That makes the TAG check the only thing standing
between it and a user's redefinition, so this is the test that the tag
check alone is enough."
  (let ((result (%compiled-value
                 "(progn (defun use (x) (null x))
                         (setq before (use nil))
                         (defun null (x) 'mine)
                         (list before (use nil)))")))
    (is (string= "T" (autolisp-symbol-name (first result))))
    (is (string= "MINE" (autolisp-symbol-name (second result)))
        "compiled code ignored a redefinition of null (got ~S)" result)))

;;;; The third batch (2.0.19): CONS, LIST, = and /=, and the
;;;; three-argument arities of the arithmetic and relational operators.
;;;;
;;;; Two things here are new in kind.
;;;;
;;;; CONS and LIST are TOTAL: BUILTIN-CONS is (cons a b) and BUILTIN-LIST
;;;; returns its &rest list, so neither can signal and neither has a
;;;; narrow case. Their fast path has no guard beyond the tag check --
;;;; which makes the tag check the only thing between them and a
;;;; redefinition, tested below.
;;;;
;;;; = and /= are NOT numeric-only, and that is the trap. AutoLISP's
;;;; COMPARISON-EQUAL-P is EQL, then numeric = for two numbers, then
;;;; STRING= for two strings. An inline `=' that only knew about numbers
;;;; would answer nil for (= "a" "a"), which is the same shape of defect
;;;; as an inline EQ that forgot interned strings.

(defparameter *open-coded-third-corpus*
  '(;; n-ary arithmetic: the fast path is over all three arguments at once
    "(+ 1 2 3)" "(- 10 3 2)" "(* 2 3 4)"
    "(+ 5)" "(* 5)" "(- 5)"
    "(+ 2147483645 1 1)"
    "(vl-catch-all-error-message (vl-catch-all-apply (function +) (list 2147483647 1 1)))"
    "(vl-catch-all-error-message (vl-catch-all-apply (function *) (list 100000 100000 2)))"
    ;; ... and a float anywhere in the chain sends the whole thing to the
    ;; builtin, whose promotion rules decide
    "(+ 1 2 3.5)" "(- 10 0.5 2)" "(* 2 3 0.5)"
    ;; n-ary relational: pairwise ALONG the arguments, not first-against-rest
    "(< 1 2 3)" "(< 1 3 2)" "(> 3 2 1)" "(<= 1 1 2)" "(>= 3 3 1)"
    "(< 1 2 nil)" "(< 1.0 2 3)"
    ;; = and /= on integers -- the narrow case
    "(= 1 1)" "(= 1 2)" "(/= 1 2)" "(/= 1 1)"
    ;; ... and off it, where the builtin's own rules apply
    "(= 1 1.0)" "(= \"a\" \"a\")" "(= \"a\" \"b\")" "(= 'x 'x)" "(= nil nil)"
    "(/= 1 1.0)" "(/= \"a\" \"a\")" "(/= 'x 'y)"
    "(= 1 2 3)" "(= 1 1 1)" "(/= 1 2 3)"
    ;; cons and list: total, so every shape must agree
    "(cons 1 2)" "(cons 1 nil)" "(cons 1 '(2 3))" "(cons nil nil)"
    "(cons '(1) '(2))" "(cons \"a\" \"b\")"
    "(list 1)" "(list 1 2)" "(list 1 2 3)" "(list)" "(list 1 2 3 4)"
    "(list nil nil)" "(list '(1) 2)"
    ;; nested, so an open-coded operand feeds an open-coded operator
    "(car (cons 1 2))" "(cdr (list 1 2 3))" "(length (list 1 2 3))"
    "(= (+ 1 1) (* 1 2))")
  "Expressions whose compiled and interpreted values must agree.")

(test the-third-batch-agrees-with-the-interpreter
  (dolist (text *open-coded-third-corpus*)
    (let ((interpreted (%run-interpreted text))
          (compiled (%run-with-compiled-bodies text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled ~S" text interpreted compiled))))

(test equality-on-two-strings-goes-to-the-builtin
  "`=' compares STRINGS as well as numbers, so the inline path -- which
knows only about two integers -- must decline for anything else. An
inline `=' that had assumed numbers would answer nil here."
  (is (not (null (%run-with-compiled-bodies "(= \"a\" \"a\")")))
      "compiled (= \"a\" \"a\") gave nil; the fast path did not decline")
  (is (null (%run-with-compiled-bodies "(= \"a\" \"b\")")))
  ;; and the mixed-type numeric case, where EQL says no and = says yes
  (is (not (null (%run-with-compiled-bodies "(= 1 1.0)")))
      "compiled (= 1 1.0) gave nil"))

(test the-relational-chain-is-pairwise-not-first-against-rest
  "(< 1 3 2) is NIL: the comparison walks the arguments in pairs, so a
three-argument chain is (and (< 1 3) (< 3 2)). Comparing the first
against each of the rest would say T here, which is the mistake an
n-ary fast path invites."
  (is (null (%run-with-compiled-bodies "(< 1 3 2)")))
  (is (not (null (%run-with-compiled-bodies "(< 1 2 3)"))))
  (is (%same-value-p (%run-interpreted "(< 1 3 2)")
                     (%run-with-compiled-bodies "(< 1 3 2)"))))

(test a-redefinition-of-a-total-operator-still-wins
  "CONS cannot signal, so its fast path has no type test -- the tag check
alone stands between it and a user's definition."
  (let ((result (%compiled-value
                 "(progn (defun use (a b) (cons a b))
                         (setq before (use 1 2))
                         (defun cons (a b) 'mine)
                         (list before (use 1 2)))")))
    (is (equal '(1 . 2) (first result)))
    (is (string= "MINE" (autolisp-symbol-name (second result)))
        "compiled code ignored a redefinition of cons (got ~S)" result)))
