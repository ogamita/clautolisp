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
                #:eval-plan-with-action-hooks
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
                #:make-eval-result
                #:eval-result-status
                #:eval-result-value
                #:eval-result-output
                #:eval-result-error-output
                #:eval-result-condition
                #:eval-result-exit-code)
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
                #:log-info
                #:log-warn)
  ;; The plug-in system. alfe.cli drives it (loading, option parsing,
  ;; hook call sites); alfe.plugin never depends on alfe.cli.
  (:import-from #:alfe.plugin
                #:run-hook
                #:hook-active-p
                #:with-run-context
                #:plugin-option-specs
                #:resolve-plugin-options
                #:activate-plugin-by-name
                #:plugin-usage-text
                #:load-plugins
                #:prescan-plugin-arguments
                #:print-plugins
                #:compile-plugin)
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
                #:cli-situation-encoding-explicit
                #:encoding-keyword
                #:cli-options-dwg
                #:cli-options-plugin-options
                #:cli-options-plugins-active
                #:cli-options-list-plugins-p
                #:cli-options-compile-plugin
                #:cli-options-bootstrap-phase
                #:cli-options-verbosity
                #:cli-options-workdir
                #:cli-options-timeout
                #:cli-options-help-p
                #:cli-options-version-p
                #:cli-options-list-encodings-p
                #:cli-options-list-dialects-p
                #:cli-options-list-hosts-p
                #:cli-options-list-situations-p
                #:cli-options-list-cad-programs-p
                #:cli-options-dry-run-p
                #:cli-options-print-command-p
                #:cli-options-no-init-p
                #:cli-options-no-color-p
                #:cli-options-keep-workdir-p
                #:cli-options-write-workdir-path
                #:cli-options-cad-log
                #:cli-options-main
                #:cli-options-positional
                #:make-option-spec
                #:option-spec-longs
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
           #:situation-engine-keywords
           #:console-is-terminal-p
           #:cli-options-dwg
           #:cli-options-plugin-options
           #:cli-options-plugins-active
           #:cli-options-list-plugins-p
           #:cli-options-compile-plugin
           #:cli-options-bootstrap-phase
           #:cli-options-verbosity
           #:cli-options-workdir
           #:cli-options-timeout
           #:cli-options-help-p
           #:cli-options-version-p
           #:cli-options-list-encodings-p
           #:cli-options-list-dialects-p
           #:cli-options-list-hosts-p
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
           #:clautolisp-program-requirement
           #:plan-from-options
           ;; transmit-options bridge
           #:cli-options-transmit-bindings-for-alfe))

(in-package #:alfe.cli)

;; The plug-ins are loaded, and their options parsed, before anything else
;; knows the CLI's own option set, so alfe.plugin needs to be told what the
;; core options are to refuse a plug-in option that collides with one. Set
;; below, once *ALFE-OPTION-SPECS* exists.

(defvar *on-error* :quit
  "The --on-error policy in force for the current RUN, as it governs alfe
ITSELF. --on-error is the clautolisp program's option (shared spec): under
--clautolisp the engine applies it to the user's AutoLISP errors (debug stops
in aldo), in both variants. Independently, and under every backend, it says
how an unexpected Lisp condition escaping alfe itself is reported: :QUIT --
also when the option is absent -- prints the one-line `alfe: <condition>' and
exits; :DEBUG and :IGNORE additionally dump the CL backtrace at the point of
the error -- the intact stack, captured with HANDLER-BIND before the outer
HANDLER-CASE unwinds -- so a crash inside alfe itself can be diagnosed without
a rebuild. Bound per RUN; set by RUN from the parsed option.")

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
  --backend {direct,subprocess}     --clautolisp: run the engine inside alfe (default)
                                    or as the clautolisp executable. Same meaning for
                                    every option either way. A run needing the
                                    clautolisp program itself (a REPL: -i or no
                                    action; --dribble; --dcl gui|ncurses; --host
                                    cadtui) runs as the executable by default and
                                    is a usage error with --backend direct.

Actions (processed in order):
  -l, --load FILE        Load FILE (relative to alfe's invocation directory).
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
  --list-hosts           Print the --host backends with a one-line summary and exit.
  --list-situations      Print the encoding situations (source/file/console/…) and exit.
  --list-cad-programs    Scan the host and print each installed CAD with its
                         canonical denotation (acad-2026, bricscad-v26, …), then exit.
  --cad DENOTATION       Select a specific installed CAD by denotation
                         (acad-2026, accoreconsole-2022, bricscad-v25-fr_FR,
                         or a bare/partial acad / bricscad / autocad → latest;
                         autocad honours --mode: batch→accoreconsole, else acad).
  --host NAME            Host backend of --clautolisp: cador (default: the headless
                         CAD core), cadtui (the textual UI-tree host) or nihil (no
                         host). cadtui runs in the clautolisp executable, so alfe
                         starts it as --backend subprocess. Ignored under
                         --autocad/--bricscad, where the CAD is the host.
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

Plug-ins:
  --plugin NAME          Activate the installed plug-in NAME (repeatable).
                         Mirrors $ALFE_PLUGINS.
  --plugin-path DIR      Add DIR to the plug-in search path (repeatable).
                         Mirrors $ALFE_PLUGIN_PATH.
  --no-plugins           Load no plug-in. Mirrors $ALFE_NO_PLUGINS.
  --list-plugins         Print the installed plug-ins and the search path, then exit.
  --compile-plugin FILE  Compile the plug-in source FILE for this alfe, then exit.

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
  --cad-log FILE         --autocad / --bricscad: after the run, copy the CAD's own
                         command-history log (LOGFILEMODE, which alfe directs
                         into its workdir) to FILE in UTF-8, decoded per -Elog,
                         else as measured (a BOM's encoding; windows-1252 on
                         MS-Windows; auto-detected elsewhere).
  --dribble              Record the session (forms sent, output `;; O:', error
                         output `;; E:', conditions `;; C:') into
                         $XDG_STATE_HOME/alfe/dribbles/BACKEND/TIMESTAMP.log.
                         The header names both versions (alfe and the CAD).
  --dribble=FILE         Record into FILE (appended when it exists).
  --dribble-interactors=IS  Which interactors are recorded: t for all, or a
                         comma-separated list. Forwarded to --clautolisp, where
                         interactors exist; the CAD backends have none and
                         record the whole session. Under --clautolisp the
                         recording is the ENGINE's own REPL transcript.
  --dcl MODE             --clautolisp: the DCL renderer, as clautolisp's --dcl:
                         tui (line form), ncurses, gui ($CLAUTOLISP_GUI driver)
                         or auto (default).
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

Debugger (aldo; the clautolisp program's options, same spelling and meaning):
      --on-error POLICY  An uncaught AutoLISP error under --clautolisp: quit
                         (report it and exit 1; the default of a batch run),
                         debug (stop in the aldo debugger at the error; the
                         default of an interactive REPL) or ignore (no
                         debugger: the AutoLISP *error* handler runs). Under
                         every backend, debug and ignore also make alfe dump
                         the CL backtrace of an unexpected condition in alfe
                         itself.
      --on-interrupt POLICY  Control-C under --clautolisp: debug (break into
                         aldo; the default), ignore, or quit (exit 130).
      --on-quit POLICY   (quit) / (exit) under --clautolisp: quit (default) or
                         debug (enter aldo before unwinding).
      --debugger-ui UI   The aldo front-end: dumb (alias terminal, tui),
                         ncurses, or aldb (alias emacs).
      --aldb-listen [HOST:]PORT  The aldb (Emacs) listener address; implies
                         --debugger-ui aldb.
      --aldb-stdio       aldb over stdin/stdout; implies --debugger-ui aldb;
                         excludes --interactive and --aldb-listen.
                         All six apply to both --backend variants. The CAD
                         backends have no aldo: they refuse every one of them
                         except --on-error (EX_USAGE 64).

Informational:
  -h, --help             Show this help and exit.
  -V, --version          Print version and exit.
  --list-encodings       Print every encoding name accepted by -e / -E and exit.
                         Encoding names are case-insensitive on the CLI.
")

(defun print-usage (&optional (stream *standard-output*))
  (write-string *usage-banner* stream)
  ;; The options of the installed plug-ins, generated from what they
  ;; registered (empty when none is installed or --no-plugins was given).
  (let ((plugins (plugin-usage-text)))
    (when plugins (write-string plugins stream)))
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

(defparameter +alfe-hosts+
  '(("cador" . :cador) ("cadtui" . :cadtui) ("nihil" . :nihil))
  "The --host names alfe accepts, with the keyword each stands for. The
keyword is what the rest of alfe, and *AUTOLISP-HOST*, see.")

(defun %parse-alfe-host (value option)
  (or (cdr (assoc value +alfe-hosts+ :test #'string-equal))
      (error 'cli-usage-error
             :option option
             :message (format nil "Unknown --host ~S (expected ~{~A~^, ~})"
                              value (mapcar #'car +alfe-hosts+)))))

(defun %make-alfe-option-specs ()
  "Build the alfe-only option-spec list: --mode/--backend/--dwg/
--workdir/--keep-workdir/--write-workdir-path/--timeout/
--bootstrap-phase/--dry-run/--main/--quit/--plugin*/--list-plugins/
--compile-plugin. Also wraps the common dialect-shorthand
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
   ;; --host: alfe knows three hosts, cador (the default), cadtui and nihil,
   ;; and passes the choice on to clautolisp as is. This spec comes before
   ;; the shared one, which still tolerates the retired spellings of the
   ;; same hosts for the clautolisp executable's sake; alfe does not.
   (make-option-spec
    :longs '("--host") :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (cli-options-host opts) (%parse-alfe-host value name))))
   (make-option-spec
    :longs '("--dwg") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-dwg opts) value)))
   ;; --plugin NAME activates an installed plug-in that has no flag of its
   ;; own (or that the caller prefers to name). --plugin-path and
   ;; --no-plugins are consumed by PRESCAN-PLUGIN-ARGUMENTS in RUN, before
   ;; the parser exists: what they say decides what is loaded, and the
   ;; loaded plug-ins are what tell the parser which options are legal. The
   ;; parser accepts them so that they are not "unknown".
   (make-option-spec
    :longs '("--plugin") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (activate-plugin-by-name opts value)))
   (make-option-spec
    :longs '("--plugin-path") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore opts value name))))
   (make-option-spec
    :longs '("--no-plugins") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore opts value name))))
   (make-option-spec
    :longs '("--list-plugins") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-list-plugins-p opts) t)))
   (make-option-spec
    :longs '("--compile-plugin") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-compile-plugin opts) value)))
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
   ;; --on-error, --on-interrupt, --on-quit, --debugger-ui, --aldb-listen
   ;; and --aldb-stdio are the SHARED specs of *COMMON-OPTION-SPECS*: the
   ;; clautolisp program's, spelled, parsed and meant the same way
   ;; (debugger-public-interface-and-on-error.issue, pjb 2026-10-06). RUN
   ;; sets *ON-ERROR* from the parsed --on-error, and refuses the ones a CAD
   ;; backend cannot honour (CHECK-DEBUGGER-OPTIONS-FOR-BACKEND).
   (make-option-spec
    :longs '("--keep-workdir") :takes-arg-p nil
    :handler (lambda (opts value name)
               (declare (ignore value name))
               (setf (cli-options-keep-workdir-p opts) t)))
   (make-option-spec
    :longs '("--write-workdir-path") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-write-workdir-path opts) value)))
   ;; --cad-log FILE: the `log' encoding situation read back
   ;; (encoding-situations-cli-options). WRITE-CAD-LOG-IF-ASKED.
   (make-option-spec
    :longs '("--cad-log") :takes-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (cli-options-cad-log opts) value)))
   ;; --- dribble (alfe-dribble.issue) -------------------------------
   ;; The slots live in the SHARED cli-options struct, which already
   ;; carried them ("clautolisp today, alfe planned"); only the specs
   ;; are per-program, because clautolisp's --dribble and alfe's differ
   ;; in what they record. Spelled exactly as clautolisp spells them --
   ;; a user who knows one knows the other.
   ;;
   ;; --dribble takes an OPTIONAL value: bare records into the default
   ;; timestamped file, --dribble=FILE into FILE (appended).
   (make-option-spec
    :longs '("--dribble") :shorts nil :takes-arg-p t :optional-arg-p t
    :handler (lambda (opts value name)
               (declare (ignore name))
               (setf (clautolisp.autolisp-cli:cli-options-dribble opts)
                     (or value t))))
   (make-option-spec
    :longs '("--dribble-interactors") :shorts nil :takes-arg-p t
    :handler (lambda (opts value name)
               (setf (clautolisp.autolisp-cli:cli-options-dribble-interactors opts)
                     (clautolisp.autolisp-cli:parse-dribble-interactors
                      value name))))))

(defparameter *alfe-option-specs* (%make-alfe-option-specs))

(setf alfe.plugin:*core-option-names-function*
      (lambda ()
        (loop for spec in (append *alfe-option-specs* *common-option-specs*)
              append (option-spec-longs spec))))

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
parser with the union of *common-option-specs* + *alfe-option-specs* + the
options of the registered plug-ins (which the caller has loaded: see
LOAD-PLUGINS).
Post-translation steps fold env-var defaults in and rewrite the
action conses produced by the shared parser into alfe.backend
action objects so the rest of alfe (PLAN-FROM-OPTIONS, EVAL-PLAN,
etc.) sees the legacy shape. The transmit-options installer reads
through CLI-OPTIONS->TRANSMIT-BINDINGS-FOR-ALFE which translates
the action objects back to conses on the fly."
  (let* ((options (make-cli-options :host :cador)))
    (apply-env-defaults options)
    (parse-arguments-with-spec
     (append *alfe-option-specs* (plugin-option-specs) *common-option-specs*)
     argv
     :initial-options options)
    (setf (cli-options-actions options)
          (mapcar (lambda (a)
                    (%translate-action-cons
                     a (cli-options-load-encoding options)))
                  (cli-options-actions options)))
    ;; Command line, then environment, then default; the options of a
    ;; plug-in that is not active are refused here, as a usage error.
    (resolve-plugin-options options)
    ;; The aldb channel rules, as the clautolisp program applies them:
    ;; --aldb-stdio excludes --interactive and --aldb-listen.
    (clautolisp.autolisp-cli:validate-debugger-options options)
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

(defun clautolisp-program-requirement (options)
  "Why the run OPTIONS describe needs the clautolisp PROGRAM -- not only the
engine alfe embeds -- as (VALUES OPTION REASON), or NIL when it does not.

The embedded engine is the clautolisp runtime; some of what `clautolisp'
offers is the program's own machinery, built around that runtime, and is not
in alfe's image (alfe-clautolisp-backend-semantic-parity.issue):

  --host cadtui         the UI-tree layer and its console interactor;
  an interactive run    the REPL: interactors, comma commands, the aldo
  (-i, or no action)    debugger an error breaks into, Control-C policy;
  --dribble[-interactors]  the recorder, which tees that REPL;
  --dcl gui / ncurses   the GUI and full-screen DCL renderers and their
                        selection (tui / auto are the line renderer in
                        both variants: the child's captured stdout is no TTY).

Rather than a second, poorer copy of each in alfe, such a run IS the program's:
the clautolisp backend runs it as the subprocess variant, so the default and
--backend subprocess behave identically by construction."
  (cond ((eq (cli-options-host options) :cadtui)
         (values "--host" "the cadtui host (--host cadtui)"))
        ((some (lambda (action) (eq (action-kind action) :interactive))
               (plan-from-options options))
         (values "--interactive"
                 "an interactive session (-i, or no -l / -x / --main / FILE)"))
        ((clautolisp.autolisp-cli:cli-options-dribble options)
         (values "--dribble" "a recording (--dribble)"))
        ((member (clautolisp.autolisp-cli:cli-options-dcl options) '(:gui :ncurses))
         (values "--dcl"
                 (format nil "the ~(~A~) DCL renderer (--dcl ~:*~(~A~))"
                         (clautolisp.autolisp-cli:cli-options-dcl options))))
        (t nil)))

(defun %clautolisp-variant (options)
  "The clautolisp engine variant OPTIONS ask for: the --backend one, except
that a run needing the clautolisp PROGRAM's own machinery
(CLAUTOLISP-PROGRAM-REQUIREMENT: --host cadtui, an interactive session,
--dribble, --dcl gui/ncurses) is the program's, so it means the subprocess
variant. Asking for one of those and --backend direct together is a
contradiction, and a usage error."
  (let ((variant (cli-options-backend-variant options)))
    (multiple-value-bind (option reason) (clautolisp-program-requirement options)
      (cond ((null option) variant)
            ((eq variant :direct)
             (error 'cli-usage-error
                    :option option
                    :message (format nil "~A runs in the clautolisp executable, not in alfe's embedded engine: it cannot be combined with --backend direct (leave --backend out, or use --backend subprocess)"
                                     reason)))
            (t :subprocess)))))

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
        (let ((variant (if (eq selected :clautolisp)
                           (%clautolisp-variant options)
                           (cli-options-backend-variant options))))
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
  ;; Hook :plan sees the whole plan — init files, user actions and the
  ;; terminator — so a plug-in can put actions in front of everything (EPUREE
  ;; does), and --dry-run shows what it did.
  (run-hook :plan
            (append (resolve-init-file-actions options)
                    (plan-from-options options))))

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
  (dolist (line (run-hook :dry-run-report nil))
    (format stream "  ~A~%" line))
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

;;; --- G1: the `terminal` situation encoding -- the code is shared ---------
;;; (clautolisp.autolisp-cli, terminal.lisp) since the clautolisp tool applies
;;; -Eterminal to its own streams too; these keep alfe's names.

(defun console-is-terminal-p (options)
  "True when the `console' situation of OPTIONS' run is alfe's own terminal:
the selected backend is the clautolisp engine (the default, as in
RESOLVE-BACKEND), whose console is in-process -- the same stream as the
terminal. A CAD backend (--autocad / --bricscad, or --cad naming one, or an
$ALFE_BACKEND_OVERRIDE) has a console DEVICE of its own, which -Econsole
describes; it must not reconfigure alfe's terminal then. Decided from OPTIONS
alone because the terminal is reconfigured before the backend is resolved."
  (let ((selected
          (or (cli-options-backend options)
              ;; --cad is resolved later (apply-cad-selection); it names a
              ;; CAD program, so treat it as one.
              (and (cli-options-cad options) :cad)
              (let ((override (env-default :override)))
                (and override
                     (ignore-errors
                      (parse-backend-symbol override "$ALFE_BACKEND_OVERRIDE"))))
              :clautolisp)))
    (eq selected :clautolisp)))

(defun terminal-encoding-plan (options)
  (clautolisp.autolisp-cli:terminal-encoding-plan
   options :fold-console (console-is-terminal-p options)))

(defun apply-terminal-encoding (options)
  (clautolisp.autolisp-cli:apply-terminal-encoding
   options :tool "alfe" :fold-console (console-is-terminal-p options)))

;;; --- section 6 point 1: one START-ENGINE keyword per situation -----------
;;;
;;; START-ENGINE used to receive only the two legacy mirrors (:load-encoding =
;;; source, :io-encoding = terminal). SITUATION-ENGINE-KEYWORDS resolves every
;;; situation x direction once, here, with the right resolver per boundary:
;;;   - source / file / log / terminal: CLI-SITUATION-ENCODING -- the bare -E
;;;     reaches them (they are ours, or follow our choice);
;;;   - console / cadstdio: CLI-SITUATION-ENCODING-EXPLICIT -- only an option
;;;     naming them; a bare -E must not reach a product-fixed boundary (a
;;;     blanket -E UTF-8 once made alfe read accoreconsole's UTF-16LE pipe as
;;;     UTF-8).
;;; The terminal pair folds an explicit -Econsole in when the console IS the
;;; terminal (CONSOLE-IS-TERMINAL-P: the clautolisp engine), with the same
;;; precedence as the terminal plan, so what alfe applies to its own streams
;;; and what it forwards to a clautolisp child agree.

(defun situation-engine-keywords (options &key
                                            (console-is-terminal-p
                                             (and options
                                                  (console-is-terminal-p options))))
  "The START-ENGINE keyword plist for every encoding situation of OPTIONS (a
cli-options record, or NIL -> every value NIL): :SOURCE-ENCODING
:FILE-READ-ENCODING :FILE-WRITE-ENCODING :CONSOLE-IN-ENCODING
:CONSOLE-OUT-ENCODING :CADSTDIO-IN-ENCODING :CADSTDIO-OUT-ENCODING
:LOG-ENCODING :TERMINAL-IN-ENCODING :TERMINAL-OUT-ENCODING. Each value is the
canonical encoding name the user asked for, or NIL (the backend default)."
  (flet ((all (situation &optional direction)
           (and options (cli-situation-encoding options situation direction)))
         (explicit (situation &optional direction)
           (and options
                (cli-situation-encoding-explicit options situation direction)))
         (terminal (direction)
           (and options
                (clautolisp.autolisp-cli:terminal-situation-encoding
                 options direction :fold-console console-is-terminal-p))))
    (list :source-encoding       (all "source")
          :file-read-encoding    (all "file" "read")
          :file-write-encoding   (all "file" "write")
          :console-in-encoding   (explicit "console" "in")
          :console-out-encoding  (explicit "console" "out")
          :cadstdio-in-encoding  (explicit "cadstdio" "in")
          :cadstdio-out-encoding (explicit "cadstdio" "out")
          :log-encoding          (all "log")
          :terminal-in-encoding  (terminal "in")
          :terminal-out-encoding (terminal "out"))))

(defun windows-console-code-page (external-format)
  (clautolisp.autolisp-cli:windows-console-code-page external-format))

;;; --- G2: the `console` encoding alfe DECODES the CAD's output AS ---
;;;
;;; The file-IPC drain (drain-stdout/-stderr → decode-console-octets) reads
;;; the CAD's console/stdout bytes back through the protocol channel files.
;;; RESOLVED-CONSOLE-ENCODING picks the codec from the resolved `console`
;;; (then `cadstdio`) situation; NIL from the CLI → :AUTO, i.e. the robust
;;; auto-detect cascade — the behaviour-preserving default. A per-backend
;;; default (accoreconsole → true UTF-16LE) is deliberately NOT forced here
;;; yet: that flip waits on real-runner verification (Phase 2 plan).
;;;
;;; Only an option NAMING the console / cadstdio counts (the EXPLICIT
;;; resolver): the bare -E / --encoding no longer reaches the BricsCAD drain.
;;; It used to -- -E UTF-8, meant for the source files and alfe's terminal,
;;; forced the drain to UTF-8 over the auto-detect cascade that reads a
;;; BricsCAD/Windows cp1252 drain (E3) correctly. AutoCAD already had this
;;; rule (%AUTOCAD-REQUESTED-STDIO-ENCODING); both CAD drains now agree.
(defun resolved-console-encoding (options)
  "The encoding alfe should decode the CAD console output AS — the explicitly
requested `console`-out / `console` / `cadstdio`-out / `cadstdio` situation,
or :AUTO when none was requested (a bare -E does not count)."
  (or (and options
           (or (cli-situation-encoding-explicit options "console" "out")
               (cli-situation-encoding-explicit options "cadstdio" "out")))
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

(defun %print-alfe-backtrace (condition stream)
  "Dump CONDITION and the live CL backtrace to STREAM. Used by the
--on-error debug|ignore policies; portable across SBCL and CCL, and a
no-op note elsewhere."
  (format stream "~&alfe[on-error]: ~A~%~%Backtrace:~%" condition)
  (ignore-errors
   #+sbcl (sb-debug:print-backtrace :stream stream :count 200)
   #+ccl  (ccl:print-call-history :stream stream :detailed-p nil)
   #-(or sbcl ccl)
   (format stream "  (no backtrace: unsupported CL implementation)~%"))
  (finish-output stream))

(defun %load-installed-plugins (argv version)
  "Load the plug-ins ARGV allows: --no-plugins (or $ALFE_NO_PLUGINS) loads
none and forgets any registered before; --plugin-path adds roots."
  (multiple-value-bind (directories none) (prescan-plugin-arguments argv)
    (cond ((alfe.plugin:plugins-disabled-p none)
           (alfe.plugin:reset-plugins))
          (t
           (load-plugins :directories directories
                         :version (or version "0.0.0"))))))

(defun %compile-plugin-command (file version)
  "--compile-plugin FILE: compile FILE for this alfe, print where, and return
the exit status: 0, EX_NOINPUT (66) when FILE cannot be opened, EX_DATAERR
(65) when it does not compile (or is not named NAME.lisp)."
  (handler-case
      (let ((output (compile-plugin file :version (or version "0.0.0"))))
        (format t "~&~A~%" (uiop:native-namestring output))
        (finish-output)
        clautolisp.sysexits:+ex-ok+)
    (error (condition)
      (format *error-output* "~&alfe: --compile-plugin: ~A~%" condition)
      (if (typep condition 'file-error)
          clautolisp.sysexits:+ex-noinput+
          clautolisp.sysexits:+ex-dataerr+))))

(defun %condition-phase (condition)
  (typecase condition
    (cli-usage-error :usage)
    (backend-error (alfe.error:backend-error-phase condition))
    (t :internal)))

(defun %report-error-to-plugins (condition)
  "Hook :error, at the point of the error (before any unwinding, so the
--on-error backtrace is untouched). A failing handler must not mask the
error it was told about."
  (handler-case (run-hook :error condition :phase (%condition-phase condition))
    (error (failure)
      (log-debug "cli: hook :error failed: ~A" failure))))

(defmacro %with-error-hook (&body body)
  `(handler-bind ((error #'%report-error-to-plugins))
     ,@body))

(defun run (argv &key version)
  "alfe entry point. ARGV is the argument list *without* the program
name; VERSION is the version string printed by --version. Returns an
integer exit code; the executable's MAIN wraps this and calls UIOP:QUIT
with the result.

The exit statuses are the <sysexits.h> codes (sysexits-exit-statuses.issue;
the table is in the alfe specification, Exit status):
  0  — success
  1  — the user's AutoLISP program failed
  N  — the program's own (exit N) / (quit N) / autolisp-set-status N
  64..78 — the condition that stopped the run, mapped by
       ALFE.ERROR:EXIT-CODE-FOR-CONDITION (EX_USAGE for a usage error,
       EX_UNAVAILABLE for an engine that is not there, ...)"
  (handler-case
      (let ((*on-error* :quit))
        (handler-bind
            ((error (lambda (condition)
                      (when (member *on-error* '(:debug :ignore))
                        (%print-alfe-backtrace condition *error-output*)))))
        (let ((options (progn
                         ;; Plug-ins first: their options are what the
                         ;; parser must accept.
                         (%load-installed-plugins argv version)
                         (let ((options (parse-arguments argv)))
                           ;; --on-error also governs how alfe reports its
                           ;; OWN unexpected conditions (see *ON-ERROR*).
                           (setf *on-error*
                                 (or (clautolisp.autolisp-cli:cli-options-on-error
                                      options)
                                     :quit))
                           options))))
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
          ((cli-options-list-hosts-p options)
           ;; The shared parser has always ACCEPTED --list-hosts and set
           ;; this slot; with no branch here alfe fell through to its REPL
           ;; instead of answering (alfe-list-hosts-ignored). ALIASES NIL:
           ;; alfe takes cador, cadtui and nihil and nothing else, so the
           ;; shared note about mock / null / none would name spellings it
           ;; refuses.
           (clautolisp.autolisp-cli:print-hosts :aliases nil)
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
          ((cli-options-list-plugins-p options)
           (print-plugins)
           0)
          ((cli-options-compile-plugin options)
           (%compile-plugin-command (cli-options-compile-plugin options) version))
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
               (with-run-context (options :version version)
                 (%with-error-hook
                   (run-hook :cli-parsed options)
                   (let ((backend (resolve-backend
                                   options
                                   :detect-p (not (cli-options-dry-run-p options)))))
                     ;; The debugger options a CAD backend cannot honour are
                     ;; refused, never silently ignored -- dry run included.
                     (check-debugger-options-for-backend
                      options (alfe.backend:backend-name backend))
                     ;; From here the run's backend is the one really chosen
                     ;; (an $ALFE_BACKEND_OVERRIDE, a default), which is what
                     ;; a plug-in's :applies-to is matched against.
                     (setf (alfe.plugin:context-backend alfe.plugin:*context*)
                           (alfe.backend:backend-name backend))
                     (run-hook :backend-selected backend
                               :options options
                               :dry-run-p (cli-options-dry-run-p options))
                     (cond
                       ((cli-options-dry-run-p options)
                        (emit-dry-run options backend)
                        0)
                       ((cli-options-print-command-p options)
                        (print-command-plan options backend :version-text version))
                       (t
                        (run-plan options backend :version-text version)))))))))))))
    ;; One report, one mapping for every error that ends the run
    ;; (sysexits-exit-statuses.issue).
    (error (condition)
      (format *error-output* "~&alfe: ~A~%" condition)
      (exit-code-for-condition condition))))

(defparameter +cad-refused-debugger-options+
  '("--on-interrupt" "--on-quit" "--debugger-ui" "--aldb-listen" "--aldb-stdio")
  "The debugger options a CAD backend (--autocad / --bricscad) refuses. They
configure aldo, the clautolisp engine's debugger, and the AutoLISP of a CAD runs
in the CAD, with no aldo: honouring them is impossible and ignoring them would
lie. --on-error is not among them: under every backend it also governs how
alfe reports its own unexpected conditions (*ON-ERROR*).")

(defun check-debugger-options-for-backend (options backend-name)
  "Signal a CLI-USAGE-ERROR when OPTIONS carry a debugger option the backend
BACKEND-NAME cannot honour (+CAD-REFUSED-DEBUGGER-OPTIONS+ under a CAD
backend). The clautolisp backend honours them all, in both variants."
  (when (member backend-name '(:autocad :bricscad))
    (let ((refused (remove-if-not
                    (lambda (name)
                      (member name +cad-refused-debugger-options+ :test #'string=))
                    (clautolisp.autolisp-cli:given-debugger-options options))))
      (when refused
        (error 'cli-usage-error
               :option (format nil "~{~A~^, ~}" refused)
               :message
               (format nil "~:[this option configures~;these options configure~] ~
aldo, the debugger of the clautolisp engine; the ~(~A~) backend runs AutoLISP in ~
the CAD, which has no aldo (use --clautolisp, or drop ~:[it~;them~])"
                       (rest refused) backend-name (rest refused)))))))

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

(defun %safe-hook (name value &rest details)
  "Run the hook NAME during teardown. An error in a handler is reported, not
propagated: shutdown and cleanup must still happen, and the run's own
outcome must not be replaced by a plug-in's teardown failure."
  (handler-case (apply #'run-hook name value details)
    (error (condition)
      (format *error-output* "~&alfe: warning: hook ~S failed: ~A~%"
              name condition)
      nil)))

(defun %eval-plan-with-hooks (session plan)
  "Evaluate PLAN through EVAL-PLAN-WITH-ACTION-HOOKS, calling :pre-action and
:post-action around each action. Used only when an active plug-in registered
one of the two hooks. How the actions are separated is the backend's business:
the CAD backends evaluate the plan one action at a time and stop at the first
that fails; the clautolisp backend, in both variants, stops at the action
boundaries of the ONE run it would make without hooks, so the run -- its state,
output, stopping point and exit status -- is the same with or without a
plug-in (alfe-clautolisp-backend-semantic-parity.issue)."
  (let ((count (length plan)))
    (eval-plan-with-action-hooks
     session plan
     (lambda (action index)
       (run-hook :pre-action action :index index :count count
                                    :session session))
     (lambda (action index result)
       (run-hook :post-action action :index index :count count
                                     :session session :result result)))))

(defun %prepare-workdir-or-fail (backend workdir-root)
  "PREPARE-WORKDIR, with a workdir that cannot be created reported as a
BACKEND-BOOTSTRAP-ERROR of code :CANNOT-CREATE-WORKDIR, whose exit status
is EX_CANTCREAT (73) (sysexits-exit-statuses.issue)."
  (handler-case (prepare-workdir backend workdir-root)
    (file-error (condition)
      (error 'alfe.error:backend-bootstrap-error
             :backend (alfe.backend:backend-name backend)
             :code :cannot-create-workdir
             :message (format nil "cannot create the workdir~@[ ~A~]: ~A"
                              workdir-root condition)))))

(defun run-plan (options backend &key version-text)
  "Drive a real backend through the action plan. Returns the exit code.
VERSION-TEXT propagates the alfe version string from RUN so backends
can publish it as the *AUTOLISP-VERSION* global of their hosted
engine."
  (log-verbose "cli: load-encoding ~S, io-encoding ~S"
               (cli-options-load-encoding options)
               (cli-options-io-encoding options))
  (let* ((started-at (get-internal-real-time))
         ;; The plan first, before a workdir exists or a CAD is launched: a
         ;; plug-in that cannot build its part of it (EPUREE without ALPM)
         ;; says so at once, not after a two-minute CAD start.
         (plan (effective-plan options))
         (workdir (let ((wd (%prepare-workdir-or-fail
                             backend (cli-options-workdir options))))
                    (%write-workdir-path-file options wd)
                    (run-hook :workdir-prepared wd)
                    wd))
         (session (apply #'start-engine backend workdir
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
                         :version-text version-text
                         ;; one keyword per encoding situation
                         ;; (encoding-situations section 6 point 1)
                         (situation-engine-keywords
                          options
                          :console-is-terminal-p
                          (eq (alfe.backend:backend-name backend) :clautolisp)))))
    ;; Start recording, for the backends alfe records itself. The clautolisp
    ;; backend is NOT one of them: its flags were forwarded to the engine, which
    ;; records its own REPL, and a second alfe-side file would be a poorer copy
    ;; of the same session (alfe-dribble.issue; pjb's split).
    (%start-dribble-if-asked options version-text)
    (unwind-protect
         (progn
           (run-hook :engine-started session)
           (log-verbose "cli: resolved plan with ~D action~:P" (length plan))
           (loop for action in plan
                 for i from 1
                 do (log-verbose "cli: plan[~D] = ~A"
                                 i (render-action action)))
           (let ((result (if (or (hook-active-p :pre-action)
                                 (hook-active-p :post-action))
                             (%eval-plan-with-hooks session plan)
                             (eval-plan session plan))))
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
             (let ((exit-code (run-hook :exit-code
                                        ;; The engine's own status when it
                                        ;; decided one (the clautolisp backend:
                                        ;; (exit N), a file error), else the
                                        ;; outcome's.
                                        ;; :aborted is a CAD that did not
                                        ;; answer in time: EX_TEMPFAIL.
                                        (or (eval-result-exit-code result)
                                            (ecase (eval-result-status result)
                                              (:success  clautolisp.sysexits:+ex-ok+)
                                              (:failed   clautolisp.sysexits:+exit-autolisp-error+)
                                              (:aborted  clautolisp.sysexits:+ex-tempfail+)))
                                        :result result))
                   (elapsed (/ (float (- (get-internal-real-time) started-at))
                               internal-time-units-per-second)))
               (log-verbose "cli: plan finished status=~S exit=~D elapsed=~,2Fs"
                            (eval-result-status result) exit-code elapsed)
               exit-code)))
      (%safe-hook :pre-shutdown session :reason :cli-exit)
      (ignore-errors (shutdown session :reason :cli-exit))
      (%safe-hook :post-shutdown session :workdir workdir)
      ;; The engine is down, so its log is closed; the workdir that holds it
      ;; is still there.
      (ignore-errors (write-cad-log-if-asked options backend workdir))
      ;; Close the transcript before the workdir goes: the dribble lives outside
      ;; it (a run that cleans up must still leave its record behind), but the
      ;; open line is flushed here rather than at process exit, so a killed alfe
      ;; loses at most the line in progress.
      (ignore-errors (alfe.dribble:stop-dribble))
      (ignore-errors (cleanup-workdir backend workdir
                                      :keep-p (cli-options-keep-workdir-p options))))))

(defun write-cad-log-if-asked (options backend workdir)
  "--cad-log FILE: write the CAD's own command-history log of this run
(ALFE.BACKEND:COLLECT-ENGINE-LOG) to FILE, in UTF-8 with LF line ends. Several
log files (one per drawing) are written one after the other, each under a
`==> NAME <==' line. A backend without a CAD log (clautolisp), or a CAD that
wrote none, is warned about and FILE is not created. Returns FILE's pathname
when it was written, else NIL."
  (let ((file (cli-options-cad-log options)))
    (when file
      (multiple-value-bind (entries status)
          (alfe.backend:collect-engine-log backend workdir :cli-options options)
        (case status
          (:unsupported
           (log-warn "cli: --cad-log ~A ignored: the ~(~A~) backend has no CAD log ~
to collect (clautolisp writes its own LOGFILEMODE log where LOGFILEPATH points; ~
-Elog sets its encoding)."
                     file (alfe.backend:backend-name backend))
           nil)
          (:none
           (log-warn "cli: --cad-log ~A: the CAD wrote no log (none in ~A logs/; ~
BricsCAD on macOS writes none in batch mode, and --bootstrap-phase marker / core ~
do not turn it on)."
                     file workdir)
           nil)
          (t
           (handler-case
               (with-open-file (out file :direction :output
                                         :if-exists :supersede
                                         :if-does-not-exist :create
                                         :external-format :utf-8)
                 (dolist (entry entries)
                   (when (rest entries)
                     (format out "==> ~A <==~%" (car entry)))
                   (write-string (cdr entry) out)
                   (unless (or (zerop (length (cdr entry)))
                               (char= #\Newline
                                      (char (cdr entry) (1- (length (cdr entry))))))
                     (terpri out)))
                 (log-verbose "cli: --cad-log: ~D CAD log file~:P written to ~A"
                              (length entries) file)
                 (pathname file))
             (error (e)
               (log-warn "cli: --cad-log ~A cannot be written: ~A" file e)
               nil))))))))

(defun %start-dribble-if-asked (options version-text)
  "Start alfe's own recording when --dribble was given AND the selected backend
is one alfe records: the CAD backends. Returns the path, or NIL.

VERSION-TEXT is alfe's own version, threaded from RUN -- alfe.tool owns the
stamp and loads after this file, so the value is passed in rather than reached
for.

The clautolisp backend is excluded BY DESIGN, not by omission: its --dribble was
forwarded into the spawned engine's argv (or, in :direct mode, the engine's own
recording is already in-process), and the engine's REPL transcript is richer
than anything alfe could reconstruct from the outside -- it has the prompts, the
interactor stack, and the values. Recording both would leave two files for one
session, which is the double-recording the issue's acceptance criteria forbid."
  (let ((dribble (clautolisp.autolisp-cli:cli-options-dribble options))
        (kind (cli-options-backend options)))
    (when (and dribble (member kind '(:autocad :bricscad)))
      (let ((path (handler-case
                   (alfe.dribble:start-dribble
                     :file dribble
                     :backend kind
                     :alfe-version version-text
                     ;; What alfe KNOWS now: the --cad denotation it resolved
                     ;; (acad-2022, bricscad-v25, …). The engine has not answered
                     ;; yet and may never; ALFE.DRIBBLE writes `unknown' then, and
                     ;; the header is not delayed for it -- a transcript that
                     ;; appeared only after a successful CAD start would be
                     ;; missing the sessions worth reading.
                     :cad-version (cli-options-cad options))
                    ;; A transcript that cannot be created: EX_CANTCREAT
                    ;; (sysexits-exit-statuses.issue).
                    (file-error (condition)
                      (error 'clautolisp.autolisp-cli:cli-error
                             :option "--dribble"
                             :message (format nil "cannot create the transcript: ~A"
                                              condition)
                             :status clautolisp.sysexits:+ex-cantcreat+)))))
        (log-verbose "cli: dribble recording into ~A" path)
        path))))

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
          (directory nil)
          (keep-p (cli-options-keep-workdir-p options))
          (workdir (let ((wd (prepare-workdir backend
                                              (cli-options-workdir options))))
                     (%write-workdir-path-file options wd)
                     (run-hook :workdir-prepared wd)
                     wd)))
      (unwind-protect
           (progn
             (apply #'start-engine backend workdir
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
                           :launcher (lambda (argv &rest keys)
                                       (setf captured argv
                                             directory (getf keys :directory))
                                       nil)
                           ;; one keyword per encoding situation (a CAD
                           ;; backend here: its console is its own device)
                           (situation-engine-keywords
                            options
                            :console-is-terminal-p
                            (eq (alfe.backend:backend-name backend) :clautolisp)))
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
             ;; A working directory chosen by a plug-in is part of the command:
             ;; running the line elsewhere would not start the same thing.
             (format stream "~&~@[cd ~A && ~]~A~%"
                     (and directory
                          (quote-command-argument
                           (uiop:native-namestring directory)))
                     (format-launch-command captured))
             (finish-output stream)
             (unless keep-p
               (log-verbose "cli: --print-command removing workdir ~A ~
(pass --keep-workdir to keep the staged artefacts)" workdir))
             0)
        (ignore-errors (cleanup-workdir backend workdir :keep-p keep-p))))))
