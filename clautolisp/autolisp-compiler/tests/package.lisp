(defpackage #:clautolisp.autolisp-compiler.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:run
                #:explain!
                #:results-status
                #:test)
  (:import-from #:clautolisp.autolisp-compiler
                #:autolisp-function-compiled-p
                #:autolisp-function-instrumented-compiled-p
                #:compile-autolisp-form
                #:compile-autolisp-function
                #:compile-instrumented-usubr
                #:transpiler-coverage)
  (:import-from #:clautolisp.debug
                ;; Test-only: an instrumented body is the debugger's
                ;; product, so the instrumented variant cannot be tested
                ;; without it.
                #:instrument-usubr
                #:reset-function-id-registry
                #:call-with-debugging)
  (:import-from #:clautolisp.autolisp-builtins-core
                ;; The fallback path calls real builtins (+, CAR, STRCAT …),
                ;; so they must be installed or every fallback case fails as
                ;; an undefined AutoLISP function -- and the suite would then
                ;; be testing the harness, not the compiler.
                #:install-core-builtins)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-eval
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-symbol
                #:autolisp-usubr
                #:autolisp-usubr-site
                #:usubr-site
                #:autolisp-string
                #:autolisp-string-value
                #:autolisp-symbol-name
                #:default-evaluation-context
                #:lookup-variable
                #:read-runtime-from-string
                #:reset-default-evaluation-context
                #:resolve-autolisp-function-designator
                #:*autolisp-compilation-enabled*
                #:*autolisp-compilation-threshold*
                #:*autolisp-speed-level*
                #:*compile-usubr-hook*
                #:*compile-instrumented-usubr-hook*
                #:*compiled-poll-hook*
                #:+poll-operator-name+
                #:call-with-compiled-poll-point
                #:autolisp-usubr-instrumented-body
                #:autolisp-usubr-compiled-instrumented-body
                #:intern-autolisp-symbol
                #:lookup-function)
  (:export #:run-all-tests))
