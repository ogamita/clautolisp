(defpackage #:clautolisp.autolisp-compiler
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-eval
                #:autolisp-eval-progn
                #:autolisp-false-p
                #:autolisp-true-p
                #:autolisp-string
                #:autolisp-symbol
                #:autolisp-symbol-name
                #:call-autolisp-function-in-context
                #:current-evaluation-context
                #:intern-autolisp-symbol
                #:lookup-variable
                #:resolve-autolisp-function-designator
                #:set-variable)
  (:export #:transpile-form
           #:transpile-body
           #:compile-autolisp-form
           #:*transpiler-fallbacks*
           #:transpiler-coverage))
