(defpackage #:clautolisp.debug
  (:use #:cl)
  (:documentation
   "Clautolisp debugger engine (Phase 1 of the clautolisp-debugger plan):
the interpreter two-bodies instrumentation (§3a), poll points with a
Bloom-filter fast path (spec §11), the per-thread breakpoint table
(spec §8/§12), and a two-thread pause loop (spec §8). UI-independent.")
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-usubr
                #:autolisp-usubr-name
                #:autolisp-usubr-lambda-list
                #:autolisp-usubr-body
                #:autolisp-usubr-instrumented-body
                #:autolisp-usubr-debug-metadata
                #:autolisp-symbol
                #:autolisp-symbol-name
                #:autolisp-string
                #:make-autolisp-string
                #:intern-autolisp-symbol
                #:split-usubr-lambda-list
                #:register-special-operator
                #:known-special-operator-p
                #:autolisp-eval
                #:*debugging*
                #:current-evaluation-context
                #:evaluation-context-dynamic-frame
                #:dynamic-frame-parent
                #:dynamic-frame-symbols
                #:dynamic-frame-binding-value
                #:set-dynamic-frame-binding-value
                #:lookup-variable
                #:set-variable
                #:autolisp-runtime-error
                #:autolisp-runtime-error-message
                #:autolisp-runtime-error-code
                #:autolisp-errno
                #:catch-frame-function
                #:catch-frame-arguments
                #:*autolisp-catch-stack*
                #:*autolisp-caught-error-hook*)
  (:import-from #:clautolisp.source
                #:position-of
                #:source-position
                #:source-position-p
                #:source-position-equal
                #:source-position-file
                #:source-position-start-line
                #:source-position-start-column
                #:source-position-end-line)
  (:export
   #:*protocol-version*
   ;; debug metadata + function-id registry (spec §7)
   #:function-debug-metadata
   #:function-debug-metadata-p
   #:function-debug-metadata-function-id
   #:function-debug-metadata-name
   #:function-debug-metadata-usubr
   #:function-debug-metadata-source-position
   #:function-debug-metadata-form-id->position
   #:function-debug-metadata-form-id->kind
   #:function-debug-metadata-parent-form-map
   #:function-debug-metadata-poll-point-count
   #:function-debug-metadata-bound-names
   #:function-debug-metadata-source-text
   #:metadata-for-function-id
   #:metadata-for-usubr
   #:all-function-metadata
   #:metadata-for-name
   #:wildcard-name-match-p
   #:functions-matching
   #:form-id-position
   #:form-id-kind
   #:find-form-id-at-line
   #:form-ids-at-line
   #:form-id-at-line-col
   #:poll-point-id
   #:poll-point-location
   ;; instrumentation (§3a / spec §5)
   #:instrument-usubr
   #:ensure-metadata-for-name
   #:instrumentedp
   #:reset-function-id-registry
   ;; pre-debug navigation (aldo-pre-debug.issue)
   #:*pending-nav-request*
   #:*defer-nav-request*
   #:request-nav
   #:*selected-source*
   #:select-source
   ;; thread-debug-info + breakpoints (spec §8 / §12)
   #:thread-debug-info
   #:make-thread-debug-info
   #:thread-debug-info-p
   #:thread-debug-info-debug-flag
   #:thread-debug-info-breakpoints
   #:thread-debug-info-summary
   #:thread-debug-info-volatile
   #:thread-debug-info-current-pp
   #:thread-debug-info-status
   #:thread-debug-info-inbound
   #:thread-debug-info-outbound
   #:*thread-debug-info*
   #:*thread-debug-info-table*
   #:breakpoint
   #:breakpoint-p
   #:breakpoint-id
   #:breakpoint-fid
   #:breakpoint-form-id
   #:breakpoint-when
   #:breakpoint-steady-p
   #:breakpoint-condition
   #:breakpoint-action
   #:breakpoint-trace-p
   #:breakpoint-enabled-p
   #:set-breakpoint-enabled
   #:set-breakpoint-action
   #:add-breakpoint
   #:add-breakpoint-in
   #:find-active-breakpoint
   #:remove-breakpoint
   #:list-breakpoints
   #:clear-breakpoints
   #:rebuild-summary
   ;; virtual (deferred) breakpoints on a not-yet-loaded file
   ;; (aldo-pre-debug.issue)
   #:virtual-breakpoint
   #:virtual-breakpoint-p
   #:virtual-breakpoint-id
   #:virtual-breakpoint-file
   #:virtual-breakpoint-function-name
   #:virtual-breakpoint-line
   #:virtual-breakpoint-col
   #:virtual-breakpoint-anchor-line
   #:virtual-breakpoint-ti
   #:add-virtual-breakpoint
   #:list-virtual-breakpoints
   #:find-virtual-breakpoint
   #:remove-virtual-breakpoint
   #:clear-virtual-breakpoints
   #:virtual-breakpoints-for-file
   #:materialize-virtual-breakpoints
   ;; software watchpoints (command reference §2 watch)
   #:watch #:watch-p
   #:watch-symbol #:watch-name #:watch-last-value #:watch-prev-value
   #:watch-last-bound-p #:watch-prev-bound-p #:watch-predicate
   #:add-watch #:remove-watch #:clear-watches #:list-watches #:check-watches
   ;; form-level jump (command reference §1 jump)
   #:request-jump #:clear-jump #:jump-pending-p #:jump-disposition
   #:form-id-parent #:form-ancestor-p
   ;; poll points + hit dispatch (spec §11 / §6.4)
   #:poll-point
   #:invoke-debugger-break
   #:hit
   #:hit-p
   #:hit-thread-info
   #:hit-breakpoint
   #:hit-fid
   #:hit-form-id
   #:hit-when
   #:hit-metadata
   #:hit-source-position
   #:hit-snapshot
   #:hit-stop-reason
   #:hit-watch
   #:hit-condition
   #:hit-error-message
   #:hit-errno
   #:*debug-hit-handler*
   ;; error integration (spec §10)
   #:debug-handle-error
   #:abort-thread
   #:return-thread
   #:*break-on-error*
   #:*break-on-caught-error*
   ;; snapshot + environment (spec §9)
   #:snapshot
   #:snapshot-p
   #:snapshot-thread
   #:snapshot-function-name
   #:snapshot-fid
   #:snapshot-form-id
   #:snapshot-when
   #:snapshot-source-position
   #:snapshot-call-stack
   #:snapshot-binding-stack
   #:snapshot-visible-names
   #:snapshot-globals-touched
   #:snapshot-catch-stack
   #:stack-frame
   #:stack-frame-function-name
   #:stack-frame-fid
   #:stack-frame-form-id
   #:stack-frame-source-position
   #:stack-frame-bindings-introduced
   #:binding-entry
   #:binding-entry-symbol
   #:binding-entry-value
   #:binding-entry-frame
   #:binding-entry-shadowed-p
   #:bindings-of-name
   #:visible-value
   #:set-binding-entry
   #:set-visible-variable
   #:coerce-from-cl
   #:eval-in-frame
   ;; stepping (spec §6)
   #:request-step
   #:advance-to-point
   #:poll-point-at
   #:step-thread
   ;; session / entry (spec §8 / §21)
   #:call-with-debugging
   #:with-debugging
   #:run-debugged-thread
   #:continue-thread
   #:blocking-queue
   #:make-blocking-queue
   #:bq-push
   #:bq-pop))
