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
                #:intern-autolisp-symbol
                #:split-usubr-lambda-list
                #:register-special-operator
                #:known-special-operator-p
                #:autolisp-eval
                #:*debugging*)
  (:import-from #:clautolisp.source
                #:position-of
                #:source-position
                #:source-position-p
                #:source-position-start-line
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
   #:form-id-position
   #:form-id-kind
   #:find-form-id-at-line
   ;; instrumentation (§3a / spec §5)
   #:instrument-usubr
   #:instrumentedp
   #:reset-function-id-registry
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
   #:add-breakpoint
   #:add-breakpoint-in
   #:remove-breakpoint
   #:list-breakpoints
   #:clear-breakpoints
   #:rebuild-summary
   ;; poll points + hit dispatch (spec §11 / §6.4)
   #:poll-point
   #:hit
   #:hit-p
   #:hit-thread-info
   #:hit-breakpoint
   #:hit-fid
   #:hit-form-id
   #:hit-when
   #:hit-metadata
   #:hit-source-position
   #:*debug-hit-handler*
   ;; session / entry (spec §8 / §21)
   #:call-with-debugging
   #:with-debugging
   #:run-debugged-thread
   #:continue-thread
   #:blocking-queue
   #:make-blocking-queue
   #:bq-push
   #:bq-pop))
