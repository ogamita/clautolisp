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
                                            (frontend "CLAUTOLISP")
                                            usage-text version-text)
  "Return the ((NAME-STRING VALUE) …) list of *AUTOLISP-…* bindings
implied by OPTIONS.

BACKEND is the *engine* identity published as *AUTOLISP-BACKEND* —
the AutoLISP runtime actually doing the work. One of \"CLAUTOLISP\",
\"BRICSCAD\", \"AUTOCAD\". When the clautolisp tool runs directly,
backend = \"CLAUTOLISP\"; when alfe drives an engine, backend is the
selected backend (clautolisp / bricscad / autocad).

FRONTEND is the *tool* identity published as *AUTOLISP-FRONTEND* —
the user-facing executable. \"CLAUTOLISP\" when clautolisp is the
entry point, \"ALFE\" when alfe is. User code branches on this to
detect which CLI surface it runs under, independently of which
engine answers.

USAGE-TEXT is the --help string published as *AUTOLISP-HELP*; pass
nil to publish nil. VERSION-TEXT becomes *AUTOLISP-VERSION* —
required.

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
   (list "*AUTOLISP-FRONTEND*"           (intern-autolisp-symbol frontend))
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
   ;; *AUTOLISP-FILE-ENCODING* and *AUTOLISP-TERMINAL-ENCODING*
   ;; are never NIL — encoding.issue rule. The two-tier resolve
   ;; consults explicit -e/-E then the host locale. The launch-
   ;; chain spec answer ("US-ASCII when nothing resolves") applies
   ;; to *SYSCODEPAGE* — not to *AUTOLISP-FILE-ENCODING*. Pinning
   ;; *AUTOLISP-FILE-ENCODING* to "US-ASCII" in the no-locale case
   ;; would break LOAD of init files with non-ASCII bytes (e.g.
   ;; UTF-8 content under a runner with LC_ALL unset). The empty-
   ;; string degenerate value lets LOOKUP-AUTOLISP-FILE-ENCODING
   ;; fall through to the dialect default — the 1.0.72 precedence
   ;; chain's documented intent.
   (list "*AUTOLISP-FILE-ENCODING*"
         (make-autolisp-string
          (or (and (cli-options-load-encoding options)
                   (canonical-encoding-name (cli-options-load-encoding options)))
              (resolve-locale-encoding-name)
              "")))
   (list "*AUTOLISP-TERMINAL-ENCODING*"
         (make-autolisp-string
          (resolve-effective-encoding (cli-options-io-encoding options))))
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

(defun %autolisp-string->plain (value)
  "If VALUE is an autolisp-string, return its underlying CL string;
otherwise nil. Helper used during install-transmit-variables to
mirror selected bindings into host-side sysvars."
  (when (and value
             (typep value 'clautolisp.autolisp-runtime:autolisp-string))
    (clautolisp.autolisp-runtime:autolisp-string-value value)))

(defun apply-launch-codepage-to-sysvars (context encoding-string)
  "Push the launch-resolved file encoding into the host's SYSCODEPAGE
and DWGCODEPAGE system variables. Both are documented as read-only,
so this goes through HOST-SET-DERIVED-SYSVAR which bypasses the
cell's read-only flag for the launch-time init step.

Without this, SYSCODEPAGE / DWGCODEPAGE return the catalogue's \"\"
placeholder — the bug spelled out at the top of
issues/closed/encoding-dispatch.issue.

ENCODING-STRING is the value bound to *AUTOLISP-FILE-ENCODING*. An
empty value (the degenerate launch-chain fallback when -e is
absent and the locale env vars are all unset) maps to the spec's
US-ASCII placeholder for SYSCODEPAGE/DWGCODEPAGE — the global
itself stays empty so LOAD's precedence chain can fall through to
the dialect default rather than pinning every source-file LOAD to
strict ASCII.

DWGCODEPAGE defaults to SYSCODEPAGE; when a drawing is later loaded
that carries its own codepage, the host backend overrides
DWGCODEPAGE via HOST-SET-DERIVED-SYSVAR again."
  (when context
    (let* ((effective (if (and encoding-string (plusp (length encoding-string)))
                          encoding-string
                          "US-ASCII"))
           (host
            (clautolisp.autolisp-runtime:current-evaluation-host context)))
      (when host
        (clautolisp.autolisp-host:host-set-derived-sysvar
         host "SYSCODEPAGE" effective)
        (clautolisp.autolisp-host:host-set-derived-sysvar
         host "DWGCODEPAGE" effective)))))

(defun launch-program-name (frontend-name)
  "Return the value to publish as the PROGRAM sysvar (the AutoLISP/
AutoCAD `(getvar \"PROGRAM\")` slot = the running application).

FRONTEND-NAME is the *AUTOLISP-FRONTEND* identity (\"CLAUTOLISP\" /
\"ALFE\"), the user-facing executable — that is precisely what PROGRAM
should report, and unlike argv[0] it survives image dumping. Downcased
to \"clautolisp\" / \"alfe\". Falls back to argv0's basename, then to
\"clautolisp\", if no frontend identity was transmitted."
  (or (and frontend-name (stringp frontend-name) (plusp (length frontend-name))
           (string-downcase frontend-name))
      (let ((argv0 (ignore-errors (uiop:argv0))))
        (and argv0 (stringp argv0) (plusp (length argv0))
             (let ((p (ignore-errors (pathname argv0))))
               (and p (pathname-name p)))))
      "clautolisp"))

(defun apply-clautolisp-host-identity (context version-string frontend-name)
  "Stamp the clautolisp engine's identity onto the host sysvars that
report which CAD program is running, so user code (e.g. a portability
layer) can tell it is running on clautolisp rather than BricsCAD.

The mock host's sysvar catalogue is generated from BricsCAD data, so
PROGRAM / VENDORNAME / PLATFORM / ACADVER would otherwise masquerade
as Bricsys (\"reports BRICSCAD from clautolisp\"). Set once at launch
through HOST-SET-DERIVED-SYSVAR, which bypasses the read-only flag and
silently no-ops on hosts (or sysvar subsets) that lack the cell.

Reached only by the clautolisp engine: alfe's bricscad/autocad
backends drive a real CAD and never call INSTALL-TRANSMIT-VARIABLES on
a local context, so this never clobbers a genuine CAD's identity.
See issues/open/clautolisp-mock-host-getvar.issue."
  (when context
    (let ((host (clautolisp.autolisp-runtime:current-evaluation-host context)))
      (when host
        (clautolisp.autolisp-host:host-set-derived-sysvar
         host "PROGRAM" (launch-program-name frontend-name))
        (clautolisp.autolisp-host:host-set-derived-sysvar
         host "VENDORNAME" "clautolisp")
        (clautolisp.autolisp-host:host-set-derived-sysvar
         host "PLATFORM" "clautolisp")
        (when (and version-string (plusp (length version-string)))
          (clautolisp.autolisp-host:host-set-derived-sysvar
           host "ACADVER" version-string))))))

(defun install-transmit-variables (context bindings)
  "Intern each binding's name as an AutoLISP symbol and set it to
the binding's value in CONTEXT. Called once, before the first user
action runs (init files included), so init files can branch on
the values.

Side effects:
- when the *AUTOLISP-FILE-ENCODING* binding is seen, the same value
  is also pushed into the host's SYSCODEPAGE and DWGCODEPAGE sysvars
  via APPLY-LAUNCH-CODEPAGE-TO-SYSVARS, fixing the historical empty-
  string default for those sysvars;
- the clautolisp engine identity (PROGRAM / VENDORNAME / PLATFORM /
  ACADVER) is stamped onto the host via APPLY-CLAUTOLISP-HOST-IDENTITY
  so a clautolisp host stops reporting itself as BricsCAD;
- the dialect-dependent SECURELOAD / TRUSTEDPATHS defaults (and the
  clautolisp-only trust sysvars) are stamped via
  APPLY-DIALECT-TRUST-DEFAULTS so each dialect launches with its own
  secure-load posture (spec clautolisp-secureload-trust-model)."
  (dolist (binding bindings)
    (let ((name (first binding))
          (value (second binding)))
      (set-variable (intern-autolisp-symbol name) value context)
      (when (string= name "*AUTOLISP-FILE-ENCODING*")
        (apply-launch-codepage-to-sysvars
         context (%autolisp-string->plain value)))))
  (let ((version (let ((entry (assoc "*AUTOLISP-VERSION*" bindings
                                     :test #'string=)))
                   (and entry (%autolisp-string->plain (second entry)))))
        (frontend (let ((entry (assoc "*AUTOLISP-FRONTEND*" bindings
                                      :test #'string=)))
                    (when (and entry (second entry))
                      (clautolisp.autolisp-runtime:autolisp-symbol-name
                       (second entry))))))
    (apply-clautolisp-host-identity context version frontend)
    (apply-dialect-trust-defaults context (transmit-dialect-keyword bindings))
    (apply-dialect-sysvar-defaults context (transmit-dialect-keyword bindings))))

(defun transmit-dialect-keyword (bindings)
  "Recover the dialect keyword (:strict / :autocad-2026 / :bricscad-v26
/ :lax / :clautolisp) from the *AUTOLISP-DIALECT* binding, whose value
is an AutoLISP symbol named after the dialect. Returns :strict when the
binding is absent."
  (let ((entry (assoc "*AUTOLISP-DIALECT*" bindings :test #'string=)))
    (if (and entry (second entry))
        (intern (string-upcase
                 (clautolisp.autolisp-runtime:autolisp-symbol-name
                  (second entry)))
                :keyword)
        :strict)))

(defun apply-dialect-trust-defaults (context dialect-keyword)
  "Apply the dialect-dependent SECURELOAD / TRUSTEDPATHS defaults and
register the clautolisp-only trust sysvars on CONTEXT's host. Delegates
to the trust-model overlay in autolisp-builtins-core. Reached only by
the clautolisp engine (alfe's CAD backends never install transmit
variables on a local context), so this never touches a real CAD's
sysvars."
  (when context
    (let ((host (clautolisp.autolisp-runtime:current-evaluation-host context)))
      (when host
        (clautolisp.autolisp-builtins-core:apply-dialect-trust-sysvar-defaults
         host dialect-keyword)))))

(defun apply-dialect-sysvar-defaults (context dialect-keyword)
  "Apply the dialect-dependent sysvar overlay on CONTEXT's host. For the
bricscad dialect this drops the catalogue sysvars BricsCAD does not
define (the catalogue is AutoCAD-2026-derived), so `clautolisp --bricscad`
reports BricsCAD's sysvar *set* rather than AutoCAD's. Other dialects are
left on the AutoCAD-derived catalogue. Reached only by the clautolisp
engine (alfe's CAD backends never install transmit variables on a local
context), so this never touches a real CAD's sysvars.
See issues/open/bricscad-dialect-sysvar-parity.issue."
  (when context
    (let ((host (clautolisp.autolisp-runtime:current-evaluation-host context)))
      (when (and host (eq dialect-keyword :bricscad-v26))
        (clautolisp.autolisp-mock-host:apply-bricscad-dialect-sysvars host)))))

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
