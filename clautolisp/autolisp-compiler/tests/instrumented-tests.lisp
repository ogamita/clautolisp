(in-package #:clautolisp.autolisp-compiler.tests)

(in-suite autolisp-compiler-suite)

;;;; THE INSTRUMENTED TRANSPILER VARIANT.
;;;;
;;;; pjb asked for two variants of the transpiler, instrumented and not.
;;;; They are not two compilers: they are the same TRANSPILE-FORM given
;;;; two different bodies. The non-instrumented variant compiles a
;;;; function's plain body; the instrumented one compiles the body the
;;;; DEBUGGER wove, whose every instrumentable form is wrapped in a
;;;; (%CLAL-POLL fid form-id INNER) node.
;;;;
;;;; That node is the whole difference, and the reason the second variant
;;;; needed anything at all. %CLAL-POLL is a registered special operator,
;;;; so before this the transpiler fell back on it -- and since the
;;;; OUTERMOST node wraps the entire body, "compiling" an instrumented
;;;; function produced one call to AUTOLISP-EVAL and gained nothing.
;;;;
;;;; What is being tested here is therefore two separate claims:
;;;;   1. the instrumented body actually COMPILES (it is not a fallback
;;;;      wearing a compiled body's clothes), and
;;;;   2. compiling it does not change what the program computes.
;;;; The claim that compiling it does not change how the program DEBUGS
;;;; is far larger, and is tested by running the entire debug corpus
;;;; against compiled instrumented bodies -- see debug-suite-compiled.lisp
;;;; and `make test-debug-compiled'. No corpus of hand-written cases here
;;;; would be worth as much as the stepping/breakpoint/jump suites the
;;;; debugger already has.

(defun %instrumented-context (source name)
  "Define SOURCE, instrument the function called NAME, return the context
and its usubr."
  (reset-function-id-registry)
  (clautolisp.source:clear-source-positions)
  (let ((context (%fresh-context)))
    (clautolisp.source:with-source-tracking ()
      (dolist (form (read-runtime-from-string source :source-name "test.lsp"))
        (autolisp-eval form context)))
    (let ((usubr (lookup-function (intern-autolisp-symbol name) context)))
      (instrument-usubr usubr)
      (values context usubr))))

(defparameter *instrumented-corpus*
  '(("(defun sq (x) (* x x))" "SQ" "(sq 9)")
    ("(defun fact (n) (if (< n 2) 1 (* n (fact (- n 1)))))" "FACT" "(fact 6)")
    ("(defun sum-to (n) (setq i 0) (setq s 0) (while (< i n) (setq s (+ s i)) (setq i (+ i 1))) s)"
     "SUM-TO" "(sum-to 20)")
    ("(defun pick (l) (cond ((null l) nil) (t (car l))))" "PICK" "(pick '(4 5))")
    ("(defun both (a b) (and (> a 0) (> b 0)))" "BOTH" "(both 1 2)"))
  "(DEFINITION FUNCTION-NAME CALL) triples whose function must give the
same answer with its instrumented body compiled as with it interpreted.")

(test a-compiled-instrumented-body-agrees-with-an-interpreted-one
  "The equivalence contract, applied to the instrumented variant: under a
debug session, a function must compute the same value whether the
instrumented body it runs is compiled or interpreted."
  (dolist (entry *instrumented-corpus*)
    (destructuring-bind (definition name call) entry
      (let ((interpreted
              (multiple-value-bind (context usubr)
                  (%instrumented-context definition name)
                (declare (ignore usubr))
                (let ((*autolisp-compilation-enabled* nil))
                  (call-with-debugging
                   (lambda () (autolisp-eval (%read-one call) context))))))
            (compiled
              (multiple-value-bind (context usubr)
                  (%instrumented-context definition name)
                (compile-instrumented-usubr usubr)
                (let ((*autolisp-compilation-enabled* t)
                      (*autolisp-compilation-threshold* 1))
                  (call-with-debugging
                   (lambda () (autolisp-eval (%read-one call) context)))))))
        (is (%same-value-p interpreted compiled)
            "~S: interpreted ~S, compiled ~S" call interpreted compiled)))))

(test an-instrumented-body-really-compiles-rather-than-falling-back
  "The claim this whole slice rests on, asserted rather than assumed.

Every case above would pass unchanged if COMPILE-INSTRUMENTED-USUBR
produced a single AUTOLISP-EVAL of the whole woven body -- that is what
it produced before %CLAL-POLL was open-coded, and it is CORRECT, merely
pointless. So: the transpiler must not report %CLAL-POLL among the
operators it fell back on."
  (multiple-value-bind (context usubr)
      (%instrumented-context "(defun sq (x) (* x x))" "SQ")
    (declare (ignore context))
    (let ((fallbacks (transpiler-coverage
                      (first (autolisp-usubr-instrumented-body usubr)))))
      (is (null (member +poll-operator-name+ fallbacks :test #'string=))
          "the transpiler fell back on the poll node; the instrumented ~
           variant compiles to nothing but an interpreter call. Fell back ~
           on: ~S" fallbacks))))

(test compiling-the-instrumented-fork-leaves-the-plain-fork-alone
  "The two forks are separate slots, and must stay so: a function compiled
for a debug session must not be handed that body once the session ends,
or the debugger's poll points would keep firing on undebugged code."
  (multiple-value-bind (context usubr)
      (%instrumented-context "(defun sq (x) (* x x))" "SQ")
    (declare (ignore context))
    (compile-instrumented-usubr usubr)
    (is (autolisp-function-instrumented-compiled-p usubr))
    (is (not (autolisp-function-compiled-p usubr))
        "compiling the instrumented body also filled the plain fork")))

(test a-malformed-poll-node-is-left-to-the-interpreter
  "FID and FORM-ID are host integers written by the instrumenter. Anything
else is not a woven node, and the transpiler must not translate it as one
-- inventing a poll point around a form the debugger never wrapped would
corrupt the shadow stack, which unbalances on the way out rather than
where the mistake was made."
  (let ((form (%read-one "(%clal-poll \"not-a-fid\" 2 3)")))
    (is (not (null (transpiler-coverage form)))
        "a malformed poll node was translated as a poll point")))

(test compiled-poll-points-run-the-debuggers-protocol-not-a-copy
  "CALL-WITH-COMPILED-POLL-POINT must DELEGATE. With no hook installed it
runs the thunk and nothing else; with one installed, that hook is what
runs. The failure this pins is a compiler that grew its own quiet
reimplementation of the poll protocol, which would show up as a debugger
that steps differently on functions that happen to be hot."
  (let ((calls '()))
    (let ((*compiled-poll-hook* nil))
      (is (eql 7 (call-with-compiled-poll-point 1 2 nil (lambda () 7)))))
    (let ((*compiled-poll-hook*
            (lambda (fid form-id context thunk)
              (declare (ignore context))
              (push (list fid form-id) calls)
              (funcall thunk))))
      (is (eql 7 (call-with-compiled-poll-point 3 4 nil (lambda () 7)))))
    (is (equal '((3 4)) calls))))

(test the-debugger-no-longer-switches-the-compiler-off
  "Before this slice the runtime asked for a compiled fork only when
*DEBUGGING* was NIL, so attaching a debugger put every function back in
the interpreter. Pinned as behaviour, not as an implementation detail:
after enough calls under a debug session, the function is running
compiled code."
  (multiple-value-bind (context usubr)
      (%instrumented-context "(defun sq (x) (* x x))" "SQ")
    (let ((*autolisp-compilation-enabled* t)
          (*autolisp-compilation-threshold* 1)
          (*compile-instrumented-usubr-hook* #'compile-instrumented-usubr))
      (call-with-debugging
       (lambda () (autolisp-eval (%read-one "(sq 3)") context)))
      (is (autolisp-function-instrumented-compiled-p usubr)
          "a function called under a debug session never compiled"))))
