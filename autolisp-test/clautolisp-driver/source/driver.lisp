(in-package #:autolisp-test.clautolisp-driver)

;;;; clautolisp-side driver for the autolisp-test conformance suite.
;;;;
;;;; The harness itself is pure AutoLISP. This file is a thin Common
;;;; Lisp wrapper that:
;;;;   - installs the clautolisp core builtins into a fresh runtime
;;;;     session,
;;;;   - exposes a marker variable (*CLAUTOLISP-VERSION*) so the
;;;;     harness's platform-detect step can identify the implementation,
;;;;   - loads autolisp-test/harness/run.lsp,
;;;;   - calls (autolisp-test-run-all) inside that session,
;;;;   - and converts any unexpected error escape into a non-zero exit
;;;;     code rather than letting the host Lisp drop into the debugger.
;;;;
;;;; A run that produces FAIL test results is normal: the harness
;;;; reports them and continues. The top-level handler here only
;;;; engages when an error escapes both the AutoLISP-level catch-all
;;;; AND the AutoLISP runtime's own error handler -- i.e. when
;;;; something is wrong in the harness itself or the CL bridge.
;;;;
;;;; Pass :debug t to bypass this guard (and the harness-level
;;;; *autolisp-test-debug-p* one) for interactive investigation.

(defun setup-clautolisp-marker (context &key (debug-p nil))
  "Bind a marker variable so the harness can detect that it is running
inside clautolisp, and propagate DEBUG-P into the AutoLISP-side
*autolisp-test-debug-p* control variable."
  (declare (ignore context))
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (let* ((version-symbol
          (clautolisp.autolisp-runtime:intern-autolisp-symbol
           "*CLAUTOLISP-VERSION*"))
         (version (clautolisp.autolisp-runtime:make-autolisp-string
                   "0.x"))
         (debug-symbol
          (clautolisp.autolisp-runtime:intern-autolisp-symbol
           "*AUTOLISP-TEST-DEBUG-P*"))
         (debug-value
          (if debug-p
              (clautolisp.autolisp-runtime:intern-autolisp-symbol "T")
              nil)))
    (clautolisp.autolisp-runtime:set-autolisp-symbol-value
     version-symbol version)
    (clautolisp.autolisp-runtime:set-autolisp-symbol-value
     debug-symbol debug-value)))

(defun autolisp-test-root-pathname ()
  "Return the root pathname of the autolisp-test subproject. Uses
ASDF's system-source-directory rather than *load-pathname* so the
function works correctly when called at runtime from the REPL or
from a CI driver after the ASDF compilation phase has completed."
  (asdf:system-source-directory "autolisp-test"))

(defun %invoke-harness (dialect debug-p)
  (let* ((root (namestring (autolisp-test-root-pathname)))
         (root-form (format nil "(setq *autolisp-test-root* ~S)" root))
         (load-form (format nil "(load ~S)"
                            (concatenate 'string root "harness/run.lsp")))
         (run-form  "(autolisp-test-run-all)")
         (script (concatenate 'string root-form " " load-form " " run-form))
         (setup-fn (lambda (context)
                     (setup-clautolisp-marker context :debug-p debug-p))))
    (clautolisp.autolisp-runtime:run-autolisp-string
     script
     :dialect dialect
     :setup-fn setup-fn)))

(defun run-autolisp-test-suite (&key (dialect nil) (debug nil))
  "Invoke the AutoLISP harness inside a fresh clautolisp runtime
session. DIALECT defaults to the strict dialect descriptor.

When DEBUG is nil (the default), every error that escapes the
AutoLISP harness is intercepted and reported on *error-output*; the
function then returns NIL. This guarantees that a run never drops
into the SBCL/CCL debugger because of a bug discovered while a tested
function was being evaluated, regardless of how that bug surfaces.

When DEBUG is non-nil, both this guard AND the harness-side
*autolisp-test-debug-p* are enabled, so any unexpected error trips
the host debugger. Use this only when interactively investigating
a single test or harness change.

The harness writes a self-describing s-expression report under
autolisp-test/results/clautolisp/.../report.sexp."
  (cond
    (debug
     (%invoke-harness dialect t))
    (t
     (handler-case
         (%invoke-harness dialect nil)
       (error (condition)
         (format *error-output*
                 "~&[autolisp-test] internal-harness-error escaped: ~A~%"
                 condition)
         (format *error-output*
                 "[autolisp-test] re-run with :debug t for a backtrace.~%")
         nil)))))
