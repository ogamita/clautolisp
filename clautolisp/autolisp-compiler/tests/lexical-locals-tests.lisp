(in-package #:clautolisp.autolisp-compiler.tests)

(in-suite autolisp-compiler-suite)

;;;; The LEXICAL fork (lexical-locals-escape-analysis): at (SPEED 3) (DEBUG 0)
;;;; a function's formals and /-locals become Common Lisp variables and no
;;;; dynamic frame is pushed per call. The contract is the suite's: the program
;;;; computes the same thing. What these tests add is the evidence that the
;;;; ESCAPES -- everything that can see a local by name -- still see it.

(defmacro %with-lexical-forks ((context &key force) &body body)
  "Run BODY with a fresh CONTEXT in which every DEFUN is compiled eagerly and
given a lexical fork when eligible (FORCE: even when some site materialises).
The flags are bound AFTER the context is made: INSTALL-CORE-BUILTINS re-applies
the optimization qualities and would reset them."
  `(let ((,context (%fresh-context)))
     (let ((*autolisp-compilation-enabled* t)
           (clautolisp.autolisp-runtime:*autolisp-speed-level* 3)
           (clautolisp.autolisp-runtime:*autolisp-lexical-locals-enabled* t)
           (clautolisp.autolisp-compiler::*lexical-build-even-when-unsafe* ,force))
       ,@body)))

(defun %eval-text (text context)
  (autolisp-eval (%read-one text) context))

(defun %lexical-p (name context)
  (clautolisp.autolisp-compiler:autolisp-function-lexical-p
   (resolve-autolisp-function-designator (%read-one name) context)))

(defun %run-lexical (text &key force)
  (%with-lexical-forks (context :force force)
    (%eval-text text context)))

(defparameter *lexical-corpus*
  '(;; leaf arithmetic over formals and /-locals
    "(progn (defun sq (x) (* x x)) (sq 9))"
    "(progn (setq g 9) (defun f (x / g) (setq g (* x 2)) g) (list (f 5) g))"
    "(progn (setq x 100) (defun f (x) (* x 2)) (list (f 3) x))"
    "(progn (defun sum-to (n / i s) (setq i 0 s 0) (while (< i n) (setq s (+ s i) i (1+ i))) s) (sum-to 50))"
    "(progn (defun j (a b) (strcat a b)) (j \"left\" \"right\"))"
    "(progn (defun rev2 (l) (list (cadr l) (car l))) (rev2 '(1 2)))"
    "(progn (defun unused (a / b c) a) (unused 7))"
    ;; a callee that reads the caller's local BY DYNAMIC SCOPE
    "(progn (defun peek () y) (defun f (y) (peek)) (f 7))"
    ;; ... and one that WRITES it
    "(progn (defun poke () (setq y 42)) (defun f (y) (poke) y) (f 7))"
    ;; SET / BOUNDP / EVAL naming a local
    "(progn (defun f (x) (set 'x 5) x) (f 1))"
    "(progn (defun f (/ z) (boundp 'z)) (f))"
    "(progn (defun f (x) (eval 'x)) (f 3))"
    ;; arguments evaluated before a materialising call sees the locals
    "(progn (defun peek () y) (defun f (y) (list (peek) (setq y 2) (peek))) (f 1))"
    ;; recursion through a user function
    "(progn (defun fact (n) (if (< n 2) 1 (* n (fact (- n 1))))) (fact 8))")
  "Programs whose value must not change when their functions get lexical forks.")

(test lexical-forks-agree-with-interpreted-evaluation
  "Each program, run with every eligible function given a lexical fork -- and
again with forks forced even where a site must materialise the locals, which is
what exercises the escapes -- gives the interpreted answer."
  (dolist (text *lexical-corpus*)
    (let ((expected (%interpreted text)))
      (is (%same-value-p expected (%run-lexical text))
          "~A: lexical ~S, interpreted ~S" text (%run-lexical text) expected)
      (is (%same-value-p expected (%run-lexical text :force t))
          "~A (forced): lexical ~S, interpreted ~S"
          text (%run-lexical text :force t) expected))))

(test lexical-forks-are-built-where-they-pay-and-only-there
  "Leaf functions calling audited builtins get one; a function whose call would
materialise every time does not (by default); a local in operator position,
or rebound by FOREACH, refuses it outright; nothing below (SPEED 3) (DEBUG 0)."
  (%with-lexical-forks (context)
    (%eval-text "(defun sq (x / y) (setq y (* x x)) y)" context)
    (is (%lexical-p "sq" context))
    (%eval-text "(defun peek () 1)" context)
    (%eval-text "(defun calls-user (x) (peek))" context)
    (is (not (%lexical-p "calls-user" context)))
    (%eval-text "(defun op-local (g) (g 1))" context)
    (is (not (%lexical-p "op-local" context)))
    (%eval-text "(defun rebinds (l / e) (foreach e l (setq s e)))" context)
    (is (not (%lexical-p "rebinds" context))))
  (%with-lexical-forks (context :force t)
    ;; forced: still refused, since those cannot be materialised
    (%eval-text "(defun op-local (g) (g 1))" context)
    (is (not (%lexical-p "op-local" context))))
  (let ((context (%fresh-context)))
    (let ((*autolisp-compilation-enabled* t)
          (clautolisp.autolisp-runtime:*autolisp-speed-level* 3)
          (clautolisp.autolisp-runtime:*autolisp-lexical-locals-enabled* nil))
      (%eval-text "(defun sq (x) (* x x))" context)
      (is (not (%lexical-p "sq" context))))))

(test a-builtin-redefined-after-the-fork-was-built-still-sees-the-locals
  "The guard is at RUN TIME. F is built calling `+', which is audited safe;
then `+' is redefined as a user function that reads F's local Y by dynamic
scope. The fork must notice at the call and materialise Y, not return a
stale or unbound answer."
  (%with-lexical-forks (context)
    (%eval-text "(defun f (y) (+ y 1))" context)
    (is (%lexical-p "f" context))
    (is (eql 11 (%eval-text "(f 10)" context)))
    (%eval-text "(defun + (a b) (list 'saw y))" context)
    (is (%same-value-p (%read-one "(saw 10)") (%eval-text "(f 10)" context))
        "the redefined + did not see the local: ~S" (%eval-text "(f 10)" context))))

(test a-lexical-fork-refuses-the-same-calls-in-the-same-words
  "Arity is checked by the fork itself, since no frame is bound -- with the
rule and message BIND-USUBR-FRAME uses."
  (flet ((message (text lexical)
           (handler-case
               (progn (if lexical
                          (%run-lexical text)
                          (%interpreted text))
                      nil)
             (autolisp-runtime-error (c) (clautolisp.autolisp-runtime:autolisp-runtime-error-message c)))))
    (let ((text "(progn (defun f (a b) (+ a b)) (f 1))"))
      (is (equal (message text nil) (message text t)))
      (is (search "expects 2 arguments, got 1" (message text t))))))

(test the-lexical-fork-never-runs-under-a-debug-session
  "The debugger reads and writes frame bindings at a stop; a lexical fork has
none to show it. So a debug session runs the other bodies."
  (%with-lexical-forks (context)
    (%eval-text "(defun sq (x) (* x x))" context)
    (let ((usubr (resolve-autolisp-function-designator (%read-one "sq") context)))
      (is (%lexical-p "sq" context))
      ;; poison the fork: if the dispatch took it under *DEBUGGING*, this
      ;; would signal
      (setf (clautolisp.autolisp-runtime:autolisp-usubr-lexical-body usubr)
            (lambda (context arguments)
              (declare (ignore context arguments))
              (error "the lexical fork ran under a debug session")))
      (let ((clautolisp.autolisp-runtime:*debugging* t))
        (is (eql 9 (%eval-text "(sq 3)" context)))))))
