(defpackage #:clautolisp.autolisp-cli
  (:use #:cl)
  (:import-from #:clautolisp.autolisp-runtime
                #:intern-autolisp-symbol
                #:make-autolisp-string
                #:set-variable)
  (:export
   ;; conditions
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
   #:cli-options-actions         ; AC — ordered action list ((:file . PATH)/(:expression . TEXT))
   #:cli-options-interactive-p   ; AC
   #:cli-options-quit-p          ; A
   #:cli-options-host            ; AC — :mock / :null
   #:cli-options-dialect         ; AC — :strict / :autocad-2026 / :bricscad-v26 / :clautolisp
   #:cli-options-load-encoding   ; AC — -e ENC
   #:cli-options-io-encoding     ; AC — -E ENC
   #:cli-options-dwg             ; A
   #:cli-options-epure-p         ; A
   #:cli-options-bootstrap-phase ; A
   #:cli-options-verbosity       ; AC — :debug/:verbose/:info/:warn
   #:cli-options-workdir         ; A
   #:cli-options-timeout         ; A
   #:cli-options-help-p          ; AC
   #:cli-options-version-p       ; AC
   #:cli-options-list-encodings-p ; AC
   #:cli-options-list-dialects-p ; AC
   #:cli-options-on-error        ; AC — --on-error :quit/:debug/:ignore (nil = auto)
   #:cli-options-dry-run-p       ; A
   #:cli-options-no-init-p       ; AC
   #:cli-options-no-color-p      ; AC
   #:cli-options-keep-workdir-p  ; A
   #:cli-options-main            ; A — symbol name (string)
   #:cli-options-mock-input      ; C — clautolisp mock-host prompt-stream
   #:cli-options-gui             ; C — clautolisp DCL subprocess renderer
   #:cli-options-trace-p         ; C — clautolisp --trace
   #:cli-options-positional      ; both — positional FILE arguments

   ;; value parsers (one per option-value vocabulary)
   #:parse-mode
   #:parse-backend-symbol
   #:parse-backend-variant
   #:parse-host
   #:parse-dialect
   #:parse-on-error
   #:parse-bootstrap-phase
   #:parse-timeout

   ;; option-spec + parser
   #:option-spec
   #:make-option-spec
   #:option-spec-longs
   #:option-spec-shorts
   #:option-spec-takes-arg-p
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

   ;; encoding registry + resolver
   #:*encoding-aliases*
   #:resolve-encoding-name
   #:encoding-keyword
   #:canonical-encoding-name
   #:resolve-locale-encoding-name
   #:resolve-effective-encoding
   #:enumerate-implementation-encodings
   #:print-encodings
   #:print-dialects))
