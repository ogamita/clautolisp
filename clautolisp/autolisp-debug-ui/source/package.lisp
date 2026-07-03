(defpackage #:clautolisp.debug.ui
  (:use #:cl)
  (:documentation
   "The debugger UI protocol (clautolisp-debugger spec §17) and session
lifecycle (§21–§24). A UI is a CLOS object implementing a fixed set of
generic functions; the debugger calls UI-* to report state and the UI
calls CMD-* to drive the session. This layer is UI-agnostic — concrete
UIs (dumb terminal, ncurses, Emacs) build on it. In-image terminal UIs
run synchronously: at a stopping point the engine's *debug-hit-handler*
calls UI-AWAIT-COMMAND, which returns a resume directive.")
  (:import-from #:clautolisp.autolisp-runtime
                #:autolisp-symbol
                #:autolisp-symbol-name
                #:intern-autolisp-symbol
                #:read-runtime-from-string
                #:make-default-runtime-context
                #:current-evaluation-context)
  (:import-from #:clautolisp.debug
                #:*debug-hit-handler*
                #:*protocol-version*
                #:make-thread-debug-info
                #:call-with-debugging
                #:add-breakpoint
                #:add-breakpoint-in
                #:remove-breakpoint
                #:list-breakpoints
                #:clear-breakpoints
                #:add-watch #:remove-watch #:clear-watches #:list-watches
                #:request-step
                #:advance-to-point
                #:poll-point-at
                #:metadata-for-function-id
                #:function-debug-metadata-function-id
                #:find-form-id-at-line
                #:hit-snapshot #:hit-stop-reason #:hit-source-position
                #:hit-error-message #:hit-fid #:hit-form-id #:hit-when #:hit-breakpoint
                #:snapshot #:snapshot-function-name #:snapshot-source-position
                #:snapshot-call-stack #:snapshot-binding-stack #:snapshot-visible-names
                #:snapshot-form-id #:snapshot-catch-stack
                #:stack-frame-function-name #:stack-frame-source-position
                #:binding-entry-symbol #:binding-entry-value #:binding-entry-shadowed-p
                #:binding-entry-frame
                #:bindings-of-name #:visible-value
                #:eval-in-frame #:set-binding-entry #:set-visible-variable
                #:breakpoint-id #:breakpoint-fid #:breakpoint-form-id #:breakpoint-when
                #:breakpoint-enabled-p #:set-breakpoint-enabled)
  (:import-from #:clautolisp.source
                #:source-position-p
                #:source-position-file
                #:source-position-start-line
                #:source-position-start-column
                #:lines-of)
  ;; clautolisp.inspect:inspect shadows cl:inspect here (we call the
  ;; inspector's INSPECT, not the CL one).
  (:shadowing-import-from #:clautolisp.inspect #:inspect)
  (:import-from #:clautolisp.inspect
                #:session-down #:session-up #:session-eval
                #:session-path-expression #:session-bind #:session-current #:session-page
                #:inspect-page-type-name #:inspect-page-header #:inspect-page-components
                #:inspect-component-label #:inspect-component-preview
                #:inspect-component-accessor #:inspect-component-descendable-p
                #:make-workspace #:workspace-list #:workspace-clear
                #:inspector-session-workspace)
  (:export
   ;; UI protocol — debugger → UI (notifications)
   #:ui-attached #:ui-detached
   #:ui-thread-hit #:ui-thread-unhandled-error #:ui-thread-caught-error
   #:ui-thread-resumed #:ui-thread-exited
   #:ui-breakpoint-added #:ui-breakpoint-removed
   #:ui-show-source #:ui-show-message
   #:ui-await-command
   ;; session object
   #:debugger-session
   #:debugger-session-p
   #:session-ui #:session-thread-info #:session-context #:session-workspace
   #:session-snapshot #:session-selected-frame #:session-inspector #:session-last-step
   #:session-nav-target
   ;; UI → debugger (commands)
   #:cmd-continue #:cmd-step #:cmd-advance #:cmd-abort #:cmd-return #:cmd-jump
   #:cmd-set-breakpoint #:cmd-set-breakpoint-at-line #:cmd-advance-at-line
   #:cmd-remove-breakpoint #:cmd-list-breakpoints
   #:cmd-watch #:cmd-unwatch #:cmd-clear-watches #:cmd-list-watches
   #:cmd-select-frame #:cmd-eval #:cmd-set-variable
   #:cmd-inspect #:cmd-inspector-descend #:cmd-inspector-up
   #:cmd-inspector-bind #:cmd-inspector-path-expression
   #:cmd-workspace-list #:cmd-workspace-clear
   #:current-snapshot #:current-metadata
   ;; lifecycle
   #:start-session #:call-with-session #:with-session #:session-stop
   #:register-ui #:*ui-constructors* #:make-ui
   ;; settings / configuration (command reference §8)
   #:*aldo-configuration* #:*default-aldo-configuration* #:*setting-specs*
   #:reset-aldo-configuration
   #:config-get #:config-set #:config-keys #:normalize-config-key
   #:set-aldo-setting #:get-aldo-setting #:setting-spec #:parse-setting-value
   #:aldo-settings-lines #:format-setting-value
   #:xdg-config-home #:xdg-config-dirs
   #:aldo-config-save-path #:aldo-config-load-path
   #:save-aldo-configuration #:load-aldo-configuration
   #:write-aldo-configuration #:read-aldo-configuration
   ;; theme / decorations renderer (command reference §8)
   #:glyph->string #:theme-of #:decoration-entries #:decoration-for
   #:color-theme-p #:sgr-wrap #:apply-decoration #:situation-prefix
   ;; command table + stacked dictionaries (command reference §8)
   #:command #:command-p #:command-key #:command-words #:command-phrase
   #:command-lambda-list #:command-docstring #:command-function #:command-arity
   #:dictionary #:dictionary-name #:make-command-dictionary
   #:*global-dictionary* #:+debugger-escape-word+
   #:*active-command-dictionaries* #:active-command-dictionaries
   #:*debugger-ui* #:*debugger-session* #:*debugger-hit*
   #:bind-debugger-command #:unbind-debugger-command #:define-debugger-command
   #:find-command #:lookup-command
   ;; config bridge to the canonical AutoLISP *CLAL-ALDO-CONFIGURATION*
   #:aldo-config-variable-symbol #:autolisp->cl-config #:cl-config->autolisp
   #:config-variable-bound-p #:read-config-variable #:write-config-variable
   #:sync-config-from-variable #:sync-config-to-variable
   ;; structural sexp navigator (command reference §3)
   #:make-navigator #:navigator-root #:navigator-path #:nav-selected
   #:nav-parent #:nav-index
   #:nav-down #:nav-up #:nav-forward #:nav-backward #:nav-first #:nav-last
   #:nav-skip #:nav-render #:nav-source-listing #:nav-selected-position
   #:nav-code-down #:nav-code-forward #:nav-code-backward
   #:nav-code-first #:nav-code-last #:nav-code-skip
   #:*special-form-grammars* #:*sub-grammars* #:child-role #:role-at-path
   #:nav-selected-role #:nav-code-p))
