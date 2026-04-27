(defpackage #:clautolisp.tools.clautolisp
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:clautolisp.autolisp-reader
                #:autolisp-dialect
                #:autolisp-dialect-name
                #:find-autolisp-dialect
                #:autolisp-dialect-strict
                #:autolisp-dialect-autocad-2026
                #:autolisp-dialect-bricscad-v26
                #:diagnostic
                #:diagnostic-code
                #:diagnostic-message
                #:diagnostic-severity
                #:diagnostic-span
                #:source-span
                #:source-span-end-column
                #:source-span-end-line
                #:source-span-source-name
                #:source-span-start-column
                #:source-span-start-line)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-eval-progn
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:autolisp-runtime-error-call-stack
                #:autolisp-termination
                #:autolisp-termination-kind
                #:call-with-autolisp-error-handler
                #:derive-reader-options-for-dialect
                #:make-default-runtime-context
                #:read-runtime-from-string
                #:run-autolisp-file
                #:run-autolisp-string)
  (:import-from #:clautolisp.autolisp-builtins-core
                #:autolisp-value->string
                #:install-core-builtins)
  (:export #:main
           #:*version*))
