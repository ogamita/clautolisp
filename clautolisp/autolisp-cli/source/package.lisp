(defpackage #:clautolisp.autolisp-cli
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:intern-autolisp-symbol
                #:make-autolisp-string
                #:set-variable)
  (:export
   #:cli-situation-encoding-explicit
   #:terminal-encoding-plan
   #:terminal-situation-encoding
   #:apply-terminal-encoding
   #:windows-console-code-page
   ;; conditions
   #:cli-error
   #:cli-error-option
   #:cli-error-message
   #:cli-error-status
   #:cli-usage-error
   #:cli-usage-error-option
   #:cli-usage-error-message

   ;; cli-options struct + accessors (union of clautolisp + alfe slots)
   #:cli-options
   #:make-cli-options
   #:copy-cli-options
   #:cli-options-backend         ; A — alfe backend selector (:clautolisp/:bricscad/:autocad)
   #:cli-options-mode            ; A — :auto / :automation / :batch
   #:cli-options-backend-variant ; A — :attach / :launch / …
   #:cli-options-cad             ; A — --cad DENOTATION (alfe backend selection)
   #:cli-options-actions         ; AC — ordered action list ((:file . PATH)/(:expression . TEXT))
   #:cli-options-interactive-p   ; AC
   #:cli-options-quit-p          ; A
   #:cli-options-host            ; AC — :mock / :null
   #:cli-options-dialect         ; AC — :strict / :autocad-2026 / :bricscad-v26 / :clautolisp
   #:cli-options-load-encoding   ; AC — the `source' situation (-Esource)
   #:cli-options-io-encoding     ; AC — the `terminal' situation (-Eterminal)
   #:cli-options-situation-encodings ; AC — the -E<situation>[-<dir>] alist
   #:cli-situation-encoding      ; AC — resolver: (opts situation &optional direction)
   #:*encoding-situations*       ; AC — the situation registry
   #:cli-options-dwg             ; A
   #:cli-options-plugin-options  ; A — alist (PLUGIN-NAME . plist of resolved option values)
   #:cli-options-plugins-active  ; A — names of the active plug-ins, in activation order
   #:cli-options-list-plugins-p  ; A — --list-plugins
   #:cli-options-compile-plugin  ; A — --compile-plugin FILE
   #:cli-options-bootstrap-phase ; A
   #:cli-options-verbosity       ; AC — :debug/:verbose/:info/:warn
   #:cli-options-workdir         ; A
   #:cli-options-timeout         ; A
   #:cli-options-help-p          ; AC
   #:cli-options-version-p       ; AC
   #:cli-options-list-encodings-p ; AC
   #:cli-options-list-dialects-p ; AC
   #:cli-options-list-situations-p ; AC
   #:cli-options-list-hosts-p    ; AC
   #:cli-options-list-cad-programs-p ; AC
   #:cli-options-dry-run-p       ; A
   #:cli-options-print-command-p ; A
   #:cli-options-no-init-p       ; AC
   #:cli-options-no-color-p      ; AC
   #:cli-options-keep-workdir-p  ; A
   #:cli-options-write-workdir-path ; A — --write-workdir-path FILE
   #:cli-options-cad-log         ; A — --cad-log FILE
   #:cli-options-main            ; A — symbol name (string)
   #:cli-options-mock-input      ; C — clautolisp cador prompt-stream
   #:cli-options-gui             ; C — clautolisp DCL subprocess renderer
   #:cli-options-dcl             ; C — clautolisp --dcl tui|gui|auto renderer selection
   #:cli-options-trace-p         ; C — clautolisp --trace
   #:cli-options-optimization    ; C — clautolisp --optimize / -O
   #:cli-options-on-error        ; C — clautolisp --on-error policy
   #:cli-options-on-interrupt    ; C — clautolisp --on-interrupt policy
   #:cli-options-on-quit         ; C — clautolisp --on-quit policy
   #:cli-options-user-interface  ; C — clautolisp --debugger-ui
   #:cli-options-aldb-address    ; C — clautolisp --aldb-listen HOST part
   #:cli-options-aldb-port       ; C — clautolisp --aldb-listen PORT part
   #:cli-options-aldb-stdio-p    ; C — clautolisp --aldb-stdio
   #:cli-options-dribble         ; C — --dribble / --dribble=FILE (t / string)
   #:cli-options-dribble-interactors ; C — --dribble-interactors=IS (:all / names)
   #:cli-options-positional      ; both — positional FILE arguments
   #:cli-options-front-end-bindings ; C — --front-end-bindings FILE (alfe subprocess)
   #:cli-options-front-end-action-boundaries ; C — --front-end-action-boundaries DIR (alfe subprocess)

   ;; value parsers (one per option-value vocabulary)
   #:parse-mode
   #:parse-backend-symbol
   #:parse-backend-variant
   #:parse-host
   #:parse-dialect
   #:parse-bootstrap-phase
   #:parse-timeout
   #:parse-on-error
   #:parse-on-interrupt
   #:parse-on-quit
   #:parse-user-interface
   #:parse-dcl-mode
   #:parse-optimize
   #:parse-aldb-listen
   #:parse-dribble-interactors

   ;; the debugger (aldo) options, shared by clautolisp and alfe
   ;; (debugger-public-interface-and-on-error.issue)
   #:*debugger-option-names*
   #:validate-debugger-options
   #:effective-user-interface
   #:debugger-session-requested-p
   #:aldb-listen-argument
   #:debugger-option-arguments
   #:given-debugger-options

   ;; Control-C, portably (SBCL signal handler / CCL *break-hook*)
   #:install-sigint-handler
   #:restore-sigint-handler
   #:call-with-sigint-handler
   #:abrupt-exit
   #:forward-sigint

   ;; option-spec + parser
   #:option-spec
   #:make-option-spec
   #:option-spec-longs
   #:option-spec-shorts
   #:option-spec-takes-arg-p
   #:option-spec-optional-arg-p
   #:option-spec-handler
   #:*common-option-specs*
   #:parse-arguments-with-spec

   ;; transmit
   #:autolisp-bool
   #:autolisp-string-or-nil
   #:dialect-name-symbol-keyword
   #:host-name-symbol-keyword
   #:actions-to-autolisp-list
   #:cli-options->transmit-bindings
   #:install-transmit-variables
   #:call-with-dynamic-transmit-binding

   ;; engine contract shared by the clautolisp program and alfe's
   ;; in-process engine (alfe-clautolisp-backend-semantic-parity.issue)
   #:write-transmit-bindings-file
   #:read-transmit-bindings-file
   #:render-action-value
   #:action-boundary-pathname
   #:write-action-boundary
   #:read-action-boundary
   #:acknowledge-action-boundary
   #:report-action-boundary
   #:wait-for-action-boundary-reply
   #:call-at-action-boundaries
   #:*action-boundary-poll-interval*
   #:report-autolisp-runtime-error
   #:report-autolisp-termination
   #:report-engine-error
   #:engine-drawing-error-message
   #:engine-drawing-error
   #:engine-exit-status
   #:reader-diagnostic-error-p

   ;; encoding registry + resolver
   #:*encoding-aliases*
   #:resolve-encoding-name
   #:encoding-keyword
   #:canonical-encoding-name
   #:resolve-locale-encoding-name
   #:resolve-effective-encoding
   #:enumerate-implementation-encodings
   #:print-encodings
   #:print-dialects
   #:print-situations
   #:print-hosts
   #:*host-descriptions*))
