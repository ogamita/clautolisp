(defpackage #:clautolisp.tools.clautolisp
  (:use #:cl)
  (:import-from #:uiop
                #:command-line-arguments
                #:quit)
  (:import-from #:clautolisp.interactor
                #:define-interactor #:define-command
                #:interactor-commands #:interactor-user-commands
                #:dictionary-commands
                #:command-key #:command-words #:command-phrase #:command-docstring
                #:*interactor-stack*
                #:make-input-context #:input-context-stream
                #:comma-command-read #:input-command-p #:find-and-run-command)
  (:import-from #:clautolisp.autolisp-reader
                #:autolisp-dialect
                #:autolisp-dialect-name
                #:find-autolisp-dialect
                #:autolisp-dialect-strict
                #:autolisp-dialect-autocad-2026
                #:autolisp-dialect-bricscad-v26
                #:autolisp-dialect-clautolisp
                #:autolisp-dialect-lax
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
                #:autolisp-eval-toplevel-progn
                #:autolisp-load-file-in-context
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:autolisp-runtime-error-call-stack
                #:autolisp-termination
                #:autolisp-termination-kind
                #:autolisp-termination-status
                #:autolisp-exit-status
                #:call-with-autolisp-error-handler
                #:derive-reader-options-for-dialect
                #:intern-autolisp-symbol
                #:lookup-variable
                #:make-autolisp-string
                #:make-default-runtime-context
                #:read-runtime-from-string
                #:run-autolisp-file
                #:run-autolisp-string
                #:set-runtime-session-host
                #:set-variable
                #:set-default-source-encoding
                #:locale-default-source-encoding
                #:current-evaluation-context
                #:evaluation-context-session
                #:*default-runtime-host*)
  (:import-from #:clautolisp.autolisp-host
                #:host-name
                #:null-host
                #:make-null-host
                #:*null-host*)
  (:import-from #:clautolisp.autolisp-mock-host
                #:make-mock-host
                #:mock-host
                #:mock-host-prompt-stream)
  (:import-from #:clautolisp.autolisp-builtins-core
                #:autolisp-value->string
                #:install-core-builtins)
  (:import-from #:clautolisp.autolisp-init-files
                #:*default-clautolisp-stems*
                #:find-init-files
                #:no-init-requested-p)
  (:export #:main
           #:*version*))
