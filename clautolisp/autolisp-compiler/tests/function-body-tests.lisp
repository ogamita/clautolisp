(in-package #:clautolisp.autolisp-compiler.tests)

(in-suite autolisp-compiler-suite)

;;;; Compiling the BODY of an AutoLISP function.
;;;;
;;;; The contract is the same one as everywhere else in this suite —
;;;; compiled and interpreted evaluation agree — but the comparison has to
;;;; be set up differently. A compiled body is woven LAZILY by the
;;;; evaluator, so there is no "compile this and call it" to write: what
;;;; the tests below do is run the SAME AutoLISP program twice, once with
;;;; compilation off and once with the threshold at 1 (compile on first
;;;; call), and require the two answers to be equal.
;;;;
;;;; That shape is worth more than it looks. It is exactly the switch a
;;;; user would flip when they suspect the compiler of changing an answer,
;;;; so the test exercises the supported way of telling the two apart.

(defun %run-interpreted (text)
  "Evaluate TEXT with compilation switched off."
  (let ((*autolisp-compilation-enabled* nil)
        (context (%fresh-context)))
    (autolisp-eval (%read-one text) context)))

(defun %run-with-compiled-bodies (text)
  "Evaluate TEXT with every function body compiled on its first call."
  (let ((*autolisp-compilation-enabled* t)
        (*autolisp-compilation-threshold* 1)
        (context (%fresh-context)))
    (autolisp-eval (%read-one text) context)))

(defparameter *function-body-corpus*
  '(;; the plain case: a body of operators the transpiler open-codes
    "(progn (defun sq (x) (* x x)) (sq 9))"
    ;; several body forms — the value is the LAST one
    "(progn (defun f (x) (setq y (+ x 1)) (* y 2)) (f 4))"
    ;; parameters shadow, and the shadowing must survive compilation:
    ;; the body's X is the parameter, not the global
    "(progn (setq x 100) (defun f (x) (* x 2)) (list (f 3) x))"
    ;; recursion — the compiled body calls the function it is the body of
    "(progn (defun fact (n) (if (< n 2) 1 (* n (fact (- n 1))))) (fact 8))"
    "(progn (defun fib (n) (if (< n 2) n (+ (fib (- n 1)) (fib (- n 2))))) (fib 12))"
    ;; a loop inside a compiled body
    "(progn (defun sum-to (n) (setq i 0) (setq s 0) (while (< i n) (setq s (+ s i)) (setq i (+ i 1))) s) (sum-to 50))"
    ;; a body containing an operator the transpiler does NOT handle: it
    ;; falls back inside the compiled body, which must still be right
    "(progn (defun f (l) (foreach e l (setq last e)) last) (f '(1 2 3)))"
    ;; a body whose local variables are AutoLISP locals (the / convention)
    "(progn (setq g 9) (defun f (x / g) (setq g (* x 2)) g) (list (f 5) g))"
    ;; functions calling functions, both compiled
    "(progn (defun a (x) (* x 2)) (defun b (x) (+ (a x) (a x))) (b 7))"
    ;; strings and lists through a compiled body
    "(progn (defun j (a b) (strcat a b)) (j \"left\" \"right\"))"
    "(progn (defun rev2 (l) (list (car (cdr l)) (car l))) (rev2 '(1 2)))")
  "AutoLISP programs whose functions must give the same answers with their
bodies compiled as with them interpreted.")

(test compiled-function-bodies-agree-with-interpreted-ones
  "The contract, applied to function bodies: the same program run with
compilation off and with every body compiled must give the same value."
  (dolist (text *function-body-corpus*)
    (let ((interpreted (%run-interpreted text))
          (compiled (%run-with-compiled-bodies text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled bodies ~S" text interpreted compiled))))

(test a-body-is-compiled-only-once-it-is-hot
  "Compiling costs more than interpreting a short body once, so a function
called a few times must NOT have been compiled. Pinned because the whole
justification for having this on by default is that loading a file does
not pay for it."
  (let ((*autolisp-compilation-enabled* t)
        (*autolisp-compilation-threshold* 5)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (* x x))") context)
    (let ((usubr (resolve-autolisp-function-designator (%read-one "f") context)))
      (is (not (autolisp-function-compiled-p usubr))
          "a function was compiled before it was ever called")
      ;; below the threshold: still interpreted
      (dotimes (i 3) (autolisp-eval (%read-one "(f 2)") context))
      (is (not (autolisp-function-compiled-p usubr))
          "a function called 3 times was compiled at a threshold of 5")
      ;; crossing it: compiled, and still giving the same answer
      (dotimes (i 5) (autolisp-eval (%read-one "(f 2)") context))
      (is (autolisp-function-compiled-p usubr)
          "a function called 8 times was not compiled at a threshold of 5")
      (is (eql 4 (autolisp-eval (%read-one "(f 2)") context))))))

(test compilation-can-be-switched-off-entirely
  "With *AUTOLISP-COMPILATION-ENABLED* nil nothing is compiled however hot
it gets. This is the switch to reach for when compiled and interpreted
results are suspected of disagreeing, so it has to actually work."
  (let ((*autolisp-compilation-enabled* nil)
        (*autolisp-compilation-threshold* 1)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (* x x))") context)
    (dotimes (i 20) (autolisp-eval (%read-one "(f 3)") context))
    (let ((usubr (resolve-autolisp-function-designator (%read-one "f") context)))
      (is (not (autolisp-function-compiled-p usubr))
          "a body was compiled while compilation was switched off")
      (is (eql 9 (autolisp-eval (%read-one "(f 3)") context))))))

(test a-compiled-body-keeps-the-interpreters-error-behaviour
  "An error raised inside a compiled body is the interpreter's error: the
compiled fork calls the same builtins through the same entry point, so
what used to signal still signals rather than returning a wrong value."
  (let ((*autolisp-compilation-enabled* t)
        (*autolisp-compilation-threshold* 1)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (nosuchfunction x))") context)
    ;; NOTE the shape: the outcome is captured in a variable and asserted
    ;; afterwards. FiveAM's IS requires a LIST as its argument, so (is t)
    ;; and (is nil) are compile-time errors -- ones SBCL defers until the
    ;; form actually runs, which means a landmine that only goes off on
    ;; the branch you were least expecting to take.
    (let ((signalled nil))
      (handler-case (autolisp-eval (%read-one "(f 1)") context)
        (autolisp-runtime-error () (setf signalled t)))
      (is (eq t signalled)
          "a compiled body swallowed an undefined function"))))

(test a-body-that-cannot-be-compiled-still-runs
  "A compilation that fails must leave the function working, through its
plain body, and must not be retried on every later call — which is what
the :FAILED marker in the slot is for. Simulated by making the hook
signal, since a body the transpiler cannot handle does not exist: unknown
operators fall back rather than fail."
  (let ((*autolisp-compilation-enabled* t)
        (*autolisp-compilation-threshold* 1)
        (attempts 0)
        (context (%fresh-context)))
    (let ((*compile-usubr-hook*
            (lambda (usubr) (declare (ignore usubr))
              (incf attempts)
              (error "compilation refused, for the test"))))
      (autolisp-eval (%read-one "(defun f (x) (* x 3))") context)
      (dotimes (i 10)
        (is (eql 12 (autolisp-eval (%read-one "(f 4)") context)))))
    (is (= 1 attempts)
        "a failing compilation was retried ~D times instead of once" attempts)))

;;;; SPEED, end to end.
;;;;
;;;; The gates themselves are tested in the builtins suite, where
;;;; CLAL-OPTIMIZE lives. What is tested here is that they reach the
;;;; compiler: a level is only meaningful if a function's actual fork
;;;; changes because of it.

(test speed-zero-turns-the-compiler-off
  "SPEED 0 means interpreted. The switch has to be observable in the
function object, not merely in the variable that was set."
  (let ((*autolisp-speed-level* 0)
        (*autolisp-compilation-threshold* 1)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (* x x))") context)
    (dotimes (i 5) (autolisp-eval (%read-one "(f 2)") context))
    (let ((usubr (resolve-autolisp-function-designator (%read-one "f") context)))
      (is (not (autolisp-function-compiled-p usubr))
          "a function compiled at SPEED 0"))))

(test speed-three-compiles-at-definition-not-once-hot
  "The difference between SPEED 2 and SPEED 3 is WHEN. At 2 a function is
compiled on the call that makes it hot; at 3 it is compiled by DEFUN, so
that a whole file can eventually be compiled in one unit and optimized
across function boundaries. Pinned at the observable end: after DEFUN and
before any call, is there a compiled body?"
  (let ((*autolisp-speed-level* 2)
        (*autolisp-compilation-threshold* 16)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (* x x))") context)
    (is (not (autolisp-function-compiled-p
              (resolve-autolisp-function-designator (%read-one "f") context)))
        "SPEED 2 compiled a function that had never been called"))
  (let ((*autolisp-speed-level* 3)
        (*autolisp-compilation-threshold* 16)
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun g (x) (* x x))") context)
    (is (autolisp-function-compiled-p
         (resolve-autolisp-function-designator (%read-one "g") context))
        "SPEED 3 did not compile at definition")))

(test eager-compilation-of-an-uncompilable-body-still-defines-it
  "SPEED 3 must not become a correctness setting. A body the compiler
chokes on has to be DEFINED anyway and run interpreted -- a DEFUN that
signalled because compiling failed would turn an optimization request
into a load failure."
  (let ((*autolisp-speed-level* 3)
        (*autolisp-compilation-threshold* 1)
        (*compile-usubr-hook* (lambda (usubr)
                                (declare (ignore usubr))
                                (error "compiler exploded")))
        (context (%fresh-context)))
    (autolisp-eval (%read-one "(defun f (x) (* x x))") context)
    (is (eql 9 (autolisp-eval (%read-one "(f 3)") context))
        "a function whose eager compilation failed did not run interpreted")))

(test a-self-recursive-function-can-be-compiled-eagerly
  "Eager compilation happens inside DEFUN, so the order matters: the
function has to be bound to its name BEFORE it is compiled, or a
recursive call in its own body would compile against an undefined name."
  (let ((*autolisp-speed-level* 3)
        (*autolisp-compilation-threshold* 1)
        (context (%fresh-context)))
    (autolisp-eval
     (%read-one "(defun fact (n) (if (< n 2) 1 (* n (fact (- n 1)))))")
     context)
    (is (eql 120 (autolisp-eval (%read-one "(fact 5)") context)))))

;;;; REPEAT and FOREACH, open-coded (2.0.21).
;;;;
;;;; Until this, a compiled function containing either ran the WHOLE loop
;;;; through the interpreter -- a fallback hands over the entire subform,
;;;; so the body went with it. They are the two commonest loops in
;;;; AutoLISP, which made this the largest hole left in what "compiled"
;;;; meant.
;;;;
;;;; What the transpiler emits is the SHAPE. Every decision -- the count
;;;; check, the sequence check, and FOREACH's rule for giving its variable
;;;; a value -- is a call to the runtime function the interpreter calls,
;;;; so there is nothing here that can disagree with the interpreter. The
;;;; tests below are about the parts a shape can still get wrong: what the
;;;; loop RETURNS, and what it does to the surrounding bindings.

(defparameter *loop-corpus*
  '(;; REPEAT yields NIL, not the last body value -- the mistake a Lisp
    ;; reflex makes
    "(progn (defun f (/ a) (setq a 0) (list (repeat 3 (setq a (+ a 1))) a)) (f))"
    "(progn (defun f () (repeat 0 1)) (f))"
    "(progn (defun f () (repeat -5 1)) (f))"
    "(progn (defun f (/ a) (setq a 0) (repeat 4 (setq a (+ a 2))) a) (f))"
    "(progn (defun f () (repeat 2)) (f))"
    ;; a bad count is the interpreter's error, raised by the same check
    "(progn (defun f () (repeat \"x\" 1)) (vl-catch-all-error-message (vl-catch-all-apply (function f) nil)))"
    "(progn (defun f () (repeat nil 1)) (vl-catch-all-error-message (vl-catch-all-apply (function f) nil)))"
    ;; FOREACH yields the LAST BODY VALUE, and nil for an empty list
    "(progn (defun f (l) (foreach e l e)) (f '(1 2 3)))"
    "(progn (defun f (l) (foreach e l e)) (f nil))"
    "(progn (defun f (l / s) (setq s 0) (foreach e l (setq s (+ s e))) s) (f '(1 2 3 4)))"
    "(progn (defun f (l) (foreach e l)) (f '(1 2)))"
    ;; EMPTY LOOP BODIES. Not a degenerate case in AutoLISP -- draining a
    ;; list for its side effect is what `(while (setq i (cdr i)))\' is for
    ;; -- and the shape that was broken in compiled WHILE until 2.0.21
    ;; (issues/closed/compiled-loop-with-empty-body.issue).
    "(progn (defun drain (l / i) (setq i l) (while (setq i (cdr i))) i) (drain '(1 2 3)))"
    "(progn (defun f (/ i) (setq i 0) (while (< (setq i (+ i 1)) 4)) i) (f))"
    "(progn (defun f () (repeat 3)) (f))"
    "(progn (defun f (l) (foreach e l)) (f '(1 2 3)))"
    "(progn (defun f (l / acc) (setq acc nil) (foreach e l (setq acc (cons e acc))) acc) (f '(1 2 3)))"
    ;; nested loops, and a loop whose body contains the other loop
    "(progn (defun f (l / n) (setq n 0) (foreach e l (repeat e (setq n (+ n 1)))) n) (f '(1 2 3)))"
    "(progn (defun f (ll / n) (setq n 0) (foreach l ll (foreach e l (setq n (+ n e)))) n) (f '((1 2) (3))))"
    ;; a non-list is the interpreter's error, raised by the same check
    "(progn (defun f () (foreach e 5 e)) (vl-catch-all-error-message (vl-catch-all-apply (function f) nil)))"
    ;; the loop variable after the loop: FOREACH assigns when the name is
    ;; already bound anywhere in the chain, so a /-local survives with the
    ;; last element in it
    "(progn (defun f (l / e) (setq e 'before) (foreach e l nil) e) (f '(1 2 3)))"
    ;; ... and does NOT leak when the name was not bound before
    "(progn (setq g 'outer) (defun f (l) (foreach g l nil)) (list (f '(1 2)) g))")
  "Programs whose functions must give the same answers with their bodies
compiled as with them interpreted. Most are about what the loops RETURN
and what they leave behind, which is where a hand-written loop shape can
differ from the interpreter's even when every check is shared.")

(test compiled-loops-agree-with-interpreted-ones
  (dolist (text *loop-corpus*)
    (let ((interpreted (%run-interpreted text))
          (compiled (%run-with-compiled-bodies text)))
      (is (%same-value-p interpreted compiled)
          "~S: interpreted ~S, compiled bodies ~S" text interpreted compiled))))

(test a-compiled-foreach-really-compiles-its-body
  "The point of open-coding FOREACH: the BODY is compiled too. A fallback
hands the interpreter the whole subform, so before this the body of every
foreach in every compiled function was interpreted. Asserted through the
coverage report, which is the transpiler's own account of what it handed
back."
  (is (null (transpiler-coverage
             (%read-one "(foreach e l (setq a (+ a e)))")))
      "a foreach body was still handed to the interpreter")
  (is (null (transpiler-coverage
             (%read-one "(repeat n (setq a (+ a 1)))")))
      "a repeat body was still handed to the interpreter"))

(test a-compiled-repeat-yields-nil-not-its-body
  "REPEAT's value is NIL however many times it ran -- the one thing a
Lisp reflex writes wrongly, and invisible in any test that only checks
side effects."
  (is (null (%run-with-compiled-bodies
             "(progn (defun f (/ a) (setq a 0) (repeat 3 (setq a 1))) (f))")))
  (is (%same-value-p (%run-interpreted "(progn (defun f () (repeat 3 99)) (f))")
                     (%run-with-compiled-bodies "(progn (defun f () (repeat 3 99)) (f))"))))
