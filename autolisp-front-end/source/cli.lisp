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
                #:set-level)
  (:export ;; public entry point
           #:run
           ;; option record + parser (also exposed for tests)
           #:cli-options
           #:make-cli-options
           #:parse-arguments
           #:options-backend
           #:options-mode
           #:options-backend-variant
           #:options-actions
           #:options-interactive-p
           #:options-quit-p
           #:options-host
           #:options-dialect
           #:options-load-encoding
           #:options-io-encoding
           #:options-dwg
           #:options-epure-p
           #:options-bootstrap-phase
           #:options-verbosity
           #:options-workdir
           #:options-timeout
           #:options-help-p
           #:options-version-p
           #:options-dry-run-p
           #:options-no-init-p
           #:options-main
           #:options-positional
           ;; usage + version (so the executable's main can re-use)
           #:print-usage
           #:print-version
           ;; env-var resolution helpers, exported for tests
           #:env-default
           ;; resolution
           #:resolve-backend
           #:plan-from-options))

(in-package #:alfe.cli)

;;; --- options record --------------------------------------------------

(defstruct cli-options
  "Snapshot of every CLI option after parsing argv (and folding in the
matching environment variables). Pure data — RUN translates this into
calls against the backend protocol."
  (backend          nil)                ; :clautolisp / :bricscad / :autocad / nil
  (mode             :auto)              ; :auto / :automation / :batch
  (backend-variant  nil)                ; :attach / :launch / nil
  (actions          nil :type list)     ; list of ALFE.BACKEND:ACTION
  (interactive-p    nil)
  (quit-p           nil)
  (host             :mock)              ; :mock / :null
  (dialect          :strict)            ; :strict / :autocad-2026 / :bricscad-v26 / :clautolisp
  (load-encoding    nil)                ; -e
  (io-encoding      nil)                ; -E
  (dwg              nil)
  (epure-p          nil)
  (bootstrap-phase  :full)              ; :marker / :core / :log / :full
  (verbosity        :info)              ; :debug / :verbose / :info / :warn
  (workdir          nil)
  (timeout          nil)                ; seconds, integer or nil
  (help-p           nil)
  (version-p        nil)
  (dry-run-p        nil)
  (no-init-p        nil)
  (main             nil)                ; symbol name as string
  (positional       nil :type list))

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

;;; --- low-level argument-list utilities ------------------------------

(defun starts-with-double-dash-p (string)
  (and (>= (length string) 2)
       (char= (char string 0) #\-)
       (char= (char string 1) #\-)))

(defun split-long-option (argument)
  "Split a `--opt=VALUE` argument into (values OPT VALUE), where OPT
keeps its leading dashes. For `--opt` without an `=`, VALUE is NIL."
  (let ((equals (position #\= argument)))
    (if equals
        (values (subseq argument 0 equals)
                (subseq argument (1+ equals)))
        (values argument nil))))

(defun pop-required (option remaining-cell)
  "Pop the next argument off the cons cell holding the argv tail.
Signals CLI-USAGE-ERROR when no argument follows. REMAINING-CELL is a
cons whose CAR is the live argv tail; this dance lets the caller stay
in a LOOP without juggling a setf-able place by hand."
  (let ((rest (car remaining-cell)))
    (unless rest
      (error 'cli-usage-error
             :option option
             :message (format nil "Missing argument after ~A" option)))
    (setf (car remaining-cell) (rest rest))
    (first rest)))

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
  --no-init              Skip site init.
  --dry-run              Print the resolved action plan and exit 0.

Diagnostics:
  -v, --verbose          Verbose progress.
  -q, --quiet            Suppress non-error output.
  -d, --debug            Debug traces (implies --verbose).

Informational:
  -h, --help             Show this help and exit.
  -V, --version          Print version and exit.
")

(defun print-usage (&optional (stream *standard-output*))
  (write-string *usage-banner* stream)
  (finish-output stream))

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
        (env-epure   (env-default :epure)))
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
      (setf (cli-options-epure-p options) t)))
  options)

(defun parse-mode (value option)
  (cond ((string-equal value "auto")       :auto)
        ((string-equal value "automation") :automation)
        ((string-equal value "batch")      :batch)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown mode ~S (expected auto/automation/batch)"
                                   value)))))

(defun parse-backend-symbol (value option)
  (cond ((string-equal value "clautolisp") :clautolisp)
        ((string-equal value "bricscad")   :bricscad)
        ((string-equal value "autocad")    :autocad)
        ((string-equal value "echo")       :echo)   ; tests only
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown backend ~S" value)))))

(defun parse-backend-variant (value option)
  (cond ((string-equal value "attach") :attach)
        ((string-equal value "launch") :launch)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown --backend variant ~S (expected attach/launch)"
                                   value)))))

(defun parse-host (value option)
  (cond ((string-equal value "mock") :mock)
        ((string-equal value "null") :null)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown --host ~S (expected mock/null)"
                                   value)))))

(defun parse-dialect (value option)
  (cond ((string-equal value "strict")        :strict)
        ((string-equal value "autocad-2026")  :autocad-2026)
        ((string-equal value "bricscad-v26")  :bricscad-v26)
        ((string-equal value "clautolisp")    :clautolisp)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown dialect ~S" value)))))

(defun parse-bootstrap-phase (value option)
  (cond ((string-equal value "marker") :marker)
        ((string-equal value "core")   :core)
        ((string-equal value "log")    :log)
        ((string-equal value "full")   :full)
        (t (error 'cli-usage-error
                  :option option
                  :message (format nil "Unknown bootstrap phase ~S" value)))))

(defun parse-timeout (value option)
  (let ((parsed (parse-integer value :junk-allowed t)))
    (unless (and parsed (plusp parsed))
      (error 'cli-usage-error
             :option option
             :message (format nil "Timeout must be a positive integer (got ~S)"
                              value)))
    parsed))

;;; --- the parser itself ----------------------------------------------

(defun parse-arguments (argv)
  "Parse ARGV (a list of strings, *without* the program name) into a
CLI-OPTIONS record. Pure: no I/O, no calls into the registry. The
caller can inspect the result, validate it (RESOLVE-BACKEND), or
build the action plan (PLAN-FROM-OPTIONS).

Long options accept both `--opt VALUE` and `--opt=VALUE`. Short
options are single-letter; their VALUE comes from the next argument
when required. Unknown options signal CLI-USAGE-ERROR."
  (let* ((options (make-cli-options))
         (remaining (cons argv nil))
         (actions '()))
    (apply-env-defaults options)
    (labels ((take (option)
               (pop-required option remaining))
             (queue (action)
               (push action actions))
             (set-backend (kind)
               (when (and (cli-options-backend options)
                          (not (eql (cli-options-backend options) kind)))
                 (error 'cli-usage-error
                        :option (format nil "--~(~A~)" kind)
                        :message
                        (format nil "Conflicting backend selectors (~S vs ~S)"
                                (cli-options-backend options) kind)))
               (setf (cli-options-backend options) kind)))
      (loop while (car remaining)
          for arg = (pop (car remaining))
          do (cond
               ;; --help / -h
               ((or (string= arg "--help") (string= arg "-h"))
                (setf (cli-options-help-p options) t))
               ;; --version / -V
               ((or (string= arg "--version") (string= arg "-V"))
                (setf (cli-options-version-p options) t))
               ;; verbosity
               ((or (string= arg "--verbose") (string= arg "-v"))
                (setf (cli-options-verbosity options) :verbose))
               ((or (string= arg "--quiet") (string= arg "-q"))
                (setf (cli-options-verbosity options) :warn))
               ((or (string= arg "--debug") (string= arg "-d"))
                (setf (cli-options-verbosity options) :debug))
               ;; backend selection
               ((string= arg "--clautolisp") (set-backend :clautolisp))
               ((string= arg "--bricscad")   (set-backend :bricscad))
               ((string= arg "--autocad")    (set-backend :autocad))
               ;; mode / variant
               ((option-value arg "--mode" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--mode" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-mode options)
                        (parse-mode value "--mode"))))
               ((option-value arg "--backend" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--backend" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-backend-variant options)
                        (parse-backend-variant value "--backend"))))
               ;; actions
               ((or (string= arg "-l") (string= arg "--load"))
                (queue (action-load (take arg)
                                    :encoding (cli-options-load-encoding options))))
               ((option-value arg "--load" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--load" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest)
                  (queue (action-load value
                                      :encoding (cli-options-load-encoding options)))))
               ((or (string= arg "-x") (string= arg "--eval"))
                (queue (action-eval (take arg))))
               ((option-value arg "--eval" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--eval" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest)
                  (queue (action-eval value))))
               ((option-value arg "--main" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--main" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-main options) value)
                  (queue (action-main value))))
               ((or (string= arg "-i") (string= arg "--interactive"))
                (setf (cli-options-interactive-p options) t)
                (queue (action-interactive)))
               ((string= arg "--quit")
                (setf (cli-options-quit-p options) t)
                (queue (action-quit)))
               ;; host / dialect
               ((option-value arg "--host" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--host" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-host options)
                        (parse-host value "--host"))))
               ((option-value arg "--dialect" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--dialect" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-dialect options)
                        (parse-dialect value "--dialect"))))
               ;; encoding
               ((string= arg "-e")
                (setf (cli-options-load-encoding options) (take arg)))
               ((string= arg "-E")
                (setf (cli-options-io-encoding options) (take arg)))
               ;; dwg / epure
               ((option-value arg "--dwg" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--dwg" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-dwg options) value)))
               ((string= arg "--epure")
                (setf (cli-options-epure-p options) t))
               ;; bootstrap
               ((option-value arg "--bootstrap-phase" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--bootstrap-phase" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-bootstrap-phase options)
                        (parse-bootstrap-phase value "--bootstrap-phase"))))
               ;; workdir
               ((option-value arg "--workdir" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--workdir" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-workdir options) value)))
               ;; timeout
               ((option-value arg "--timeout" (car remaining))
                (multiple-value-bind (matched value rest)
                    (consume-long-option arg "--timeout" (car remaining))
                  (declare (ignore matched))
                  (setf (car remaining) rest
                        (cli-options-timeout options)
                        (parse-timeout value "--timeout"))))
               ;; flags
               ((string= arg "--dry-run")
                (setf (cli-options-dry-run-p options) t))
               ((string= arg "--no-init")
                (setf (cli-options-no-init-p options) t))
               ;; unknown long option
               ((and (>= (length arg) 2)
                     (char= (char arg 0) #\-)
                     (char= (char arg 1) #\-))
                (error 'cli-usage-error
                       :option arg
                       :message (format nil "Unknown option ~A" arg)))
               ;; unknown short option (any -X that wasn't matched above)
               ((and (>= (length arg) 1)
                     (char= (char arg 0) #\-)
                     (> (length arg) 1))
                (error 'cli-usage-error
                       :option arg
                       :message (format nil "Unknown option ~A" arg)))
               ;; positional argument: implicit -l for the first file
               (t
                (push arg (cli-options-positional options))
                (queue (action-load arg
                                    :encoding (cli-options-load-encoding options))))))
      (setf (cli-options-positional options)
            (nreverse (cli-options-positional options))
            (cli-options-actions options)
            (nreverse actions))
      options)))

(defun option-value (arg long-name argv-tail)
  "True when ARG names LONG-NAME (either `--name` standalone or
`--name=value`). The third argument ARGV-TAIL is the live tail of the
unprocessed argument list and is not consulted here — it is part of
the predicate's signature so CONSUME-LONG-OPTION can pull the value
out without re-matching."
  (declare (ignore argv-tail))
  (let ((eq-pos (position #\= arg)))
    (cond
      (eq-pos (string= (subseq arg 0 eq-pos) long-name))
      (t      (string= arg long-name)))))

(defun consume-long-option (arg long-name argv-tail)
  "Return (values matched-p value remaining-argv). When ARG has the
form `--name=value`, value is taken from the embedded part and
ARGV-TAIL is returned unchanged. When ARG is `--name`, the value is
the head of ARGV-TAIL (and the returned remaining is its tail)."
  (let ((eq-pos (position #\= arg)))
    (cond
      (eq-pos
       (values t (subseq arg (1+ eq-pos)) argv-tail))
      (t
       (unless argv-tail
         (error 'cli-usage-error
                :option long-name
                :message (format nil "Missing argument after ~A" long-name)))
       (values t (first argv-tail) (rest argv-tail))))))

;;; --- backend resolution ---------------------------------------------

(defun resolve-backend (options)
  "Apply the spec's backend-defaulting algorithm to OPTIONS. Returns
the registered backend instance to drive.

Algorithm (matches spec section \"Algorithme par défaut\"):
  1. Explicit --bricscad / --autocad / --clautolisp wins.
  2. Otherwise, $ALFE_BACKEND_OVERRIDE supplies a default for early
     adopters.
  3. Otherwise, $AUTOLISP_BACKEND supplies the legacy default.
  4. Otherwise, every registered backend's DETECT is called in order;
     the first to succeed wins.
  5. If everything fails, signal BACKEND-NOT-AVAILABLE."
  (let* ((selected (or (cli-options-backend options)
                       (let ((override (env-default :override)))
                         (when override
                           (parse-backend-symbol
                            override "$ALFE_BACKEND_OVERRIDE"))))))
    (when selected
      (let ((backend (find-backend selected)))
        (unless backend
          (error 'backend-not-available
                 :backend selected
                 :message (format nil "Backend ~S is not registered."
                                  selected)))
        (return-from resolve-backend (detect backend))))
    ;; Auto: try each registered backend in order.
    (dolist (key (list-backends))
      (let ((backend (find-backend key)))
        (handler-case
            (return-from resolve-backend (detect backend))
          (backend-not-available () nil))))
    (error 'backend-not-available
           :message "No backend detected. Set --clautolisp explicitly or install a supported CAD.")))

;;; --- action plan ----------------------------------------------------

(defun plan-from-options (options)
  "Return the ordered action plan from OPTIONS. Currently the parser
appends actions in command-line order; this function exists so that
later refinements (e.g. inserting an implicit --quit when no -i and no
--interactive) have a single place to live."
  (let ((actions (copy-list (cli-options-actions options))))
    ;; Spec invariant: if neither --interactive nor an explicit --quit
    ;; was requested, the engine should stop cleanly when the queue
    ;; drains. We append a synthetic :quit so backends see a uniform
    ;; \"queue ends with quit\" shape.
    (unless (or (cli-options-interactive-p options)
                (cli-options-quit-p options)
                (some (lambda (a) (eq (action-kind a) :interactive)) actions)
                (some (lambda (a) (eq (action-kind a) :quit)) actions))
      (setf actions (append actions (list (action-quit)))))
    actions))

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
  (dolist (action (plan-from-options options))
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
          (t
           (set-level (cli-options-verbosity options))
           (let ((backend (resolve-backend options)))
             (cond
               ((cli-options-dry-run-p options)
                (emit-dry-run options backend)
                0)
               (t
                (run-plan options backend)))))))
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

(defun run-plan (options backend)
  "Drive a real backend through the action plan. Returns the exit code."
  (let* ((workdir (prepare-workdir backend
                                   (cli-options-workdir options)))
         (session (start-engine backend workdir
                                :dialect (cli-options-dialect options)
                                :host (cli-options-host options)
                                :mock-input nil
                                :bootstrap-phase
                                (cli-options-bootstrap-phase options)
                                :interactive-p
                                (cli-options-interactive-p options))))
    (unwind-protect
         (let* ((plan (plan-from-options options))
                (result (eval-plan session plan)))
           ;; Echo whatever stdout the backend captured (the in-process
           ;; clautolisp backend leaves it empty because output flows
           ;; through the live streams; the echo and file-IPC backends
           ;; return non-empty strings).
           (let ((stdout (eval-result-output result))
                 (stderr (eval-result-error-output result)))
             (when (and stdout (plusp (length stdout)))
               (write-string stdout *standard-output*))
             (when (and stderr (plusp (length stderr)))
               (write-string stderr *error-output*)))
           (finish-output)
           (finish-output *error-output*)
           (ecase (eval-result-status result)
             (:success  0)
             (:failed   1)
             (:aborted  1)))
      (ignore-errors (shutdown session :reason :cli-exit))
      (ignore-errors (cleanup-workdir backend workdir
                                      :keep-p (cli-options-no-init-p options))))))
