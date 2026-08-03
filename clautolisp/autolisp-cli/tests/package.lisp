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
