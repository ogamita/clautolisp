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
                #:autolisp-symbol-function-bound-p
                #:autolisp-symbol-name
                #:autolisp-symbol-value-bound-p
                #:autolisp-type
                #:autolisp-vl-symbol-name
                #:autolisp-vl-symbolp
                #:autolisp-vl-symbol-value
                #:autolisp-listp
                #:autolisp-atom
                #:autolisp-null
                #:autolisp-not
                #:autolisp-read-from-string
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
