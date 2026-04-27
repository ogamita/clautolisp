(defpackage #:clautolisp.autolisp-host.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:test
                #:is
                #:run
                #:explain!
                #:results-status)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-runtime-error
                #:autolisp-runtime-error-code
                #:autolisp-runtime-error-message
                #:make-runtime-session
                #:runtime-session-host
                #:set-runtime-session-host
                #:current-evaluation-host
                #:current-evaluation-context
                #:default-evaluation-context
                #:reset-default-evaluation-context
                #:*default-runtime-host*)
  (:import-from #:clautolisp.autolisp-host
                #:host
                #:hostp
                #:host-name
                #:null-host
                #:make-null-host
                #:*null-host*
                #:host-entget
                #:host-entlast
                #:host-getvar
                #:host-setvar
                #:host-command
                #:host-prompt
                #:host-getstring
                #:host-grdraw
                #:host-ssget
                #:host-tblsearch
                #:host-tblnext
                #:host-dictsearch
                #:host-dictadd)
  (:export #:autolisp-host-suite
           #:run-all-tests))
