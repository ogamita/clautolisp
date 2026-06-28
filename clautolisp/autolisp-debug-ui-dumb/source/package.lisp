(defpackage #:clautolisp.ui.dumb
  (:use #:cl #:clautolisp.debug.ui)
  (:documentation
   "The dumb-terminal debugger UI (clautolisp-debugger spec §18): the
lowest-common-denominator front-end, line-by-line over plain input/output
streams with no cursor control. Works over a pipe, in a logfile-style
shell, and in CI. Registered as :terminal / :dumb. It is the UI the
implementer uses to bring the debugger up, and the baseline every richer
UI refines.")
  (:import-from #:clautolisp.source
                #:source-position-p #:source-position-file
                #:source-position-start-line #:source-position-start-column
                #:lines-of)
  (:import-from #:clautolisp.debug
                #:hit-stop-reason #:hit-source-position #:hit-error-message
                #:hit-when
                #:snapshot-function-name #:snapshot-source-position
                #:snapshot-call-stack #:snapshot-visible-names #:snapshot-catch-stack
                #:stack-frame-function-name #:stack-frame-source-position
                #:breakpoint-id #:breakpoint-fid #:breakpoint-form-id #:breakpoint-when
                #:breakpoint-enabled-p #:set-breakpoint-enabled #:breakpoint-condition
                #:poll-point-id #:poll-point-location
                #:function-debug-metadata-function-id
                #:function-debug-metadata-poll-point-count #:form-id-position)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol-name #:read-runtime-from-string
                #:autolisp-eval #:current-evaluation-context #:*debugging*)
  (:import-from #:clautolisp.inspect
                #:inspect-page-type-name #:inspect-page-header #:inspect-page-components
                #:inspect-component-label #:inspect-component-preview
                #:inspect-component-accessor #:inspect-component-descendable-p
                ;; session-* called directly on the inspector session
                #:session-page #:session-origin #:session-eval)
  (:export #:dumb-ui #:make-dumb-ui))
