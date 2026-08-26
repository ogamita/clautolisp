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
                #:known-special-operator-p
                #:lookup-variable
                #:resolve-autolisp-function-designator
                #:self-evaluating-runtime-value-p
                #:set-variable)
  (:export #:transpile-form
           #:transpile-body
           #:compile-autolisp-form
           #:*transpiler-fallbacks*
           #:transpiler-coverage))
