(in-package #:clautolisp.autolisp-cli)

;;;; Translate a parsed CLI-OPTIONS into a list of *AUTOLISP-…*
;;;; variable bindings, then install them into a runtime context
;;;; before the first user action runs. See
;;;; issues/closed/transmit-options.issue for the variable contract.
;;;;
;;;; The bindings list shape is ((NAME-STRING VALUE) …). Each tool
;;;; builds it via CLI-OPTIONS->TRANSMIT-BINDINGS (passing its
;;;; backend identity + the rendered --help text) and feeds the
;;;; result to INSTALL-TRANSMIT-VARIABLES.

(defun autolisp-bool (truth-value)
  "Return the AutoLISP T symbol when TRUTH-VALUE is true, nil otherwise."
  (and truth-value (intern-autolisp-symbol "T")))

(defun autolisp-string-or-nil (string-value)
  "Wrap STRING-VALUE in an autolisp-string when non-empty; nil otherwise."
  (and string-value (stringp string-value) (plusp (length string-value))
       (make-autolisp-string string-value)))

(defun dialect-name-symbol-keyword (dialect-keyword)
  "Render the dialect keyword as the AutoLISP symbol shown in
*AUTOLISP-DIALECT*: STRICT, AUTOCAD-2026, BRICSCAD-V26, CLAUTOLISP."
  (and dialect-keyword
       (intern-autolisp-symbol (symbol-name dialect-keyword))))

(defun host-name-symbol-keyword (host-keyword)
  "Render the host keyword as the AutoLISP symbol shown in
*AUTOLISP-HOST*: MOCK, NULL, or nil."
  (and host-keyword
       (intern-autolisp-symbol (symbol-name host-keyword))))

(defun actions-to-autolisp-list (actions)
  "Render the queued ACTIONS — each a (:KIND . PAYLOAD) cons — as
the AutoLISP list shown in *AUTOLISP-ACTIONS*:
  (:FILE . PATH)        → (load \"PATH\")
  (:EXPRESSION . TEXT)  → (eval \"TEXT\")
  (:INTERACTIVE . T)    → (interactive T)
  (:MAIN . FN)          → (main \"FN\")
  (:QUIT . T)           → (quit T)
The symbols and strings are AutoLISP-runtime values; the list is a
plain CL cons chain."
  (loop for action in actions
        for kind = (car action)
        for payload = (cdr action)
        collect (ecase kind
                  (:file
                   (list (intern-autolisp-symbol "LOAD")
                         (make-autolisp-string (string payload))))
                  (:expression
                   (list (intern-autolisp-symbol "EVAL")
                         (make-autolisp-string payload)))
                  (:interactive
                   (list (intern-autolisp-symbol "INTERACTIVE")
                         (intern-autolisp-symbol "T")))
                  (:main
                   (list (intern-autolisp-symbol "MAIN")
                         (make-autolisp-string (string payload))))
                  (:quit
                   (list (intern-autolisp-symbol "QUIT")
                         (intern-autolisp-symbol "T"))))))

(defun cli-options->transmit-bindings (options
                                       &key (backend "CLAUTOLISP")
                                            usage-text version-text)
  "Return the ((NAME-STRING VALUE) …) list of *AUTOLISP-…* bindings
implied by OPTIONS. BACKEND is the tool-identity string published as
*AUTOLISP-BACKEND* (\"CLAUTOLISP\" or \"ALFE\"). USAGE-TEXT is the
--help string published as *AUTOLISP-HELP*; pass nil to publish nil.
VERSION-TEXT becomes *AUTOLISP-VERSION* — required.

*AUTOLISP-VERSION* is the FIRST entry per transmit-options.issue's
remote table convention, so a downstream emit-as-setq-list run-
common.lsp consumer can show the version before any other CLI-
derived value."
  (declare (type cli-options options))
  (list
   ;; *AUTOLISP-VERSION* must come first — transmit-options.issue's
   ;; remote-forwarding table.
   (list "*AUTOLISP-VERSION*"
         (make-autolisp-string (or version-text "0.0.0")))
   (list "*AUTOLISP-BACKEND*"            (intern-autolisp-symbol backend))
   (list "*AUTOLISP-DIALECT*"
         (dialect-name-symbol-keyword (cli-options-dialect options)))
   (list "*AUTOLISP-HOST*"
         (host-name-symbol-keyword (cli-options-host options)))
   (list "*AUTOLISP-MODE*"
         (and (cli-options-mode options)
              (intern-autolisp-symbol (symbol-name (cli-options-mode options)))))
   (list "*AUTOLISP-PROCESS*"
         (and (cli-options-backend-variant options)
              (intern-autolisp-symbol
               (symbol-name (cli-options-backend-variant options)))))
   (list "*AUTOLISP-MOCK-INPUT*"
         (autolisp-string-or-nil (cli-options-mock-input options)))
   (list "*AUTOLISP-GUI-COMMAND*"
         (autolisp-string-or-nil (cli-options-gui options)))
   (list "*AUTOLISP-TRACE*"
         (autolisp-bool (cli-options-trace-p options)))
   (list "*AUTOLISP-FILE-ENCODING*"
         (autolisp-string-or-nil (cli-options-load-encoding options)))
   (list "*AUTOLISP-TERMINAL-ENCODING*"
         (autolisp-string-or-nil (cli-options-io-encoding options)))
   (list "*AUTOLISP-NO-INIT*"
         (autolisp-bool (cli-options-no-init-p options)))
   (list "*AUTOLISP-NO-COLOR*"
         (autolisp-bool (cli-options-no-color-p options)))
   (list "*AUTOLISP-VERBOSE*"
         (autolisp-bool (eq :verbose (cli-options-verbosity options))))
   (list "*AUTOLISP-DEBUG*"
         (autolisp-bool (eq :debug (cli-options-verbosity options))))
   (list "*AUTOLISP-QUIET*"
         (autolisp-bool (eq :warn (cli-options-verbosity options))))
   (list "*AUTOLISP-WILL-QUIT*"
         (autolisp-bool (cli-options-quit-p options)))
   (list "*AUTOLISP-MAIN*"
         (and (cli-options-main options)
              (intern-autolisp-symbol (string-upcase (cli-options-main options)))))
   (list "*AUTOLISP-DRAWING*"
         (autolisp-string-or-nil (cli-options-dwg options)))
   (list "*AUTOLISP-PLUGIN-OPTIONS*"
         (when (cli-options-epure-p options)
           (list (intern-autolisp-symbol "EPURE"))))
   (list "*AUTOLISP-WORKDIR*"
         (autolisp-string-or-nil (cli-options-workdir options)))
   (list "*AUTOLISP-KEEP-WORKDIR*"
         (autolisp-bool (cli-options-keep-workdir-p options)))
   (list "*AUTOLISP-TIMEOUT*"
         (cli-options-timeout options))   ; integer or nil
   (list "*AUTOLISP-DRY-RUN*"
         (autolisp-bool (cli-options-dry-run-p options)))
   (list "*AUTOLISP-ACTIONS*"
         (actions-to-autolisp-list (cli-options-actions options)))
   (list "*AUTOLISP-INTERACTIVE*" nil) ; dynamically T during REPL
   (list "*AUTOLISP-LOAD-PATHNAME*" nil) ; dynamically set during -l
   (list "*AUTOLISP-EXPRESSION*" nil)    ; dynamically set during -x
   (list "*AUTOLISP-HELP*"
         (autolisp-string-or-nil (or usage-text "")))))

(defun install-transmit-variables (context bindings)
  "Intern each binding's name as an AutoLISP symbol and set it to
the binding's value in CONTEXT. Called once, before the first user
action runs (init files included), so init files can branch on
the values."
  (dolist (binding bindings)
    (let ((name (first binding))
          (value (second binding)))
      (set-variable (intern-autolisp-symbol name) value context))))

(defun call-with-dynamic-transmit-binding (context name value thunk)
  "Set the *AUTOLISP-…* variable NAME to VALUE for the duration of
THUNK, then reset to nil. Used to scope *AUTOLISP-LOAD-PATHNAME*
around each -l action, *AUTOLISP-EXPRESSION* around each -x, and
*AUTOLISP-INTERACTIVE* around the REPL. Reset runs even on
non-local exit so a later reference cannot see stale state from
a failed action."
  (let ((sym (intern-autolisp-symbol name)))
    (unwind-protect
         (progn
           (set-variable sym value context)
           (funcall thunk))
      (set-variable sym nil context))))
