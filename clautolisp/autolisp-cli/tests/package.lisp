(defpackage #:clautolisp.autolisp-cli.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:signals
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.autolisp-cli
                ;; value parsers (pure functions)
                #:parse-host
                #:parse-dialect
                #:parse-timeout
                #:cli-usage-error)
  (:export #:autolisp-cli-suite
           #:run-all-tests))

;;; The registry sandbox: a suite run outside the Makefiles (which set it)
;;; must not write the developer's real registry either -- SETVAR of LISPSYS
;;; persists (lispsys persistence, 2026-10-04).
(let ((value (uiop:getenv "CLAUTOLISP_REGISTRY_FILE")))
  (unless (and value (plusp (length value)))
    (setf (uiop:getenv "CLAUTOLISP_REGISTRY_FILE")
          (namestring (merge-pathnames
                       (format nil "clautolisp-test-registry-~36R.sexp"
                               (random (expt 36 8) (make-random-state t)))
                       (uiop:temporary-directory))))))
