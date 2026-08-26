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
                #:autolisp-usubr-body
                #:autolisp-usubr-compiled-body
                #:call-autolisp-function-in-context
                #:*compile-usubr-hook*
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
           #:compile-usubr
           #:compile-autolisp-function
           #:autolisp-function-compiled-p
           #:*transpiler-fallbacks*
           #:transpiler-coverage))
