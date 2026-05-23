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
interactive-p host mock-input gui trace-p).

ACTIONS is a list of action records in the order they appear on
the command line. Each record is either (:FILE PATH) or
(:EXPRESSION TEXT). The front-end runs them sequentially against
a single shared evaluation context; -i additionally drops into
the REPL on the same context once the queue is drained. With no
actions and no -i, the REPL is the implicit fallback.

The short-form aliases (-l, -x, -i, -q, -v, -d, -h, -V) match the
generic CLI surface specified for the sibling alfe front-end."
  (let ((dialect (autolisp-dialect-strict))
        (actions '())
        (quiet-p nil)
        (verbose-p nil)
        (debug-p nil)
        (interactive-p nil)
        (host (make-mock-host))
        (mock-input nil)
        (gui nil)
        (trace-p nil))
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
                 ((or (string= argument "-x")
                      (string= argument "--eval"))
                  (queue-action :expression (take argument)))
                 ((or (string= argument "-l")
                      (string= argument "--load"))
                  (queue-action :file (take argument)))
                 ((and (> (length argument) 0)
                       (char= (char argument 0) #\-))
                  (error "Unknown option ~S." argument))
                 (t
                  (queue-action :file argument)))))
    (values dialect actions quiet-p verbose-p debug-p
            interactive-p host mock-input gui trace-p)))

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

(defun build-context (dialect host mock-input)
  "Make a fresh runtime context, install builtins, attach the host
and any mock-input stream. Returns the context."
  (let ((context (make-default-runtime-context :dialect dialect)))
    (setup-context context host mock-input)
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
  "Run one action — (:FILE . PATH) or (:EXPRESSION . TEXT) — against
CONTEXT (an already-set-up evaluation context). DIALECT is the
dialect descriptor used to derive reader options. All actions in a
queue share one context, so side effects compose."
  (let ((kind (car action))
        (payload (cdr action)))
    (ecase kind
      (:file
       (let ((options (derive-reader-options-for-dialect
                       dialect :source-name (namestring payload))))
         (autolisp-load-file-in-context payload context :options options)))
      (:expression
       (let* ((options (derive-reader-options-for-dialect
                        dialect :source-name "<-x>"))
              (forms (read-runtime-from-string payload :options options)))
         (call-with-autolisp-error-handler
          (lambda () (autolisp-eval-progn forms context))
          context))))))

;;; --- Batch entry points ---------------------------------------------

(defun run-with-input (dialect actions
                       &key quiet-p interactive-p host mock-input gui trace-p)
  "Build a shared evaluation context, run every action in ACTIONS
against it in order, then optionally enter the REPL on the same
context. When ACTIONS is empty, the REPL is the implicit fallback
(unless --interactive is also off and the caller wants a strict
no-op — currently no such caller exists). INTERACTIVE-P forces the
REPL to follow a non-empty action queue."
  (handler-case
      (let ((context (build-context dialect host mock-input)))
        (dolist (action actions)
          (let ((start (get-internal-real-time)))
            (eval-action-in-context context action dialect)
            (maybe-summarise-action (car action) (cdr action) start)))
        (when (or (null actions) interactive-p)
          (repl-loop dialect context
                     :quiet-p quiet-p
                     :mock-input mock-input
                     :gui gui
                     :trace-p trace-p)))
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
                            interactive-p host mock-input gui trace-p)
          (parse-arguments (rest argv))
        (let ((*verbose-p* verbose-p)
              (*debug-p* debug-p))
          (install-gui-renderer gui)
          (when trace-p
            (setf clautolisp.autolisp-runtime:*autolisp-trace-p* t))
          (run-with-input dialect actions
                          :quiet-p quiet-p
                          :interactive-p interactive-p
                          :host host
                          :mock-input mock-input
                          :gui gui
                          :trace-p trace-p)
          (finish-output)
          (quit 0)))
    (error (error)
      (report-error error)
      (finish-output *error-output*)
      (quit 1))))
