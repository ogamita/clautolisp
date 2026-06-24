;;;; autolisp-front-end/source/cli.lisp
;;;;
;;;; alfe CLI — argument parsing, action sequencing, exit codes.
;;;;
;;;; Specified by ../issues/open/alfe-cli.issue and
;;;; documentation/alfe--specifications.org (sections "Sélection du
;;;; moteur et matrice backend × système", "Variables d'environnement",
;;;; "Phases de bootstrap", "Invariants testés").
;;;;
;;;; The module is split into three logical parts:
;;;;
;;;;   1. PARSE-ARGUMENTS — pure (argv-list → cli-options) parser. No
;;;;      I/O, no side effects, so the FiveAM tests can exercise every
;;;;      branch without subprocess gymnastics.
;;;;
;;;;   2. RESOLVE-BACKEND — applies the spec's defaulting algorithm to
;;;;      a parsed cli-options record. Returns the registered backend
;;;;      instance to drive, or signals ALFE.ERROR:BACKEND-NOT-AVAILABLE
;;;;      / CLI-USAGE-ERROR.
;;;;
;;;;   3. RUN — the entry point bound to the alfe executable. Parses
;;;;      argv, builds the action plan, instantiates the backend, runs
;;;;      EVAL-PLAN, and returns an exit code. Handles --help /
;;;;      --version short-circuits and --dry-run.
;;;;
;;;; This file lands the *full* option grammar from the spec, but the
;;;; backend it drives by default in Phase 0 is the echo backend (no
;;;; real evaluator yet). Phase 1 swaps in the clautolisp backend; the
;;;; CLI itself does not change.

(defpackage #:alfe.cli
  (:use #:cl)
  (:import-from #:alfe.backend
                #:find-backend
                #:list-backends
                #:detect
                #:prepare-workdir
                #:start-engine
                #:eval-plan
                #:shutdown
                #:cleanup-workdir
                #:make-action
                #:action-kind
                #:action-payload
                #:action-load
                #:action-eval
                #:action-main
                #:action-interactive
                #:action-quit
                #:eval-result-status
                #:eval-result-value
                #:eval-result-output
                #:eval-result-error-output
                #:eval-result-condition)
  (:import-from #:alfe.error
                #:backend-error
                #:backend-not-available
                #:backend-eval-error
                #:cli-usage-error
                #:exit-code-for-condition)
  (:import-from #:alfe.logging
                #:set-level
                #:log-debug
                #:log-verbose
                #:log-info)
  (:import-from #:clautolisp.autolisp-init-files
                #:*default-alfe-stems*
                #:find-init-files
                #:no-init-requested-p)
  ;; CLI parsing + cli-options struct + value parsers are owned by
  ;; clautolisp.autolisp-cli (single source of truth shared with the
  ;; clautolisp CLI). alfe re-exports the struct and its accessors
  ;; under their original names so the existing FiveAM tests keep
  ;; importing them from alfe.cli unchanged. alfe layers its own
  ;; option-specs (--mode/--backend/--dwg/--epure/--workdir/…) onto
  ;; *common-option-specs* and post-translates the parsed action
  ;; conses into alfe.backend action objects.
  (:import-from #:clautolisp.autolisp-cli
                #:cli-options
                #:make-cli-options
                #:copy-cli-options
                #:cli-options-backend
                #:cli-options-mode
                #:cli-options-backend-variant
                #:cli-options-actions
                #:cli-options-interactive-p
                #:cli-options-quit-p
                #:cli-options-host
                #:cli-options-dialect
                #:cli-options-load-encoding
                #:cli-options-io-encoding
                #:cli-options-dwg
                #:cli-options-epure-p
                #:cli-options-bootstrap-phase
                #:cli-options-verbosity
                #:cli-options-workdir
                #:cli-options-timeout
                #:cli-options-help-p
                #:cli-options-version-p
                #:cli-options-list-encodings-p
                #:cli-options-dry-run-p
                #:cli-options-no-init-p
                #:cli-options-no-color-p
                #:cli-options-keep-workdir-p
                #:cli-options-main
                #:cli-options-positional
                #:make-option-spec
                #:*common-option-specs*
                #:parse-arguments-with-spec
                #:parse-mode
                #:parse-backend-symbol
                #:parse-backend-variant
                #:parse-host
                #:parse-dialect
                #:parse-bootstrap-phase
                #:parse-timeout)
  (:export ;; public entry point
           #:run
           ;; option record + parser (re-exported from clautolisp.autolisp-cli)
           #:cli-options
           #:make-cli-options
           #:parse-arguments
           #:cli-options-backend
           #:cli-options-mode
           #:cli-options-backend-variant
           #:cli-options-actions
           #:cli-options-interactive-p
           #:cli-options-quit-p
           #:cli-options-host
           #:cli-options-dialect
           #:cli-options-load-encoding
           #:cli-options-io-encoding
           #:cli-options-dwg
           #:cli-options-epure-p
           #:cli-options-bootstrap-phase
           #:cli-options-verbosity
           #:cli-options-workdir
           #:cli-options-timeout
           #:cli-options-help-p
           #:cli-options-version-p
           #:cli-options-list-encodings-p
           #:cli-options-dry-run-p
           #:cli-options-no-init-p
           #:cli-options-no-color-p
           #:cli-options-keep-workdir-p
           #:cli-options-main
           #:cli-options-positional
           ;; usage + version (so the executable's main can re-use)
           #:print-usage
           #:usage-string
           #:print-version
           ;; env-var resolution helpers, exported for tests
           #:env-default
           ;; resolution
           #:resolve-backend
           #:plan-from-options
           ;; transmit-options bridge
           #:cli-options-transmit-bindings-for-alfe))

(in-package #:alfe.cli)

;;; --- options record --------------------------------------------------
;;;
;;; The CLI-OPTIONS struct lives in clautolisp.autolisp-cli (the
;;; single source of truth shared with the clautolisp CLI). alfe
;;; consumes its accessors via the import-from clause above and
;;; re-exports them under their original names for backwards
;;; compatibility with the existing FiveAM tests.

;;; --- environment-variable resolution --------------------------------
;;;
;;; The spec lists an extensive env-var surface. We keep the mapping
;;; in a single alist so the test suite can iterate over it and assert
;;; that every documented var resolves to a default.

(defparameter +env-defaults+
  '((:workdir          . "AUTOLISP_WORKDIR")
    (:timeout          . "AUTOLISP_WAIT_SECS")
    (:mode             . "AUTOLISP_MODE")
    (:backend          . "AUTOLISP_BACKEND")
    (:os               . "AUTOLISP_OS")
    (:bootstrap-phase  . "AUTOLISP_BOOTSTRAP_PHASE")
    (:remote-io-mode   . "AUTOLISP_REMOTE_IO_MODE")
    (:dwg              . "AUTOLISP_DWG")
    (:epure            . "AUTOLISP_EPURE")
    (:autocad-install  . "AUTOCAD_INSTALL")
    (:autocad-version  . "AUTOCAD_VERSION")
    (:bricscad-install . "BRICSCAD_INSTALL")
    (:bricscad-version . "BRICSCAD_VERSION")
    (:keep-workdir     . "AUTOLISP_KEEP_WORKDIR")
    (:override         . "ALFE_BACKEND_OVERRIDE"))
  "Mapping from logical option key to the environment variable name
documented in the spec. The CLI consults this table before consuming
argv so that any option not set on the command line falls back to its
env default. The test suite asserts the table is exhaustive.")

(defun env-default (key)
  "Return the current process-environment value for the env var bound
to KEY (a keyword in +env-defaults+), or NIL if unset / empty. Signals
when KEY is not in the mapping table — typoed lookups are bugs."
  (let ((entry (assoc key +env-defaults+)))
    (unless entry
      (error "Unknown env-default key ~S; expected one of ~S"
             key (mapcar #'car +env-defaults+)))
    (let ((value (uiop:getenv (cdr entry))))
      (and value (plusp (length value)) value))))

;;; --- usage banner ---------------------------------------------------

(defparameter *usage-banner*
  "Usage: alfe [options] [FILE.lsp]

Backend selection (mutually exclusive):
  --clautolisp           Default. Drive clautolisp (in-process or subprocess).
  --bricscad             Drive BricsCAD via the file-IPC protocol.
  --autocad              Drive AutoCAD via the file-IPC protocol.

Mode and variant:
  --mode {auto,automation,batch}    How to launch the engine (default: auto).
  --backend {attach,launch}         Attach to a running CAD or launch a fresh one.

Actions (processed in order):
  -l, --load FILE        Load and evaluate FILE.
  -x, --eval EXPR        Evaluate EXPR.
  --main FN              Call FN as the script entry point after loading.
  -i, --interactive      Drop into a REPL after the action queue.
  --quit                 Force the engine to shut down after the queue.

Dialect, host, encoding:
  --dialect NAME         strict (default), autocad-2026, bricscad-v26, clautolisp.
  --host {mock,null}     HAL backend (clautolisp only).
  -e ENC                 Load encoding for -l files.
  -E ENC                 I/O encoding for the engine's stdin/stdout.

CAD-specific options:
  --dwg FILE             Drawing to open before running the script.
  --epure                Enable the EPURE plugin hook.

Bootstrap and runtime:
  --bootstrap-phase {marker,core,log,full}   Truncate the bootstrap.
  --workdir DIR          Override $AUTOLISP_WORKDIR.
  --timeout SECS         Per-action timeout.
  --no-init, -norc       Skip user init files (~/.alfe{,rc}, ~/.autolisp{,rc},
                         ~/.config/alfe/init, ~/.config/autolisp/init).
                         Mirrors $AUTOLISP_NO_INIT and $ALFE_NO_INIT.
  --no-color             Disable ANSI colour in AutoLISP value output. Honoured
                         equivalently via $NO_COLOR (https://no-color.org).
                         Without it, the runtime probes the terminal background
                         and picks a contrasting accent (yellow on dark,
                         blue on light).
  --keep-workdir         Keep the engine workdir at end of run (do not delete).
                         Mirrors $AUTOLISP_KEEP_WORKDIR.
  --dry-run              Print the resolved action plan and exit 0.

Diagnostics:
  -v, --verbose          Verbose progress.
  -q, --quiet            Suppress non-error output.
  -d, --debug            Debug traces (implies --verbose).
                         The three flags compose additively and are
                         commutative: among --quiet/--verbose/--debug,
                         the most verbose request wins regardless of
                         CLI argument order.

Informational:
  -h, --help             Show this help and exit.
  -V, --version          Print version and exit.
  --list-encodings       Print every encoding name accepted by -e / -E and exit.
                         Encoding names are case-insensitive on the CLI.
")

(defun print-usage (&optional (stream *standard-output*))
  (write-string *usage-banner* stream)
  (finish-output stream))

(defun usage-string ()
  "Return the --help banner as a string. Used to populate the
*AUTOLISP-HELP* AutoLISP global via the transmit-options pipeline,
so user code can call (princ *AUTOLISP-HELP*) to redisplay the
front-end's --help text."
  (with-output-to-string (s)
    (print-usage s)))

(defun print-version (version-string &optional (stream *standard-output*))
  (format stream "~&alfe ~A~%" version-string)
  (finish-output stream))

;;; --- env-default seeding -------------------------------------------

(defun apply-env-defaults (options)
  "Pre-populate OPTIONS from environment variables. Called *before*
argument parsing so explicit CLI options always win."
  (let ((env-workdir (env-default :workdir))
        (env-timeout (env-default :timeout))
        (env-mode    (env-default :mode))
        (env-backend (env-default :backend))
        (env-bootstrap (env-default :bootstrap-phase))
        (env-dwg     (env-default :dwg))
        (env-epure   (env-default :epure))
        (env-keep-workdir (env-default :keep-workdir)))
    (when env-workdir
      (setf (cli-options-workdir options) env-workdir))
    (when env-timeout
      (setf (cli-options-timeout options)
            (or (parse-integer env-timeout :junk-allowed t)
                (error 'cli-usage-error
                       :option "AUTOLISP_WAIT_SECS"
                       :message
                       (format nil "AUTOLISP_WAIT_SECS=~A is not an integer"
                               env-timeout)))))
    (when env-mode
      (setf (cli-options-mode options) (parse-mode env-mode "AUTOLISP_MODE")))
    (when env-backend
      (setf (cli-options-backend options)
            (parse-backend-symbol env-backend "AUTOLISP_BACKEND")))
    (when env-bootstrap
      (setf (cli-options-bootstrap-phase options)
            (parse-bootstrap-phase env-bootstrap "AUTOLISP_BOOTSTRAP_PHASE")))
    (when env-dwg
      (setf (cli-options-dwg options) env-dwg))
    (when env-epure
      (setf (cli-options-epure-p options) t))
    (when env-keep-workdir
      (setf (cli-options-keep-workdir-p options) t)))
  options)

;; PARSE-MODE, PARSE-BACKEND-SYMBOL, PARSE-BACKEND-VARIANT,
;; PARSE-HOST, PARSE-DIALECT, PARSE-BOOTSTRAP-PHASE, PARSE-TIMEOUT
;; live in clautolisp.autolisp-cli and are imported above. They are
;; pure value-string → keyword mappers and don't depend on any alfe
;; type — moved out so the clautolisp CLI shares the same vocabulary
;; verbatim.

;;; --- alfe-specific option specs + parse-arguments -------------------

(defun %set-backend-checked (opts kind option-name)
  "Set the cli-options backend slot to KIND, signalling cli-usage-error
if a different backend was already requested. Matches the legacy
parser's mutual-exclusion semantics for --bricscad/--autocad/
--clautolisp combinations."
  (when (and (cli-options-backend opts)
             (not (eql (cli-options-backend opts) kind)))
    (error 'cli-usage-error
           :option option-name
           :message (format nil "Conflicting backend selectors (~S vs ~S)"
                            (cli-options-backend opts) kind)))
  (setf (cli-options-backend opts) kind))

(defun %make-alfe-option-specs ()
  "Build the alfe-only option-spec list: --mode/--backend/--dwg/
--epure/--workdir/--keep-workdir/--timeout/--bootstrap-phase/
--dry-run/--main/--quit. Also wraps the common dialect-shorthand
specs (--autocad/--bricscad/--clautolisp) with conflict-checking
handlers so a `--bricscad --autocad` invocation signals cli-usage-
error rather than silently last-winning."
  (list
   ;; Backend selectors — override the common versions with
   ;; conflict-checking wrappers. They go first so the parser's
   ;; first-match-wins lookup picks them up.
   (make-option-spec
    :longs '("--clautolisp") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
               (setf (cli-options-dialect opts) :clautolisp)
               (%set-backend-checked opts :clautolisp name)))
   (make-option-spec
    :longs '("--autocad") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
               (setf (cli-options-dialect opts) :autocad-2026)
               (%set-backend-checked opts :autocad name)))
   (make-option-spec
    :longs '("--bricscad") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
               (setf (cli-options-dialect opts) :bricscad-v26)
               (%set-backend-checked opts :bricscad name)))
   (make-option-spec
    :longs '("--mode") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-mode opts) (parse-mode value name))))
   (make-option-spec
    :longs '("--backend") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-backend-variant opts)
                     (parse-backend-variant value name))))
   (make-option-spec
    :longs '("--main") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-main opts) value
                     (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :main value))))))
   (make-option-spec
    :longs '("--quit") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-quit-p opts) t
                     (cli-options-actions opts)
                     (append (cli-options-actions opts)
                             (list (cons :quit t))))))
   (make-option-spec
    :longs '("--dwg") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-dwg opts) value)))
   (make-option-spec
    :longs '("--epure") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-epure-p opts) t)))
   (make-option-spec
    :longs '("--bootstrap-phase") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-bootstrap-phase opts)
                     (parse-bootstrap-phase value name))))
   (make-option-spec
    :longs '("--workdir") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-workdir opts) value)))
   (make-option-spec
    :longs '("--timeout") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-timeout opts)
                     (parse-timeout value name))))
   (make-option-spec
    :longs '("--dry-run") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-dry-run-p opts) t)))
   (make-option-spec
    :longs '("--keep-workdir") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-keep-workdir-p opts) t)))))

(defparameter *alfe-option-specs* (%make-alfe-option-specs))

(defun %translate-action-cons (cons load-encoding)
  "Convert one (:KIND . PAYLOAD) cons produced by the shared parser
into the alfe.backend action object the rest of alfe consumes."
  (ecase (car cons)
    (:file        (action-load (cdr cons) :encoding load-encoding))
    (:expression  (action-eval (cdr cons)))
    (:interactive (action-interactive))
    (:main        (action-main (cdr cons)))
    (:quit        (action-quit))))

(defun parse-arguments (argv)
  "Parse ARGV (a list of strings, *without* the program name) into a
CLI-OPTIONS record. Pure: no I/O, no calls into the registry. The
caller can inspect the result, validate it (RESOLVE-BACKEND), or
build the action plan (PLAN-FROM-OPTIONS).

Internally delegates to clautolisp.autolisp-cli's spec-driven
parser with the union of *common-option-specs* + *alfe-option-specs*.
Post-translation steps fold env-var defaults in and rewrite the
action conses produced by the shared parser into alfe.backend
action objects so the rest of alfe (PLAN-FROM-OPTIONS, EVAL-PLAN,
etc.) sees the legacy shape. The transmit-options installer reads
through CLI-OPTIONS->TRANSMIT-BINDINGS-FOR-ALFE which translates
the action objects back to conses on the fly."
  (let* ((options (make-cli-options)))
    (apply-env-defaults options)
    (parse-arguments-with-spec
     (append *alfe-option-specs* *common-option-specs*)
     argv
     :initial-options options)
    (setf (cli-options-actions options)
          (mapcar (lambda (a)
                    (%translate-action-cons
                     a (cli-options-load-encoding options)))
                  (cli-options-actions options)))
    options))

(defun %action-object-to-cons (action)
  "Inverse of %TRANSLATE-ACTION-CONS. Used by
CLI-OPTIONS->TRANSMIT-BINDINGS-FOR-ALFE to render the actions
slot in the shared parser's cons format so the runtime installer
(which doesn't know about alfe.backend) can render it as the
*AUTOLISP-ACTIONS* AutoLISP value."
  (ecase (action-kind action)
    (:load        (cons :file (getf (action-payload action) :path)))
    (:eval        (cons :expression (action-payload action)))
    (:interactive (cons :interactive t))
    (:main        (cons :main (action-payload action)))
    (:quit        (cons :quit t))))

(defun cli-options-transmit-bindings-for-alfe (options
                                               &key backend
                                                    (frontend "ALFE")
                                                    usage-text
                                                    version-text)
  "Wrap CLI-OPTIONS->TRANSMIT-BINDINGS so alfe's action-object
actions slot is rendered as the cons format the shared installer
expects. Returns the ((NAME-STRING VALUE) …) bindings list.

BACKEND is the engine identity (\"CLAUTOLISP\" / \"BRICSCAD\" /
\"AUTOCAD\") — what *AUTOLISP-BACKEND* will hold on the remote side.
FRONTEND is the tool identity (\"ALFE\") — what *AUTOLISP-FRONTEND*
will hold; alfe is the front-end driving the engine, so we default
it here. USAGE-TEXT becomes *AUTOLISP-HELP*."
  (let ((normalised (copy-cli-options options)))
    (setf (cli-options-actions normalised)
          (mapcar #'%action-object-to-cons (cli-options-actions options)))
    (clautolisp.autolisp-cli:cli-options->transmit-bindings
     normalised
     :backend backend
     :frontend frontend
     :usage-text usage-text
     :version-text version-text)))

;; STARTS-WITH-DOUBLE-DASH-P, SPLIT-LONG-OPTION, POP-REQUIRED,
;; OPTION-VALUE, CONSUME-LONG-OPTION moved into the shared parser
;; (clautolisp.autolisp-cli, source/parser.lisp). The shared parser
;; handles the long-option = sugar and short-option dispatch
;; uniformly across both tools.

;;; --- backend resolution ---------------------------------------------

(defun resolve-backend (options &key (detect-p t))
  "Apply the spec's backend-defaulting algorithm to OPTIONS. Returns
the registered backend instance to drive.

Algorithm (matches spec section \"Algorithme par défaut\"):
  1. Explicit --bricscad / --autocad / --clautolisp wins.
  2. Otherwise, $ALFE_BACKEND_OVERRIDE supplies a default for early
     adopters.
  3. Otherwise, $AUTOLISP_BACKEND supplies the legacy default.
  4. Otherwise, the default is :clautolisp — the in-process engine
     that ships with alfe and is available on every system. CAD
     backends are NEVER auto-selected: they require explicit
     --autocad / --bricscad (a host with both BricsCAD and
     AutoCAD installed got surprising and order-dependent results
     from the historical auto-detect; with this rule, `alfe` with
     no flags always means \"talk to the in-process clautolisp
     engine\").
  5. If the :clautolisp backend itself isn't registered (a
     stripped-down test image), the first registered backend
     wins; if there are none, signal BACKEND-NOT-AVAILABLE.

DETECT-P, when NIL, skips the DETECT call on the selected backend
— used by --dry-run, which prints the action plan but never
actually launches an engine. With DETECT-P NIL the function
returns the registered instance unconditionally. Without this
knob a host that doesn't have BricsCAD or AutoCAD installed would
fail `alfe --bricscad --dry-run -x \"(+ 1 2)\"` with exit 3 even
though no engine is actually needed — caught by the matching
conformance scenarios under tests/scenarios/{bricscad,cli}/."
  (let* ((selected (or (cli-options-backend options)
                       (let ((override (env-default :override)))
                         (when override
                           (parse-backend-symbol
                            override "$ALFE_BACKEND_OVERRIDE")))
                       ;; Default — no auto-detection of CADs.
                       ;; The :clautolisp engine ships with alfe and
                       ;; is always available; CADs need explicit
                       ;; opt-in via --autocad / --bricscad. If the
                       ;; :clautolisp key isn't registered (test
                       ;; image rebound *backends* to an echo-only
                       ;; map), fall back to the first registered
                       ;; backend below.
                       (when (find :clautolisp (list-backends))
                         :clautolisp))))
    (log-debug "resolve-backend: selected ~S (source: ~A)"
               selected
               (cond ((cli-options-backend options) "explicit flag")
                     ((env-default :override)        "$ALFE_BACKEND_OVERRIDE")
                     (t                               "default :clautolisp")))
    (when selected
      (let ((backend (find-backend selected)))
        (unless backend
          (error 'backend-not-available
                 :backend selected
                 :message (format nil "Backend ~S is not registered."
                                  selected)))
        ;; When --backend subprocess is in play and the selected
        ;; backend is the clautolisp one, swap in a fresh instance
        ;; tagged with the requested variant. The registered backend
        ;; is the :direct default; we don't mutate it.
        (let ((variant (cli-options-backend-variant options)))
          (when (and (eq selected :clautolisp)
                     (member variant '(:subprocess :direct)))
            (when (find-symbol "MAKE-CLAUTOLISP-BACKEND"
                               '#:alfe.backend.clautolisp)
              (log-debug "resolve-backend: clautolisp variant = ~S" variant)
              (setf backend
                    (funcall (find-symbol "MAKE-CLAUTOLISP-BACKEND"
                                          '#:alfe.backend.clautolisp)
                             :variant variant)))))
        (return-from resolve-backend
          (if detect-p (detect backend) backend))))
    ;; Stripped-down test image: :clautolisp wasn't registered,
    ;; nothing else explicit chosen. Fall back to the first
    ;; registered backend (the FiveAM test image rebinds *backends*
    ;; to an echo-only map and expects the auto-resolver to pick
    ;; echo here).
    (let ((all (list-backends)))
      (dolist (key all)
        (let ((backend (find-backend key)))
          (cond
            (detect-p
             (handler-case
                 (return-from resolve-backend (detect backend))
               (backend-not-available () nil)))
            (t
             (return-from resolve-backend backend))))))
    (error 'backend-not-available
           :message "No backend registered.")))

;;; --- action plan ----------------------------------------------------

(defun plan-from-options (options)
  "Return the ordered action plan from OPTIONS. PURE — does not
touch the filesystem.

The CLI-supplied actions (-l / -x / --main / positional) run in
command-line order. A synthetic terminator is appended depending
on what the user expressed:

  * The user explicitly requested -i / :interactive → no terminator;
    the backend will hand control to its REPL once the queue drains.
  * The user explicitly requested --quit / :quit → no terminator;
    their :quit already terminates the queue.
  * The user supplied content actions (-l / -x / --main / positional)
    but neither -i nor --quit → append :quit so the backend exits
    cleanly after the last action (batch mode, current behaviour).
  * The user supplied no content actions at all (e.g. plain `alfe')
    → append :interactive. Per command-line-option-ammendment.issue,
    `alfe' alone drops into the REPL the same way `clautolisp' does,
    because the init-file loads in EFFECTIVE-PLAN are machinery,
    not user intent.

This function is a pure transformation of OPTIONS; tests can
inspect it without worrying about user init files on the test
host. The init-file prepending lives in EFFECTIVE-PLAN below — it
walks the filesystem, so only the live run path + the dry-run
renderer go through it."
  (let* ((actions (copy-list (cli-options-actions options)))
         (has-content
           (some (lambda (a) (member (action-kind a) '(:load :eval :main)))
                 actions))
         (has-interactive
           (or (cli-options-interactive-p options)
               (some (lambda (a) (eq (action-kind a) :interactive)) actions)))
         (has-quit
           (or (cli-options-quit-p options)
               (some (lambda (a) (eq (action-kind a) :quit)) actions))))
    (cond
      ;; User explicitly asked for REPL or quit — keep queue as-is.
      ((or has-interactive has-quit) actions)
      ;; User has content actions but neither -i nor --quit —
      ;; append :quit so the backend exits after the last action
      ;; (batch mode).
      (has-content (append actions (list (action-quit))))
      ;; No user actions of any kind — implicit -i: drop into REPL.
      (t (append actions (list (action-interactive)))))))

(defun resolve-init-file-actions (options)
  "Walk the alfe init-file stems and return a list of (:load PATH)
actions, one per existing file in stem-list order. Returns NIL
when --no-init is set OR $AUTOLISP_NO_INIT / $ALFE_NO_INIT gate
the lookup."
  (when (no-init-requested-p (cli-options-no-init-p options)
                             "ALFE_NO_INIT")
    (return-from resolve-init-file-actions nil))
  (loop for path in (find-init-files *default-alfe-stems*)
        collect (action-load (namestring path)
                             :encoding (cli-options-load-encoding options))))

(defun effective-plan (options)
  "Return the action plan that will actually be handed to the
backend: init-file loads first (when the lookup is not gated),
then PLAN-FROM-OPTIONS. Touches the filesystem (via
RESOLVE-INIT-FILE-ACTIONS); intended for the live run path and
the dry-run renderer."
  (append (resolve-init-file-actions options)
          (plan-from-options options)))

;;; --- dry-run renderer ----------------------------------------------

(defun render-action (action)
  (let ((kind (action-kind action))
        (payload (action-payload action)))
    (case kind
      (:load        (format nil "load ~S" (getf payload :path)))
      (:eval        (format nil "eval ~S" payload))
      (:main        (format nil "main ~A" payload))
      (:interactive "interactive")
      (:quit        "quit"))))

(defun emit-dry-run (options backend &optional (stream *standard-output*))
  (format stream "~&alfe --dry-run~%")
  (format stream "  backend:   ~A~%" (alfe.backend:backend-name backend))
  (format stream "  dialect:   ~A~%" (cli-options-dialect options))
  (format stream "  host:      ~A~%" (cli-options-host options))
  (format stream "  mode:      ~A~%" (cli-options-mode options))
  (format stream "  workdir:   ~A~%" (or (cli-options-workdir options) "<auto>"))
  (format stream "  actions:~%")
  (dolist (action (effective-plan options))
    (format stream "    - ~A~%" (render-action action)))
  (finish-output stream))

;;; --- top-level RUN --------------------------------------------------

(defun run (argv &key version)
  "alfe entry point. ARGV is the argument list *without* the program
name; VERSION is the version string printed by --version. Returns an
integer exit code; the executable's MAIN wraps this and calls UIOP:QUIT
with the result.

The handler chain matches alfe-cli.issue's exit-code table:
  0 — success
  1 — user script reported failure (or unexpected condition)
  2 — CLI-USAGE-ERROR
  3 — BACKEND-NOT-AVAILABLE
  4 — BACKEND-BOOTSTRAP-ERROR / BACKEND-PROTOCOL-ERROR"
  (handler-case
      (let ((options (parse-arguments argv)))
        (cond
          ((cli-options-help-p options)
           (print-usage)
           0)
          ((cli-options-version-p options)
           (print-version (or version "0.0.0"))
           0)
          ((cli-options-list-encodings-p options)
           (clautolisp.autolisp-cli:print-encodings)
           0)
          (t
           (set-level (cli-options-verbosity options))
           ;; Once the log level is set, dump the resolved option
           ;; surface at :debug so a `--debug` run shows what the
           ;; parser decided. Mirrors the bash autolisp script's
           ;; startup "[DEBUG] OS=…" dump.
           (log-debug "cli: version ~A" (or version "0.0.0"))
           (log-debug "cli: backend ~S, dialect ~S, host ~S, mode ~S"
                      (cli-options-backend options)
                      (cli-options-dialect options)
                      (cli-options-host options)
                      (cli-options-mode options))
           (log-debug "cli: load-encoding ~S, io-encoding ~S, no-color-p ~A"
                      (cli-options-load-encoding options)
                      (cli-options-io-encoding options)
                      (cli-options-no-color-p options))
           (log-debug "cli: actions = ~D"
                      (length (cli-options-actions options)))
           ;; Colour policy is computed once, against *standard-output*
           ;; as it stood when the CLI started, and bound for the
           ;; duration of the run. The binding covers both the
           ;; in-process clautolisp backend (which prints AutoLISP
           ;; values directly from this process and therefore sees
           ;; *COLOR-OUTPUT*) and the dry-run renderer below. For
           ;; subprocess backends the runtime in the child does its
           ;; own probe; we additionally export $NO_COLOR=1 to the
           ;; child env when the parent's policy is off, so the
           ;; child's probe agrees with the parent.
           (let* ((color-policy
                    (clautolisp.autolisp-runtime:resolve-color-policy
                     :no-color-flag (cli-options-no-color-p options))))
             (when (and (null color-policy)
                        (or (cli-options-no-color-p options)
                            (clautolisp.autolisp-runtime:env-no-color-set-p)))
               ;; Make the off-policy explicit to any subprocess —
               ;; child can't observe our --no-color flag directly.
               (setf (uiop:getenv "NO_COLOR") "1"))
             (let ((clautolisp.autolisp-runtime:*color-output* color-policy))
               ;; --dry-run resolves the backend by *name* only (no
               ;; engine probe), so an `alfe --bricscad --dry-run …`
               ;; invocation on a host without BricsCAD still prints
               ;; the action plan and exits 0 — matching the user
               ;; intent of "show me what would happen" rather than
               ;; "verify the engine works".
               (let ((backend (resolve-backend
                               options
                               :detect-p (not (cli-options-dry-run-p options)))))
                 (cond
                   ((cli-options-dry-run-p options)
                    (emit-dry-run options backend)
                    0)
                   (t
                    (run-plan options backend :version-text version)))))))))
    (cli-usage-error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      2)
    (backend-not-available (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      3)
    (alfe.error:backend-bootstrap-error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      4)
    (alfe.error:backend-protocol-error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      4)
    (backend-eval-error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      1)
    (backend-error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      (exit-code-for-condition condition))
    (error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      1)))

(defun run-plan (options backend &key version-text)
  "Drive a real backend through the action plan. Returns the exit code.
VERSION-TEXT propagates the alfe version string from RUN so backends
can publish it as the *AUTOLISP-VERSION* global of their hosted
engine."
  (log-verbose "cli: load-encoding ~S, io-encoding ~S"
               (cli-options-load-encoding options)
               (cli-options-io-encoding options))
  (let* ((started-at (get-internal-real-time))
         (workdir (prepare-workdir backend
                                   (cli-options-workdir options)))
         (session (start-engine backend workdir
                                :dialect (cli-options-dialect options)
                                :host (cli-options-host options)
                                :mock-input nil
                                :bootstrap-phase
                                (cli-options-bootstrap-phase options)
                                :interactive-p
                                (cli-options-interactive-p options)
                                :mode (cli-options-mode options)
                                :dwg (cli-options-dwg options)
                                :load-encoding
                                (cli-options-load-encoding options)
                                :io-encoding
                                (cli-options-io-encoding options)
                                :cli-options options
                                :version-text version-text)))
    (unwind-protect
         (let* ((plan (effective-plan options)))
           (log-verbose "cli: resolved plan with ~D action~:P" (length plan))
           (loop for action in plan
                 for i from 1
                 do (log-verbose "cli: plan[~D] = ~A"
                                 i (render-action action)))
           (let ((result (eval-plan session plan)))
             ;; The backend contract is: EVAL-PLAN writes live output
             ;; to *STANDARD-OUTPUT* / *ERROR-OUTPUT* during the call,
             ;; AND captures a copy in EVAL-RESULT-{OUTPUT,ERROR-OUTPUT}
             ;; for tests and diagnostics. We do not re-echo the capture
             ;; here — doing so would double-print everything the backend
             ;; already wrote to the live streams. Backends that genuinely
             ;; capture-only (e.g. the file-IPC drivers, which read
             ;; stdout.txt back from disk *after* the engine wrote it)
             ;; are responsible for replaying their own capture to the
             ;; live streams from inside EVAL-PLAN.
             ;;
             ;; We intentionally do NOT auto-print EVAL-RESULT-VALUE
             ;; here. Per the alfe spec ("Action output semantics"),
             ;; `-x EXPR' / `-l FILE' / `--main FN' are not REPL
             ;; steps — they are batch evaluations whose value is
             ;; discarded unless the user wrote an explicit
             ;; (print …) / (princ …) / (prin1 …). That makes alfe
             ;; behave identically across all three backends (the CAD
             ;; backends never had auto-print) and matches AutoLISP's
             ;; convention where only the top-level REPL prints
             ;; values automatically.
             ;;
             ;; Earlier alfe versions did auto-print the value for the
             ;; clautolisp backend ("alfe -x '(+ 1 2)' → 3"); that was
             ;; surprising both because it diverged from the CAD
             ;; backends and because it produced double output when
             ;; the user's expression already printed (e.g.
             ;; "(princ \"hi\")" yielded "hi\"hi\""). The auto-print
             ;; is removed; users who want the value back must wrap
             ;; with (print …).
             (finish-output)
             (finish-output *error-output*)
             (let ((exit-code (ecase (eval-result-status result)
                                (:success  0)
                                (:failed   1)
                                (:aborted  1)))
                   (elapsed (/ (float (- (get-internal-real-time) started-at))
                               internal-time-units-per-second)))
               (log-verbose "cli: plan finished status=~S exit=~D elapsed=~,2Fs"
                            (eval-result-status result) exit-code elapsed)
               exit-code)))
      (ignore-errors (shutdown session :reason :cli-exit))
      (ignore-errors (cleanup-workdir backend workdir
                                      :keep-p (cli-options-keep-workdir-p options))))))
