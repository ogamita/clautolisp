(defpackage #:clautolisp.autolisp-builtins-core.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.autolisp-builtins-core
                #:find-core-builtin
                #:install-core-builtins)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-details
                #:autolisp-file
                #:autolisp-string
                #:make-autolisp-string
                #:autolisp-string-value
                #:autolisp-subr
                #:autolisp-subr-name
                #:autolisp-symbol
                #:autolisp-symbol-function
                #:autolisp-symbol-name
                #:set-autolisp-symbol-value
                #:call-autolisp-function
                #:set-autolisp-current-directory
                #:set-autolisp-support-paths
                #:set-autolisp-trusted-paths
                #:find-autolisp-symbol
                #:intern-autolisp-symbol
                #:reset-autolisp-symbol-table)
  (:export #:autolisp-builtins-core-suite
           #:run-all-tests))
