;;;; autolisp-front-end/tests/package.lisp
;;;;
;;;; FiveAM test package for the alfe front-end. The suite layout
;;;; mirrors the clautolisp test packages (see e.g.
;;;; clautolisp/autolisp-runtime/tests/package.lisp): one top-level
;;;; suite, per-area child suites, a single RUN-ALL-TESTS the Makefile
;;;; and the ASDF :test-op hook into.

(defpackage #:autolisp-front-end.tests
  (:use #:cl)
  (:import-from #:fiveam
                #:def-suite
                #:in-suite
                #:is
                #:signals
                ;; #:run intentionally NOT imported here — alfe.cli also
                ;; exports a RUN symbol (the CLI entry point) and the
                ;; tests reach for that one constantly. We call FiveAM's
                ;; runner via FIVEAM:RUN qualified from run.lisp instead.
                #:explain!
                #:results-status
                #:test)
  (:import-from #:alfe.backend
                #:find-backend
                #:list-backends
                #:detect
                #:start-engine
                #:eval-plan
                #:shutdown
                #:make-action
                #:action-eval
                #:action-load
                #:action-main
                #:action-interactive
                #:action-quit
                #:action-kind
                #:action-payload
                #:eval-result-status
                #:eval-result-value
                #:eval-result-output
                #:session-state)
  (:import-from #:alfe.error
                #:backend-error
                #:backend-not-available
                #:cli-usage-error
                #:exit-code-for-condition)
  (:import-from #:alfe.cli
                #:run
                #:parse-arguments
                #:cli-options
                #:cli-options-actions
                #:cli-options-backend
                #:cli-options-dialect
                #:cli-options-host
                #:cli-options-help-p
                #:cli-options-version-p
                #:cli-options-verbosity
                #:cli-options-interactive-p
                #:cli-options-quit-p
                #:cli-options-dry-run-p
                #:cli-options-mode
                #:cli-options-load-encoding
                #:cli-options-io-encoding
                #:cli-options-dwg
                #:cli-options-epure-p
                #:cli-options-bootstrap-phase
                #:cli-options-workdir
                #:cli-options-timeout
                #:cli-options-positional
                #:cli-options-no-init-p
                #:plan-from-options
                #:env-default)
  (:export #:autolisp-front-end-suite
           #:run-all-tests))
