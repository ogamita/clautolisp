(defpackage #:clautolisp.configuration.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:is #:run #:explain!
                #:results-status #:test)
  (:import-from #:clautolisp.configuration
                #:config-getenv
                #:xdg-config-home
                #:xdg-config-dirs
                #:config-relative-path
                #:config-save-path
                #:config-load-path
                #:*configuration-names*
                #:configuration-name-p)
  (:export #:run-all-tests))
