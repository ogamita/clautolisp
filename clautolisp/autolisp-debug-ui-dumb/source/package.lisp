(defpackage #:clautolisp.ui.dumb
  (:use #:cl #:clautolisp.debug.ui)
  (:documentation
   "The dumb-terminal debugger UI (clautolisp-debugger spec §18): the
lowest-common-denominator front-end, line-by-line over plain input/output
streams with no cursor control. Works over a pipe, in a logfile-style
shell, and in CI. Registered as :terminal / :dumb. It is the UI the
implementer uses to bring the debugger up, and the baseline every richer
UI refines.")
  (:import-from #:clautolisp.interactor
                #:bind-command #:bind-command-alias
                #:command-raw-argument-p #:dictionary-commands
                #:+system-command-word+
                ;; the unified loop (interactor-unification.issue) over
                ;; singleton interactors + activations (design-revision T1)
                #:define-interactor #:define-command
                #:make-interactor
                #:interactor-commands #:interactor-user-commands
                #:interactor-prompt #:interactor-reader #:interactor-evaluator
                #:interactor-status #:interactor-on-result
                #:make-activation #:activation-state #:find-activation
                #:*command-interactor* #:*command-activation*
                #:*interactor-stack* #:push-interactor #:pop-interactor
                #:interactor-loop #:interactor-return
                #:command-read #:read-line-from-input-context
                #:input-command-p #:make-input-command
                #:input-command-raw #:input-command-tokens #:ident)
  (:import-from #:clautolisp.source
                #:source-position-p #:source-position-file
                #:source-position-start-line #:source-position-start-column
                #:source-position-end-line #:position-of #:with-source-tracking
                #:lines-of)
  (:import-from #:clautolisp.debug
                #:hit-stop-reason #:hit-source-position #:hit-error-message
                #:hit-when #:hit-watch #:hit-fid #:hit-form-id
                #:find-form-id-at-line #:form-ids-at-line #:form-id-at-line-col
                #:watch-name #:watch-symbol #:watch-last-value #:watch-prev-value
                #:watch-last-bound-p #:watch-prev-bound-p #:watch-predicate
                #:snapshot-function-name #:snapshot-source-position
                #:snapshot-call-stack #:snapshot-visible-names #:snapshot-catch-stack
                #:stack-frame-function-name #:stack-frame-source-position
                #:list-breakpoints
                #:breakpoint-id #:breakpoint-fid #:breakpoint-form-id #:breakpoint-when
                #:breakpoint-enabled-p #:set-breakpoint-enabled #:breakpoint-condition
                #:breakpoint-steady-p #:breakpoint-action #:breakpoint-trace-p
                #:set-breakpoint-action
                #:poll-point-id #:poll-point-location
                #:*break-on-error* #:*break-on-caught-error*
                #:metadata-for-name #:ensure-metadata-for-name
                #:*pending-nav-request* #:*selected-source*
                #:all-function-metadata #:functions-matching
                #:function-debug-metadata-function-id #:function-debug-metadata-usubr
                #:function-debug-metadata-name #:function-debug-metadata-source-position
                #:function-debug-metadata-poll-point-count #:form-id-position)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol-name #:read-runtime-from-string
                #:read-current-source
                #:autolisp-eval #:current-evaluation-context #:*debugging*
                #:intern-autolisp-symbol #:autolisp-usubr-name
                #:autolisp-usubr-lambda-list #:autolisp-usubr-body
                #:lookup-function #:call-autolisp-function #:autolisp-string-value)
  (:import-from #:clautolisp.inspect
                #:inspect-page-type-name #:inspect-page-header #:inspect-page-components
                #:inspect-component-label #:inspect-component-preview
                #:inspect-component-accessor #:inspect-component-descendable-p
                ;; session-* called directly on the inspector session
                #:session-page #:session-origin #:session-eval)
  (:export #:dumb-ui #:make-dumb-ui))
