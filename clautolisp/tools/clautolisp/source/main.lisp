(in-package #:clautolisp.tools.clautolisp)

;;;; clautolisp — standalone AutoLISP evaluator and interactive REPL.
;;;;
;;;; Reads an AutoLISP source file (or `-x EXPR` snippet, or stdin via
;;;; the REPL), evaluates every form in a fresh runtime session under
;;;; a chosen dialect, and exits with a meaningful status code.

(defun usage ()
  (format t "~&Usage: clautolisp [options] [FILE.lsp]~%")
  (format t "       clautolisp [options] -l FILE.lsp                  # load a file~%")
  (format t "       clautolisp [options] -x EXPRESSION                # evaluate EXPR~%")
  (format t "       clautolisp [options]                              # interactive REPL~%")
  (format t "       clautolisp [options] {-l FILE | -x EXPR} -i       # action then REPL~%")
  (format t "Input selection:~%")
  (format t "  -l, --load FILE        Load and evaluate FILE. Equivalent to the positional form.~%")
  (format t "  -x, --eval EXPRESSION  Evaluate EXPRESSION instead of reading a file.~%")
  (format t "  -i, --interactive      Enter the REPL after the action (same evaluation context).~%")
  (format t "Dialect:~%")
  (format t "  --dialect NAME         One of: strict (default), autocad[-mac][-YEAR], autocad-2022,~%")
  (format t "                         autocad-2026, bricscad[-mac|-linux][-vNN], bricscad-v25,~%")
  (format t "                         bricscad-v26, clautolisp, lax. An unversioned vendor name maps~%")
  (format t "                         to the last known version; an unqualified platform means windows.~%")
  (format t "  --list-dialects        Print every --dialect name (strict first, lax last) and exit.~%")
  (format t "  --lax                  Shorthand for --dialect lax: every extension available, no~%")
  (format t "                         out-of-dialect diagnostic.~%")
  (format t "  --strict               Shorthand for --dialect strict (portable AutoCAD ∩ BricsCAD).~%")
  (format t "  --autocad              Shorthand for --dialect autocad-2026.~%")
  (format t "  --bricscad             Shorthand for --dialect bricscad-v26.~%")
  (format t "  --clautolisp           Shorthand for --dialect clautolisp. Enables clautolisp~%")
  (format t "                         extensions (e.g. variadic functions). Out-of-dialect~%")
  (format t "                         operators stay callable but emit a diagnostic at use.~%")
  (format t "Host:~%")
  (format t "  --host NAME            HAL backend: cador (default), nihil. mock=alias of cador; null/none=aliases of nihil.~%")
  (format t "  --mock-input PATH      Attach the file at PATH as the MockHost prompt-stream.~%")
  (format t "                         Lines are consumed by GETSTRING / GETPOINT / etc. in order.~%")
  (format t "  --gui CMD              DCL GUI driver: subprocess CMD speaking the sexp wire protocol.~%")
  (format t "                         Also read from $CLAUTOLISP_GUI when --gui is omitted.~%")
  (format t "  --dcl MODE             DCL renderer selection: tui (force the terminal / command-line~%")
  (format t "                         form — clautolisp's spelling of AutoCAD's `-command' convention),~%")
  (format t "                         gui (the --gui subprocess driver), or auto (default: GUI when a~%")
  (format t "                         driver is configured and stdout is a TTY, else the TUI, so every~%")
  (format t "                         headless / piped run gets the command-line form).~%")
  (format t "  --trace                Print every AutoLISP function call (entry args + exit value),~%")
  (format t "                         indented by call depth. Output goes to *trace-output* (stderr).~%")
  (format t "Debugger (aldo):~%")
  (format t "  --on-error POLICY      What to do when an uncaught AutoLISP error reaches the top~%")
  (format t "                         level: quit (report and exit, the default for a batch run),~%")
  (format t "                         debug (break into the aldo debugger, the default for the~%")
  (format t "                         interactive REPL), or ignore (run the AutoLISP *error*~%")
  (format t "                         handler). Sets *CLAL-ON-ERROR*, which code may rebind.~%")
  (format t "  --on-interrupt POLICY  What Control-C (SIGINT) does: debug (break into the aldo~%")
  (format t "                         debugger at the interrupt point, the default), ignore~%")
  (format t "                         (execution resumes), or quit (exit with status 130). Sets~%")
  (format t "                         *CLAL-ON-INTERRUPT*, re-read LIVE at each interrupt, so~%")
  (format t "                         (setq *CLAL-ON-INTERRUPT* 'POLICY) overrides it at runtime.~%")
  (format t "                         A second Control-C while one is being handled exits at once.~%")
  (format t "  --on-quit POLICY       What (quit) / (exit) does: quit (the default), or debug —~%")
  (format t "                         break into the debugger BEFORE the stack unwinds; continuing~%")
  (format t "                         resumes the quit, aborting cancels it. Sets *CLAL-ON-QUIT*,~%")
  (format t "                         re-read LIVE at each (quit)/(exit) call.~%")
  (format t "  --debugger-ui UI       Debugger front-end: tui (the line/terminal UI), ncurses, or~%")
  (format t "                         aldb (the Emacs front-end). Selecting one runs the program~%")
  (format t "                         under a debug session. Per-run override of the persisted~%")
  (format t "                         default-user-interface aldo setting (aldo.conf), default tui.~%")
  (format t "  --aldb-listen [HOST:]PORT  Address the aldb (Emacs) listener binds; HOST defaults~%")
  (format t "                         to 127.0.0.1, PORT is a number (0 = pick a free port) or a~%")
  (format t "                         service name. Implies --debugger-ui aldb.~%")
  (format t "  --aldb-stdio           Use the process's stdin/stdout as the aldb RPC channel.~%")
  (format t "                         Implies --debugger-ui aldb; mutually exclusive with~%")
  (format t "                         --interactive and --aldb-listen.~%")
  (format t "Dribble:~%")
  (format t "  --dribble              Record the REPL interactions (input, output, errors,~%")
  (format t "                         conditions) into ~~/.local/state/clautolisp/dribbles/~%")
  (format t "                         ($XDG_STATE_HOME honoured), timestamped .log file.~%")
  (format t "  --dribble=FILE         Record into FILE (appended when it exists).~%")
  (format t "  --dribble-interactors=IS  Which interactors are recorded: t for all, or a~%")
  (format t "                         comma-separated list of names (default: AUTOLISP only).~%")
  (format t "                         Also settable as *CLAL-DRIBBLE-INTERACTORS*; toggle at~%")
  (format t "                         runtime with (clal-dribble [FILE [INTERACTORS]]).~%")
  (format t "REPL and diagnostics:~%")
  (format t "  -q, --quiet            Suppress the REPL banner.~%")
  (format t "  -v, --verbose          Print extra diagnostic information (banner, summary, …).~%")
  (format t "  -d, --debug            Print debug traces; include CL backtraces on runtime errors.~%")
  (format t "                         --quiet/--verbose/--debug compose additively and commutatively:~%")
  (format t "                         the most verbose request wins regardless of CLI argument order.~%")
  (format t "  --no-color             Disable ANSI colour in AutoLISP value output. Honoured~%")
  (format t "                         equivalently via $NO_COLOR (https://no-color.org).~%")
  (format t "                         Without it, the CLI probes the terminal and picks a~%")
  (format t "                         contrasting accent (yellow on dark, blue on light).~%")
  (format t "Source-file encoding:~%")
  (format t "  -e ENC                 Override the default source-file encoding for this session.~%")
  (format t "                         ENC is one of: utf-8, iso-8859-1, latin-1, windows-1252, cp1252.~%")
  (format t "                         Applied to every load in the session, including the nested~%")
  (format t "                         (load ...) calls a user's init file may issue.~%")
  (format t "  -E ENC                 Declared terminal-IO encoding for the session. Surfaced to~%")
  (format t "                         AutoLISP code as the *AUTOLISP-TERMINAL-ENCODING* global so~%")
  (format t "                         user code that emits raw bytes can adapt. No stream rebinding~%")
  (format t "                         is performed at the CL level — see transmit-options.issue.~%")
  (format t "Init files:~%")
  (format t "  -norc, --no-init       Skip user init files (~~/.clautolisp{,rc}, ~~/.autolisp{,rc},~%")
  (format t "                         ~~/.config/clautolisp/init, ~~/.config/autolisp/init).~%")
  (format t "                         Honoured equivalently via $AUTOLISP_NO_INIT or $CLAUTOLISP_NO_INIT.~%")
  (format t "Informational:~%")
  (format t "  -V, --version          Print the version string and exit.~%")
  (format t "  -h, --help             Show this help and exit.~%")
  (format t "  --list-encodings       Print every encoding name accepted by -e / -E~%")
  (format t "                         (mandatory four + every encoding the running CL~%")
  (format t "                         implementation exposes) and exit. Encoding names~%")
  (format t "                         are case-insensitive on the CLI.~%")
  (format t "  --list-situations      Print the encoding situations settable with~%")
  (format t "                         -E<situation>[-<dir>] / --<situation>[-<dir>]-encoding,~%")
  (format t "                         with their defaults, and exit. Under a backend flag,~%")
  (format t "                         shows that backend's defaults and their provenance.~%"))

(defun resolve-host-backend (name)
  "Return a HAL backend instance for the given --host argument."
  (cond
    ((or (null name)
         (string-equal name "nihil")
         (string-equal name "null")      ; null/none = deprecated aliases of nihil
         (string-equal name "none"))
     *nihil*)
    ((or (string-equal name "cador")
         (string-equal name "mock"))     ; "mock" is the deprecated alias of cador
     (make-cador))
    (t
     (error "Unknown host backend ~S. Expected one of: cador, nihil (mock=alias of cador, null/none=aliases of nihil)." name))))

(defun print-version ()
  (format t "~&clautolisp ~A~%" *version*))

(defun resolve-dialect (name-or-keyword)
  (let ((dialect (find-autolisp-dialect name-or-keyword)))
    (unless dialect
      (error "Unknown dialect ~S. Expected one of: strict, autocad-2026, bricscad-v26."
             name-or-keyword))
    dialect))

(defun keyword->dialect (dialect-keyword)
  "Map a parser dialect keyword (any name accepted by --dialect:
:strict / :autocad-2022 / :autocad-2026 / :autocad / :bricscad-v25 /
:bricscad-v26 / :bricscad / :clautolisp / :lax — an unversioned vendor
name resolving to the last known version) to clautolisp's dialect
descriptor. Delegates to the reader's single-source-of-truth registry
so adding a dialect only touches dialect.lisp."
  (or (find-autolisp-dialect (or dialect-keyword :strict))
      ;; Should never happen: parse-dialect validates against the same
      ;; registry. Fall back to strict rather than crash the launcher.
      (autolisp-dialect-strict)))

(defun keyword->host (host-keyword)
  "Map :cador / :mock / :null to a HAL backend instance. Defaults to
cador (the headless CAD core) when HOST-KEYWORD is nil (the empty
default for clautolisp omits --host). :mock is the deprecated alias."
  (case host-keyword
    ((nil :cador :mock)  (make-cador))
    ((:nihil :null)      *nihil*)))

(defun pop-required-argument (option arguments)
  "Pop the next argument off ARGUMENTS or signal a usage error
mentioning OPTION. Returns (values value remaining-arguments)."
  (unless arguments
    (error "Missing argument after ~A." option))
  (values (first arguments) (rest arguments)))

(defun parse-arguments (arguments)
  "Returns (values dialect actions quiet-p verbose-p debug-p
interactive-p host mock-input gui trace-p no-init-p load-encoding
no-color-p).

ACTIONS is a list of action records in the order they appear on
the command line. Each record is either (:FILE PATH) or
(:EXPRESSION TEXT). The front-end runs them sequentially against
a single shared evaluation context; -i additionally drops into
the REPL on the same context once the queue is drained. With no
actions and no -i, the REPL is the implicit fallback.

NO-INIT-P, when true, suppresses the user-init-file lookup
(`~/.clautolisp{,rc}{...}`, `~/.config/clautolisp/init{...}`,
plus the `~/.autolisp` and `~/.config/autolisp/init` siblings).
Mirrors the `-norc` / `--no-init` flag of the legacy bash
autolisp wrapper and matches alfe's flag of the same name.

NO-COLOR-P, when true, forces *COLOR-OUTPUT* to NIL so the
AutoLISP value printers emit no ANSI escape sequences. The
$NO_COLOR environment variable (https://no-color.org) is honoured
equivalently inside RESOLVE-COLOR-POLICY, so this flag is only
needed when the user wants per-invocation suppression without
exporting the variable.

The short-form aliases (-l, -x, -i, -q, -v, -d, -h, -V, -norc)
match the generic CLI surface specified for the sibling alfe
front-end."
  ;; Build clautolisp's spec: common-option-specs + clautolisp-only
  ;; specs for --mock-input / --gui / --trace. The shared parser
  ;; produces a CLI-OPTIONS struct; clautolisp maps the keyword
  ;; values to its runtime types (dialect descriptor, host instance)
  ;; further downstream in MAIN.
  (let ((specs
          (append
           clautolisp.autolisp-cli:*common-option-specs*
           (list
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--mock-input") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (declare (ignore name))
                        (setf (clautolisp.autolisp-cli:cli-options-mock-input opts) value)))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--gui") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (declare (ignore name))
                        (setf (clautolisp.autolisp-cli:cli-options-gui opts) value)))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--trace") :shorts nil :takes-arg-p nil
             :handler (lambda (opts value name)
                        (declare (ignore value name))
                        (setf (clautolisp.autolisp-cli:cli-options-trace-p opts) t)))
            ;; --- debugger (aldo) options (debugger §10,
            ;; debugger-public-interface-and-on-error.issue Parts B-D) ---
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--on-error") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-on-error opts)
                              (clautolisp.autolisp-cli:parse-on-error value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--on-interrupt") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-on-interrupt opts)
                              (clautolisp.autolisp-cli:parse-on-interrupt value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--on-quit") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-on-quit opts)
                              (clautolisp.autolisp-cli:parse-on-quit value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--debugger-ui") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-user-interface opts)
                              (clautolisp.autolisp-cli:parse-user-interface value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--aldb-listen") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (multiple-value-bind (host port)
                            (clautolisp.autolisp-cli:parse-aldb-listen value name)
                          (setf (clautolisp.autolisp-cli:cli-options-aldb-address opts) host
                                (clautolisp.autolisp-cli:cli-options-aldb-port opts) port))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--aldb-stdio") :shorts nil :takes-arg-p nil
             :handler (lambda (opts value name)
                        (declare (ignore value name))
                        (setf (clautolisp.autolisp-cli:cli-options-aldb-stdio-p opts) t)))
            ;; --- dribble options (dribble.issue) ---
            ;; --dribble takes an OPTIONAL value: bare `--dribble' (VALUE
            ;; nil) records into the default timestamped file;
            ;; `--dribble=FILE' records into FILE.
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--dribble") :shorts nil :takes-arg-p t :optional-arg-p t
             :handler (lambda (opts value name)
                        (declare (ignore name))
                        (setf (clautolisp.autolisp-cli:cli-options-dribble opts)
                              (or value t))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--dribble-interactors") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-dribble-interactors opts)
                              (clautolisp.autolisp-cli:parse-dribble-interactors
                               value name))))))))
    (let ((options (clautolisp.autolisp-cli:parse-arguments-with-spec specs arguments)))
      (validate-debugger-options options)
      options)))

(defun validate-debugger-options (options)
  "Cross-option validation for the aldb channel options
(debugger-public-interface-and-on-error.issue C.2): --aldb-stdio turns the
process's stdin/stdout into the aldb RPC channel, so it is mutually
exclusive with --interactive (the REPL would fight the RPC for stdio) and
with --aldb-listen (one transport at a time). Signals a cli-usage-error."
  (when (clautolisp.autolisp-cli:cli-options-aldb-stdio-p options)
    (when (clautolisp.autolisp-cli:cli-options-interactive-p options)
      (error 'clautolisp.autolisp-cli:cli-usage-error
             :option "--aldb-stdio"
             :message "--aldb-stdio and --interactive are mutually exclusive (stdio becomes the aldb RPC channel)"))
    (when (or (clautolisp.autolisp-cli:cli-options-aldb-address options)
              (clautolisp.autolisp-cli:cli-options-aldb-port options))
      (error 'clautolisp.autolisp-cli:cli-usage-error
             :option "--aldb-stdio"
             :message "--aldb-stdio and --aldb-listen are mutually exclusive (pick one aldb transport)")))
  options)

(defun effective-user-interface (options)
  "The --debugger-ui selection from OPTIONS, with the aldb-channel
implication (debugger-public-interface-and-on-error.issue C.3): an aldb
transport option (--aldb-listen / --aldb-stdio) implies the aldb UI unless
an explicit --debugger-ui says otherwise. NIL when no UI was requested."
  (or (clautolisp.autolisp-cli:cli-options-user-interface options)
      (and (or (clautolisp.autolisp-cli:cli-options-aldb-address options)
               (clautolisp.autolisp-cli:cli-options-aldb-port options)
               (clautolisp.autolisp-cli:cli-options-aldb-stdio-p options))
           :aldb)))

(defun aldb-transport-status (debug-ui aldb-listen)
  "How an aldb DEBUG-UI reaches Emacs (debugger §10). ALDB-LISTEN is :STDIO for
--aldb-stdio, a \"HOST:PORT\" string for --aldb-listen, else NIL. Returns:
  :not-aldb  — DEBUG-UI is not aldb;
  :stdio     — --aldb-stdio: RPC over the process stdin/stdout (Emacs launched
               clautolisp as an inferior process);
  :listener  — the TCP listener: --aldb-listen, or plain aldb (CLI or persisted
               default) which listens on the default address and prints the
               connect prompt.
Pure (no I/O) so the gating is unit-testable away from the CLI entry point."
  (cond ((not (eq debug-ui :aldb)) :not-aldb)
        ((eq aldb-listen :stdio)   :stdio)
        (t                         :listener)))

(defun aldb-default-listen-address ()
  "The default aldb listener address when nothing is configured: the persisted
default-aldb-listening-address / -port aldo settings, else 127.0.0.1 on an
OS-chosen FREE port (port 0). A random free port is a better default than a
fixed one — it never clashes with another session, and the actual port is
printed in the connect prompt (command reference §10); pin one via
default-aldb-listening-port if you want a stable port."
  (format nil "~A:~A"
          (or (ignore-errors
                (clautolisp.debug.ui:get-aldo-setting :default-aldb-listening-address))
              "127.0.0.1")
          (or (ignore-errors
                (clautolisp.debug.ui:get-aldo-setting :default-aldb-listening-port))
              0)))

(defun aldb-resolve-listener-address (debug-ui aldb-listen)
  "The HOST:PORT the aldb listener binds when DEBUG-UI is :aldb over the TCP
listener (not stdio): the --aldb-listen \"HOST:PORT\" if given, else the default
address. NIL when aldb is not over a listener."
  (when (eq (aldb-transport-status debug-ui aldb-listen) :listener)
    (if (stringp aldb-listen) aldb-listen (aldb-default-listen-address))))

(defun resolve-default-debugger-ui ()
  "The persisted default-user-interface aldo setting (command reference §8;
$XDG_CONFIG_HOME/clautolisp/aldo.conf), :tui when unset — the value an
explicit --debugger-ui overrides for this run only."
  (ignore-errors (clautolisp.debug.ui:load-aldo-configuration))
  (ignore-errors (clautolisp.debug.ui:load-lisp-configuration))
  ;; the aldo/lisp cascade (faces/bindings) rides in the two files above via the
  ;; settings consume hook; load the remaining cascade-only files (sedit/navi/…)
  ;; here (windows-and-interactor-templates.issue: the cascade shares the files).
  (ignore-errors (clautolisp.ui.ncurses:load-cascade-only-configurations))
  ;; Route (clal-sedit …) from the REPL through the LISP interactor's own
  ;; configuration. Only lisp.conf is active at the REPL — the debugger side
  ;; has its own bridge and gets the stacked aldo-over-lisp lookup
  ;; (lisp-configuration.issue).
  (setf clautolisp.sedit:*default-on-quit-policy*
        (lambda ()
          (or (ignore-errors (clautolisp.debug.ui:lisp-setting :sedit-on-quit))
              :ask)))
  ;; Make (clal-save-aldo-configuration) write the SAME self-documenting
  ;; aldo.conf that `,settings save' writes. The builtin cannot call the
  ;; debug UI's writer itself — the dependency runs the other way — so the
  ;; wiring lives here, where both sides are visible, and it serialises the
  ;; AUTOLISP variable (through the existing bridge) rather than the UI's
  ;; own store, so saving from AutoLISP still saves what AutoLISP holds
  ;; (clal-save-aldo-configuration-undocumented-file.issue).
  (setf clautolisp.autolisp-builtins-core::*aldo-configuration-writer*
        (lambda (stream)
          (clautolisp.debug.ui:write-aldo-configuration
           stream (clautolisp.debug.ui:read-config-variable))))
  ;; Shell escape (bang.issue). Two hooks for one feature, because the
  ;; interactor system is deliberately dependency-free: it can neither read
  ;; the configuration (which lives above it) nor spawn a process (which
  ;; would drag in uiop). Both are supplied here, where both are available.
  (setf clautolisp.interactor:*shell-escape-character-hook*
        (lambda ()
          (ignore-errors (clautolisp.debug.ui:shell-escape-character-setting)))
        clautolisp.interactor:*shell-escape-runner* #'run-shell-command)
  (or (ignore-errors (clautolisp.debug.ui:get-aldo-setting :default-user-interface))
      :tui))

(defun run-shell-command (command)
  "Run COMMAND through $SHELL with stdin/stdout/stderr INHERITED.

Inheriting is the whole point of bang.issue: `startapp' exists already and
does not do it, so an interactive shell command run from the REPL could
neither prompt nor page. Failure is reported, never signalled — a mistyped
shell command must not unwind the REPL that launched it."
  (let ((shell (or (uiop:getenv "SHELL") "/bin/sh")))
    (handler-case
        (uiop:run-program (list shell "-c" command)
                          :input :interactive
                          :output :interactive
                          :error-output :interactive
                          :ignore-error-status t)
      (error (condition)
        (format *error-output* "~&shell: ~A~%" condition)
        nil))))

(defun prepend-init-file-actions (actions no-init-p)
  "Walk the user's init-file stem list and prepend a (:FILE PATH)
action for each existing file, so they run before any -l / -x /
positional action. Returns the new action list. When NO-INIT-P is
true (the CLI flag or the documented env vars), returns ACTIONS
unchanged.

The two-arg env-var check `no-init-requested-p NO-INIT-P
\"CLAUTOLISP_NO_INIT\"` consolidates the CLI flag, the
$AUTOLISP_NO_INIT shared kill-switch, and the per-program
$CLAUTOLISP_NO_INIT env var into one boolean."
  (when (no-init-requested-p no-init-p "CLAUTOLISP_NO_INIT")
    ;; --no-init: do not load init files, and trust nothing on their
    ;; behalf (the SECURELOAD resolver's trusted-init-file set is empty).
    (clautolisp.autolisp-runtime:set-autolisp-trusted-init-files '())
    (return-from prepend-init-file-actions actions))
  (let ((init-paths (find-init-files *default-clautolisp-stems*)))
    ;; The init files the engine auto-loads are trusted by exact path, so
    ;; the SECURELOAD gate never warns/blocks on the user's own init
    ;; files. See the secureload trust model spec.
    (clautolisp.autolisp-runtime:set-autolisp-trusted-init-files init-paths)
    (append
     (loop for path in init-paths
           collect (cons :file (namestring path)))
     actions)))

;;; --- Verbosity / debug flags -----------------------------------------
;;;
;;; *verbose-p* enriches the REPL banner with the active host and any
;;; non-default knobs, and emits a one-line summary on batch action
;;; completion. *debug-p* additionally appends the host-Lisp backtrace
;;; to the AutoLISP backtrace printed on a runtime error. Both default
;;; to nil; the CLI flags (-v / -d, --verbose / --debug) set them per
;;; invocation.

(defparameter *verbose-p* nil)
(defparameter *debug-p* nil)

(defun span->string (span)
  (if (null span)
      "<unknown>"
      (format nil "~A:~D:~D-~D:~D"
              (or (source-span-source-name span) "<source>")
              (source-span-start-line span)
              (source-span-start-column span)
              (source-span-end-line span)
              (source-span-end-column span))))

(defun render-autolisp-value-safely (object)
  "Render OBJECT through the AutoLISP value printer, falling back to
~S if that printer signals (e.g. when the structure is malformed in
mid-error)."
  (handler-case (autolisp-value->string object nil)
    (error () (prin1-to-string object))))

(defun render-frame-arguments (arguments)
  "Render a list of AutoLISP argument values as a space-separated
parenthesised list, matching how the source would have written
them at the call site."
  (with-output-to-string (out)
    (write-char #\( out)
    (loop for cell on arguments
          for first-p = t then nil
          do (unless first-p (write-char #\Space out))
             (write-string (render-autolisp-value-safely (car cell)) out))
    (write-char #\) out)))

(defun format-call-stack-frame-for-cli (frame)
  "Render one (KIND . PAYLOAD) backtrace frame as a single line."
  (let ((kind (car frame))
        (payload (cdr frame)))
    (case kind
      (:eval        (format nil "  in EVAL: ~A"
                            (render-autolisp-value-safely payload)))
      (:special-op  (format nil "  in SPECIAL: ~A"
                            (render-autolisp-value-safely payload)))
      (:subr        (format nil "  in SUBR ~A: ~A"
                            (car payload)
                            (render-frame-arguments (cdr payload))))
      (:usubr       (format nil "  in USUBR ~A: ~A"
                            (car payload)
                            (render-frame-arguments (cdr payload))))
      (otherwise    (format nil "  ~A: ~S" kind payload)))))

(defun frame-is-noise-p (frame)
  "True for backtrace frames that add no information — :eval frames
whose form is a self-evaluating atom or a bare symbol. They dominate
the printout when arguments to a call are themselves atoms; hiding
them keeps the trace focused on actual call frames."
  (and (eq :eval (car frame))
       (let ((form (cdr frame)))
         (not (consp form)))))

(defun report-runtime-error (condition)
  (format *error-output* "~&clautolisp: runtime error: ~A: ~A~%"
          (autolisp-runtime-error-code condition)
          (autolisp-runtime-error-message condition))
  (let ((stack (autolisp-runtime-error-call-stack condition)))
    (cond
      ((null stack)
       (format *error-output*
               "AutoLISP backtrace: <no frames captured — signal raised outside an active evaluation context>~%"))
      (t
       (let ((interesting (remove-if #'frame-is-noise-p stack)))
         (format *error-output*
                 "AutoLISP backtrace (most recent call first, ~D frame~:P~@[, ~D atom frame~:P hidden~]):~%"
                 (length interesting)
                 (let ((hidden (- (length stack) (length interesting))))
                   (when (plusp hidden) hidden)))
         (dolist (frame interesting)
           (format *error-output* "~A~%"
                   (format-call-stack-frame-for-cli frame))))))
    ;; --debug additionally dumps the host-Lisp backtrace. Useful when
    ;; the runtime error is wrapping a deeper CL fault (e.g. an
    ;; integer overflow inside a builtin) that the AutoLISP frames
    ;; alone do not locate. uiop:print-backtrace is the portable
    ;; entry point across SBCL and CCL.
    (when *debug-p*
      (format *error-output* "~&CL backtrace (host Lisp):~%")
      (handler-case
          (uiop:print-backtrace :stream *error-output* :condition condition)
        (error (probe)
          (format *error-output*
                  "  <unable to render host backtrace: ~A>~%" probe))))))

(defun report-termination (condition)
  (format *error-output* "~&clautolisp: terminated by ~A~%"
          (autolisp-termination-kind condition)))

(defun report-error (condition)
  (format *error-output* "~&clautolisp: ~A~%" condition))

(defun print-host-backtrace (condition)
  "Dump the host-Lisp backtrace for an UNHANDLED internal error. Called from a
HANDLER-BIND at signal time — before the stack unwinds — so the trace reaches
the fault, not the handler. Used when the user asked to debug (--debug or
--on-error debug): an internal fault then shows where it came from instead of a
bare one-line condition. uiop:print-backtrace is the portable SBCL/CCL entry."
  (format *error-output*
          "~&clautolisp: unhandled internal error: ~A~%CL backtrace (host Lisp):~%"
          condition)
  (handler-case
      (uiop:print-backtrace :stream *error-output* :condition condition)
    (error (probe)
      (format *error-output* "  <unable to render host backtrace: ~A>~%" probe)))
  (finish-output *error-output*))

(defun setup-context (context host &optional mock-input)
  "Install the core builtins into the freshly created evaluation
context's namespace and attach the chosen HAL backend to its
session. When MOCK-INPUT is supplied and HOST is a MockHost,
attach the file at MOCK-INPUT as the host's prompt-stream so
that subsequent get* calls read deterministic answers from it."
  (when host
    (set-runtime-session-host (evaluation-context-session context) host))
  (when (and mock-input
             (typep host 'clautolisp.cador:cador))
    (let ((stream (open mock-input :direction :input
                                   :external-format :utf-8
                                   :if-does-not-exist :error)))
      (setf (clautolisp.cador:cador-prompt-stream host) stream)))
  (install-core-builtins))

(defun setup-builtins (context)
  "Backwards-compatible setup that uses the default HAL backend
inherited from *default-runtime-host*."
  (setup-context context nil))

;;; --- Interactive REPL -----------------------------------------------

(defun simple-error-diagnostic (condition)
  "Return the reader's structured diagnostic carried by CONDITION (the
parser raises a `simple-error` whose first format argument is a
`diagnostic`), or nil if the condition is not shaped that way."
  (let ((arguments (simple-condition-format-arguments condition)))
    (and arguments
         (typep (first arguments) 'diagnostic)
         (first arguments))))

(defun reader-error-incomplete-p (condition)
  "True iff CONDITION reports an unexpected end of input — i.e. the
parser ran out of tokens partway through a list, dotted pair, or
other structured form. Used by the REPL to know whether to prompt
for another continuation line."
  (let ((diagnostic (simple-error-diagnostic condition)))
    (and diagnostic
         (eq :unexpected-eof (diagnostic-code diagnostic)))))

(defun read-balanced-source-from-stream (stream prompt continuation-prompt
                                                  dialect)
  "Read whole, parser-balanced AutoLISP source from STREAM, prompting
between continuation lines. Returns (values text eofp) where TEXT is
the accumulated source string (with embedded newlines) or nil when
STREAM signalled end-of-file before any input was given."
  (let ((accumulated nil))
    (loop
      ;; The dribble omits prompts. It normally infers that from an input
      ;; line completing, but at end of input nothing completes, so the
      ;; prompt has to say what it is -- otherwise the pending partial
      ;; was recorded as ";; O: _$" at the end of every dribble file
      ;; (dribble-eof-prompt-recorded.issue).
      (with-dribble-prompt
        (write-string (if accumulated continuation-prompt prompt)))
      (finish-output)
      (let ((line (read-line stream nil :eof)))
        (cond
          ((and (eq line :eof) (null accumulated))
           (return (values nil t)))
          ((eq line :eof)
           ;; Treat a stranded continuation as end-of-input: surface
           ;; what we have (parser will surface a diagnostic).
           (return (values accumulated nil)))
          (t
           (setf accumulated
                 (if accumulated
                     (concatenate 'string accumulated (string #\Newline) line)
                     line))
           (handler-case
               (progn
                 (read-runtime-from-string
                  accumulated
                  :options (derive-reader-options-for-dialect
                            dialect :source-name "<repl>"))
                 (return (values accumulated nil)))
             (simple-error (condition)
               (unless (reader-error-incomplete-p condition)
                 (return (values accumulated nil)))))))))))

(defparameter *copyright-start-year* 2026
  "First year of the clautolisp copyright range shown in the REPL banner;
the end year is the current year, so a fresh year needs no source edit.")

(defun emit-repl-banner (dialect context &key mock-input gui trace-p)
  "Print the multi-line REPL welcome banner: product + version, copyright,
license + source URL, then the AUTOLISP REPL line naming the active dialect
and host. The whole banner is suppressed by -q/--quiet (the caller guards on
QUIET-P, i.e. verbosity :warn). With *verbose-p* on, append a line listing
any non-default knobs so the user sees exactly what they are typing into."
  (let* ((session (evaluation-context-session context))
         (host (clautolisp.autolisp-runtime:runtime-session-host session))
         (this-year (nth-value 5 (get-decoded-time))))
    (format t "~&Welcome to clautolisp Version ~A~%" *version*)
    (format t "Copyright ~D-~D Ogamita Ltd~%" *copyright-start-year* this-year)
    (format t "Licensed under AGPL; source codes available at:~%")
    (format t "http://gitlab.com/ogamita/clautolisp/~%")
    (format t "AUTOLISP REPL (~A dialect, ~A host) — Ctrl-D to exit.~%"
            (autolisp-dialect-name dialect)
            (host-name host))
    (when *verbose-p*
      (let ((knobs (remove nil
                           (list (when mock-input
                                   (format nil "mock-input=~A" mock-input))
                                 (when gui (format nil "gui=~A" gui))
                                 (when trace-p "trace=on")
                                 (when *debug-p* "debug=on")))))
        (when knobs
          (format t "  (~{~A~^, ~})~%" knobs))))))

;;; --- REPL history variables --------------------------------------------
;;;
;;; CL's REPL maintains - / + ++ +++ / * ** *** / / // ///. AutoLISP is a
;;; Lisp-1, so we can't clobber the names of the +, -, * and / functions
;;; — instead we use the colon-prefixed family :- :+ :++ :+++ :* :** :***
;;; :/ :// :///. AutoLISP's reader treats `:foo' as a plain identifier
;;; (not a self-binding keyword), so `(setq :- something)' is well-formed
;;; and `:-' at the prompt evaluates to whatever was last stored.
;;;
;;; These are REPL-only — they are never bound by source-file LOADs or
;;; -x actions. The repl-loop below rotates them around each iteration.

(defparameter *repl-form-history-symbols*
  '(":-" ":+" ":++" ":+++")
  "Form-history slots in oldest-to-newest order. `:-' is the form being
read this turn; `:+' is last turn's form; `:++' the one before; `:+++'
the one before that.")

(defparameter *repl-result-history-symbols*
  '(":*" ":**" ":***")
  "Result-history slots, newest first. `:*' is the previous result,
`:**' the one before, `:***' the one before that.")

(defparameter *repl-list-result-history-symbols*
  '(":/" "://" ":///")
  "List-of-result history. `:/' is `(list :*)' (a one-element list for
single-value evals — AutoLISP has no multiple values, so the wrap is
trivial; the slot exists for parity with CL where `/' / `//' / `///'
hold the whole multiple-value tuple).")

(defun %repl-intern (name)
  (intern-autolisp-symbol name))

(defun %repl-init-history (context)
  "Initialise every REPL history slot to nil up-front so that the first
time the user references one (before any turn has shifted a value in)
it evaluates to nil rather than signalling unbound-variable."
  (dolist (name (append *repl-form-history-symbols*
                        *repl-result-history-symbols*
                        *repl-list-result-history-symbols*))
    (set-variable (%repl-intern name) nil context)))

(defun %repl-bind-dash (form context)
  "Bind `:-' to the form about to be evaluated, BEFORE eval. The user
can legitimately reference `:-' from inside their form (e.g. to
inspect what they typed via `(print :-)'), and the end-of-turn rotate
needs `:-' to hold the just-evaluated form so that `:+ <- :-' lands
the right value."
  (set-variable (%repl-intern (first *repl-form-history-symbols*))
                form context))

(defun %repl-rotate-history (result context)
  "Called after a successful turn (with `:-' already holding the
just-evaluated form). Shifts the form and result histories one slot
older — `:+++' <- `:++' <- `:+' <- `:-' and `:***' <- `:**' <- `:*'
<- result — then refreshes the list-of-result slots `:/' / `://' /
`:///' so each holds `(list <its matching * slot>)'.

The colon-prefixed slot names are wired in the *repl-*-history-symbols
parameters; this helper just walks the shift mechanically. The pair
walk goes oldest-receiver-first so each slot reads its predecessor
*before* that predecessor itself gets overwritten on the next pair."
  (let* ((forms      (mapcar #'%repl-intern *repl-form-history-symbols*))
         (results    (mapcar #'%repl-intern *repl-result-history-symbols*))
         (list-slots (mapcar #'%repl-intern *repl-list-result-history-symbols*)))
    ;; Form history: oldest (:+++) <- previous (:++); :++ <- :+; :+ <- :-
    ;; (`:-' already holds this turn's form per %repl-bind-dash, so the
    ;; last pair `:+ <- :-' is exactly what we want).
    (loop for (target source) on (reverse forms) by #'cdr
          while source
          do (set-variable target
                           (nth-value 0 (lookup-variable source context))
                           context))
    ;; Result history: :*** <- :**; :** <- :*; :* <- result.
    (loop for (target source) on (reverse results) by #'cdr
          while source
          do (set-variable target
                           (nth-value 0 (lookup-variable source context))
                           context))
    (set-variable (first results) result context)
    ;; List-of-result slots: :/ <- (list :*); :// <- (list :**); etc.
    (loop for list-slot in list-slots
          for result-slot in results
          do (set-variable list-slot
                           (list (nth-value 0 (lookup-variable result-slot
                                                                context)))
                           context))))

(defun repl-eval-turn (forms context session break-on-error)
  "Evaluate one REPL turn's FORMS. With no SESSION this is the plain path (run
the user's *error* on an uncaught error, else re-signal to the REPL). With a
SESSION (--on-error debug) the turn runs under call-with-debugging so the aldo
debugger breaks at the live error frame BEFORE the stack unwinds: the debugger's
§10 handler is installed INSIDE (more recently than) call-with-autolisp-error-
handler, so it fires first. Declining (c) lets the error propagate to *error* /
the REPL; aborting (a/q) yields :ABORTED — this turn is dropped and the prompt
returns; and forms evaluate through the compiled-eval model so they are
instrumentable/steppable."
  (call-with-autolisp-error-handler
   (lambda ()
     (if session
         ;; Defer any CLAL-NAV-* request queued this turn to the post-turn
         ;; drain, so (clal-nav-function 'NAME) opens the navigator without a
         ;; fake break (bug-aldo-nav-entry-and-breakpoint-flow).
         (let ((clautolisp.debug:*defer-nav-request* t))
           (run-under-session-debugging
            session
            (lambda () (autolisp-eval-toplevel-progn forms context))
            break-on-error))
         (autolisp-eval-progn forms context)))
   context))

(defun %repl-drain-navigation-request (session)
  "After a REPL turn, if evaluating it queued a CLAL-NAV-* request (e.g.
(clal-nav-function 'NAME), (clal-nav-file \"f.lsp\")) and a debug SESSION is
attached, open the navigator now. This is the pre-debug entry that needs no
fake break: the request was queued during the turn but no stop occurred to
consume it (bug-aldo-nav-entry-and-breakpoint-flow)."
  (let ((request (and session clautolisp.debug:*pending-nav-request*)))
    (when request
      (setf clautolisp.debug:*pending-nav-request* nil)
      ;; The turn's dynamic context binding is gone; re-establish the session's
      ;; context so the navigator resolves the named function (ensure-metadata-
      ;; for-name defaults to the active evaluation context).
      (let ((clautolisp.autolisp-runtime.internal:*active-evaluation-context*
              (clautolisp.debug.ui:session-context session)))
        (clautolisp.debug.ui:ui-open-navigation-request
         (clautolisp.debug.ui:session-ui session) session request)))))

(defun wire-cador-to-terminal (context)
  "In an interactive REPL the MockHost has no prompt-stream, so every
get* (GETSTRING, GETINT, …) reads EOF and returns nil. Point the
host's prompt input at *standard-input* and its prompt output at
*standard-output* — via synonym streams so the wiring follows any
dynamic rebinding of those specials — so interactive get* calls read
the line the user types after the form. Only applies when the active
host is a MockHost that has no prompt-stream yet (i.e. --mock-input was
not supplied)."
  (let ((host (clautolisp.autolisp-runtime:runtime-session-host
               (evaluation-context-session context))))
    (when (and (typep host 'clautolisp.cador:cador)
               (null (clautolisp.cador:cador-prompt-stream host)))
      (setf (clautolisp.cador:cador-prompt-stream host)
            (make-synonym-stream '*standard-input*)
            (clautolisp.cador:cador-prompt-output host)
            (make-synonym-stream '*standard-output*)))))

;;; --- the AUTOLISP interactor: REPL comma-commands -----------------------
;;;
;;; The Lisp REPL is the bottom interactor (interactors design,
;;; issues/open/interactor-unification.issue): its reader takes a line
;;; starting with a comma as a command — `,date', `,quit' — and anything
;;; else as AutoLISP source. The comma keeps command names out of the
;;; expression namespace (at a toplevel read it is unambiguous: no
;;; backquote in AutoLISP).

;;; The *AUTOLISP* REPL interactor, its REPL-STATE, its reader/evaluator, and
;;; the "lisp" window template now live in the CLAUTOLISP.REPL library (below
;;; this tool, so a Lisp window is instantiable from the ncurses debugger).
;;; This file keeps the tool-specific parts: the comma-commands below (which
;;; register into *AUTOLISP*'s dictionaries), REPL-LOOP (which drives it), and
;;; the rich per-turn behaviour — installed into the library's hooks just after
;;; REPL-LOOP.

(define-command (*autolisp* d date) ()
    "Print the current date and time (ISO 8601)."
  (multiple-value-bind (se mi ho da mo ye)
      (decode-universal-time (get-universal-time))
    (format t "~&~4,'0D~2,'0D~2,'0DT~2,'0D~2,'0D~2,'0D~%"
            ye mo da ho mi se)))

(defvar *boot-time* nil
  "When this clautolisp process started (set by MAIN); ,uptime reports from it.")

(define-command (*autolisp* u uptime) ()
    "Print how long this clautolisp process has been running."
  (let* ((uptime (- (get-universal-time) (or *boot-time* (get-universal-time))))
         (sec (mod uptime 60))
         (min (mod (truncate uptime 60) 60))
         (hou (mod (truncate uptime 3600) 24))
         (day (truncate uptime 86400)))
    (format t "~&~:[~*~;~D day~:*~P, ~]~2,'0D:~2,'0D:~2,'0D~%"
            (plusp day) day hou min sec)))

(define-command (*autolisp* h help) ()
    "Print the REPL comma-commands."
  (format t "~&REPL commands (a line starting with `,'; anything else evaluates):~%")
  (dolist (dictionary (list (interactor-user-commands *autolisp*)
                            (interactor-commands *autolisp*)))
    (dolist (cmd (dictionary-commands dictionary))
      (format t "  ,~A~@[ / ,~A~]~28T~A~%"
              (command-key cmd)
              (let ((phrase (command-phrase cmd)))
                (and (plusp (length phrase)) phrase))
              (command-docstring cmd))))
  (format t "  Ctrl-D~28Texit the REPL~%"))

(define-command (*autolisp* q quit) ()
    "Exit the Lisp REPL (sometimes (quit) is not available)."
  (interactor-return :quit))

;;; The LISP interactor's own configuration (lisp-configuration.issue): the
;;; `,set' / `,settings' pair mirrors the debugger's `set' / `,settings'.
;;; Writes go to the ACTIVE interactor's configuration, so `,set' here always
;;; writes lisp.conf — never aldo.conf, even for a key both define.

(define-command (*autolisp* s set) (&whole arguments)
    "Show the LISP interactor's settings, or set one: ,set [NAME VALUE]."
  ;; The issue asked for a `,set NAME VALUE' / `,settings' pair. They are
  ;; folded into one command because the framework derives a command's key
  ;; from its words' initials, and `set' and `settings' both yield `s' — two
  ;; commands could not both be reached by key. Bare `,set' listing the
  ;; settings is the usual shell idiom anyway.
  (let* ((words (remove "" (uiop:split-string (string-trim " " (or arguments ""))
                                              :separator " ")
                        :test #'string=))
         (name (first words))
         (value (second words)))
    (cond
      ((null name)
       (format t "~&LISP interactor settings (~A):~%"
               (clautolisp.debug.ui:lisp-config-save-path))
       (dolist (line (clautolisp.debug.ui:lisp-settings-lines))
         (format t "  ~A~%" line))
       (format t "  ,set NAME VALUE changes one, ,write-settings persists it.~%~
  Inside DBG> the debugger's own `set' shadows these.~%"))
      ((null value)
       (format t "~&usage: ,set NAME VALUE  (bare ,set lists them)~%"))
      (t
       (handler-case
           (let ((stored (clautolisp.debug.ui:set-lisp-setting name value)))
             (format t "~&~(~A~) = ~A~%" name
                     (clautolisp.debug.ui:format-setting-value stored)))
         (error (condition)
           (format t "~&,set: ~A~%" condition)))))))

;; `,write-settings', not `,save-settings': the framework enforces the §0
;; naming rule that a command's key is its words' initials, and it derives the
;; long invocation by joining the words with SPACES. So `save-settings' would
;; have to take the key `s' — already `set' — and `(save settings)' would have
;; to be typed `,save settings'. `write' sidesteps both.
(define-command (*autolisp* w write-settings) ()
    "Write the LISP interactor's settings to lisp.conf."
  (handler-case
      (format t "~&saved ~A~%" (clautolisp.debug.ui:save-lisp-configuration))
    (error (condition) (format t "~&,write-settings: ~A~%" condition))))

(defun repl-loop (dialect context &key quiet-p mock-input gui trace-p
                                        session break-on-error
                                        dribble dribble-interactors)
  (unless quiet-p
    (emit-repl-banner dialect context
                      :mock-input mock-input :gui gui :trace-p trace-p))
  (unless mock-input
    (wire-cador-to-terminal context))
  (%repl-init-history context)
  ;; The dribble tee/echo streams were installed by RUN-WITH-INPUT
  ;; (before the debug session captured its streams); they are pure
  ;; pass-throughs until a dribble starts.
  (progn
    ;; --dribble / --dribble=FILE: start recording now — after the
    ;; banner, before the first prompt.
    (when dribble
      (clal-dribble (if (stringp dribble) dribble nil) dribble-interactors))
    (unwind-protect
         ;; Route sedit's `debug'/`aldo' prefix to the attached session's UI, so
         ;; debugger commands (e.g. `aldo help') work from inside (clal-sedit …).
         (let ((clautolisp.autolisp-runtime:*debug-command-hook*
                 (when session
                   (lambda (command)
                     (clautolisp.debug.ui:ui-run-command
                      (clautolisp.debug.ui:session-ui session) session command))))
               ;; The REPL is the bottom interactor: the single INTERACTOR-LOOP
               ;; drives the *AUTOLISP* singleton, this run's dialect / context /
               ;; session as the activation's state — a `,command' line dispatches
               ;; against *AUTOLISP*'s dictionaries, AutoLISP source goes to the
               ;; evaluator.
               ;; The stack is innermost-first: *AUTOLISP* on top, with the
               ;; sleeping-aldo interactor pushed BELOW it (aldo-command-from-
               ;; repl.issue) so a subset of aldo's breakpoint commands is
               ;; reachable from the REPL — shadowed by any same-name lisp
               ;; command, reached explicitly via the ALDO/DEBUG prefix.
               (*interactor-stack*
                 (list (make-activation *autolisp*
                                        (make-repl-state :context context
                                                         :session session
                                                         :break-on-error break-on-error))
                       (make-sleeping-aldo-activation session))))
           (when (null (interactor-loop))
             ;; EOF (Ctrl-D): a fresh line before leaving. ,quit / (quit) return
             ;; markers through INTERACTOR-RETURN and print nothing extra.
             (terpri)))
      ;; Leaving the REPL closes any active dribble (flushing a pending
      ;; partial output line).
      (dribble-stop))))

;;; Install the tool's rich per-turn REPL behaviour into the relocated
;;; *AUTOLISP* interactor (clautolisp.repl): the library keeps a minimal default
;;; so a Lisp window works stand-alone; the tool supplies the full turn (input
;;; history, the dribble, navigation requests, the debug-session eval path) via
;;; %REPL-EVAL-SOURCE, and the balanced/dribble-aware source reader
;;; %REPL-SOURCE-READER. Quoted symbols — resolved at call time; both functions
;;; are defined just below and are fbound before the first REPL turn runs.
(setf clautolisp.repl:*repl-eval-hook*          '%repl-eval-source
      clautolisp.repl:*repl-source-reader-hook* '%repl-source-reader)

(defun %repl-source-reader (dialect)
  "The sexp-reader COMMA-COMMAND-READ falls back to: read one whole,
parser-balanced AutoLISP turn from the input context (the prompt is already
printed; continuation lines get `   '). Returns (:SOURCE TEXT) or :EOF."
  (lambda (input-context)
    (multiple-value-bind (source eofp)
        (read-balanced-source-from-stream
         (input-context-stream input-context) "" "   " dialect)
      (if (or eofp (null source))
          :eof
          (list :source source)))))

(defun %repl-eval-source (source context session break-on-error exit)
  "Evaluate one REPL turn's SOURCE (the body of the historical repl-loop):
read — under the dialect in force NOW (READ-CURRENT-SOURCE, design-revision
D2) — record, bind :- , evaluate, print, rotate history, drain navigation.
Calls EXIT (a closure returning from the REPL loop) on AUTOLISP-TERMINATION."
  (handler-case
      (let* ((forms (read-current-source source :source-name "<repl>"
                                                :context context))
             ;; A turn evaluates the *last* form of the typed
             ;; sequence as the canonical "form being evaluated"
             ;; for the :- / :+ / :++ history. If the user typed
             ;; just one form (the common case) this is exactly
             ;; that form; multi-form turns get their final form
             ;; recorded — same convention as SLIME / Allegro's
             ;; repl bookkeeping.
             (this-form (car (last forms))))
        ;; Record this turn's source for sedit recall (spec §3): the raw
        ;; SOURCE text (runtime forms drop their spans), so `(clal-sedit
        ;; 'NAME)' can recall a REPL-defined function/variable's form.
        (ignore-errors (clautolisp.sedit:record-source source "<repl>"))
        ;; Bind :- BEFORE eval so the user's form can reference
        ;; what they just typed via (print :-), etc.
        (%repl-bind-dash this-form context)
        (let ((result (repl-eval-turn forms context session break-on-error)))
          ;; An aborted (a/q) debug turn yields :ABORTED — a CL sentinel,
          ;; not an AutoLISP value — so skip printing/history for it.
          (unless (eq result :aborted)
            (format t "~A~%" (autolisp-value->string result nil))
            (%repl-rotate-history result context)))
        ;; A turn that called (clal-nav-function 'NAME) etc. queued a
        ;; navigation request but never stopped; open the navigator now,
        ;; without faking a break (bug-aldo-nav-entry-and-breakpoint-flow).
        (%repl-drain-navigation-request session))
    (simple-error (condition)
      (dribble-condition condition)
      (let ((diagnostic (simple-error-diagnostic condition)))
        (if diagnostic
            (format *error-output* "~&; reader error: ~A: ~A~%"
                    (diagnostic-code diagnostic)
                    condition)
            (format *error-output* "~&; reader error: ~A~%" condition))))
    (autolisp-runtime-error (condition)
      (dribble-condition condition)
      (report-runtime-error condition))
    (autolisp-termination (condition)
      (dribble-condition condition)
      (report-termination condition)
      (funcall exit))))

(defun encoding-keyword (encoding-string)
  "Map a CLI encoding string to the Lisp keyword external-format.
Delegates to the shared CLI alias registry
(clautolisp.autolisp-cli:encoding-keyword); kept here as a thin
wrapper to preserve the (potentially nil-accepting) call shape used
by BUILD-CONTEXT below."
  (and encoding-string
       (clautolisp.autolisp-cli:encoding-keyword encoding-string "-Esource")))

(defun build-context (dialect host mock-input &optional load-encoding)
  "Make a fresh runtime context, install builtins, attach the host
and any mock-input stream. Computes an effective default source-file
encoding via the precedence:

  1. `-e ENC' on the CLI (LOAD-ENCODING — strongest, explicit).
  2. POSIX locale env: LC_ALL > LANG > LC_CTYPE (host-wide hint;
     LANG before LC_CTYPE per encoding.issue).
  3. NIL — fall through to the dialect's default at load time.

When (1) or (2) yields an encoding it is installed on the session;
subsequent loads (including nested (load ...) calls in init files)
use it instead of the dialect default."
  (let ((context (make-default-runtime-context :dialect dialect)))
    (setup-context context host mock-input)
    (let ((effective
            (or (and load-encoding (encoding-keyword load-encoding))
                (locale-default-source-encoding))))
      (when effective
        (set-default-source-encoding context effective)))
    context))

(defun maybe-summarise-action (kind label start-time)
  "Print a one-line completion summary to stderr when *verbose-p* is
on. KIND is :FILE or :EXPRESSION; LABEL is the action's surface
text (filename or an excerpt of the expression)."
  (when *verbose-p*
    (let ((elapsed (/ (float (- (get-internal-real-time) start-time))
                      internal-time-units-per-second)))
      (format *error-output*
              "~&clautolisp: ~A ~A in ~,3F s~%"
              (ecase kind
                (:file "loaded")
                (:expression "evaluated"))
              label
              elapsed))))

(defun eval-action-in-context (context action dialect)
  "Run one action — (:FILE . PATH) or (:EXPRESSION . TEXT) or
(:INTERACTIVE . T) — against CONTEXT (an already-set-up evaluation
context). DIALECT is the dialect descriptor used to derive reader
options. All actions in a queue share one context, so side
effects compose.

Dynamic *AUTOLISP-…* variables are bound for the action's duration:
*AUTOLISP-LOAD-PATHNAME* for :file, *AUTOLISP-EXPRESSION* for
:expression. Cleared on return (success or signal). (:interactive)
is handled separately by the REPL wrapper in RUN-WITH-INPUT."
  (let ((kind (car action))
        (payload (cdr action)))
    (ecase kind
      (:file
       (let ((options (derive-reader-options-for-dialect
                       dialect :source-name (namestring payload))))
         (clautolisp.autolisp-cli:call-with-dynamic-transmit-binding
          context "*AUTOLISP-LOAD-PATHNAME*"
          (make-autolisp-string (namestring payload))
          (lambda ()
            (autolisp-load-file-in-context payload context :options options)))))
      (:expression
       (let* ((options (derive-reader-options-for-dialect
                        dialect :source-name "<-x>"))
              (forms (read-runtime-from-string payload :options options)))
         (clautolisp.autolisp-cli:call-with-dynamic-transmit-binding
          context "*AUTOLISP-EXPRESSION*"
          (make-autolisp-string payload)
          (lambda ()
            (call-with-autolisp-error-handler
             (lambda () (autolisp-eval-progn forms context))
             context)))))
      (:interactive
       ;; The (:interactive . T) action is a placeholder so the
       ;; queue order is preserved when the user mixed -i in with
       ;; -l/-x; the actual REPL invocation is driven by the
       ;; interactive-p flag in RUN-WITH-INPUT.
       nil))))

;;; --- Batch entry points ---------------------------------------------

(defun usage-string ()
  "Return the --help output as a string. Captured for the
*AUTOLISP-HELP* global by re-running USAGE against a string sink."
  (with-output-to-string (*standard-output*)
    (usage)))

(defun debug-ui-designator (ui-keyword)
  "Map a --debugger-ui keyword to a registered UI designator
(register-ui name). :tui is the dumb/terminal UI."
  (ecase ui-keyword
    (:tui :terminal)
    (:ncurses :ncurses)
    (:aldb :aldb)))

(defun ncurses-terminal-screen ()
  "Return a real terminal screen for the ncurses debugger UI, or NIL (after a
warning) when no curses backend is present in this image.

Preferred backend: the no-grovel CFFI ncurses backend (package
clautolisp.ui.tui.curses, system clautolisp-tui-curses) — its CL code carries
no build-time dependency on ncurses and opens libncurses on demand. The retired
cl-charms backend (clautolisp.ui.tui.charms) is accepted as a fallback if still
loaded. Either must be present in the image (a build that includes it, or an
init file that loads it); when neither is, we return NIL and the caller falls
back to the terminal (tui) UI rather than crashing on an unbound screen slot."
  (flet ((backend-sym (package name)
           (let ((sym (and (find-package package)
                           (find-symbol (string name) package))))
             (and sym (fboundp sym) sym))))
    ;; The FIRST backend present in the image decides the outcome: if its
    ;; libncurses can be opened we hand back a screen; if it is present but
    ;; unusable on this host (libncurses missing / unlinkable), we PROBE that
    ;; here and fall back to the tui UI with the real reason — rather than
    ;; deferring a raw alien crash to the first debugger stop.
    (dolist (backend '((#:clautolisp.ui.tui.curses  ; no-grovel CFFI backend
                        #:make-curses-screen #:curses-available-p)
                       (#:clautolisp.ui.tui.charms  ; retired cl-charms, if loaded
                        #:make-charms-screen nil))
                      ;; neither backend present in this image:
                      (progn
                        (format *error-output*
                                "~&clautolisp: --debugger-ui ncurses needs a curses backend ~
(package clautolisp.ui.tui.curses, system clautolisp-tui-curses), not loaded in ~
this image; using the terminal (tui) UI instead.~%")
                        nil))
      (destructuring-bind (package maker-name probe-name) backend
        (let ((maker (backend-sym package maker-name)))
          (when maker
            (let ((probe (and probe-name (backend-sym package probe-name))))
              (multiple-value-bind (usable reason)
                  (if probe (funcall probe) (values t nil))
                (return
                  (if usable
                      (funcall maker)
                      (progn
                        (format *error-output*
                                "~&clautolisp: --debugger-ui ncurses: the curses backend is ~
present but not usable on this host — ~A.~%Using the terminal (tui) UI instead.~%"
                                (or reason "libncurses could not be initialized"))
                        nil)))))))))))

;;;; --- the aldb (Emacs) TCP listener (debugger §10) ------------------
;;;;
;;;; --aldb-listen [HOST:]PORT (and a persisted default-user-interface aldb) open
;;;; a TCP listener. The FIRST time the program reaches the debugger, aldo prints
;;;; the connect line on the terminal and WAITS — for an Emacs aldb connection at
;;;; the listener, or for the user to type 1/2 to fall back to the tui / ncurses
;;;; UI for the session. The prompt is LAZY (no stop ⇒ no prompt; the program
;;;; runs normally until it breaks). The listener is a forwarding UI wrapper whose
;;;; DELEGATE — the emacs-ui over the accepted socket, or a tui/ncurses UI — is
;;;; chosen at that first stop (inside CALL-WITH-STOP-INTERACTOR, which wraps the
;;;; whole stop) and drives every stop thereafter.

(defvar *aldb-listener-address* nil
  "When non-NIL (bound in RUN for the aldb TCP-listener transport), the
\"HOST:PORT\" START-DEBUG-SESSION opens an ALDB-LISTENER-UI on instead of a bare
stdin/stdout emacs-ui.")

(defclass aldb-listener-ui ()
  ((socket     :initarg :socket   :accessor aldb-socket)     ; usocket listener
   (address    :initarg :address  :accessor aldb-address)    ; "HOST:PORT" shown
   (context    :initarg :context  :accessor aldb-context)    ; for a tui/ncurses fallback
   (connection :initform nil      :accessor aldb-connection) ; the accepted usocket, if any
   (delegate   :initform nil      :accessor aldb-delegate))  ; the chosen real UI
  (:documentation "A debugger UI that listens for an Emacs aldb connection and,
at the first stop, becomes (delegates to) the emacs-ui over the accepted socket
— or the tui / ncurses UI the user picked at the connect prompt (§10)."))

(defun aldb-clean-host (host)
  (let ((h (string-trim " " host)))
    (cond ((string= h "") "127.0.0.1")
          ((and (> (length h) 1) (char= (char h 0) #\[)
                (char= (char h (1- (length h))) #\]))
           (subseq h 1 (1- (length h))))          ; [::1] -> ::1
          (t h))))

(defun aldb-tokens (line)
  "The whitespace-separated tokens of LINE."
  (loop with len = (length line) with i = 0
        for start = (position-if-not (lambda (c) (member c '(#\Space #\Tab))) line :start i)
        while start
        for end = (or (position-if (lambda (c) (member c '(#\Space #\Tab))) line :start start)
                      len)
        collect (subseq line start end)
        do (setf i end)))

(defun aldb-services-file ()
  "The system services database path: %SystemRoot%\\System32\\drivers\\etc\\
services on Windows, else /etc/services."
  (or (and (uiop:os-windows-p)
           (let ((root (uiop:getenv "SystemRoot")))
             (and root (plusp (length root))
                  (merge-pathnames "System32/drivers/etc/services"
                                   (uiop:ensure-directory-pathname root)))))
      #p"/etc/services"))

(defun aldb-resolve-service-port (name)
  "Resolve TCP service NAME to a port number via the system services database
(getservbyname-style: /etc/services, or the Windows equivalent — a line
=NAME PORT/tcp [ALIASES…]=). Case-insensitive on the name/aliases. Signal an
error when NAME is unknown (or the database is absent)."
  (with-open-file (in (aldb-services-file) :if-does-not-exist nil)
    (when in
      (loop for line = (read-line in nil nil) while line do
        (let ((tokens (aldb-tokens (subseq line 0 (position #\# line)))))
          (when (>= (length tokens) 2)
            (destructuring-bind (service port/proto &rest aliases) tokens
              (let ((slash (position #\/ port/proto)))
                (when (and slash
                           (string-equal "tcp" (subseq port/proto (1+ slash)))
                           (or (string-equal name service)
                               (member name aliases :test #'string-equal)))
                  (return-from aldb-resolve-service-port
                    (parse-integer port/proto :end slash))))))))))
  (error "aldb: unknown TCP service ~S (not in ~A)" name (aldb-services-file)))

(defun aldb-port-number (port-string)
  "PORT-STRING as a port integer: a decimal number, or a TCP service name
resolved via the system services database."
  (if (and (plusp (length port-string)) (every #'digit-char-p port-string))
      (parse-integer port-string)
      (aldb-resolve-service-port port-string)))

(defun aldb-split-address (address)
  "Split \"[HOST:]PORT\" into (values HOST PORT-integer). A bare token is a port
on 127.0.0.1; PORT is a decimal number or a TCP service name; [::1]:PORT keeps
the bracketed IPv6 host. The LAST colon separates host from port."
  (let ((colon (position #\: address :from-end t)))
    (if (and colon (< (1+ colon) (length address)))
        (values (aldb-clean-host (subseq address 0 colon))
                (aldb-port-number (subseq address (1+ colon))))
        (values "127.0.0.1" (aldb-port-number address)))))

(defun make-aldb-listener-ui (address context)
  "Open a TCP listener at ADDRESS (\"HOST:PORT\"; PORT 0 = an OS-chosen free
port) and return an ALDB-LISTENER-UI that accepts the Emacs aldb connection
there at the first stop. CONTEXT builds the tui/ncurses fallback UI."
  (multiple-value-bind (host port) (aldb-split-address address)
    (let* ((socket (usocket:socket-listen host port
                                          :reuse-address t
                                          :element-type 'character))
           (actual (usocket:get-local-port socket)))
      (make-instance 'aldb-listener-ui
                     :socket socket
                     :address (format nil "~A:~A" host actual)
                     :context context))))

(defun aldb-stop-reason-line (hit)
  "A one-line reason for the stop, shown above the connect prompt, or NIL."
  (and hit
       (member (clautolisp.debug:hit-stop-reason hit) '(:unhandled-error :caught-error))
       (clautolisp.debug:hit-error-message hit)))

(defun aldb-el-path ()
  "The filesystem path of the shipped Emacs client aldb.el, or NIL when it can't
be located. Checks the in-tree source (dev checkout) first, then the installed
site-lisp copy — $PREFIX/share/emacs/site-lisp/clautolisp/aldb.el, derived from
the installed CL source tree (…/share/common-lisp/source/clautolisp/…), where
`make install-emacs' puts it. Best-effort via ASDF."
  (flet ((existing (path) (and path (let ((p (ignore-errors (probe-file path))))
                                      (and p (namestring p))))))
    (or
     ;; dev checkout: emacs/aldb.el beside the emacs-UI system's source
     (ignore-errors
       (existing (asdf:system-relative-pathname
                  "clautolisp/autolisp-debug-ui-emacs" "emacs/aldb.el")))
     ;; installed: reconstruct <…>/share/emacs/site-lisp/clautolisp/aldb.el from
     ;; the system source dir (…/share/common-lisp/source/clautolisp/…-emacs/)
     (ignore-errors
       (let* ((dir (pathname-directory
                    (asdf:system-source-directory "clautolisp/autolisp-debug-ui-emacs")))
              (share (position "share" dir :test #'string= :from-end t)))
         (when share
           (existing
            (make-pathname :directory (append (subseq dir 0 (1+ share))
                                              '("emacs" "site-lisp" "clautolisp"))
                           :name "aldb" :type "el"))))))))

(defun aldb-print-connect-prompt (ui hit)
  ;; NB continue long format lines with ~<newline> (tilde-newline), which elides
  ;; the source newline + indentation — a bare \\<newline> in a CL string is a
  ;; LITERAL newline, so it would double every ~% here.
  (multiple-value-bind (host port) (aldb-split-address (aldb-address ui))
    (let ((el (aldb-el-path)))
      (format t "~&~@[~A~%~]~
Aldo debugger activated, connect from Emacs aldb:~%~
~@[~4TM-x load-file RET ~A RET~%~]~
~4TM-x aldb-connect RET ~A RET ~A RET~%~
Alternatively, select a terminal or ncurses user interface,~%~
~2T1) TUI~%~2T2) ncurses~%Debugger UI? "
              (aldb-stop-reason-line hit) el host port)))
  (finish-output))

(defun aldb-poll-terminal-choice ()
  "If the terminal has a line ready, read it: 1 → :tui, 2 → :ncurses, else NIL."
  (when (listen *standard-input*)
    (let ((line (read-line *standard-input* nil nil)))
      (when line
        (case (find-if-not (lambda (c) (member c '(#\Space #\Tab))) line)
          (#\1 :tui) (#\2 :ncurses) (t nil))))))

(defun aldb-fallback-ncurses-ui ()
  (let ((screen (ncurses-terminal-screen)))
    (if screen
        (clautolisp.debug.ui:make-ui :ncurses :screen screen)
        (clautolisp.debug.ui:make-ui :terminal))))

(defun aldb-wait-for-delegate (ui)
  "Block until an Emacs aldb connects at the listener (→ an emacs-ui over the
socket) or the user types 1/2 at the terminal (→ a tui/ncurses UI)."
  (loop
    (when (usocket:wait-for-input (aldb-socket ui) :timeout 1 :ready-only t)
      (let* ((conn (usocket:socket-accept (aldb-socket ui) :element-type 'character))
             (stream (usocket:socket-stream conn)))
        (setf (aldb-connection ui) conn)
        (format t "~&aldb connected.~%") (finish-output)
        (return (clautolisp.debug.ui:make-ui :aldb :input stream :output stream))))
    (let ((choice (aldb-poll-terminal-choice)))
      (when choice
        (format t "~&using ~A.~%" (string-downcase (symbol-name choice))) (finish-output)
        (return (ecase choice
                  (:tui (clautolisp.debug.ui:make-ui :terminal))
                  (:ncurses (aldb-fallback-ncurses-ui))))))))

(defun aldb-ensure-delegate (ui session hit)
  "On the first stop, print the connect prompt and block until a delegate is
chosen (an Emacs connection or a 1/2 fallback), then attach it. Idempotent."
  (unless (aldb-delegate ui)
    (aldb-print-connect-prompt ui hit)
    (setf (aldb-delegate ui) (aldb-wait-for-delegate ui))
    (clautolisp.debug.ui:ui-attached (aldb-delegate ui) session)))

(defun aldb-close-listener (ui)
  "Tear the listener down cleanly. On the accepted connection: flush what we
wrote (the trailing (:detached)), then DRAIN any bytes the client already sent
that we never read, and only then close. A close() while unread input sits in
the socket's receive buffer makes the OS send a TCP RST to the peer (notably on
macOS/BSD); that RST discards the (:detached) line still queued in the client's
receive buffer, so the client sees `connection reset' instead of reading its
last line then a clean EOF. Draining first lets close() send an orderly FIN."
  (let ((conn (aldb-connection ui)))
    (when conn
      (ignore-errors
       (let ((stream (usocket:socket-stream conn)))
         (finish-output stream)
         (loop while (listen stream) do (read-char stream nil nil))))
      (ignore-errors (usocket:socket-close conn))))
  (ignore-errors (usocket:socket-close (aldb-socket ui))))

;;; The wrapper defers until the first stop: CALL-WITH-STOP-INTERACTOR wraps the
;;; whole stop (announcement included), so activating there means the delegate is
;;; chosen before any notification and its own stop-interactor wrap (e.g. the
;;; dumb UI's ALDO) still frames the stop. Every other notification forwards to
;;; the delegate once it exists; UI-ATTACHED keeps the protocol default (no-op)
;;; so nothing happens at session start — only at the first real stop.

(defmethod clautolisp.debug.ui:call-with-stop-interactor
    ((ui aldb-listener-ui) session hit thunk)
  (aldb-ensure-delegate ui session hit)
  (clautolisp.debug.ui:call-with-stop-interactor (aldb-delegate ui) session hit thunk))

(macrolet ((forward (name (&rest args))
             `(defmethod ,name ((ui aldb-listener-ui) ,@args)
                (let ((d (aldb-delegate ui)))
                  (when d (,name d ,@args))))))
  (forward clautolisp.debug.ui:ui-thread-hit (session hit))
  (forward clautolisp.debug.ui:ui-thread-unhandled-error (session hit))
  (forward clautolisp.debug.ui:ui-thread-caught-error (session hit))
  (forward clautolisp.debug.ui:ui-thread-resumed (session))
  (forward clautolisp.debug.ui:ui-thread-exited (session outcome))
  (forward clautolisp.debug.ui:ui-show-source (source-position))
  (forward clautolisp.debug.ui:ui-breakpoint-added (breakpoint))
  (forward clautolisp.debug.ui:ui-breakpoint-removed (breakpoint))
  (forward clautolisp.debug.ui:ui-open-navigation-request (session request)))

(defmethod clautolisp.debug.ui:ui-await-command ((ui aldb-listener-ui) session hit)
  (let ((d (aldb-delegate ui)))
    (if d (clautolisp.debug.ui:ui-await-command d session hit) :continue)))

(defmethod clautolisp.debug.ui:ui-show-stop-source-p ((ui aldb-listener-ui))
  (let ((d (aldb-delegate ui)))
    (if d (clautolisp.debug.ui:ui-show-stop-source-p d) t)))

(defmethod clautolisp.debug.ui:ui-show-message
    ((ui aldb-listener-ui) level format-string &rest args)
  (let ((d (aldb-delegate ui)))
    (when d (apply #'clautolisp.debug.ui:ui-show-message d level format-string args))))

(defmethod clautolisp.debug.ui:ui-run-command
    ((ui aldb-listener-ui) session command &optional hit)
  (let ((d (aldb-delegate ui)))
    (when d (clautolisp.debug.ui:ui-run-command d session command hit))))

(defmethod clautolisp.debug.ui:ui-detached ((ui aldb-listener-ui))
  ;; A disconnecting Emacs must not crash the debugged session: if the client
  ;; is already gone, writing the delegate's (:detached) hits a broken pipe —
  ;; swallow it and still close the listener.
  (let ((d (aldb-delegate ui)))
    (when d (ignore-errors (clautolisp.debug.ui:ui-detached d))))
  (aldb-close-listener ui))

(defun build-debug-ui (debug-ui context)
  "Construct the debugger UI object for the keyword DEBUG-UI (:tui/:ncurses/:aldb),
applying the transport/screen specials: :aldb with a bound listener address becomes
an ALDB-LISTENER-UI; :ncurses acquires a real terminal screen, falling back to the
terminal (tui) UI when the curses backend is unavailable (rather than crashing on
an unbound screen). Shared by session start and the live per-stop UI selector."
  (if (eq debug-ui :aldb)
      ;; aldb reaches Emacs over a channel. A configured listener address
      ;; (--aldb-listen, or the launch aldb default) binds it; --aldb-stdio
      ;; explicitly uses the process stdin/stdout. Otherwise — nothing
      ;; configured, e.g. a live switch to aldb (aldb-stdio-is-a-poor-default) —
      ;; default to a TCP listener on 127.0.0.1 / a free port, NOT stdio: the
      ;; user connects from Emacs at the address the connect prompt prints.
      (cond
        (*aldb-listener-address*
         (make-aldb-listener-ui *aldb-listener-address* context))
        ((eq clautolisp.autolisp-runtime:*clal-aldb-listen* :stdio)
         (clautolisp.debug.ui:make-ui :aldb))
        (t
         (make-aldb-listener-ui (aldb-default-listen-address) context)))
      (let* ((screen (when (eq debug-ui :ncurses) (ncurses-terminal-screen)))
             (designator (if (and (eq debug-ui :ncurses) (null screen))
                             :terminal
                             (debug-ui-designator debug-ui))))
        (apply #'clautolisp.debug.ui:make-ui designator
               (when screen (list :screen screen))))))

(defun live-debugger-ui-keyword ()
  "The LIVE debugger-UI selection: the AutoLISP *CLAL-DEBUGGER-UI* variable when
it names one of :tui/:ncurses/:aldb, else the CLI-set *clal-debugger-ui* default
(the same override pattern as the interrupt/quit policies). Read fresh at each
stop, so (setq *clal-debugger-ui* 'tui) picks the UI for the NEXT debugger entry."
  (clautolisp.autolisp-builtins-core:live-event-policy
   "*CLAL-DEBUGGER-UI*"
   clautolisp.autolisp-runtime:*clal-debugger-ui*
   '(:tui :ncurses :aldb)))

(defun make-debug-ui-selector (initial-kind initial-ui context)
  "A closure the debug session calls at each stop to get the UI to use, honoring
the LIVE *CLAL-DEBUGGER-UI* (debugger-ui-live-switch). It remembers the current
kind and its constructed UI, rebuilding (a fresh screen/socket) only when the kind
actually changes, and returns the SAME object while the kind is unchanged so the
session does no needless detach/attach. Seeded with the launch UI so the first
stop reuses the one session start already attached."
  (let ((kind initial-kind) (ui initial-ui))
    (lambda ()
      (let ((want (live-debugger-ui-keyword)))
        (unless (eql want kind)
          (setf kind want ui (build-debug-ui want context)))
        ui))))

(defun start-debug-session (debug-ui context)
  "Start the debugger session for DEBUG-UI, installing a per-stop UI SELECTOR so
the live *CLAL-DEBUGGER-UI* selection is honored at every debugger entry (a
program may switch UI between stops). The launch UI is built once and reused
until the selection changes; see BUILD-DEBUG-UI for the transport/screen
specials."
  ;; Make the CLAL-OPTIMIZATION DEBUG level authoritative for instrumentation at
  ;; session start: derive the runtime gate from it so a debuggable-configured
  ;; run (DEBUG>0 — the default) actually weaves instrumented forks, and a
  ;; DEBUG-0/SPACE run does not. (CLAL-OPTIMIZE keeps the gate in sync for LIVE
  ;; changes; this covers the launch value / any path that set DEBUG without it.)
  (setf clautolisp.autolisp-runtime:*debug-instrumentation-enabled*
        (plusp (clautolisp.autolisp-builtins-core:clal-optimization-level :debug)))
  (let* ((initial-ui (build-debug-ui debug-ui context))
         (selector (make-debug-ui-selector debug-ui initial-ui context)))
    (clautolisp.debug.ui:start-session
     :ui initial-ui :context context :ui-selector selector)))

;;; --- SIGINT / --on-interrupt (debugger-public-interface-and-on-error
;;; Part B) -------------------------------------------------------------

(defvar *interrupt-in-progress* nil
  "True while a Control-C is being handled under the :DEBUG interrupt
policy (e.g. the aldo debugger is up at the interrupt point). A second
SIGINT while it is set means the user wants out NOW, forgoing the
debugger: the process exits immediately with status 130. A global (not a
dynamic binding) because the raw signal handler may run on another
thread.")

(defun handle-interrupt ()
  "The main-thread part of the SIGINT handler: apply the LIVE
*CLAL-ON-INTERRUPT* policy (the AutoLISP variable overrides the CLI-set
default). :IGNORE returns, which resumes the interrupted computation;
:QUIT exits with status 130 (128+SIGINT, the shell convention); :DEBUG
breaks into the aldo debugger at the current poll point — continuing
resumes the program, aborting unwinds to the toplevel REPL. With no
active debug session :DEBUG degrades to :QUIT (there is no debugger to
enter)."
  (let ((policy (clautolisp.autolisp-builtins-core:live-event-policy
                 "*CLAL-ON-INTERRUPT*"
                 clautolisp.autolisp-runtime:*clal-on-interrupt*
                 '(:debug :ignore :quit))))
    (case policy
      (:ignore nil)
      (:quit
       (format *error-output* "~&clautolisp: interrupted.~%")
       (finish-output *error-output*)
       (quit 130))
      (otherwise                        ; :debug
       (cond
         ((and clautolisp.autolisp-runtime:*debugging*
               clautolisp.autolisp-runtime:*debug-break-hook*)
          (setf *interrupt-in-progress* t)
          (unwind-protect
               (funcall clautolisp.autolisp-runtime:*debug-break-hook*
                        "interrupt (Control-C)")
            (setf *interrupt-in-progress* nil)))
         (t
          (format *error-output*
                  "~&clautolisp: interrupted (no debug session active; ~
                   the debug interrupt policy degrades to quit).~%")
          (finish-output *error-output*)
          (quit 130)))))))

(defun install-interrupt-handler ()
  "Install the process SIGINT handler implementing --on-interrupt /
*CLAL-ON-INTERRUPT* (Part B). The raw handler only forwards to
HANDLE-INTERRUPT on the thread that installed it (the main AutoLISP
thread), where the interruption runs at the next safe point — returning
from it resumes the interrupted computation, which is how :IGNORE and the
debugger's `continue' work. A second SIGINT while one is being handled
exits immediately (status 130). Returns T when a handler was installed;
NIL on implementations where the native Control-C behaviour is kept.

On SBCL/Windows the native console keeps its own Control-C behaviour:
the POSIX-signal API this uses (SB-SYS:ENABLE-INTERRUPT, SB-UNIX:SIGINT)
does not exist in the win32 build — those symbols are absent from the
SB-SYS / SB-UNIX packages, so the guarded form must be excluded at
*read* time (a plain #+sbcl would still fail COMPILE-FILE while reading
the package-qualified symbols). The (not win32) reader conditional does
that, degrading to the documented NIL."
  #+(and sbcl (not win32))
  (let ((thread sb-thread:*current-thread*))
    (sb-sys:enable-interrupt
     sb-unix:sigint
     (lambda (signal info context)
       (declare (ignore signal info context))
       (if *interrupt-in-progress*
           (progn
             (ignore-errors
              (format *error-output* "~&clautolisp: second interrupt — exiting.~%")
              (finish-output *error-output*))
             (sb-ext:exit :code 130 :abort t))
           (sb-thread:interrupt-thread thread #'handle-interrupt))))
    t)
  #-(and sbcl (not win32))
  nil)

(defun run-under-session-debugging (session thunk break-on-error)
  "Run THUNK with debugging active under an already-attached SESSION (debugger
§10): an uncaught AutoLISP error stops in the session's UI when BREAK-ON-ERROR
is set (--on-error debug), and stepping/breakpoints ride on the instrumented
forks the compiled-eval weaves. Returns THUNK's value, or :ABORTED if the user
aborted from the debugger. Each call is its own abort extent, so a REPL turn's
abort returns to the prompt rather than unwinding the whole loop."
  (let ((clautolisp.debug:*break-on-error* break-on-error)
        (clautolisp.debug:*debug-hit-handler*
          (lambda (hit) (clautolisp.debug.ui:session-stop session hit))))
    (clautolisp.debug:call-with-debugging
     thunk :thread-info (clautolisp.debug.ui:session-thread-info session))))

(defun run-with-input (dialect actions cli-options
                       &key quiet-p verbose-p debug-p
                            interactive-p host mock-input gui trace-p
                            load-encoding io-encoding
                            no-init-p no-color-p
                            debug-ui on-error-policy
                            dribble dribble-interactors)
  "Build a shared evaluation context, install the CLI-derived
*AUTOLISP-…* globals from CLI-OPTIONS via the shared
clautolisp.autolisp-cli installer, run every action in ACTIONS in
order, then enter the REPL on the same context when INTERACTIVE-P
is true.

INTERACTIVE-P expresses the *effective* request — true when either
the CLI passed -i / --interactive, OR the user supplied no explicit
-l / -x / positional action so the REPL is the implicit default.
The caller computes this; the function intentionally does not
inspect ACTIONS to make the decision, because by the time this
function is called ACTIONS may include init-file loads (which are
machinery, not user intent)."
  (declare (ignore verbose-p debug-p
                   load-encoding io-encoding
                   no-init-p no-color-p))
  (handler-case
      (let* ((context (build-context dialect host mock-input
                                     (clautolisp.autolisp-cli:cli-options-load-encoding
                                      cli-options)))
             (bindings (clautolisp.autolisp-cli:cli-options->transmit-bindings
                        cli-options
                        :backend "CLAUTOLISP"
                        :frontend "CLAUTOLISP"
                        :usage-text (usage-string)
                        :version-text *version*))
             ;; The dribble tee/echo streams (dribble.issue) are
             ;; installed UNCONDITIONALLY — pure pass-throughs while no
             ;; dribble is active, so (clal-dribble) can start recording
             ;; at any time. Installed HERE, before the debug session is
             ;; started, because the session's UI captures the ambient
             ;; streams at creation — this is what lets a DBG>/NAV>
             ;; interaction be recorded under --dribble-interactors=t.
             (*standard-output* (make-dribble-output-tee *standard-output* "O"))
             (*error-output*    (make-dribble-output-tee *error-output*    "E"))
             (*standard-input*  (make-dribble-input-echo *standard-input*)))
        (clautolisp.autolisp-cli:install-transmit-variables context bindings)
        ;; Control-C now follows the *CLAL-ON-INTERRUPT* policy
        ;; (--on-interrupt, Part B), read live at each interrupt.
        (install-interrupt-handler)
        ;; --dribble-interactors=IS also sets the AutoLISP variable
        ;; *CLAL-DRIBBLE-INTERACTORS* (dribble.issue: the option is the
        ;; CLI spelling of (setq *clal-dribble-interactors* 'IS)), so a
        ;; later (clal-dribble) restart keeps the requested set.
        (when dribble-interactors
          (set-variable (intern-autolisp-symbol "*CLAL-DRIBBLE-INTERACTORS*")
                        (if (eq dribble-interactors :all)
                            (intern-autolisp-symbol "T")
                            (mapcar #'make-autolisp-string dribble-interactors))
                        context))
        (flet ((run-actions ()
                 (dolist (action actions)
                   (unless (eq :interactive (car action))
                     (let ((start (get-internal-real-time)))
                       (eval-action-in-context context action dialect)
                       (maybe-summarise-action (car action) (cdr action) start))))))
          ;; --on-error debug / --debugger-ui attach ONE debugger
          ;; session (debugger §10) for the whole program:
          ;;  • batch program (-l/-x, non-interactive): run the actions as one
          ;;    debugging extent so an uncaught error breaks into the UI;
          ;;  • interactive REPL: run the batch actions PLAIN (init files are
          ;;    machinery you don't debug) and hand the session to the REPL,
          ;;    which debugs each turn (so `clautolisp` + (/ 0) breaks in).
          ;; *break-on-error* is off under --on-error ignore.
          (let ((break (and debug-ui (not (eq on-error-policy :ignore))))
                (session (and debug-ui (start-debug-session debug-ui context))))
            (unwind-protect
                 (progn
                   (if (and session (not interactive-p))
                       (run-under-session-debugging session #'run-actions break)
                       (run-actions))
                   (when interactive-p
                     (clautolisp.autolisp-cli:call-with-dynamic-transmit-binding
                      context "*AUTOLISP-INTERACTIVE*" (intern-autolisp-symbol "T")
                      (lambda ()
                        (repl-loop dialect context
                                   :quiet-p quiet-p
                                   :mock-input mock-input
                                   :gui gui
                                   :trace-p trace-p
                                   :session session
                                   :break-on-error break
                                   :dribble dribble
                                   :dribble-interactors dribble-interactors)))))
              (when session
                (clautolisp.debug.ui:ui-detached (clautolisp.debug.ui:session-ui session))))))
        ;; Normal completion: exit with the status a script recorded via
        ;; (autolisp-set-status N) — 0 when it never touched the channel.
        (autolisp-exit-status context))
    (autolisp-runtime-error (condition)
      (report-runtime-error condition)
      1)
    (autolisp-termination (condition)
      (report-termination condition)
      ;; (quit [status]) / (exit [status]) carry their effective status.
      (autolisp-termination-status condition))
    (file-error (condition)
      (report-error condition)
      2)))

(defun %effective-gui-command (gui-command)
  "The configured GUI driver command: the explicit --gui value, else
$CLAUTOLISP_GUI, else NIL (no driver — GUI unavailable)."
  (or gui-command
      (let ((env (uiop:getenv "CLAUTOLISP_GUI")))
        (and env (plusp (length env)) env))))

(defun %stdout-is-tty-p ()
  "True when this process's stdout is an interactive terminal. Used by the
--dcl auto policy: a non-TTY stdout (piped / redirected / CI — i.e. a
headless or `-command'-style invocation) selects the TUI renderer."
  (or (ignore-errors
        (clautolisp.autolisp-runtime:output-stream-is-tty-p *standard-output*))
      nil))

(defun select-and-install-dcl-renderer (dcl-mode gui-command)
  "Install the DCL renderer chosen by --dcl DCL-MODE (:tui / :gui / :auto):

  :tui   the built-in terminal (command-line) renderer — the clautolisp
         spelling of AutoCAD's `-command' convention (force the non-dialog
         form even when a GUI driver is configured).
  :gui   the subprocess GUI renderer; when no driver is configured
         (--gui CMD / $CLAUTOLISP_GUI), warn and fall back to the TUI.
  :auto  the GUI when a driver is configured AND stdout is a TTY; otherwise
         the TUI — so every headless / piped run (the `-command' scenario)
         gets the command-line form automatically.

The terminal renderer is already installed at autolisp-dcl load time; this
overrides it only when the GUI is selected (and re-affirms the TUI otherwise
so a re-entrant run resets a previously-installed subprocess renderer)."
  (let* ((gui (%effective-gui-command gui-command))
         (tty (%stdout-is-tty-p))
         (debug-p (let ((env (uiop:getenv "CLAUTOLISP_DCL_DEBUG")))
                    (and env (plusp (length env)))))
         (use-gui
           (ecase dcl-mode
             (:tui  nil)
             (:gui  (cond (gui t)
                          (t (format *error-output*
                                     "~&clautolisp: --dcl gui: no GUI driver ~
configured (--gui CMD or $CLAUTOLISP_GUI); using the terminal (TUI) ~
renderer.~%")
                             nil)))
             (:auto (and gui tty)))))
    (when debug-p
      (format *error-output*
              "~&[dcl-debug] select-renderer mode=~S gui=~S tty=~S -> ~A~%"
              dcl-mode gui tty (if use-gui "GUI" "TUI")))
    (cond
      (use-gui
       (clautolisp.autolisp-dcl:install-default-renderer
        (clautolisp.autolisp-dcl:make-subprocess-renderer :command gui)))
      (t
       (clautolisp.autolisp-dcl:install-default-renderer
        (clautolisp.autolisp-dcl:make-terminal-renderer))))))

(defun synchronize-process-cwd ()
  "Align the engine's notion of the current directory with the LIVE
process working directory at launch.

The runtime captures `*autolisp-current-directory*` (and the default
support path) at image-DUMP time via `(truename \".\")`, so a saved
executable would otherwise resolve relative LOAD / OPEN / FINDFILE
paths against the build directory rather than the directory the user
launched it from. Re-reading the cwd here — and keeping Common Lisp's
`*default-pathname-defaults*` in agreement — makes a relative path
resolve against the live cwd / $PWD, matching POSIX and the CAD hosts.
See issues/open/clautolisp-boot-cwd-pwd-pathname-defaults.issue."
  (let ((cwd (ignore-errors (uiop:getcwd))))
    (when cwd
      (setf *default-pathname-defaults* cwd)
      (clautolisp.autolisp-runtime:set-autolisp-current-directory cwd)
      (clautolisp.autolisp-runtime:set-autolisp-support-paths
       (list (namestring cwd)))))
  ;; Classify the RUN frame (native / cygwin / msys2 / wsl / posix) and
  ;; install the run-frame mount table (clautolisp-windows-pathname-mapping
  ;; spec §4.3, §5.2).  On macOS/Linux this yields the identity
  ;; environment, so the whole mapping layer short-circuits and the boot
  ;; cwd sync above is the only path handling that takes effect.
  (ignore-errors (clautolisp.pathname-mapping:initialize-run-environment))
  ;; W1/W2 inspection hook: CLAUTOLISP_DEBUG_PATHMAP dumps the (frozen)
  ;; build frame recorded in the image and the freshly-detected run frame.
  ;; Handy on the Windows conformance runner to see how a real host is
  ;; classified.
  (when (uiop:getenv "CLAUTOLISP_DEBUG_PATHMAP")
    (ignore-errors
     (clautolisp.pathname-mapping:describe-mapping-environments *error-output*))))

(defun main (&rest argv)
  (setf *boot-time* (get-universal-time))       ; ,uptime measures from here
  ;; The CLAL-DRIBBLE builtin reaches the tool's dribble implementation
  ;; through the runtime hook (dribble.issue).
  (setf clautolisp.autolisp-runtime:*dribble-hook* #'clal-dribble)
  (handler-case
      (let* ((options (parse-arguments (rest argv))))
        ;; Resolve relative paths against the live launch directory,
        ;; not the (dumped) build directory.
        (synchronize-process-cwd)
        ;; --help / --version / --list-encodings short-circuit
        ;; before any context build.
        (when (clautolisp.autolisp-cli:cli-options-help-p options)
          (usage) (quit 0))
        (when (clautolisp.autolisp-cli:cli-options-version-p options)
          (print-version) (quit 0))
        (when (clautolisp.autolisp-cli:cli-options-list-encodings-p options)
          (clautolisp.autolisp-cli:print-encodings) (quit 0))
        (when (clautolisp.autolisp-cli:cli-options-list-dialects-p options)
          (clautolisp.autolisp-cli:print-dialects) (quit 0))
        (when (clautolisp.autolisp-cli:cli-options-list-situations-p options)
          (clautolisp.autolisp-cli:print-situations :backend :clautolisp) (quit 0))
        (let* ((verbosity (clautolisp.autolisp-cli:cli-options-verbosity options))
               (verbose-p (member verbosity '(:verbose :debug)))
               (debug-p   (eq verbosity :debug))
               (quiet-p   (eq verbosity :warn))
               (dialect   (keyword->dialect
                           (clautolisp.autolisp-cli:cli-options-dialect options)))
               (host      (keyword->host
                           (clautolisp.autolisp-cli:cli-options-host options)))
               (actions   (clautolisp.autolisp-cli:cli-options-actions options))
               (mock-input (clautolisp.autolisp-cli:cli-options-mock-input options))
               (gui       (clautolisp.autolisp-cli:cli-options-gui options))
               (dcl-mode  (clautolisp.autolisp-cli:cli-options-dcl options))
               (trace-p   (clautolisp.autolisp-cli:cli-options-trace-p options))
               (load-encoding (clautolisp.autolisp-cli:cli-options-load-encoding options))
               (io-encoding   (clautolisp.autolisp-cli:cli-options-io-encoding options))
               (no-init-p (clautolisp.autolisp-cli:cli-options-no-init-p options))
               (no-color-p (clautolisp.autolisp-cli:cli-options-no-color-p options))
               (dribble   (clautolisp.autolisp-cli:cli-options-dribble options))
               (dribble-interactors
                 (clautolisp.autolisp-cli:cli-options-dribble-interactors options))
               ;; -i, or no -l/-x/positional action, means the REPL is the
               ;; effective request. `actions' is the raw CLI queue here
               ;; (init-file loads are prepended later), so its emptiness is
               ;; the user-intent witness — computed BEFORE the on-error
               ;; default, which depends on it.
               (explicit-interactive-p
                 (clautolisp.autolisp-cli:cli-options-interactive-p options))
               (effective-interactive-p
                 (or explicit-interactive-p (null actions)))
               ;; --on-error policy (debugger §10 / *CLAL-ON-ERROR*). The
               ;; default is context-dependent: DEBUG for an interactive REPL
               ;; — so `clautolisp' then a bad form breaks into the aldo
               ;; debugger — and QUIT for a batch run (report the error and
               ;; exit, keeping scripts/CI deterministic). An explicit
               ;; --on-error always wins.
               (on-error  (or (clautolisp.autolisp-cli:cli-options-on-error options)
                              (if effective-interactive-p :debug :quit)))
               ;; --on-interrupt / --on-quit (Part B): the CLI supplies the
               ;; initial policy; the AutoLISP *CLAL-ON-INTERRUPT* /
               ;; *CLAL-ON-QUIT* variables override it LIVE.
               (on-interrupt (or (clautolisp.autolisp-cli:cli-options-on-interrupt options)
                                 :debug))
               (on-quit   (or (clautolisp.autolisp-cli:cli-options-on-quit options)
                              :quit))
               ;; --debugger-ui, with the aldb-channel implication (Part C);
               ;; when absent, the persisted default-user-interface aldo
               ;; setting decides (a per-run override of aldo.conf).
               (user-interface (effective-user-interface options))
               (effective-ui (or user-interface (resolve-default-debugger-ui)))
               ;; Debug the program when --on-error debug or a UI was
               ;; selected — or when an EXPLICIT --on-quit/--on-interrupt
               ;; debug asks for a debugger (the raw slots, not the
               ;; defaults: the interrupt default is debug and must not
               ;; arm a session for every run; without a session those
               ;; policies degrade as documented).
               (debug-ui  (when (or (eq on-error :debug) user-interface
                                    (eq :debug (clautolisp.autolisp-cli:cli-options-on-quit
                                                options))
                                    (eq :debug (clautolisp.autolisp-cli:cli-options-on-interrupt
                                                options)))
                            effective-ui))
               ;; --aldb-listen / --aldb-stdio (Part C/D): recorded and
               ;; mirrored to *CLAL-ALDB-LISTEN*. :stdio ⇒ RPC over the process
               ;; stdin/stdout; a "HOST:PORT" string ⇒ the TCP listener.
               (aldb-listen
                 (cond ((clautolisp.autolisp-cli:cli-options-aldb-stdio-p options)
                        :stdio)
                       ((or (clautolisp.autolisp-cli:cli-options-aldb-address options)
                            (clautolisp.autolisp-cli:cli-options-aldb-port options))
                        (format nil "~A:~A"
                                (or (clautolisp.autolisp-cli:cli-options-aldb-address options)
                                    "127.0.0.1")
                                (clautolisp.autolisp-cli:cli-options-aldb-port options)))))
               ;; The aldb TCP-listener address (debugger §10): non-NIL only when
               ;; aldb runs over the listener (not stdio) — the --aldb-listen
               ;; address, else the persisted default (127.0.0.1:4301). Bound to
               ;; *ALDB-LISTENER-ADDRESS* below so START-DEBUG-SESSION opens it.
               (aldb-listener-address
                 (aldb-resolve-listener-address debug-ui aldb-listen)))
          ;; The aldb (Emacs) front-end speaks a line-oriented S-expr RPC over
          ;; STDIO (--aldb-stdio) or a TCP socket (--aldb-listen / plain aldb).
          ;; Both are served now; the transport is chosen by ALDB-LISTEN and, for
          ;; the listener, ALDB-LISTENER-ADDRESS (see START-DEBUG-SESSION).
          (let ((*aldb-listener-address* aldb-listener-address)
                (*verbose-p* verbose-p)
                (*debug-p* debug-p)
                ;; The event policies (debugger §10 / Part B): user code may
                ;; rebind the CL variables; the AutoLISP mirrors of the
                ;; interrupt / quit policies are re-read live.
                (clautolisp.autolisp-runtime:*clal-on-error* on-error)
                (clautolisp.autolisp-runtime:*clal-on-interrupt* on-interrupt)
                (clautolisp.autolisp-runtime:*clal-on-quit* on-quit)
                (clautolisp.autolisp-runtime:*clal-debugger-ui* effective-ui)
                (clautolisp.autolisp-runtime:*clal-aldb-listen* aldb-listen)
                ;; Colour policy is computed exactly once per CLI run
                ;; against the LIVE *standard-output*. NIL means "no
                ;; colour"; a keyword is the accent the symbol
                ;; PRINT-OBJECT method will wrap names in.
                (clautolisp.autolisp-runtime:*color-output*
                  (clautolisp.autolisp-runtime:resolve-color-policy
                   :no-color-flag no-color-p))
                (effective-actions
                  (prepend-init-file-actions actions no-init-p)))
            (select-and-install-dcl-renderer dcl-mode gui)
            (when trace-p
              (setf clautolisp.autolisp-runtime:*autolisp-trace-p* t))
            (let ((status
                    ;; With debugging requested (--debug or --on-error debug), an
                    ;; UNHANDLED internal (host-Lisp) error must not vanish behind
                    ;; a one-line condition: a HANDLER-BIND dumps the host
                    ;; backtrace at signal time — the stack still intact — before
                    ;; the outer handler-case reports and exits. It fires ONLY for
                    ;; errors no inner handler took (the AutoLISP debugger / REPL
                    ;; handle their own), so ordinary program errors are
                    ;; unaffected; the handler DECLINES, so reporting/exit is
                    ;; unchanged.
                    (handler-bind
                        ((error (lambda (condition)
                                  (when (or debug-p (eq on-error :debug))
                                    (print-host-backtrace condition)))))
                    ;; Under a debug session, record source positions during
                    ;; the load so the navigator can show a form's ORIGINAL
                    ;; source text (its own line breaks and indentation) rather
                    ;; than a re-pretty-printed sexp. A no-op otherwise: the
                    ;; non-debug load path stays allocation-free.
                    (let ((clautolisp.source:*track-source-positions*
                            (if debug-ui t clautolisp.source:*track-source-positions*)))
                    (run-with-input dialect effective-actions options
                                    :quiet-p quiet-p
                                    :verbose-p verbose-p
                                    :debug-p debug-p
                                    :interactive-p effective-interactive-p
                                    :host host
                                    :mock-input mock-input
                                    :gui gui
                                    :trace-p trace-p
                                    :load-encoding load-encoding
                                    :io-encoding io-encoding
                                    :no-init-p no-init-p
                                    :no-color-p no-color-p
                                    :debug-ui debug-ui
                                    :on-error-policy on-error
                                    :dribble dribble
                                    :dribble-interactors dribble-interactors)))))
              (finish-output)
              ;; RUN-WITH-INPUT returns the effective process exit status
              ;; (autolisp-set-status / (quit N) / error → 1 / file → 2).
              (quit (if (integerp status) status 0))))))
    (clautolisp.autolisp-cli:cli-usage-error (condition)
      (format *error-output* "~&clautolisp: ~A~%" condition)
      (finish-output *error-output*)
      (quit 1))
    (error (error)
      (report-error error)
      (finish-output *error-output*)
      (quit 1))))
