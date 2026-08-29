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
    ;; T is self-evaluating REGARDLESS of its binding. The two cases above
    ;; both have an earlier clause that fires, so the t clause is present
    ;; but never TAKEN -- which is how the compiler shipped treating T as
    ;; an ordinary variable. These take it, and the (setq t nil) pair is
    ;; the case the interpreter's own guard exists for.
    "(cond (nil 1) (t 2))"
    "(progn (setq t nil) (cond (t 42)))"
    "(progn (setq t nil) (if t 1 2))"
    "(progn (setq t nil) (and t))"
    ;; while yields nil in this engine, not the last body value
    "(progn (setq i 0) (while (< i 3) (setq i (+ i 1))))"
    "(progn (setq i 0) (while (< i 3) (setq i (+ i 1))) i)"
    ;; function calls
    "(+ 1 2)"
    "(car '(1 2 3))"
    "(cdr '(1 2 3))"
    "(list 1 2 3)"
    "(strcat \"a\" \"b\")"
    ;; nested calls: the value of one call is an argument of the next, and
    ;; integers stay integers while reals stay reals across the boundary
    "(+ (* 2 3) (- 10 4))"
    "(car (cdr (list 1 2 3)))"
    "(list 1 2.0 \"three\" 'four)"
    "(strcat (strcat \"a\" \"b\") \"c\")"
    ;; arguments evaluate LEFT TO RIGHT, and their side effects are
    ;; visible in that order -- pinned by reading the variable back
    "(progn (setq a 0) (list (setq a 1) (setq a 2) a))"
    ;; a call whose arguments are themselves compiled special forms, and
    ;; the reverse -- the two halves must compose in both directions
    "(progn (setq a 2) (if (and (> a 1) (< a 10)) (+ a 40) 0))"
    "(+ (if nil 1 2) (cond (nil 10) (t 20)))"
    "(progn (setq i 0) (while (< i 4) (setq i (+ i 1))) (* i i))"
    ;; user-defined functions: DEFUN itself still falls back, the CALL of
    ;; the resulting function does not, so this crosses the boundary the
    ;; way real code does
    "(progn (defun double (x) (* 2 x)) (double 21))"
    "(progn (defun add3 (a b c) (+ a (+ b c))) (add3 1 2 3))"
    "(progn (defun fact (n) (if (< n 2) 1 (* n (fact (- n 1))))) (fact 6))")
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
  ;; COMMAND is the example now: FOREACH was, until the transpiler learned
  ;; to open-code it (2.0.21), which is the point -- the set of unhandled
  ;; operators shrinks and this test follows it rather than pinning it.
  (is (%same-value-p (%interpreted "(let ((x 1)) x)")
                     (%compiled "(let ((x 1)) x)")))
  ;; and it reports itself as a fallback rather than pretending coverage
  (is (member "LET" (transpiler-coverage (%read-one "(let ((x 1)) x)"))
              :test #'equal)))

(test coverage-is-reported-not-assumed
  "The transpiler records what it fell back on, so that coverage is a
measurement. A form built only from handled operators reports nothing."
  (is (null (transpiler-coverage (%read-one "(if 1 2 3)"))))
  (is (null (transpiler-coverage (%read-one "(progn (setq a 1) a)"))))
  (is (null (transpiler-coverage (%read-one "(cond (nil 1) (2 3))"))))
  ;; calls are compiled now, arguments included, so nothing is reported
  ;; even for a function that does not exist -- coverage is about what the
  ;; TRANSPILER handles, not about what is defined
  (is (null (transpiler-coverage (%read-one "(foo 1)"))))
  (is (null (transpiler-coverage (%read-one "(+ (car x) (cdr y))"))))
  ;; a special operator not yet open-coded still reports itself, and only
  ;; it: the arguments around it are compiled
  (is (equal '("LET") (transpiler-coverage (%read-one "(+ 1 (let ((x 2)) x))"))))
  ;; ... and the loops the transpiler DOES open-code report nothing, body
  ;; included. A fallback hands over the whole subform, so a FOREACH that
  ;; fell back would take its body with it -- which is what made these two
  ;; worth open-coding and what this line is here to keep true.
  (is (null (transpiler-coverage (%read-one "(repeat 2 (setq a 1))"))))
  (is (null (transpiler-coverage (%read-one "(foreach e l (setq a e))")))))

(test special-operators-are-never-compiled-as-calls
  "A special operator has UNEVALUATED operands. Compiling (defun f (x) …)
as a call would evaluate its lambda list and body as arguments, so the
call branch must be behind the runtime's own KNOWN-SPECIAL-OPERATOR-P
rather than behind a list kept here."
  ;; DEFUN's operands must survive unevaluated -- (X) is not a call to X
  (is (%same-value-p (%interpreted "(progn (defun f (x) (* x x)) (f 5))")
                     (%compiled "(progn (defun f (x) (* x x)) (f 5))")))
  (is (eql 25 (%compiled "(progn (defun f (x) (* x x)) (f 5))")))
  ;; Every special operator this slice does not open-code must report
  ;; itself as a fallback -- i.e. must NOT have been compiled as a call.
  ;; Listed by name so that adding an operator to the runtime without
  ;; teaching the compiler about it shows up here as a gap rather than as
  ;; evaluated operands.
  (dolist (case '(("(set 'a 1)"        . "SET")
                  ("(let ((x 1)) x)"   . "LET")
                  ("(lambda (x) x)"    . "LAMBDA")
                  ("(function car)"    . "FUNCTION")
                  ("(defun g (x) x)"   . "DEFUN")
                  ("(defun-q h (x) x)" . "DEFUN-Q")))
    (destructuring-bind (text . name) case
      (is (member name (transpiler-coverage (%read-one text)) :test #'equal)
          "~S was not reported as a fallback on ~A -- was it compiled as a ~
           call, evaluating operands the interpreter leaves alone?" text name))))

(test a-call-resolves-its-function-before-evaluating-arguments
  "The interpreter looks the function up FIRST, so an undefined function
is signalled before any argument's side effects happen. A compiler that
evaluated arguments first would leave the variable modified after the
error -- a difference nothing would notice until it did."
  (let ((context (%fresh-context))
        (function (compile-autolisp-form (%read-one "(nosuchfunction (setq a 1))")))
        (signalled nil))
    (autolisp-eval (%read-one "(setq a 0)") context)
    ;; The outcome is captured and asserted afterwards rather than
    ;; asserted inside the branches: FiveAM's IS wants a LIST, so (is nil)
    ;; is a compile-time error SBCL defers to run time -- a landmine that
    ;; only fires on the branch one expects never to take.
    (handler-case (funcall function context)
      (autolisp-runtime-error () (setf signalled t)))
    (is (eq t signalled) "calling an undefined function did not signal")
    ;; and the argument's SETQ must NOT have run
    (is (eql 0 (lookup-variable (%read-one "a") context)))))

(test calls-go-through-the-interpreters-own-entry-point
  "Compiled calls use CALL-AUTOLISP-FUNCTION-IN-CONTEXT, which is what
keeps TRACE, the call-stack frames and the debugger's dispatch working
through compiled code. Pinned here as behaviour: a function defined by
interpreted code is callable from compiled code and vice versa, which is
only true because both go through the same door."
  (let ((context (%fresh-context)))
    (autolisp-eval (%read-one "(defun triple (x) (* 3 x))") context)
    ;; compiled code calls the interpreted definition
    (is (eql 21 (funcall (compile-autolisp-form (%read-one "(triple 7)")) context)))
    ;; and interpreted code calls a function whose body ran compiled
    (funcall (compile-autolisp-form (%read-one "(setq n (triple 4))")) context)
    (is (eql 12 (autolisp-eval (%read-one "n") context)))))

(test setq-yields-its-last-assignment
  "Pinned separately because it is the one place the emitted code keeps
an intermediate: a multi-pair SETQ must yield the LAST value, not the
first and not a list."
  (is (eql 2 (%compiled "(setq a 1 b 2)")))
  (is (%same-value-p (%interpreted "(setq a 1 b 2)")
                     (%compiled "(setq a 1 b 2)"))))
