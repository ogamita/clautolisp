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
  (format t "  --dialect NAME         One of: strict (default), autocad-2026, bricscad-v26.~%")
  (format t "  --strict               Shorthand for --dialect strict (portable AutoCAD ∩ BricsCAD).~%")
  (format t "  --autocad              Shorthand for --dialect autocad-2026.~%")
  (format t "  --bricscad             Shorthand for --dialect bricscad-v26.~%")
  (format t "  --clautolisp           Synonym for --strict: the clautolisp default dialect.~%")
  (format t "Host:~%")
  (format t "  --host NAME            HAL backend: mock (default), null.~%")
  (format t "  --mock-input PATH      Attach the file at PATH as the MockHost prompt-stream.~%")
  (format t "                         Lines are consumed by GETSTRING / GETPOINT / etc. in order.~%")
  (format t "  --gui CMD              DCL renderer: subprocess CMD speaking the sexp wire protocol.~%")
  (format t "                         Defaults to the built-in terminal renderer (or $CLAUTOLISP_GUI).~%")
  (format t "  --trace                Print every AutoLISP function call (entry args + exit value),~%")
  (format t "                         indented by call depth. Output goes to *trace-output* (stderr).~%")
  (format t "REPL and diagnostics:~%")
  (format t "  -q, --quiet            Suppress the REPL banner.~%")
  (format t "  -v, --verbose          Print extra diagnostic information (banner, summary, …).~%")
  (format t "  -d, --debug            Print debug traces; include CL backtraces on runtime errors.~%")
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
  (format t "  -h, --help             Show this help and exit.~%"))

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
  (let ((dialect (autolisp-dialect-strict))
        (actions '())
        (load-encoding nil)
        (io-encoding nil)
        (quiet-p nil)
        (verbose-p nil)
        (debug-p nil)
        (interactive-p nil)
        (host (make-mock-host))
        (mock-input nil)
        (gui nil)
        (trace-p nil)
        (no-init-p nil)
        (no-color-p nil))
    (labels ((take (option)
               (multiple-value-bind (value rest)
                   (pop-required-argument option arguments)
                 (setf arguments rest)
                 value))
             (queue-action (kind payload)
               (setf actions (append actions (list (cons kind payload))))))
      (loop while arguments
            for argument = (pop arguments)
            do (cond
                 ((or (string= argument "--help")
                      (string= argument "-h"))
                  (usage)
                  (quit 0))
                 ((or (string= argument "--version")
                      (string= argument "-V"))
                  (print-version)
                  (quit 0))
                 ((or (string= argument "--quiet")
                      (string= argument "-q"))
                  (setf quiet-p t
                        ;; Last-wins between -q and -v.
                        verbose-p nil))
                 ((or (string= argument "--verbose")
                      (string= argument "-v"))
                  (setf verbose-p t
                        quiet-p nil))
                 ((or (string= argument "--debug")
                      (string= argument "-d"))
                  ;; --debug subsumes --verbose for output purposes.
                  (setf debug-p t
                        verbose-p t
                        quiet-p nil))
                 ((or (string= argument "--interactive")
                      (string= argument "-i"))
                  (setf interactive-p t))
                 ((string= argument "--dialect")
                  (setf dialect (resolve-dialect (take "--dialect"))))
                 ((string= argument "--strict")
                  (setf dialect (autolisp-dialect-strict)))
                 ((string= argument "--autocad")
                  (setf dialect (autolisp-dialect-autocad-2026)))
                 ((string= argument "--bricscad")
                  (setf dialect (autolisp-dialect-bricscad-v26)))
                 ;; --clautolisp is currently a synonym for --strict.
                 ;; Per issue function-value.issue the clautolisp dialect
                 ;; is the "permissive Lisp-1 with late HOF resolution"
                 ;; profile — the actual reader-level knobs (no AutoCAD
                 ;; or BricsCAD extensions, strict tokenisation) match
                 ;; the existing :strict descriptor, so we alias instead
                 ;; of introducing a duplicate dialect descriptor.
                 ((string= argument "--clautolisp")
                  (setf dialect (autolisp-dialect-strict)))
                 ((string= argument "--host")
                  (setf host (resolve-host-backend (take "--host"))))
                 ((string= argument "--mock-input")
                  (setf mock-input (take "--mock-input")))
                 ((string= argument "--gui")
                  ;; Pass the command string straight through —
                  ;; uiop:launch-program routes a string through the
                  ;; shell, which is what users want for pipelines
                  ;; and quoted arguments.
                  (setf gui (take "--gui")))
                 ((string= argument "--trace")
                  (setf trace-p t))
                 ((or (string= argument "--no-init")
                      (string= argument "-norc"))
                  (setf no-init-p t))
                 ((string= argument "--no-color")
                  (setf no-color-p t))
                 ((or (string= argument "-x")
                      (string= argument "--eval"))
                  (queue-action :expression (take argument)))
                 ((or (string= argument "-l")
                      (string= argument "--load"))
                  (queue-action :file (take argument)))
                 ;; -e ENC: session-wide source-file encoding override
                 ;; (utf-8 / iso-8859-1 / windows-1252 / latin-1 / cp1252).
                 ;; Honoured by every load in the session, including
                 ;; nested (load …) calls from user init files.
                 ((string= argument "-e")
                  (setf load-encoding (take argument)))
                 ;; -E ENC: terminal-IO encoding override. Sets the
                 ;; external-format of *standard-output* / *error-output*
                 ;; / *standard-input* for the lifetime of the CLI run
                 ;; (PRINC and PRIN1 honour it, including the REPL).
                 ;; Mirrors alfe's -E and is what
                 ;; transmit-options.issue notes as previously missing.
                 ((string= argument "-E")
                  (setf io-encoding (take argument)))
                 ((and (> (length argument) 0)
                       (char= (char argument 0) #\-))
                  (error "Unknown option ~S." argument))
                 (t
                  (queue-action :file argument)))))
    (values dialect actions quiet-p verbose-p debug-p
            interactive-p host mock-input gui trace-p
            no-init-p load-encoding io-encoding no-color-p)))

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
    (return-from prepend-init-file-actions actions))
  (let ((init-paths (find-init-files *default-clautolisp-stems*)))
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

(defun repl-loop (dialect context &key quiet-p mock-input gui trace-p)
  (unless quiet-p
    (emit-repl-banner dialect context
                      :mock-input mock-input :gui gui :trace-p trace-p))
  (loop
    (multiple-value-bind (source eofp)
        (read-balanced-source-from-stream
         *standard-input* "_$ " "   " dialect)
      (when eofp
        (terpri)
        (return))
      (handler-case
          (let* ((options (derive-reader-options-for-dialect
                           dialect :source-name "<repl>"))
                 (forms (read-runtime-from-string source :options options))
                 (result (call-with-autolisp-error-handler
                          (lambda () (autolisp-eval-progn forms context))
                          context)))
            (format t "~A~%" (autolisp-value->string result nil)))
        (simple-error (condition)
          (let ((diagnostic (simple-error-diagnostic condition)))
            (if diagnostic
                (format *error-output* "~&; reader error: ~A: ~A~%"
                        (diagnostic-code diagnostic)
                        condition)
                (format *error-output* "~&; reader error: ~A~%" condition))))
        (autolisp-runtime-error (condition)
          (report-runtime-error condition))
        (autolisp-termination (condition)
          (report-termination condition)
          (return))))))

(defun encoding-keyword (encoding-string)
  "Map a CLI encoding string (\"utf-8\", \"iso-8859-1\",
\"windows-1252\", \"cp1252\", \"latin-1\", \"latin1\") to the Lisp
keyword external-format. Unknown values are passed through as a
keyword interned from the upper-cased string — the underlying
implementation's OPEN will surface the failure if it can't honour
them. Mirrors the same helper in autolisp-front-end's backend-clautolisp."
  (cond
    ((null encoding-string) nil)
    ((or (string-equal encoding-string "utf-8")
         (string-equal encoding-string "utf8"))            :utf-8)
    ((or (string-equal encoding-string "iso-8859-1")
         (string-equal encoding-string "latin-1")
         (string-equal encoding-string "latin1"))          :iso-8859-1)
    ((or (string-equal encoding-string "windows-1252")
         (string-equal encoding-string "cp1252"))          :windows-1252)
    (t (intern (string-upcase encoding-string) :keyword))))

(defun build-context (dialect host mock-input &optional load-encoding)
  "Make a fresh runtime context, install builtins, attach the host
and any mock-input stream. Computes an effective default source-file
encoding via the precedence:

  1. `-e ENC' on the CLI (LOAD-ENCODING — strongest, explicit).
  2. POSIX locale env: LC_ALL > LC_CTYPE > LANG (host-wide hint).
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

(defun call-with-dynamic-transmit-binding (context name value thunk)
  "Set *AUTOLISP-…* variable NAME to VALUE for the duration of THUNK,
then reset to nil. Used to scope *AUTOLISP-LOAD-PATHNAME* around
each -l action, *AUTOLISP-EXPRESSION* around each -x, and
*AUTOLISP-INTERACTIVE* around the REPL. The reset-on-exit guard
runs even on non-local exit (autolisp-runtime-error etc.) so a
later (clautolisp-documentation 'foo) or just a top-level
reference doesn't see stale state from a failed action."
  (let ((sym (intern-autolisp-symbol name)))
    (unwind-protect
         (progn
           (set-variable sym value context)
           (funcall thunk))
      (set-variable sym nil context))))

(defun eval-action-in-context (context action dialect)
  "Run one action — (:FILE . PATH) or (:EXPRESSION . TEXT) — against
CONTEXT (an already-set-up evaluation context). DIALECT is the
dialect descriptor used to derive reader options. All actions in a
queue share one context, so side effects compose.

While the action runs the matching dynamic *AUTOLISP-…* variable
is set: *AUTOLISP-LOAD-PATHNAME* for :file, *AUTOLISP-EXPRESSION*
for :expression. Cleared on return (success or signal)."
  (let ((kind (car action))
        (payload (cdr action)))
    (ecase kind
      (:file
       (let ((options (derive-reader-options-for-dialect
                       dialect :source-name (namestring payload))))
         (call-with-dynamic-transmit-binding
          context "*AUTOLISP-LOAD-PATHNAME*"
          (make-autolisp-string (namestring payload))
          (lambda ()
            (autolisp-load-file-in-context payload context :options options)))))
      (:expression
       (let* ((options (derive-reader-options-for-dialect
                        dialect :source-name "<-x>"))
              (forms (read-runtime-from-string payload :options options)))
         (call-with-dynamic-transmit-binding
          context "*AUTOLISP-EXPRESSION*"
          (make-autolisp-string payload)
          (lambda ()
            (call-with-autolisp-error-handler
             (lambda () (autolisp-eval-progn forms context))
             context))))))))

;;; --- Batch entry points ---------------------------------------------

;;; --- transmit-options: CLI-derived *AUTOLISP-…* globals -----------
;;;
;;; The CLI publishes a set of *AUTOLISP-…* variables in the running
;;; AutoLISP image so user code can introspect how it was invoked.
;;; Set before any user action runs (init files included), so init
;;; files can branch on them. See issues/open/transmit-options.issue
;;; for the full contract; the per-clautolisp subset is implemented
;;; here.

(defun autolisp-bool (truth-value)
  "Return the AutoLISP T symbol when TRUTH-VALUE is true, nil otherwise."
  (and truth-value (intern-autolisp-symbol "T")))

(defun autolisp-string-or-nil (string-value)
  "Return an autolisp-string carrying STRING-VALUE, or nil when nil/empty."
  (and string-value (> (length string-value) 0)
       (make-autolisp-string string-value)))

(defun dialect-name-symbol (dialect)
  "Return an autolisp-symbol whose name is DIALECT's canonical name
(STRICT, AUTOCAD-2026, BRICSCAD-V26, …). Used as the value of
*AUTOLISP-DIALECT*."
  (intern-autolisp-symbol (symbol-name (autolisp-dialect-name dialect))))

(defun host-name-symbol (host)
  "Return MOCK / NULL autolisp-symbol per HOST's kind, or nil when
HOST is itself nil. Matches the --host parameter vocabulary."
  (when host
    (intern-autolisp-symbol (string-upcase (host-name host)))))

(defun actions-to-autolisp-list (actions interactive-p)
  "Render the queued ACTIONS — each a (:KIND . PAYLOAD) cons — as
an AutoLISP list of two-element lists, the value of *AUTOLISP-ACTIONS*:
  (:FILE . PATH)       → (load \"PATH\")
  (:EXPRESSION . TEXT) → (eval \"TEXT\")
plus a trailing (interactive t) when the REPL is scheduled. The
symbols (`load', `eval', `interactive') are AutoLISP symbols; the
payload strings are AutoLISP strings."
  (let ((out '()))
    (dolist (a actions)
      (let ((kind (car a))
            (payload (cdr a)))
        (push (ecase kind
                (:file (list (intern-autolisp-symbol "LOAD")
                             (make-autolisp-string (namestring payload))))
                (:expression (list (intern-autolisp-symbol "EVAL")
                                   (make-autolisp-string payload))))
              out)))
    (when interactive-p
      (push (list (intern-autolisp-symbol "INTERACTIVE")
                  (intern-autolisp-symbol "T"))
            out))
    (nreverse out)))

(defun install-transmit-variables (context dialect actions
                                   &key quiet-p verbose-p debug-p trace-p
                                        interactive-p host mock-input gui
                                        load-encoding io-encoding
                                        no-init-p no-color-p
                                        usage-text version-text)
  "Intern and bind every *AUTOLISP-…* global the CLI publishes for
this clautolisp invocation (the C and AC columns of the
transmit-options.issue table — minus the dynamically-scoped ones
LOAD-PATHNAME / EXPRESSION / INTERACTIVE which are bound around
each action by the eval loop). Called once, before the first user
action, so init files can branch on the values."
  (flet ((bind-var (name value)
           (set-variable (intern-autolisp-symbol name) value context)))
    (bind-var "*AUTOLISP-BACKEND*"            (intern-autolisp-symbol "CLAUTOLISP"))
    (bind-var "*AUTOLISP-DIALECT*"            (dialect-name-symbol dialect))
    (bind-var "*AUTOLISP-HOST*"               (host-name-symbol host))
    (bind-var "*AUTOLISP-MOCK-INPUT*"         (autolisp-string-or-nil mock-input))
    (bind-var "*AUTOLISP-GUI-COMMAND*"        (autolisp-string-or-nil gui))
    (bind-var "*AUTOLISP-TRACE*"              (autolisp-bool trace-p))
    (bind-var "*AUTOLISP-FILE-ENCODING*"      (autolisp-string-or-nil load-encoding))
    (bind-var "*AUTOLISP-TERMINAL-ENCODING*"  (autolisp-string-or-nil io-encoding))
    (bind-var "*AUTOLISP-NO-INIT*"            (autolisp-bool no-init-p))
    (bind-var "*AUTOLISP-NO-COLOR*"           (autolisp-bool no-color-p))
    (bind-var "*AUTOLISP-VERBOSE*"            (autolisp-bool verbose-p))
    (bind-var "*AUTOLISP-DEBUG*"              (autolisp-bool debug-p))
    (bind-var "*AUTOLISP-QUIET*"              (autolisp-bool quiet-p))
    (bind-var "*AUTOLISP-WILL-QUIT*"          nil) ;; clautolisp has no --quit
    (bind-var "*AUTOLISP-MAIN*"               nil) ;; clautolisp has no --main
    (bind-var "*AUTOLISP-ACTIONS*"
          (actions-to-autolisp-list actions interactive-p))
    (bind-var "*AUTOLISP-INTERACTIVE*"        nil) ;; dynamically true in REPL
    (bind-var "*AUTOLISP-LOAD-PATHNAME*"      nil) ;; dynamically set during -l
    (bind-var "*AUTOLISP-EXPRESSION*"         nil) ;; dynamically set during -x
    (bind-var "*AUTOLISP-HELP*"
          (autolisp-string-or-nil (or usage-text "")))
    (bind-var "*AUTOLISP-VERSION*"
          (make-autolisp-string (or version-text *version*)))))

(defun usage-string ()
  "Return the --help output as a string. Captured for the
*AUTOLISP-HELP* global by re-running USAGE against a string sink."
  (with-output-to-string (*standard-output*)
    (usage)))

(defun run-with-input (dialect actions
                       &key quiet-p verbose-p debug-p
                            interactive-p host mock-input gui trace-p
                            load-encoding io-encoding
                            no-init-p no-color-p)
  "Build a shared evaluation context, install the CLI-derived
*AUTOLISP-…* globals, run every action in ACTIONS in order, then
enter the REPL on the same context when INTERACTIVE-P is true.

INTERACTIVE-P expresses the *effective* request — it is true when
either the CLI passed -i / --interactive, OR the user supplied no
explicit -l / -x / positional action so the REPL is the implicit
default (per command-line-option-ammendment.issue). The caller
computes this; the function intentionally does not inspect ACTIONS
to make the decision, because by the time this function is called
ACTIONS may include init-file loads (which are machinery, not user
intent)."
  (handler-case
      (let ((context (build-context dialect host mock-input load-encoding)))
        (install-transmit-variables
         context dialect actions
         :quiet-p quiet-p :verbose-p verbose-p :debug-p debug-p
         :trace-p trace-p :interactive-p interactive-p
         :host host :mock-input mock-input :gui gui
         :load-encoding load-encoding :io-encoding io-encoding
         :no-init-p no-init-p :no-color-p no-color-p
         :usage-text (usage-string)
         :version-text *version*)
        (dolist (action actions)
          (let ((start (get-internal-real-time)))
            (eval-action-in-context context action dialect)
            (maybe-summarise-action (car action) (cdr action) start)))
        (when interactive-p
          (call-with-dynamic-transmit-binding
           context "*AUTOLISP-INTERACTIVE*" (intern-autolisp-symbol "T")
           (lambda ()
             (repl-loop dialect context
                        :quiet-p quiet-p
                        :mock-input mock-input
                        :gui gui
                        :trace-p trace-p)))))
    (autolisp-runtime-error (condition)
      (report-runtime-error condition)
      (quit 1))
    (autolisp-termination (condition)
      (report-termination condition)
      (quit 0))
    (file-error (condition)
      (report-error condition)
      (quit 2))))

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

(defun main (&rest argv)
  (handler-case
      (multiple-value-bind (dialect actions quiet-p verbose-p debug-p
                            interactive-p host mock-input gui trace-p
                            no-init-p load-encoding io-encoding no-color-p)
          (parse-arguments (rest argv))
        (let ((*verbose-p* verbose-p)
              (*debug-p* debug-p)
              ;; Colour policy is computed exactly once per CLI run
              ;; against the LIVE *standard-output* — by the time
              ;; RUN-WITH-INPUT redirects (it doesn't, but a future
              ;; caller might) the original stream's tty state is
              ;; the one that matters. NIL means "no colour"; a
              ;; keyword (:YELLOW / :BLUE) is the accent the
              ;; AUTOLISP-SYMBOL PRINT-OBJECT method will wrap
              ;; rendered names in.
              (clautolisp.autolisp-runtime:*color-output*
                (clautolisp.autolisp-runtime:resolve-color-policy
                 :no-color-flag no-color-p))
              ;; Implicit -i: when the user supplied no -l / -x /
              ;; positional action, the REPL is the desired default
              ;; (per command-line-option-ammendment.issue).
              ;; The init-file loads added below are machinery,
              ;; not user intent, so we snapshot `actions' emptiness
              ;; BEFORE prepending them.
              (effective-interactive-p
                (or interactive-p (null actions)))
              ;; Init files run BEFORE any -l / -x / positional
              ;; action so user-supplied state can override an
              ;; init-file binding. The flag (or its env-var
              ;; mirror) short-circuits the lookup entirely.
              (effective-actions
                (prepend-init-file-actions actions no-init-p)))
          (install-gui-renderer gui)
          (when trace-p
            (setf clautolisp.autolisp-runtime:*autolisp-trace-p* t))
          (run-with-input dialect effective-actions
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
                          :no-color-p no-color-p)
          (finish-output)
          (quit 0)))
    (error (error)
      (report-error error)
      (finish-output *error-output*)
      (quit 1))))
