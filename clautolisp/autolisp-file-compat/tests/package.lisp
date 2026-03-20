(defpackage #:clautolisp.autolisp-file-compat.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.autolisp-file-compat
                #:capture-file-artifact
                #:compare-bytes
                #:compare-lines
                #:compare-text
                #:emit-report
                #:file-compat-artifact-lines
                #:file-compat-artifact-text
                #:file-compat-check-passed-p
                #:file-compat-report-checks
                #:file-compat-report-runner
                #:load-scenario-file
                #:make-file-compat-scenario
                #:normalize-newlines
                #:read-file-bytes
                #:report->plist
                #:run-scenario
                #:write-file-text)
  (:export #:autolisp-file-compat-suite
           #:run-all-tests))
