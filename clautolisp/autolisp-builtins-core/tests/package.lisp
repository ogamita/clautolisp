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
                #:core-builtins
                #:find-core-builtin
                #:install-core-builtins)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:autolisp-runtime-error-details
                #:autolisp-eval
                #:autolisp-errno
                #:autolisp-file
                #:autolisp-namespace-exit
                #:autolisp-namespace-exit-kind
                #:autolisp-namespace-exit-value
                #:autolisp-termination
                #:autolisp-termination-kind
                #:autolisp-string
                #:make-autolisp-string
                #:make-autolisp-subr
                #:make-document-namespace
                #:document-namespace-ref
                #:make-evaluation-context
                #:make-runtime-session
                #:register-runtime-session-vlx-namespace
                #:register-runtime-session-document
                #:autolisp-string-value
                #:autolisp-subr
                #:autolisp-subr-name
                #:autolisp-symbol
                #:autolisp-symbol-function
                #:autolisp-symbol-name
                #:autolisp-symbol-value
                #:autolisp-symbol-value-bound-p
                #:set-autolisp-symbol-function
                #:set-autolisp-symbol-value
                #:call-autolisp-function
                #:set-autolisp-errno
                #:set-default-evaluation-context
                #:set-autolisp-current-directory
                #:set-autolisp-support-paths
                #:set-autolisp-trusted-paths
                #:find-autolisp-symbol
                #:intern-autolisp-symbol
                #:reset-autolisp-symbol-table
                #:set-function
                #:run-autolisp-string)
  (:export #:autolisp-builtins-core-suite
           #:run-all-tests))
