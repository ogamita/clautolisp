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
                #:cli-options-cad
                #:cli-options-actions
                #:cli-options-interactive-p
                #:cli-options-quit-p
                #:cli-options-host
                #:cli-options-dialect
                #:cli-options-load-encoding
                #:cli-options-io-encoding
                #:cli-options-situation-encodings
                #:cli-situation-encoding
                #:encoding-keyword
                #:cli-options-dwg
                #:cli-options-epure-p
                #:cli-options-bootstrap-phase
                #:cli-options-verbosity
                #:cli-options-workdir
                #:cli-options-timeout
                #:cli-options-help-p
                #:cli-options-version-p
                #:cli-options-list-encodings-p
                #:cli-options-list-dialects-p
                #:cli-options-list-situations-p
                #:cli-options-list-cad-programs-p
                #:cli-options-dry-run-p
                #:cli-options-print-command-p
                #:cli-options-no-init-p
                #:cli-options-no-color-p
                #:cli-options-keep-workdir-p
                #:cli-options-write-workdir-path
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
           #:cli-options-cad
           #:cli-options-actions
           #:cli-options-interactive-p
           #:cli-options-quit-p
           #:cli-options-host
           #:cli-options-dialect
           #:cli-options-load-encoding
           #:cli-options-io-encoding
           #:cli-options-situation-encodings
           #:cli-situation-encoding
           #:terminal-encoding-plan
           #:apply-terminal-encoding
           #:resolved-console-encoding
           #:cli-options-dwg
           #:cli-options-epure-p
           #:cli-options-bootstrap-phase
           #:cli-options-verbosity
           #:cli-options-workdir
           #:cli-options-timeout
           #:cli-options-help-p
           #:cli-options-version-p
           #:cli-options-list-encodings-p
           #:cli-options-list-dialects-p
           #:cli-options-list-situations-p
           #:cli-options-list-cad-programs-p
           #:cli-options-dry-run-p
           #:cli-options-print-command-p
           #:cli-options-no-init-p
           #:cli-options-no-color-p
           #:cli-options-keep-workdir-p
           #:cli-options-write-workdir-path
           #:cli-options-main
           #:cli-options-positional
           ;; usage + version (so the executable's main can re-use)
           #:print-usage
           #:usage-string
           #:print-version
           ;; env-var resolution helpers, exported for tests
           #:env-default
           ;; --print-command: staged-argv rendering (exported for tests)
           #:print-command-plan
           #:format-launch-command
           #:quote-command-argument
           #:shell-quote-argument
           #:windows-quote-argument
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
    (:write-workdir-path . "AUTOLISP_WRITE_WORKDIR_PATH")
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
  --dialect NAME         strict (default), autocad[-mac][-YEAR], autocad-2022,
                         autocad-2026, bricscad[-mac|-linux][-vNN], bricscad-v25,
                         bricscad-v26, clautolisp, lax. Unversioned vendor => last
                         known version; unqualified platform => windows.
                         Honoured under --clautolisp; ignored under --autocad/--bricscad.
  --list-dialects        Print every --dialect name (strict first, lax last) and exit.
  --list-situations      Print the encoding situations (source/file/console/…) and exit.
  --list-cad-programs    Scan the host and print each installed CAD with its
                         canonical denotation (acad-2026, bricscad-v26, …), then exit.
  --cad DENOTATION       Select a specific installed CAD by denotation
                         (acad-2026, accoreconsole-2022, bricscad-v25-fr_FR,
                         or a bare/partial acad / bricscad / autocad → latest;
                         autocad honours --mode: batch→accoreconsole, else acad).
  --host {cador,nihil}   HAL backend, --clautolisp only (mock=cador, null/none=nihil aliases).
  -E ENC                 Encoding for every situation (shorthand).
  -Esource ENC           Encoding of .lsp files loaded (-l and (load ...)).
  -Efile[-read|-write] ENC   Encoding of files the program opens.
  -Econsole[-in|-out] ENC    Encoding of the CAD's GUI console device.
  -Ecadstdio[-in|-out] ENC   Encoding of the CAD subprocess stdio pipes.
  -Elog ENC              Encoding of the CAD log file.
  -Eterminal[-in|-out] ENC   Encoding of this tool's own terminal I/O.
                         (long forms: --SITUATION-encoding /
                          --SITUATION-{input,output,read,write}-encoding;
                          ENC accepts a -mac/-dos/-unix/-lf/-cr/-crlf suffix.)

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
  --write-workdir-path FILE
                         After the workdir is prepared, write its absolute path
                         to FILE (one line). Lets a caller (e.g. a CI script)
                         locate a --keep-workdir workdir without scraping stdout.
                         Mirrors $AUTOLISP_WRITE_WORKDIR_PATH.
  --dry-run              Print the resolved action plan and exit 0.
  --print-command        Stage the workdir exactly as a real run would, print
                         the CAD command line alfe would launch (one shell-ready
                         line on stdout), then exit 0 WITHOUT launching it.
                         Requires --autocad or --bricscad (the clautolisp
                         backend runs in-process and has no command line).
                         The workdir is deleted on the way out unless
                         --keep-workdir is given; running the printed command
                         by hand starts the CAD against the staged workdir, but
                         nothing drives alfe's side of the file-IPC protocol, so
                         the engine will boot and then wait.

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
        (env-keep-workdir (env-default :keep-workdir))
        (env-write-workdir-path (env-default :write-workdir-path)))
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
      (setf (cli-options-keep-workdir-p options) t))
    (when env-write-workdir-path
      (setf (cli-options-write-workdir-path options) env-write-workdir-path)))
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
--epure/--workdir/--keep-workdir/--write-workdir-path/--timeout/
--bootstrap-phase/--dry-run/--main/--quit. Also wraps the common dialect-shorthand
specs (--autocad/--bricscad/--clautolisp) with conflict-checking
handlers so a `--bricscad --autocad` invocation signals cli-usage-
error rather than silently last-winning."
  (list
   ;; Backend selectors — override the common versions with
   ;; conflict-checking wrappers. They go first so the parser's
   ;; first-match-wins lookup picks them up.
   ;; Backend selectors set ONLY the backend; the dialect is resolved
   ;; later by EFFECTIVE-DIALECT (alfe-clautolisp-dialect.issue point 1):
   ;; --clautolisp runs the strict dialect by default and honours an
   ;; explicit --dialect (in any order); --autocad / --bricscad impose
   ;; the CAD's own dialect and ignore --dialect.
   (make-option-spec
    :longs '("--clautolisp") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
               (%set-backend-checked opts :clautolisp name)))
   (make-option-spec
    :longs '("--autocad") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
               (%set-backend-checked opts :autocad name)))
   (make-option-spec
    :longs '("--bricscad") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value))
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
   ;; --list-cad-programs scans the host for installed CADs and prints each
   ;; with its canonical denotation, then exits — same short-circuit shape as
   ;; --list-encodings / --list-dialects (alfe-backend-selection).
   (make-option-spec
    :longs '("--list-cad-programs") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-cad-programs-p opts) t)))
   ;; --cad DENOTATION picks a specific installed CAD by its canonical name
   ;; (acad-2026, bricscad-v25-fr_FR, autocad-2022, …; --list-cad-programs
   ;; enumerates them). The denotation is stored raw and resolved in RUN,
   ;; once --mode is known (autocad → acad/accoreconsole depends on it).
   (make-option-spec
    :longs '("--cad") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-cad opts) value)))
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
    :longs '("--print-command") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-print-command-p opts) t)))
   (make-option-spec
    :longs '("--keep-workdir") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-keep-workdir-p opts) t)))
   (make-option-spec
    :longs '("--write-workdir-path") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-write-workdir-path opts) value)))))

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

;;; --- --print-command ------------------------------------------------
;;;
;;; --print-command stages a run for real (workdir, run-common.lsp,
;;; run.scr / bridge script, …) and prints the CAD command line alfe
;;; WOULD spawn, instead of spawning it. It is the debugging companion
;;; to --dry-run: --dry-run resolves nothing and touches no disk;
;;; --print-command resolves the engine, writes the launch artefacts,
;;; and therefore prints the exact argv, binary path included.
;;;
;;; The printed line goes to *STANDARD-OUTPUT* ALONE (no banner), so
;;; `cmd=$(alfe --print-command --bricscad …)` is usable directly;
;;; everything else is logged at :verbose.

(defparameter +shell-safe-characters+
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_@%+=:,./-"
  "Characters that need no quoting in a POSIX shell word. Deliberately
conservative: anything outside this set sends the argument through
single-quote escaping.")

(defun shell-quote-argument (string)
  "Quote STRING for a POSIX shell (sh/bash). Uses single quotes, with
the standard `'\\''` trick for an embedded single quote, so the result
is safe for any byte sequence."
  (if (and (plusp (length string))
           (every (lambda (char) (find char +shell-safe-characters+)) string))
      string
      (with-output-to-string (out)
        (write-char #\' out)
        (loop for char across string
              do (if (char= char #\')
                     (write-string "'\\''" out)
                     (write-char char out)))
        (write-char #\' out))))

(defun windows-quote-argument (string)
  "Quote STRING for a Windows command line (cmd.exe / PowerShell's
argument mode). Double quotes are the only portable grouping there;
we quote whenever the argument holds whitespace or a shell
metacharacter, and escape an embedded double quote as \\\"."
  (if (and (plusp (length string))
           (notany (lambda (char)
                     (or (member char '(#\Space #\Tab #\Newline))
                         (find char "&|<>^\"'`,;=()%!")))
                   string))
      string
      (with-output-to-string (out)
        (write-char #\" out)
        (loop for char across string
              do (when (char= char #\") (write-char #\\ out))
                 (write-char char out))
        (write-char #\" out))))

(defun quote-command-argument (string &optional os)
  "Quote STRING for OS's shell (:WINDOWS → cmd rules, anything else →
POSIX rules). OS defaults to the host OS as ALFE.BACKEND.CAD-COMMON
sees it — resolved at call time because that package loads after this
file, and because the test suite overrides it."
  (let ((os (or os (uiop:symbol-call :alfe.backend.cad-common :host-os))))
    (if (eq os :windows)
        (windows-quote-argument string)
        (shell-quote-argument string))))

(defun format-launch-command (argv &optional os)
  "Render ARGV (binary in CAR) as one shell-ready command line, each
element quoted for OS. This is what --print-command writes to stdout."
  (format nil "~{~A~^ ~}"
          (mapcar (lambda (argument) (quote-command-argument argument os))
                  argv)))

;;; --- top-level RUN --------------------------------------------------

;;; --- G1: apply the `terminal` situation encoding to alfe's OWN streams ---
;;;
;;; -Eterminal[-in|-out] declares the encoding of alfe's own REPL / batch I/O
;;; with the user. Until now the value was published to AutoLISP code as
;;; *AUTOLISP-TERMINAL-ENCODING* but never applied to this process's
;;; *standard-output* / *standard-input*, so the flag was inert (the streams
;;; kept SBCL's locale default). G1 makes it real: when — and ONLY when — a
;;; terminal encoding is explicitly requested, rebind alfe's standard streams
;;; to fresh fd-streams in that encoding. Unset ⇒ nothing changes (the
;;; behaviour-preserving default the phased plan requires).

(defun terminal-encoding-plan (options)
  "The stream reconfiguration the resolved `terminal` encoding implies for
alfe's OWN standard streams, as a list of (KEY FD DIRECTION EXTERNAL-FORMAT)
entries — KEY one of :OUTPUT / :ERROR / :INPUT, FD the OS descriptor,
EXTERNAL-FORMAT a CL keyword. NIL when -Eterminal was not given. The bare
-Eterminal sets both directions; -Eterminal-out drives stdout+stderr,
-Eterminal-in drives stdin. Pure — so tests assert what a CLI would
reconfigure without touching real process streams. The line-ending suffix is
accepted-and-ignored here (terminal I/O is line-buffered), matching the
--list-encodings note."
  (let ((out (cli-situation-encoding options "terminal" "out"))
        (in  (cli-situation-encoding options "terminal" "in")))
    (nconc
     (when out
       (let ((ext (encoding-keyword out)))
         (list (list :output 1 :output ext)
               (list :error  2 :output ext))))
     (when in
       (list (list :input 0 :input (encoding-keyword in)))))))

(defun %make-terminal-fd-stream (fd direction external-format)
  "A fresh stream over OS descriptor FD with EXTERNAL-FORMAT (DIRECTION is
:INPUT or :OUTPUT), or NIL when the host CL cannot reliably build one; the
caller then warns and keeps the host default rather than failing.

Wired on POSIX SBCL only. On Windows we deliberately return NIL: reopening
an inherited console descriptor *by number* with SB-SYS:MAKE-FD-STREAM
succeeds, but the first write can fail with EBADF (`Descripteur non valide')
under a non-console CI/msys shell — and that write happens later, in user
code, past the caller's HANDLER-CASE, so it would abort the whole run
instead of degrading. Proper Windows terminal-encoding needs the console
API (SetConsoleOutputCP/CP_UTF8), not fd reopening; until then -Eterminal
warns-and-keeps-default on Windows. See windows-terminal-encoding-fd-stream
.issue."
  (declare (ignorable fd direction external-format))
  #+(and sbcl (not win32))
  (sb-sys:make-fd-stream fd
                         :input  (eq direction :input)
                         :output (eq direction :output)
                         :external-format external-format
                         :buffering (if (eq direction :output) :line :full)
                         :name "alfe terminal")
  #-(and sbcl (not win32))
  nil)

(defun apply-terminal-encoding (options)
  "G1 side effect: reconfigure alfe's own *standard-output* / *error-output*
/ *standard-input* per TERMINAL-ENCODING-PLAN. A no-op when -Eterminal was
not given. Any failure (unsupported host CL, un-reopenable fd) degrades to a
warning — it must never abort the run, and the un-reconfigured stream simply
keeps the locale default."
  (dolist (entry (terminal-encoding-plan options))
    (destructuring-bind (key fd direction ext) entry
      (handler-case
          (let ((stream (%make-terminal-fd-stream fd direction ext)))
            (if stream
                (ecase key
                  (:output (setf *standard-output* stream))
                  (:error  (setf *error-output* stream))
                  (:input  (setf *standard-input* stream)))
                (warn "alfe: -Eterminal terminal-encoding reconfiguration ~
is unavailable on this host (non-SBCL, or Windows where console-fd ~
reopening is unreliable); leaving ~(~A~) at the host default." key)))
        (error (e)
          (warn "alfe: could not apply -Eterminal (~A) to ~(~A~): ~A"
                ext key e))))))

;;; --- G2: the `console` encoding alfe DECODES the CAD's output AS ---
;;;
;;; The file-IPC drain (drain-stdout/-stderr → decode-console-octets) reads
;;; the CAD's console/stdout bytes back through the protocol channel files.
;;; RESOLVED-CONSOLE-ENCODING picks the codec from the resolved `console`
;;; (then `cadstdio`) situation; NIL from the CLI → :AUTO, i.e. the robust
;;; auto-detect cascade — the behaviour-preserving default. A per-backend
;;; default (accoreconsole → true UTF-16LE) is deliberately NOT forced here
;;; yet: that flip waits on real-runner verification (Phase 2 plan).
(defun resolved-console-encoding (options)
  "The encoding alfe should decode the CAD console output AS — the resolved
`console`-out / `console` / `cadstdio`-out / `cadstdio` situation, or :AUTO
when none was requested."
  (or (and options
           (or (cli-situation-encoding options "console" "out")
               (cli-situation-encoding options "console")
               (cli-situation-encoding options "cadstdio" "out")
               (cli-situation-encoding options "cadstdio")))
      :auto))

;;; --- backend selection: resolve --cad DENOTATION ---
;;;
;;; --cad names a specific installed CAD by its canonical denotation. It is
;;; resolved here (not at parse time) because the autocad→acad/accoreconsole
;;; choice depends on the fully-parsed --mode. Resolution sets the backend and
;;; overrides that backend's discovery by exporting its $*_EXE env var to the
;;; chosen path (the DETECT methods already prefer $*_EXE), so no backend code
;;; needs to change. alfe.backend.cad-common loads after this file, so its
;;; functions are reached via UIOP:SYMBOL-CALL.

(defun %default-mode (options mode)
  "Set --mode to MODE unless the user already chose one explicitly."
  (when (eq (cli-options-mode options) :auto)
    (setf (cli-options-mode options) mode)))

(defun apply-cad-selection (options)
  "Resolve --cad DENOTATION (if given) to an installed CAD program, set the
backend, and point the backend's discovery at the chosen executable. A
denotation that matches nothing is a usage error listing the way to see them."
  (let ((den (cli-options-cad options)))
    (when den
      (let* ((programs (uiop:symbol-call :alfe.backend.cad-common
                                         :discover-cad-programs))
             (program (uiop:symbol-call :alfe.backend.cad-common
                                        :resolve-cad-denotation den programs
                                        :mode (cli-options-mode options))))
        (unless program
          (error 'cli-usage-error
                 :option "--cad"
                 :message (format nil "unknown CAD program ~S (see --list-cad-programs)"
                                  den)))
        (let ((kind (uiop:symbol-call :alfe.backend.cad-common :cad-program-kind program))
              (path (uiop:symbol-call :alfe.backend.cad-common :cad-program-path program)))
          (log-verbose "cli: --cad ~S -> ~A ~A"
                       den
                       (uiop:symbol-call :alfe.backend.cad-common
                                         :cad-program-denotation program)
                       path)
          (ecase kind
            (:acad          (%set-backend-checked options :autocad "--cad")
                            (setf (uiop:getenv "AUTOCAD_EXE") path)
                            (%default-mode options :automation))
            (:accoreconsole (%set-backend-checked options :autocad "--cad")
                            (setf (uiop:getenv "AUTOCAD_ACCORECONSOLE") path)
                            (%default-mode options :batch))
            (:bricscad      (%set-backend-checked options :bricscad "--cad")
                            (setf (uiop:getenv "BRICSCAD_EXE") path))
            (:clautolisp    (%set-backend-checked options :clautolisp "--cad"))))))))

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
          ((cli-options-list-dialects-p options)
           (clautolisp.autolisp-cli:print-dialects)
           0)
          ((cli-options-list-situations-p options)
           (clautolisp.autolisp-cli:print-situations
            :backend (cli-options-backend options))
           0)
          ((cli-options-list-cad-programs-p options)
           ;; alfe.backend.cad-common loads AFTER this file (concrete backends
           ;; self-register at runtime; cli never names their packages), so
           ;; resolve PRINT-CAD-PROGRAMS at call time.
           (uiop:symbol-call :alfe.backend.cad-common :print-cad-programs)
           0)
          (t
           (set-level (cli-options-verbosity options))
           ;; G1: apply the resolved `terminal` encoding to alfe's OWN
           ;; standard streams FIRST — before any output (the debug dump,
           ;; the colour probe, the plan) so the whole run honours it. A
           ;; no-op unless -Eterminal[-in|-out] was given.
           (apply-terminal-encoding options)
           ;; Resolve --cad DENOTATION -> backend + $*_EXE override (needs
           ;; --mode, which is now parsed). No-op unless --cad was given.
           (apply-cad-selection options)
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
                   ((cli-options-print-command-p options)
                    (print-command-plan options backend :version-text version))
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

(defun effective-dialect (options)
  "Resolve the dialect to run, per alfe-clautolisp-dialect.issue point 1.
A CAD backend imposes its own dialect and IGNORES --dialect; the
clautolisp backend (the default) HONOURS --dialect, defaulting to
strict. Because the backend selectors only set the backend, --dialect
takes effect regardless of option order."
  (case (cli-options-backend options)
    (:autocad  :autocad-2026)
    (:bricscad :bricscad-v26)
    ;; :clautolisp or nil (default backend): honour --dialect, whose
    ;; slot defaults to :strict when the user gave no --dialect.
    (t (cli-options-dialect options))))

(defun %write-workdir-path-file (options workdir)
  "If --write-workdir-path FILE was given, write WORKDIR's absolute path to
FILE (one line). Best-effort: a write failure is logged, never fatal — the
run must proceed even if the caller's path-capture file is unwritable."
  (let ((path (cli-options-write-workdir-path options)))
    (when path
      (handler-case
          (with-open-file (out path :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create)
            (write-line (namestring (truename workdir)) out))
        (error (e)
          (log-verbose "cli: could not write workdir path to ~S: ~A" path e))))))

(defun run-plan (options backend &key version-text)
  "Drive a real backend through the action plan. Returns the exit code.
VERSION-TEXT propagates the alfe version string from RUN so backends
can publish it as the *AUTOLISP-VERSION* global of their hosted
engine."
  (log-verbose "cli: load-encoding ~S, io-encoding ~S"
               (cli-options-load-encoding options)
               (cli-options-io-encoding options))
  (let* ((started-at (get-internal-real-time))
         (workdir (let ((wd (prepare-workdir backend
                                             (cli-options-workdir options))))
                    (%write-workdir-path-file options wd)
                    wd))
         (session (start-engine backend workdir
                                :dialect (effective-dialect options)
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

(defun print-command-plan (options backend &key version-text
                                                (stream *standard-output*))
  "Implement --print-command. Returns the exit code (0 on success).

Prepares the workdir and stages every launch artefact exactly as
RUN-PLAN would — same runtime/bootstrap staging, same run-common.lsp,
same run.scr or bridge script — then prints the CAD command line alfe
WOULD spawn and returns, without spawning anything. The argv is
captured by handing START-ENGINE a :LAUNCHER closure that records its
argument and returns NIL (the same seam the test suite uses for the
mock CAD), with :WAIT-FOR-READY NIL since no engine will ever publish
READY.

Only the CAD backends have a command line; asking for one under
--clautolisp is a usage error rather than a silent empty answer, so a
caller doing `cmd=$(alfe --print-command …)` fails loudly.

No SHUTDOWN is performed: nothing was launched, and BricsCAD's
SHUTDOWN would spend its 5 s waiting for a STOPPED status that cannot
arrive. The workdir is removed on the way out unless --keep-workdir
was given — so the printed command references a directory that no
longer exists unless the user asked to keep it. That is deliberate:
--print-command must not litter the temp tree by default."
  (let ((backend-name (alfe.backend:backend-name backend)))
    (unless (member backend-name '(:autocad :bricscad))
      (error 'cli-usage-error
             :option "--print-command"
             :message
             (format nil
                     "applies to the CAD backends (--autocad / --bricscad); ~
backend ~(~A~) runs in-process and has no external command line."
                     backend-name)))
    (let ((captured nil)
          (keep-p (cli-options-keep-workdir-p options))
          (workdir (let ((wd (prepare-workdir backend
                                              (cli-options-workdir options))))
                     (%write-workdir-path-file options wd)
                     wd)))
      (unwind-protect
           (progn
             (start-engine backend workdir
                           :dialect (effective-dialect options)
                           :host (cli-options-host options)
                           :mock-input nil
                           :bootstrap-phase (cli-options-bootstrap-phase options)
                           :interactive-p (cli-options-interactive-p options)
                           :mode (cli-options-mode options)
                           :dwg (cli-options-dwg options)
                           :load-encoding (cli-options-load-encoding options)
                           :io-encoding (cli-options-io-encoding options)
                           :cli-options options
                           :version-text version-text
                           :wait-for-ready nil
                           :launcher (lambda (argv &rest ignored)
                                       (declare (ignore ignored))
                                       (setf captured argv)
                                       nil))
             (unless captured
               (error 'alfe.error:backend-bootstrap-error
                      :backend backend-name
                      :code :no-launch-command
                      :message
                      (format nil "Backend ~(~A~) staged the workdir but produced ~
no launch command line." backend-name)))
             (log-verbose "cli: --print-command backend ~A, workdir ~A"
                          backend-name workdir)
             (log-debug "cli: --print-command argv = ~S" captured)
             ;; The command line, alone, on stdout: this is the deliverable.
             (format stream "~&~A~%" (format-launch-command captured))
             (finish-output stream)
             (unless keep-p
               (log-verbose "cli: --print-command removing workdir ~A ~
(pass --keep-workdir to keep the staged artefacts)" workdir))
             0)
        (ignore-errors (cleanup-workdir backend workdir :keep-p keep-p))))))
