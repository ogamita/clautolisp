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
                #:collect-scenario-file-paths
                #:compare-bytes
                #:compare-lines
                #:compare-text
                #:emit-report
                #:file-compat-artifact-lines
                #:file-compat-artifact-text
                #:file-compat-check-passed-p
                #:file-compat-report-checks
                #:file-compat-report-runner
                #:file-compat-summary-failed-checks
                #:file-compat-summary-failed-scenarios
                #:file-compat-summary-passed-checks
                #:file-compat-summary-passed-scenarios
                #:file-compat-summary-total-checks
                #:file-compat-summary-total-scenarios
                #:file-compat-scenario-classification
                #:file-compat-scenario-tags
                #:load-scenario-file
                #:make-file-compat-scenario
                #:normalize-newlines
                #:read-file-bytes
                #:report->plist
                #:run-scenario
                #:scenario-matches-tags-p
                #:summarize-reports
                #:summary->plist
                #:write-file-text)
  (:export #:autolisp-file-compat-suite
           #:run-all-tests))
