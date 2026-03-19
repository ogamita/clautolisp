(defpackage #:clautolisp.autolisp-runtime.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-string
                #:autolisp-string-value
                #:autolisp-symbol
                #:autolisp-symbol-name
                #:intern-autolisp-symbol
                #:read-runtime-from-string
                #:reader-object->runtime-value
                #:reset-autolisp-symbol-table
                #:runtime-value-p)
  (:import-from #:clautolisp.autolisp-reader
                #:read-forms-from-string
                #:read-result-objects)
  (:export #:autolisp-runtime-suite
           #:run-all-tests))
