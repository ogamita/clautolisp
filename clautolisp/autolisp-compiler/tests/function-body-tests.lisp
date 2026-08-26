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
