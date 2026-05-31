(defpackage #:clautolisp.ui.ncurses
  (:use #:cl #:clautolisp.debug.ui #:clautolisp.ui.tui)
  (:documentation
   "The ncurses four-pane debugger UI (clautolisp-debugger spec §19),
built entirely on the clautolisp.ui.tui screen abstraction — it never
calls curses directly, so it runs against the mock screen in tests and
against the cl-charms backend (separate system) on a real terminal.
Panes: stack (top-left), source with poll-point/breakpoint/current
markers (top-right), interactor (bottom-left), repl (bottom-right).")
  (:shadowing-import-from #:clautolisp.inspect #:inspect)
  (:import-from #:clautolisp.debug
                #:hit-stop-reason #:hit-source-position #:hit-error-message
                #:snapshot-function-name #:snapshot-source-position
                #:snapshot-call-stack #:snapshot-visible-names
                #:stack-frame-function-name #:stack-frame-fid #:stack-frame-form-id
                #:stack-frame-source-position
                #:metadata-for-function-id #:form-id-position
                #:function-debug-metadata-form-id->position
                #:function-debug-metadata-function-id
                #:find-form-id-at-line
                #:breakpoint-fid #:breakpoint-form-id #:breakpoint-id)
  (:import-from #:clautolisp.source
                #:source-position-p #:source-position-file
                #:source-position-start-line #:lines-of)
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol-name #:read-runtime-from-string
                #:intern-autolisp-symbol)
  (:import-from #:clautolisp.inspect
                #:session-page #:session-origin
                #:inspect-page-type-name #:inspect-page-header #:inspect-page-components
                #:inspect-component-label #:inspect-component-preview
                #:inspect-component-descendable-p)
  (:export #:ncurses-ui #:make-ncurses-ui
           ;; render entry points (also used by tests)
           #:render-debugger #:render-inspector
           #:ncurses-ui-repl-lines #:ncurses-ui-message #:ncurses-ui-selected-frame))
