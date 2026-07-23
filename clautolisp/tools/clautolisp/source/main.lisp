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
  (format t "  --dialect NAME         One of: strict (default), autocad-2022, autocad-2026, autocad,~%")
  (format t "                         bricscad-v25, bricscad-v26, bricscad, clautolisp, lax. An~%")
  (format t "                         unversioned vendor name maps to the last known version.~%")
  (format t "  --list-dialects        Print every --dialect name (strict first, lax last) and exit.~%")
  (format t "  --strict               Shorthand for --dialect strict (portable AutoCAD ∩ BricsCAD).~%")
  (format t "  --autocad              Shorthand for --dialect autocad-2026.~%")
  (format t "  --bricscad             Shorthand for --dialect bricscad-v26.~%")
  (format t "  --clautolisp           Shorthand for --dialect clautolisp. Enables clautolisp~%")
  (format t "                         extensions (e.g. variadic functions). Out-of-dialect~%")
  (format t "                         operators stay callable but emit a diagnostic at use.~%")
  (format t "Host:~%")
  (format t "  --host NAME            HAL backend: mock (default), null.~%")
  (format t "  --mock-input PATH      Attach the file at PATH as the MockHost prompt-stream.~%")
  (format t "                         Lines are consumed by GETSTRING / GETPOINT / etc. in order.~%")
  (format t "  --gui CMD              DCL renderer: subprocess CMD speaking the sexp wire protocol.~%")
  (format t "                         Defaults to the built-in terminal renderer (or $CLAUTOLISP_GUI).~%")
  (format t "  --trace                Print every AutoLISP function call (entry args + exit value),~%")
  (format t "                         indented by call depth. Output goes to *trace-output* (stderr).~%")
  (format t "Debugger (aldo):~%")
  (format t "  --on-error POLICY      What to do when an uncaught AutoLISP error reaches the top~%")
  (format t "                         level: quit (report and exit, the default), debug (break into~%")
  (format t "                         the aldo debugger), or ignore (run the AutoLISP *error* handler).~%")
  (format t "                         Sets *CLAL-ON-ERROR*, which code may rebind.~%")
  (format t "  --aldo-user-interface UI  Debugger front-end: tui (the line/terminal UI, default),~%")
  (format t "                         ncurses, or aldb (the Emacs front-end). Selecting one runs the~%")
  (format t "                         program under a debug session.~%")
  (format t "  --aldb-listening-address ADDR  Address the aldb listener binds (with --aldo-user-interface aldb).~%")
  (format t "  --aldb-listening-port PORT     Port (or service name) the aldb listener binds.~%")
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
  (format t "                         are case-insensitive on the CLI.~%"))

(defun resolve-host-backend (name)
  "Return a HAL backend instance for the given --host argument."
  (cond
    ((or (null name)
         (string-equal name "null")
         (string-equal name "none"))
     *null-host*)
    ((string-equal name "mock")
     ;; Phase 9 deliverable: data structures only. Phase 10 fills in
     ;; the entget / ssget / getvar / command surfaces; until then
     ;; every host operation falls through to the base-class
     ;; :host-not-supported diagnostic.
     (make-mock-host))
    (t
     (error "Unknown host backend ~S. Expected one of: null, mock." name))))

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
  "Map :mock / :null to a HAL backend instance. Defaults to the
MockHost when HOST-KEYWORD is nil (the empty default for clautolisp
omits --host)."
  (case host-keyword
    ((nil :mock) (make-mock-host))
    ((:null)     *null-host*)))

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
            ;; --- debugger (aldo) options (debugger §10) ---
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--on-error") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-on-error opts)
                              (clautolisp.autolisp-cli:parse-on-error value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--aldo-user-interface") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (setf (clautolisp.autolisp-cli:cli-options-user-interface opts)
                              (clautolisp.autolisp-cli:parse-user-interface value name))))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--aldb-listening-address") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (declare (ignore name))
                        (setf (clautolisp.autolisp-cli:cli-options-aldb-address opts) value)))
            (clautolisp.autolisp-cli:make-option-spec
             :longs '("--aldb-listening-port") :shorts nil :takes-arg-p t
             :handler (lambda (opts value name)
                        (declare (ignore name))
                        (setf (clautolisp.autolisp-cli:cli-options-aldb-port opts) value)))
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
    (clautolisp.autolisp-cli:parse-arguments-with-spec specs arguments)))

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

(defun setup-context (context host &optional mock-input)
  "Install the core builtins into the freshly created evaluation
context's namespace and attach the chosen HAL backend to its
session. When MOCK-INPUT is supplied and HOST is a MockHost,
attach the file at MOCK-INPUT as the host's prompt-stream so
that subsequent get* calls read deterministic answers from it."
  (when host
    (set-runtime-session-host (evaluation-context-session context) host))
  (when (and mock-input
             (typep host 'clautolisp.autolisp-mock-host:mock-host))
    (let ((stream (open mock-input :direction :input
                                   :external-format :utf-8
                                   :if-does-not-exist :error)))
      (setf (clautolisp.autolisp-mock-host:mock-host-prompt-stream host) stream)))
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
      (write-string (if accumulated continuation-prompt prompt))
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

(defun emit-repl-banner (dialect context &key mock-input gui trace-p)
  "Print the REPL banner. With *verbose-p* on, append a second line
listing the active host and any non-default knobs so the user sees
exactly what they are typing into."
  (let* ((session (evaluation-context-session context))
         (host (clautolisp.autolisp-runtime:runtime-session-host session)))
    (format t "~&clautolisp ~A — REPL (~A dialect, ~A host) — Ctrl-D to exit.~%"
            *version*
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

(defun wire-mock-host-to-terminal (context)
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
    (when (and (typep host 'clautolisp.autolisp-mock-host:mock-host)
               (null (clautolisp.autolisp-mock-host:mock-host-prompt-stream host)))
      (setf (clautolisp.autolisp-mock-host:mock-host-prompt-stream host)
            (make-synonym-stream '*standard-input*)
            (clautolisp.autolisp-mock-host:mock-host-prompt-output host)
            (make-synonym-stream '*standard-output*)))))

;;; --- the AUTOLISP interactor: REPL comma-commands -----------------------
;;;
;;; The Lisp REPL is the bottom interactor (interactors design,
;;; issues/open/interactor-unification.issue): its reader takes a line
;;; starting with a comma as a command — `,date', `,quit' — and anything
;;; else as AutoLISP source. The comma keeps command names out of the
;;; expression namespace (at a toplevel read it is unambiguous: no
;;; backquote in AutoLISP).

(define-interactor *autolisp*
  :name "AUTOLISP" :alias "LISP"
  :prompt "_$ "
  :reader '%autolisp-reader
  :evaluator '%autolisp-evaluate
  :documentation "The clautolisp Lisp REPL — the bottom interactor, always
under every stacked mode (design-revision D3): reads AutoLISP forms; a
`,command' line runs a REPL command. Routable as `autolisp CMD' or `lisp
CMD' from any inner mode; a user command registered here
((clal-define-command \"AUTOLISP\" …)) is reachable everywhere — the
\"global\" user command (D6). The prompt is late-bound (an indication of
the current dialect can come later).")

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

(defun repl-loop (dialect context &key quiet-p mock-input gui trace-p
                                        session break-on-error
                                        dribble dribble-interactors)
  (unless quiet-p
    (emit-repl-banner dialect context
                      :mock-input mock-input :gui gui :trace-p trace-p))
  (unless mock-input
    (wire-mock-host-to-terminal context))
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
               (*interactor-stack*
                 (list (make-activation *autolisp*
                                        (make-repl-state :context context
                                                         :session session
                                                         :break-on-error break-on-error)))))
           (when (null (interactor-loop))
             ;; EOF (Ctrl-D): a fresh line before leaving. ,quit / (quit) return
             ;; markers through INTERACTOR-RETURN and print nothing extra.
             (terpri)))
      ;; Leaving the REPL closes any active dribble (flushing a pending
      ;; partial output line).
      (dribble-stop))))

(defstruct repl-state
  "The AUTOLISP activation's per-run state: the evaluation context and the
attached debug session (if any). The dialect is NOT here — it is consulted
live at each read (CURRENT-EVALUATION-DIALECT, design-revision D2), so a
mid-session =(setq *AUTOLISP-DIALECT* 'lax)= takes effect immediately."
  context session break-on-error)

(defun %autolisp-reader (input-context)
  "The *AUTOLISP* singleton's reader: a `,command' line dispatches, anything
else reads as one balanced AutoLISP turn under the dialect in force NOW."
  (let ((state (activation-state *command-activation*)))
    (comma-command-read input-context
                        (%repl-source-reader
                         (current-evaluation-dialect (repl-state-context state))))))

(defun %autolisp-evaluate (input)
  "The *AUTOLISP* singleton's evaluator: one REPL turn over this activation's
context and session."
  (let ((state (activation-state *command-activation*)))
    (%repl-eval-source (second input)
                       (repl-state-context state)
                       (repl-state-session state)
                       (repl-state-break-on-error state)
                       (lambda () (interactor-return :terminated)))))

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
       (clautolisp.autolisp-cli:encoding-keyword encoding-string "-e")))

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
  "Map a --aldo-user-interface keyword to a registered UI designator
(register-ui name). :tui is the dumb/terminal UI."
  (ecase ui-keyword
    (:tui :terminal)
    (:ncurses :ncurses)
    (:aldb :aldb)))

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
          ;; --on-error debug / --aldo-user-interface attach ONE debugger
          ;; session (debugger §10) for the whole program:
          ;;  • batch program (-l/-x, non-interactive): run the actions as one
          ;;    debugging extent so an uncaught error breaks into the UI;
          ;;  • interactive REPL: run the batch actions PLAIN (init files are
          ;;    machinery you don't debug) and hand the session to the REPL,
          ;;    which debugs each turn (so `clautolisp` + (/ 0) breaks in).
          ;; *break-on-error* is off under --on-error ignore.
          (let ((break (and debug-ui (not (eq on-error-policy :ignore))))
                (session (and debug-ui
                              (clautolisp.debug.ui:start-session
                               :ui (debug-ui-designator debug-ui) :context context))))
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

(defun install-gui-renderer (gui-command)
  "Switch the active DCL renderer to a subprocess driver if
GUI-COMMAND is non-nil, or if CLAUTOLISP_GUI is set in the
environment. Otherwise the terminal renderer (installed at
autolisp-dcl load time) stays in effect."
  (let ((effective
          (or gui-command
              (let ((env (uiop:getenv "CLAUTOLISP_GUI")))
                (and env (plusp (length env)) env))))
        (debug-p (let ((env (uiop:getenv "CLAUTOLISP_DCL_DEBUG")))
                   (and env (plusp (length env))))))
    (when debug-p
      (format *error-output*
              "~&[dcl-debug] install-gui-renderer effective=~S~%" effective))
    (when effective
      (clautolisp.autolisp-dcl:install-default-renderer
       (clautolisp.autolisp-dcl:make-subprocess-renderer
        :command effective))
      (when debug-p
        (format *error-output*
                "~&[dcl-debug] subprocess renderer installed.~%")))))

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
       (list (namestring cwd))))))

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
               (user-interface (clautolisp.autolisp-cli:cli-options-user-interface options))
               ;; Debug the program when --on-error debug or a UI was selected.
               (debug-ui  (when (or (eq on-error :debug) user-interface)
                            (or user-interface :tui))))
          ;; The aldb (Emacs) front-end speaks over a TCP socket; the listener
          ;; is not yet implemented (debugger §10). Fail clearly rather than
          ;; silently doing nothing.
          (when (eq debug-ui :aldb)
            (format *error-output*
                    "~&clautolisp: --aldo-user-interface aldb is not yet implemented ~
                     (the aldb TCP listener is pending); use tui or ncurses.~%")
            (finish-output *error-output*)
            (quit 2))
          (let ((*verbose-p* verbose-p)
                (*debug-p* debug-p)
                ;; The error policy (debugger §10): user code may rebind it.
                (clautolisp.autolisp-runtime:*clal-on-error* on-error)
                ;; Colour policy is computed exactly once per CLI run
                ;; against the LIVE *standard-output*. NIL means "no
                ;; colour"; a keyword is the accent the symbol
                ;; PRINT-OBJECT method will wrap names in.
                (clautolisp.autolisp-runtime:*color-output*
                  (clautolisp.autolisp-runtime:resolve-color-policy
                   :no-color-flag no-color-p))
                (effective-actions
                  (prepend-init-file-actions actions no-init-p)))
            (install-gui-renderer gui)
            (when trace-p
              (setf clautolisp.autolisp-runtime:*autolisp-trace-p* t))
            (let ((status
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
                                    :dribble-interactors dribble-interactors))))
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
