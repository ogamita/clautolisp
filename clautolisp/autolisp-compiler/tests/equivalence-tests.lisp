(in-package #:clautolisp.autolisp-compiler.tests)

(in-suite autolisp-compiler-suite)

;;;; The compiler's contract, stated as a test rather than as prose:
;;;; COMPILED AND INTERPRETED EVALUATION AGREE.
;;;;
;;;; Not "the compiler handles these forms" — that would pass while the
;;;; compiler was wrong about a form it claimed to handle, and it would
;;;; say nothing about the forms that fall back. Each case below is
;;;; evaluated BOTH ways, in a fresh context each time, and the two
;;;; results must be EQUAL. A case the transpiler does not handle
;;;; therefore still passes (it falls back to the interpreter), which is
;;;; the point of the fallback design: coverage can grow without the
;;;; contract ever loosening.

(defun %fresh-context ()
  ;; Order matters: the reset clears the symbol table, so the builtins go
  ;; in after it or every fallback case dies as an undefined function.
  (reset-default-evaluation-context)
  (install-core-builtins)
  (default-evaluation-context))

(defun %read-one (text)
  (first (read-runtime-from-string text)))

(defun %interpreted (text)
  (let ((context (%fresh-context)))
    (autolisp-eval (%read-one text) context)))

(defun %compiled (text)
  (let* ((form (%read-one text))
         (function (compile-autolisp-form form))
         (context (%fresh-context)))
    (funcall function context)))

(defun %same-value-p (a b)
  "AutoLISP value equality, which is NOT CL's EQUAL.

Strings are WRAPPER OBJECTS here, so two AutoLISP strings holding the
same characters are two distinct structs and EQUAL says no while both
print as \"ab\" -- a comparison that fails and shows two identical-looking
values, which is exactly as confusing as it sounds. Numbers are compared
with = only within the same class, because AutoLISP distinguishes 1 from
1.0. Lists recurse; everything else falls back on EQUAL."
  (cond
    ((and (typep a 'autolisp-string) (typep b 'autolisp-string))
     (string= (autolisp-string-value a) (autolisp-string-value b)))
    ((and (numberp a) (numberp b))
     (and (eq (integerp a) (integerp b)) (= a b)))
    ((and (consp a) (consp b))
     (and (%same-value-p (car a) (car b))
          (%same-value-p (cdr a) (cdr b))))
    (t (equal a b))))

(defun %agree-p (text)
  "True when TEXT evaluates to the same AutoLISP value both ways."
  (%same-value-p (%interpreted text) (%compiled text)))

(defparameter *equivalence-corpus*
  '(;; constants and self-evaluating things
    "42"
    "3.5"
    "\"hello\""
    "nil"
    "'(1 2 3)"
    "'sym"
    ;; variables
    "(setq a 1)"
    "(progn (setq a 7) a)"
    "(progn (setq a 1 b 2) (list a b))"
    ;; the value of setq is the LAST assignment
    "(setq a 1 b 2)"
    ;; if, both branches, and the missing-else case
    "(if 1 10 20)"
    "(if nil 10 20)"
    "(if nil 10)"
    "(progn (setq a 3) (if (> a 2) \"big\" \"small\"))"
    ;; progn, including the empty one
    "(progn)"
    "(progn 1 2 3)"
    ;; and / or yield T or nil, NOT the last value -- the case a Lisp
    ;; reflex gets wrong, which is why it is pinned here
    "(and 1 2)"
    "(and 1 nil)"
    "(and)"
    "(or nil 3)"
    "(or nil nil)"
    "(or)"
    ;; cond, including the test-only clause and the no-clause-taken case
    "(cond (nil 1) (2 3))"
    "(cond (nil 1))"
    "(cond ((= 1 1) \"eq\") (t \"ne\"))"
    "(progn (setq a 5) (cond ((> a 10) \"big\") ((> a 3) \"mid\") (t \"small\")))"
    ;; a test-only clause yields the TEST's value
    "(cond (7))"
    ;; while yields nil in this engine, not the last body value
    "(progn (setq i 0) (while (< i 3) (setq i (+ i 1))))"
    "(progn (setq i 0) (while (< i 3) (setq i (+ i 1))) i)"
    ;; function calls -- these fall back today, and must still agree
    "(+ 1 2)"
    "(car '(1 2 3))"
    "(cdr '(1 2 3))"
    "(list 1 2 3)"
    "(strcat \"a\" \"b\")"
    ;; nesting, so the fallback boundary is crossed in both directions
    "(progn (setq a 2) (if (and (> a 1) (< a 10)) (+ a 40) 0))")
  "AutoLISP source strings that must evaluate identically compiled and
interpreted. Cases are added here as coverage grows; a case is never
removed, so a form that once agreed keeps having to.")

(test compiled-and-interpreted-evaluation-agree
  "Every corpus entry evaluates to the same value both ways. This is the
compiler's whole contract; everything else in this suite is detail."
  (dolist (text *equivalence-corpus*)
    (let ((interpreted (%interpreted text))
          (compiled (%compiled text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled ~S" text interpreted compiled))))

(test unhandled-forms-fall-back-instead-of-failing
  "A form the transpiler knows nothing about still compiles, and still
gives the interpreter's answer. That is what makes the compiler safe to
grow: it is correct before it is complete."
  (is (%same-value-p (%interpreted "(strcat \"a\" \"b\")")
                     (%compiled "(strcat \"a\" \"b\")")))
  ;; and it reports itself as a fallback rather than pretending coverage
  (is (member "STRCAT" (transpiler-coverage (%read-one "(strcat \"a\" \"b\")"))
              :test #'equal)))

(test coverage-is-reported-not-assumed
  "The transpiler records what it fell back on, so that coverage is a
measurement. A form built only from handled operators reports nothing."
  (is (null (transpiler-coverage (%read-one "(if 1 2 3)"))))
  (is (null (transpiler-coverage (%read-one "(progn (setq a 1) a)"))))
  (is (null (transpiler-coverage (%read-one "(cond (nil 1) (2 3))"))))
  ;; a call falls back, and says which operator did
  (is (equal '("FOO") (transpiler-coverage (%read-one "(foo 1)")))))

(test setq-yields-its-last-assignment
  "Pinned separately because it is the one place the emitted code keeps
an intermediate: a multi-pair SETQ must yield the LAST value, not the
first and not a list."
  (is (eql 2 (%compiled "(setq a 1 b 2)")))
  (is (%same-value-p (%interpreted "(setq a 1 b 2)")
                     (%compiled "(setq a 1 b 2)"))))
