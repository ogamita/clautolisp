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
                #:autolisp-symbol-function
                #:autolisp-symbol-function-bound-p
                #:autolisp-symbol-name
                #:autolisp-symbol-value
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
                #:bind-dynamic-variable
                #:default-evaluation-context
                #:document-namespace-name
                #:evaluation-context-current-document
                #:evaluation-context-current-namespace
                #:evaluation-context-session
                #:function-cell-function
                #:intern-autolisp-symbol
                #:lookup-function
                #:lookup-variable
                #:make-document-namespace
                #:make-evaluation-context
                #:make-runtime-session
                #:namespace-function-cell
                #:namespace-value-cell
                #:pop-dynamic-frame
                #:push-dynamic-frame
                #:read-runtime-from-string
                #:reader-object->runtime-value
                #:reset-autolisp-symbol-table
                #:runtime-session-current-document
                #:set-default-evaluation-context
                #:set-function
                #:set-variable
                #:value-cell-value
                #:runtime-value-p)
  (:import-from #:clautolisp.autolisp-reader
                #:read-forms-from-string
                #:read-result-objects)
  (:export #:autolisp-runtime-suite
           #:run-all-tests))
