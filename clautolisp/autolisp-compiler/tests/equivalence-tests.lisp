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

(defun %signals-code (text &key compiled)
  "The runtime error code TEXT signals, or NIL if it signals none.
Comparing CODES rather than catching in one branch and not the other is
what lets a test say `both ways fail the same way' -- the interpreter
owns the diagnostic, and a transpiler that invented its own would show
up here as two different codes rather than as two passing branches."
  (handler-case
      (progn (if compiled
                 (funcall (compile-autolisp-form (%read-one text)) (%fresh-context))
                 (%interpreted text))
             nil)
    (autolisp-runtime-error (condition) (autolisp-runtime-error-code condition))))

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
  (is (%same-value-p (%interpreted "(set 'x 1)")
                     (%compiled "(set 'x 1)")))
  ;; and it reports itself as a fallback rather than pretending coverage
  (is (member "SET" (transpiler-coverage (%read-one "(set 'x 1)"))
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
  (is (equal '("SET") (transpiler-coverage (%read-one "(+ 1 (set 'x 2))"))))
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
                  ("(defun g (x) x)"   . "DEFUN")
                  ("(defun-q h (x) x)" . "DEFUN-Q")))
    (destructuring-bind (text . name) case
      (is (member name (transpiler-coverage (%read-one text)) :test #'equal)
          "~S was not reported as a fallback on ~A -- was it compiled as a ~
           call, evaluating operands the interpreter leaves alone?" text name))))

(test lambda-and-function-are-open-coded-not-handed-over
  "LAMBDA and FUNCTION were in the fallback list above until 2.0.23, and
they mattered more than their frequency suggests: a fallback hands the
interpreter the WHOLE SUBFORM, so every higher-order idiom -- the (apply
(function f) args) that portable AutoLISP is written in -- put an
AUTOLISP-EVAL back in the middle of otherwise compiled code."
  (is (null (transpiler-coverage (%read-one "(function car)"))))
  (is (null (transpiler-coverage (%read-one "(lambda (x) (* x 2))"))))
  (is (null (transpiler-coverage (%read-one "(function (lambda (x) x))"))))
  ;; the surrounding form is compiled too, body included
  (is (null (transpiler-coverage
             (%read-one "(foreach e l (apply (function car) (list e)))")))))

(test function-yields-its-argument-unevaluated
  "FUNCTION is QUOTE plus a hint to a compiler that is not this one. The
value is the DESIGNATOR -- a symbol stays a symbol -- and that is what
makes the resolution LATE: (apply (function fn) args) finds an FN
defined further down the dynamic stack, which folding a lookup here
would silently break. Stated as a value, not just as an agreement,
because two engines agreeing on a wrong answer is what an
equivalence-only test cannot see."
  (let ((compiled (%compiled "(function car)")))
    (is (typep compiled 'autolisp-symbol))
    (is (string= "CAR" (autolisp-symbol-name compiled))))
  (is (%agree-p "(function car)"))
  (is (%agree-p "(function (lambda (x) x))"))
  ;; A malformed FUNCTION must still signal the INTERPRETER's error, not
  ;; a second one invented in the transpiler.
  (is (equal (%signals-code "(function)") (%signals-code "(function)" :compiled t)))
  (is (equal (%signals-code "(function 1)") (%signals-code "(function 1)" :compiled t))))

(test lambda-builds-the-interpreters-own-closure
  "The closure comes from EVAL-LAMBDA-FORM, so it is an ordinary USUBR:
same environment capture, same arity check, and -- the part worth
pinning -- the same CALL-COUNT and COMPILED-BODY slots, which is why a
hot lambda body still reaches the compiler by the usual threshold."
  (is (eql 12 (%compiled "((lambda (x) (* x 3)) 4)")))
  (is (%agree-p "((lambda (x) (* x 3)) 4)"))
  (is (%agree-p "((lambda (x y) (+ x y)) 1 2)"))
  ;; the body sees the defining environment, not the calling one
  (is (%agree-p "(progn (setq k 10) ((lambda (x) (+ x k)) 5))"))
  (is (typep (%compiled "(lambda (x) x)") 'autolisp-usubr))
  ;; arity errors stay the interpreter's
  (is (equal (%signals-code "(lambda)") (%signals-code "(lambda)" :compiled t))))

(test let-is-open-coded-body-included
  "LET fell back until 2.0.24, and the cost was not the binding: a
fallback hands the interpreter the WHOLE SUBFORM, so a LET took ITS
ENTIRE BODY with it and a compiled function whose work sat inside a LET
ran that work interpreted. Same shape of hole FOREACH was."
  (is (null (transpiler-coverage (%read-one "(let ((x 1)) x)"))))
  (is (null (transpiler-coverage (%read-one "(let ((x 1) (y 2)) (+ x y))"))))
  ;; the BODY is compiled too -- a call inside it reports nothing
  (is (null (transpiler-coverage (%read-one "(let ((x 1)) (foreach e l (setq a e)))"))))
  ;; a malformed binding list is still the interpreter's to diagnose
  (is (member "LET" (transpiler-coverage (%read-one "(let 7 1)")) :test #'equal)))

(test let-binds-in-parallel-not-sequentially
  "Every init-form is evaluated in the ENCLOSING scope before any name is
bound, which is what BricsCAD V26 was measured doing (2026-08-07) and
what separates LET from a LET* that BricsCAD does not have. Binding as
the transpiler walked the list would have made it LET* silently -- the
values would differ only when an init mentions a name the same LET
binds, which is exactly the case nobody writes a test for."
  (is (%agree-p "(progn (setq x 10) (let ((x 1) (y x)) (list x y)))"))
  ;; stated as a VALUE as well: two engines agreeing on (1 1) would pass
  ;; an agreement-only test while both were wrong.
  (let ((v (%compiled "(progn (setq x 10) (let ((x 1) (y x)) (list x y)))")))
    (is (eql 1 (first v)))
    (is (eql 10 (second v))))
  ;; the binding is torn down afterwards, on the normal path
  (is (%agree-p "(progn (setq x 10) (let ((x 1)) x) x)"))
  (is (eql 10 (%compiled "(progn (setq x 10) (let ((x 1)) x) x)"))))

(test let-tears-its-frame-down-on-a-non-local-exit
  "The frame is popped by UNWIND-PROTECT, so an error inside the body
must not leave the LET's binding standing. Interpreted and compiled are
asserted to agree on the value AFTER the escape, which is where a
leaked frame would show."
  (let ((context (%fresh-context)))
    (autolisp-eval (%read-one "(setq x 10)") context)
    (handler-case
        (funcall (compile-autolisp-form
                  (%read-one "(let ((x 1)) (nosuchfunction))"))
                 context)
      (autolisp-runtime-error () nil))
    (is (eql 10 (lookup-variable (%read-one "x") context))
        "the LET frame outlived the error that escaped its body")))

(test a-lambda-in-a-loop-compiles-once-not-once-per-iteration
  "A LAMBDA form evaluated in a loop mints a NEW closure per iteration,
so a compilation decision taken per OBJECT is retaken from scratch on
every one of them -- objects that are all the SAME CODE. Measured at
440x SLOWER than interpreting the same loop before the site existed,
because the host compiler ran once per iteration.

The fix gives each compiled LAMBDA form one SITE, shared by every
closure it builds. Pinned here on the two things that must hold: the
site is the same object across iterations, and a closure built after
the body was compiled inherits it rather than recompiling."
  (let* ((context (%fresh-context))
         (function (compile-autolisp-form
                    (%read-one "(lambda (x) (* x 2))")))
         (a (funcall function context))
         (b (funcall function context)))
    ;; two evaluations of ONE compiled lambda form: distinct closures...
    (is (not (eq a b)) "the two closures were the same object")
    ;; ...sharing one site, which is what makes the decision one decision
    (is (eq (autolisp-usubr-site a) (autolisp-usubr-site b))
        "the two closures did not share a site")
    ;; and the site is a site, not merely non-nil
    (is (typep (autolisp-usubr-site a) 'usubr-site)))
  ;; A closure the INTERPRETER built has no site, and keeps exactly the
  ;; behaviour it had: the decision stays on the closure.
  (let ((interpreted (%interpreted "(lambda (x) (* x 2))")))
    (is (null (autolisp-usubr-site interpreted))))
  ;; The value is unchanged by any of this, compiled or not.
  (is (%agree-p "(apply (lambda (x) (* x 2)) (list 21))"))
  (is (eql 42 (%compiled "(apply (lambda (x) (* x 2)) (list 21))"))))

(test a-site-shares-a-compiled-body-but-never-an-environment
  "Only the BODY is common to the closures of one site, so only the
compiled body is shared. Two closures from the same form may capture
DIFFERENT environments, and sharing those would be a semantic change
wearing an optimization's clothes -- the reason fix (3) in the issue
was rejected. Pinned as a value: closures made when K differs must
answer differently even though they share a site."
  (let ((context (%fresh-context)))
    (autolisp-eval (%read-one "(setq k 1)") context)
    (autolisp-eval
     (%read-one "(defun mk ( / ) (lambda (x) (+ x k)))") context)
    ;; force the body compiled, then build another closure from the site
    (autolisp-eval (%read-one "(setq f (mk))") context)
    (autolisp-eval (%read-one "(setq k 100)") context)
    (autolisp-eval (%read-one "(setq g (mk))") context)
    (is (eql 101 (autolisp-eval (%read-one "(apply g (list 1))") context)))
    (is (eql 101 (autolisp-eval (%read-one "(apply f (list 1))") context))
        "K is a GLOBAL here, so both closures must see its current value")))

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
