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
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:autolisp-termination
                #:autolisp-termination-kind
                #:run-autolisp-file
                #:run-autolisp-string)
  (:import-from #:clautolisp.autolisp-builtins-core
                #:install-core-builtins)
  (:export #:main))
