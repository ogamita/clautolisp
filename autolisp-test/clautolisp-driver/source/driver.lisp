(in-package #:autolisp-test.clautolisp-driver)

;;;; clautolisp-side driver for the autolisp-test conformance suite.
;;;;
;;;; The harness itself is pure AutoLISP. This file is a thin Common
;;;; Lisp wrapper that:
;;;;   - installs the clautolisp core builtins into a fresh runtime
;;;;     session,
;;;;   - exposes a marker variable (*CLAUTOLISP-VERSION*) so the
;;;;     harness's platform-detect step can identify the implementation,
;;;;   - loads autolisp-test/harness/run.lsp, and
;;;;   - calls (autolisp-test-run-all) inside that session.
;;;;
;;;; Returns the path to the generated report so the CI job can pick
;;;; it up.

(defun setup-clautolisp-marker (context)
  "Bind a marker variable so the harness can detect that it is running
inside clautolisp."
  (declare (ignore context))
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  ;; Bind the marker as an AutoLISP-visible value so platform-detect
  ;; can find it via (boundp '*clautolisp-version*).
  (let* ((symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol
                  "*CLAUTOLISP-VERSION*"))
         (version (clautolisp.autolisp-runtime:make-autolisp-string
                   "0.x")))
    (clautolisp.autolisp-runtime:set-autolisp-symbol-value
     symbol version)))

(defun autolisp-test-root-pathname ()
  "Return the root pathname of the autolisp-test subproject. Uses
ASDF's system-source-directory rather than *load-pathname* so the
function works correctly when called at runtime from the REPL or
from a CI driver after the ASDF compilation phase has completed."
  (asdf:system-source-directory "autolisp-test"))

(defun run-autolisp-test-suite (&key (dialect nil))
  "Invoke the AutoLISP harness inside a fresh clautolisp runtime
session. DIALECT defaults to the strict dialect descriptor.

The harness writes a self-describing s-expression report under
autolisp-test/results/clautolisp/.../report.sexp."
  (let* ((root (namestring (autolisp-test-root-pathname)))
         (root-form (format nil "(setq *autolisp-test-root* ~S)" root))
         (load-form (format nil "(load ~S)"
                            (concatenate 'string root "harness/run.lsp")))
         (run-form  "(autolisp-test-run-all)")
         (script (concatenate 'string root-form " " load-form " " run-form)))
    (clautolisp.autolisp-runtime:run-autolisp-string
     script
     :dialect dialect
     :setup-fn #'setup-clautolisp-marker)))
