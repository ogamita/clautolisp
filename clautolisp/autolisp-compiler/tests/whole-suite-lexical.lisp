;;;; The whole test corpus with LEXICAL forks (lexical-locals-escape-analysis).
;;;;
;;;;   make test-lexical-locals
;;;;
;;;; Every DEFUN the corpus evaluates is compiled eagerly at (SPEED 3) (DEBUG 0)
;;;; and given a lexical fork -- FORCED even where some site must materialise
;;;; the locals, which is the path that keeps SET, BOUNDP, EVAL, user callees
;;;; and redefined builtins seeing them. The corpus's own assertions are the
;;;; test: none of them knows it is running against lexical forks, so any
;;;; answer the fork changes shows up as a failure somewhere.
;;;;
;;;; The QUALITIES are set, not just the runtime flags: every fixture
;;;; re-installs the builtins, which re-applies *CLAL-OPTIMIZATION*, and would
;;;; switch the flags straight back off.

(let ((ql (merge-pathnames #P"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(when (find-package :ql)
  (funcall (find-symbol "QUICKLOAD" :ql) "fiveam" :silent t))
(require :asdf)
(asdf:load-asd (merge-pathnames "clautolisp.asd" (uiop:getcwd)))
(asdf:load-system "clautolisp/autolisp-compiler")
(asdf:load-system "clautolisp/autolisp-builtins-core")

(defparameter *lexical-forks-built* 0)
(let* ((compiler (find-package "CLAUTOLISP.AUTOLISP-COMPILER"))
       (builtins (find-package "CLAUTOLISP.AUTOLISP-BUILTINS-CORE"))
       (build (find-symbol "COMPILE-LEXICAL-USUBR" compiler))
       (original (symbol-function build))
       (optimization (symbol-value (find-symbol "*CLAL-OPTIMIZATION*" builtins))))
  (setf (symbol-function build)
        (lambda (usubr)
          (let ((fork (funcall original usubr)))
            (when (functionp fork) (incf *lexical-forks-built*))
            fork)))
  (setf (symbol-value (find-symbol "*LEXICAL-BUILD-EVEN-WHEN-UNSAFE*" compiler)) t)
  (setf (cdr (assoc :speed optimization)) 3
        (cdr (assoc :debug optimization)) 0)
  (funcall (find-symbol "APPLY-CLAL-OPTIMIZATION" builtins)))

(format t "~&;;; running the whole corpus with LEXICAL forks (SPEED 3, DEBUG 0, forced)~%")
(finish-output)
(asdf:test-system "clautolisp")
(format t "~&;;; lexical forks built during the run: ~D~%" *lexical-forks-built*)
(finish-output)
(when (zerop *lexical-forks-built*)
  (format *error-output*
          "~&;;; NO LEXICAL FORK WAS BUILT -- this run proves nothing about them.~%")
  (uiop:quit 1))
