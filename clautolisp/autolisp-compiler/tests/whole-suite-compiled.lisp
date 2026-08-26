;;;; Run the ENTIRE clautolisp test corpus with every AutoLISP function
;;;; body compiled, and report how many bodies were actually compiled.
;;;;
;;;; This is the compiler's real equivalence test, and it is worth far
;;;; more than the corpus in equivalence-tests.lisp: that corpus contains
;;;; the cases I thought of, this one runs every AutoLISP program the
;;;; project's 31 suites exercise, through the compiler, and requires
;;;; every existing assertion to still hold. A transpiler bug that
;;;; changes an answer surfaces as a failure in whichever suite covered
;;;; that behaviour.
;;;;
;;;; THE COUNT AT THE END IS NOT DECORATION. A green run proves nothing
;;;; unless bodies were compiled: with the hook uninstalled or the
;;;; threshold unmet, everything would run interpreted and the suite
;;;; would pass exactly as it does today. So the count is printed, and a
;;;; run that compiles nothing exits non-zero rather than reporting
;;;; success -- the same failure mode as a test file that loads without
;;;; running, which is the worst kind because it looks like a pass.
;;;;
;;;; Run it with: make test-compiler-equivalence

(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (find-symbol "QUICKLOAD" :ql) "fiveam" :silent t))
(require :asdf)
(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))

;; Loading the compiler installs *COMPILE-USUBR-HOOK*; the threshold then
;; decides when a body is woven. 1 means "on first call", so the suite
;; compiles everything it calls at all.
(asdf:load-system "clautolisp/autolisp-compiler")

(defparameter *bodies-compiled* 0)

(let ((runtime (find-package "CLAUTOLISP.AUTOLISP-RUNTIME"))
      (compiler (find-package "CLAUTOLISP.AUTOLISP-COMPILER")))
  (let ((weave (symbol-function (find-symbol "COMPILE-USUBR" compiler))))
    (setf (symbol-value (find-symbol "*COMPILE-USUBR-HOOK*" runtime))
          (lambda (usubr) (incf *bodies-compiled*) (funcall weave usubr))))
  (setf (symbol-value (find-symbol "*AUTOLISP-COMPILATION-ENABLED*" runtime)) t
        (symbol-value (find-symbol "*AUTOLISP-COMPILATION-THRESHOLD*" runtime)) 1))

(format t "~&;;; running the whole corpus with compilation forced on ~
           (threshold 1)~%")
(finish-output)

(asdf:test-system "clautolisp")

(format t "~&;;; function bodies compiled during the run: ~D~%" *bodies-compiled*)
(finish-output)
(when (zerop *bodies-compiled*)
  (format *error-output*
          "~&;;; NOTHING WAS COMPILED -- this run proves nothing about the ~
           compiler.~%;;; Check that the hook is installed and the threshold ~
           is 1.~%")
  (uiop:quit 1))
