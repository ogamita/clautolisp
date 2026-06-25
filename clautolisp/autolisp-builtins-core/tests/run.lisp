(in-package #:clautolisp.autolisp-builtins-core.tests)

(defun run-all-tests ()
  ;; The SECURELOAD warn path fires whenever a test loads an untrusted
  ;; file (most temp-file load tests). Silence it suite-wide so the
  ;; output stays clean; the secureload tests that assert on the warn
  ;; rebind it locally.
  (let ((clautolisp.autolisp-runtime:*secureload-diagnostic-suppress-p* t))
    (let ((result (run 'autolisp-builtins-core-suite)))
      (explain! result)
      (unless (results-status result)
        (error "autolisp-builtins-core tests failed."))
      t)))
