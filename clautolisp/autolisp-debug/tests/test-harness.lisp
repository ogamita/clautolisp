;;;; clautolisp/autolisp-debug/tests/test-harness.lisp
;;;;
;;;; Shared fixtures. Tests use only user-defined AutoLISP functions,
;;;; special forms, and literals — never builtins — so the debug test
;;;; system needs no builtins-core / host dependency. Every fixture
;;;; resets the function-id registry and source table first.

(in-package #:clautolisp.debug.tests)

(defun rt-sym (name)
  (clautolisp.autolisp-runtime:intern-autolisp-symbol name))

(defun fresh-context ()
  (clautolisp.debug:reset-function-id-registry)
  (clautolisp.debug:clear-virtual-breakpoints)
  (clautolisp.source:clear-source-positions)
  (clautolisp.autolisp-runtime:make-default-runtime-context))

(defun load-tracked (context source &key (source-name "test.lsp"))
  "Tracked-load SOURCE into CONTEXT (defining its functions) so their
body conses carry source positions."
  (clautolisp.source:with-source-tracking ()
    (dolist (form (clautolisp.autolisp-runtime:read-runtime-from-string
                   source :source-name source-name))
      (clautolisp.autolisp-runtime:autolisp-eval form context))))

(defun usubr-named (context name)
  (clautolisp.autolisp-runtime:lookup-function (rt-sym name) context))

(defun define-and-instrument (context source &rest names)
  "Tracked-load SOURCE then instrument each named function; return a list
of the function-debug-metadata records in NAMES order."
  (load-tracked context source)
  (mapcar (lambda (name)
            (clautolisp.debug:instrument-usubr (usubr-named context name)))
          names))

(defun call-form (name &rest args)
  (cons (rt-sym name) args))

(defun eval-call (context name &rest args)
  (clautolisp.autolisp-runtime:autolisp-eval (apply #'call-form name args) context))
