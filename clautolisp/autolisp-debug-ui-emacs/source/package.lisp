(defpackage #:clautolisp.ui.emacs
  (:use #:cl #:clautolisp.debug.ui)
  (:documentation
   "The Emacs debugger UI (clautolisp-debugger spec §20), named aldb after
SLDB. The CL side is a thin RPC shim implementing the clautolisp.debug.ui
protocol over a line-oriented S-expression channel (§20.1): each
notification is written as a CL form the Emacs side reads with `read`, and
each command is a form read back from the channel. Both streams are
injectable, so the shim is fully testable headlessly. The Emacs minor mode
itself lives in emacs/aldb.el. Registered as :emacs / :aldb.")
  (:import-from #:clautolisp.debug
                #:*protocol-version*
                #:hit-stop-reason #:hit-source-position #:hit-error-message #:hit-errno
                #:hit-when
                #:snapshot-function-name #:snapshot-source-position
                #:snapshot-call-stack #:snapshot-visible-names #:snapshot-catch-stack
                #:stack-frame-function-name #:stack-frame-source-position
                #:breakpoint-id #:breakpoint-fid #:breakpoint-form-id #:breakpoint-when)
  (:import-from #:clautolisp.source
                #:source-position-p #:source-position-file
                #:source-position-start-line #:source-position-start-column)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol-name #:intern-autolisp-symbol)
  (:import-from #:clautolisp.inspect
                #:inspect-page-type-name #:inspect-page-header #:inspect-page-components
                #:inspect-component-label #:inspect-component-preview
                #:inspect-component-descendable-p
                #:session-page #:session-origin)
  (:export #:emacs-ui #:make-emacs-ui
           #:emacs-ui-input #:emacs-ui-output
           ;; the wire helpers (also used by tests)
           #:write-message #:read-command
           #:snapshot->wire #:source-position->wire))
