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
                #:compile-autolisp-form
                #:transpiler-coverage)
  (:import-from #:clautolisp.autolisp-builtins-core
                ;; The fallback path calls real builtins (+, CAR, STRCAT …),
                ;; so they must be installed or every fallback case fails as
                ;; an undefined AutoLISP function -- and the suite would then
                ;; be testing the harness, not the compiler.
                #:install-core-builtins)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-eval
                #:autolisp-string
                #:autolisp-string-value
                #:default-evaluation-context
                #:read-runtime-from-string
                #:reset-default-evaluation-context)
  (:export #:run-all-tests))
