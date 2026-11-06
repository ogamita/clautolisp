;;;; Run the debugger's own test suites with every INSTRUMENTED function
;;;; body compiled, and report how many were.
;;;;
;;;; The companion of whole-suite-compiled.lisp, for the other transpiler
;;;; variant. Where that one asserts that compiling a body does not change
;;;; what a program computes, this one asserts that compiling an
;;;; INSTRUMENTED body does not change how a program DEBUGS: the debug
;;;; suites cover stepping, breakpoints, form-level jumps, snapshots and
;;;; error handling, and every one of them must still hold when the body
;;;; being stepped through is compiled code rather than interpreted forms.
;;;;
;;;; That is the whole safety argument for the instrumented variant. A
;;;; poll point that fired in a different order, a shadow stack left
;;;; unbalanced by a non-local exit, a jump that skipped the wrong form --
;;;; none of those would show up as a wrong ANSWER, which is all the
;;;; equivalence corpus can see. They show up as a debugger that behaves
;;;; differently on a hot function, which is exactly the bug a user would
;;;; never believe and never manage to reproduce.
;;;;
;;;; AS THERE, THE COUNT IS NOT DECORATION: with nothing compiled the
;;;; suites pass exactly as they do today, so a run that compiles nothing
;;;; exits non-zero instead of reporting success.
;;;;
;;;; Run it with: make test-debug-compiled

(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (find-symbol "QUICKLOAD" :ql) "fiveam" :silent t))
(require :asdf)
(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))

;; Both layers, in either order: the compiler installs the weaving hooks,
;; the debugger installs the poll protocol behind *COMPILED-POLL-HOOK*.
;; Neither system knows the other exists -- they meet in the runtime.
(asdf:load-system "clautolisp/autolisp-compiler")
(asdf:load-system "clautolisp/autolisp-debug")

(defparameter *instrumented-bodies-compiled* 0)

(let ((runtime (find-package "CLAUTOLISP.AUTOLISP-RUNTIME"))
      (compiler (find-package "CLAUTOLISP.AUTOLISP-COMPILER")))
  (let ((weave (symbol-function
                (find-symbol "COMPILE-INSTRUMENTED-USUBR" compiler))))
    (setf (symbol-value (find-symbol "*COMPILE-INSTRUMENTED-USUBR-HOOK*" runtime))
          (lambda (usubr)
            (incf *instrumented-bodies-compiled*)
            (funcall weave usubr))))
  (setf (symbol-value (find-symbol "*AUTOLISP-COMPILATION-ENABLED*" runtime)) t
        (symbol-value (find-symbol "*AUTOLISP-COMPILATION-THRESHOLD*" runtime)) 1))

(format t "~&;;; running the whole corpus with INSTRUMENTED bodies compiled ~
           (threshold 1)~%")
(finish-output)

(asdf:test-system "clautolisp")

(format t "~&;;; instrumented function bodies compiled during the run: ~D~%"
        *instrumented-bodies-compiled*)
(finish-output)
(when (zerop *instrumented-bodies-compiled*)
  (format *error-output*
          "~&;;; NO INSTRUMENTED BODY WAS COMPILED -- this run proves nothing ~
           about the~%;;; instrumented variant. Check that ~
           *COMPILE-INSTRUMENTED-USUBR-HOOK* is installed,~%;;; that the ~
           threshold is 1, and that the debug suites still instrument.~%")
  (uiop:quit 1))
