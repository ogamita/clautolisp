;;;; autolisp-front-end/source/backend.lisp
;;;;
;;;; Abstract backend protocol for alfe. The generics below are the
;;;; *uniform* surface alfe.cli calls into; concrete backends specialise
;;;; them while alfe.cli stays backend-agnostic. The spec for this
;;;; surface is ../issues/open/alfe-backend-interface.issue.
;;;;
;;;; The package also defines:
;;;;
;;;;   - `session`   — the per-run state object every backend extends
;;;;                   via subclassing.
;;;;   - `*backends*` — a registry of detector entry points keyed by
;;;;                   backend symbol. Each per-backend module registers
;;;;                   itself at load time with REGISTER-BACKEND.
;;;;   - action-plan helpers (MAKE-ACTION / ACTION-KIND / …) — the
;;;;                   record type alfe.cli builds and EVAL-PLAN
;;;;                   consumes.
;;;;
;;;; Concrete backends (clautolisp / bricscad / autocad / echo) live in
;;;; their own files and register themselves once their package is
;;;; loaded.

(defpackage #:alfe.backend
  (:use #:cl)
  (:export ;; backend registry
           #:*backends*
           #:register-backend
           #:find-backend
           #:list-backends
           ;; backend abstract class + generics
           #:backend
           #:backend-name
           #:backend-display-name
           #:backend-supports-vlisp-compile-p
           #:detect
           #:prepare-workdir
           #:start-engine
           #:eval-plan
           #:eval-plan-with-action-hooks
           #:read-output
           #:send-input
           #:request-control
           #:shutdown
           #:cleanup-workdir
           #:collect-engine-log
           ;; session struct + accessors
           #:session
           #:make-session
           #:session-backend
           #:session-workdir
           #:session-dialect
           #:session-state
           #:session-handle
           #:session-request-timeout
           #:session-state-set
           ;; canonical session states
           #:+session-states+
           ;; action-plan helpers
           #:make-action
           #:action-kind
           #:action-payload
           #:action-load
           #:action-eval
           #:action-main
           #:action-interactive
           #:action-quit
           ;; structured result returned by EVAL-PLAN
           #:eval-result
           #:make-eval-result
           #:eval-result-status
           #:eval-result-value
           #:eval-result-output
           #:eval-result-error-output
           #:eval-result-condition
           #:eval-result-exit-code))

(in-package #:alfe.backend)

;;; --- backend registry ------------------------------------------------

(defparameter *backends* (make-hash-table :test #'eql)
  "Map from backend symbol (e.g. :clautolisp) to an instance of a
concrete BACKEND subclass. Populated by REGISTER-BACKEND at the time
each backend module is loaded. The CLI default-resolver iterates over
this map to find a backend whose DETECT generic returns a value.")

(defun register-backend (backend-symbol instance)
  "Register INSTANCE under BACKEND-SYMBOL. Re-registering replaces the
previous entry — useful for tests that swap in stubs."
  (setf (gethash backend-symbol *backends*) instance))

(defun find-backend (backend-symbol)
  "Return the backend registered under BACKEND-SYMBOL, or NIL."
  (gethash backend-symbol *backends*))

(defun list-backends ()
  "Return the list of registered backend symbols, in insertion order
when the host implementation supports it."
  (let (result)
    (maphash (lambda (key value)
               (declare (ignore value))
               (push key result))
             *backends*)
    (nreverse result)))

;;; --- backend abstract class + generics ------------------------------

(defclass backend ()
  ((name
    :initarg :name
    :reader backend-name
    :documentation
    "Keyword matching the CLI flag and the registry key. One of
:clautolisp, :bricscad, :autocad, :echo (the test mock).")
   (display-name
    :initarg :display-name
    :reader backend-display-name
    :initform nil
    :documentation
    "Human-readable name printed in --verbose traces and error
messages. Falls back to the symbol when NIL.")
   (supports-vlisp-compile-p
    :initarg :supports-vlisp-compile-p
    :reader backend-supports-vlisp-compile-p
    :initform nil
    :documentation
    "Capability flag consumed by the CLI's --mode automation fast
path; only AutoCAD on Windows sets this true today."))
  (:documentation
   "Common superclass for every alfe backend. Concrete classes add
backend-private slots (the engine binary path, the file-protocol
workdir, the COM dispatch object, …) and specialise the generics
below."))

(defgeneric detect (backend &key)
  (:documentation
   "Return BACKEND (possibly populated with discovery results) if the
engine is available on this host, or signal
ALFE.ERROR:BACKEND-NOT-AVAILABLE otherwise. Backends may accept
backend-specific keyword arguments (e.g. :install-root, :prefer-arch).
The CLI default-resolver calls DETECT with no keywords."))

(defgeneric prepare-workdir (backend workdir-root &key)
  (:documentation
   "Build the per-run WORKDIR for this BACKEND under WORKDIR-ROOT,
including backend-specific subdirs (`protocol/` for CAD backends,
no extra structure for clautolisp). Returns the absolute workdir
pathname."))

(defgeneric start-engine (backend workdir &key dialect host
                                          mock-input bootstrap-phase
                                          interactive-p mode dwg
                                          load-encoding
                                          io-encoding
                                          source-encoding
                                          file-read-encoding file-write-encoding
                                          console-in-encoding console-out-encoding
                                          cadstdio-in-encoding cadstdio-out-encoding
                                          log-encoding
                                          terminal-in-encoding terminal-out-encoding
                                          cli-options version-text)
  (:documentation
   "Bring BACKEND up to the READY state under WORKDIR, returning a
session handle (a `session` instance, or a subclass thereof). For
clautolisp this binds an evaluation context; for CAD backends this
writes the runtime LSP, launches the engine, and polls status.txt
until READY.

The encoding SITUATIONS (encoding-situations-cli-options.issue, section 6
point 1) arrive one keyword per situation x direction, each the canonical
encoding name the user asked for (e.g. \"UTF-8\") or NIL for the backend
default: SOURCE-ENCODING (-Esource), FILE-READ-ENCODING / FILE-WRITE-ENCODING
(-Efile[-read|-write]), CONSOLE-IN-ENCODING / CONSOLE-OUT-ENCODING
(-Econsole[-in|-out]), CADSTDIO-IN-ENCODING / CADSTDIO-OUT-ENCODING
(-Ecadstdio[-in|-out]), LOG-ENCODING (-Elog) and TERMINAL-IN-ENCODING /
TERMINAL-OUT-ENCODING (-Eterminal[-in|-out]). ALFE.CLI:SITUATION-ENGINE-KEYWORDS
builds them: the bare -E / --encoding reaches source, file, log and terminal
but never console or cadstdio (product-fixed boundaries), and when the backend
is the clautolisp engine an explicit -Econsole is folded into the terminal
pair (its console is its terminal). A backend honours the situations it can
and ignores (or warns about) the others.

LOAD-ENCODING / IO-ENCODING are the legacy mirrors of SOURCE-ENCODING /
TERMINAL-*-ENCODING (the `source' / `terminal' resolution with the bare -E),
kept for compatibility with callers that pass only them; a backend prefers
the per-situation keyword when it is given.

CLI-OPTIONS is the fully-parsed CLAUTOLISP.AUTOLISP-CLI:CLI-OPTIONS
struct (or NIL). When non-NIL, the backend installs the matching
*AUTOLISP-…* globals (transmit-options.issue) in the engine — for
the in-process clautolisp backend that's a direct call into
INSTALL-TRANSMIT-VARIABLES against the just-created context; for
CAD backends that means emitting additional (setq …) forms into
run-common.lsp. The clautolisp subprocess variant ignores
CLI-OPTIONS — the spawned `clautolisp-sbcl` binary installs its
own *AUTOLISP-…* globals from its own argv."))

(defgeneric eval-plan (session plan)
  (:documentation
   "Execute an action PLAN (list of action records built by
ALFE.BACKEND:MAKE-ACTION) against SESSION. Returns an EVAL-RESULT."))

(defgeneric eval-plan-with-action-hooks (session plan before-action after-action)
  (:documentation
   "Execute PLAN against SESSION as EVAL-PLAN does, calling BEFORE-ACTION with
(ACTION INDEX) before each action and AFTER-ACTION with (ACTION INDEX RESULT)
after it, INDEX counting the actions of PLAN from 1 and RESULT the action's own
EVAL-RESULT. Returns the EVAL-RESULT of the whole plan. alfe's :PRE-ACTION and
:POST-ACTION plug-in hooks are called through it.

The default method evaluates PLAN one action at a time (one EVAL-PLAN call per
action) and stops at the first action that does not succeed. A backend that can
stop at the action boundaries of ONE run specialises it, so that the run is the
one EVAL-PLAN would make -- the clautolisp backend does, in both of its
variants (alfe-clautolisp-backend-semantic-parity.issue)."))

(defgeneric read-output (session &key timeout)
  (:documentation
   "Drain stdout and stderr captured since the previous call. Returns
(VALUES STDOUT STDERR). For in-process backends both strings may be
empty because output went straight to the live streams; for file-IPC
backends, this reads from `stdout.txt` and `stderr.txt`."))

(defgeneric send-input (session text)
  (:documentation
   "Send a line of user input. For clautolisp direct, push into the
eval thread's input channel. For CAD backends, atomic write to
`stdin.txt`."))

(defgeneric request-control (session command)
  (:documentation
   "Out-of-band control. COMMAND is one of :ping :shutdown :interrupt.
Backends signal ALFE.ERROR:BACKEND-PROTOCOL-ERROR on an unknown
command."))

(defgeneric shutdown (session &key reason)
  (:documentation
   "Tear down SESSION. Idempotent: a second SHUTDOWN on an already
:stopped session is a no-op. REASON is recorded in the session
handle for the CLI's exit-trace renderer."))

(defgeneric cleanup-workdir (backend workdir &key keep-p)
  (:documentation
   "Remove WORKDIR unless KEEP-P or $AUTOLISP_KEEP_WORKDIR is set.
Default method delegates to ALFE.WORKDIR:REMOVE-WORKDIR — backends
override only when they have extra cleanup (e.g. a lock-file the
CAD process might still hold)."))

(defgeneric collect-engine-log (backend workdir &key cli-options)
  (:documentation
   "The engine's own command-history log (LOGFILEMODE) of the run that used
WORKDIR, read after the engine has shut down and before the workdir is removed
(alfe --cad-log; the `log' encoding situation). Returns (values ENTRIES
STATUS): ENTRIES a list of (NAME . TEXT), one per log file in the order the
engine wrote them, TEXT decoded per -Elog (else the backend's measured
default) with LF line ends; STATUS :COLLECTED, :NONE (the engine wrote no
log) or :UNSUPPORTED (the backend has no CAD log for alfe to collect -- the
default)."))

(defmethod collect-engine-log ((backend backend) workdir &key cli-options)
  (declare (ignore workdir cli-options))
  (values '() :unsupported))

(defmethod backend-display-name :around ((backend backend))
  (or (call-next-method) (backend-name backend)))

(defmethod cleanup-workdir ((backend backend) workdir &key keep-p)
  (alfe.workdir:remove-workdir workdir :keep-p keep-p))

;;; --- session struct -------------------------------------------------

(defparameter +session-states+
  '(:booting :ready :running :done :stopping :stopped :failed)
  "Canonical session-state vocabulary. The CLI's verbose mode renders
state transitions in this order; backends must report into the same
keyword set so the trace stays uniform across in-process and
file-IPC paths.")

(defstruct (session
            (:constructor %make-session)
            (:copier nil))
  "Per-run state shared by every backend. Concrete backends subclass
this struct via :include to add their backend-specific live handle.
The state slot follows the +SESSION-STATES+ vocabulary."
  (backend  nil)
  (workdir  nil)
  (dialect  nil)
  ;; REQUEST-TIMEOUT: the per-request wait budget the user asked for via
  ;; --timeout / $AUTOLISP_WAIT_SECS, or NIL when unspecified (backends then
  ;; fall back to their built-in default). CAD backends thread this into
  ;; DRIVE-PROTOCOL-ACTIONS so `alfe --timeout N' actually bounds (or, at the
  ;; default, keeps alive) a long eval — see
  ;; alfe-request-timeout-aborts-long-eval.
  (request-timeout nil)
  (state    :booting :type (member :booting :ready :running :done
                                   :stopping :stopped :failed))
  ;; HANDLE is opaque; backends store their engine handle here when
  ;; they do not subclass SESSION (the in-process clautolisp backend
  ;; will likely subclass; the echo backend uses HANDLE for its
  ;; scripted answer table).
  (handle   nil))

(defun make-session (&rest initargs &key backend workdir dialect (state :booting)
                                         handle)
  (declare (ignore backend workdir dialect handle))
  (apply #'%make-session :state state initargs))

(defun session-state-set (session new-state)
  "Set SESSION's state, validating NEW-STATE against +SESSION-STATES+.
The validation is here, not on the slot, so that backends which
include SESSION inherit a single canonical check."
  (unless (member new-state +session-states+)
    (error "Unknown session state ~S (expected one of ~S)."
           new-state +session-states+))
  (setf (session-state session) new-state))

;;; --- action-plan helpers --------------------------------------------

(defstruct (action
            (:constructor %make-action))
  "One node in an alfe action plan. KIND is one of :load :eval :main
:interactive :quit; PAYLOAD is the per-kind payload:
  :load        — a plist (:path PATH :encoding ENCODING-OR-NIL)
  :eval        — the expression text as a string
  :main        — the entry-point symbol-name as a string
  :interactive — NIL
  :quit        — NIL"
  (kind     :eval  :type keyword)
  (payload  nil))

(defun make-action (kind &optional payload)
  "Constructor exported to alfe.cli. Validates KIND."
  (unless (member kind '(:load :eval :main :interactive :quit))
    (error "Unknown action kind ~S." kind))
  (%make-action :kind kind :payload payload))

(defun action-load (path &key encoding)
  (make-action :load (list :path path :encoding encoding)))

(defun action-eval (text)
  (make-action :eval text))

(defun action-main (symbol-name)
  (make-action :main symbol-name))

(defun action-interactive ()
  (make-action :interactive nil))

(defun action-quit ()
  (make-action :quit nil))

;;; --- structured EVAL-PLAN result ------------------------------------

(defstruct (eval-result
            (:constructor make-eval-result))
  "Returned by EVAL-PLAN. STATUS is :success on a clean run, :failed
when the user script errored, :aborted when an out-of-band signal
unwound the plan. VALUE is the final form's value rendered as a
string (or NIL on a failure path). OUTPUT and ERROR-OUTPUT capture
the textual stdout/stderr produced by the run. CONDITION, when
non-NIL, is the originating ALFE.ERROR:BACKEND-ERROR."
  (status        :success :type (member :success :failed :aborted))
  (value         nil)
  (output        "" :type string)
  (error-output  "" :type string)
  (condition     nil)
  ;; The process exit status the ENGINE itself decided, or NIL to derive it
  ;; from STATUS. Set by the clautolisp backend, both variants alike: (exit
  ;; N) / (quit N) / an AUTOLISP-SET-STATUS, a file error (EX_NOINPUT) --
  ;; the statuses of CLAUTOLISP.AUTOLISP-CLI:ENGINE-EXIT-STATUS, what the
  ;; clautolisp program exits with (alfe-clautolisp-backend-semantic-
  ;; parity.issue).
  (exit-code     nil))

(defmethod eval-plan-with-action-hooks (session plan before-action after-action)
  (let ((results '()))
    (loop for action in plan
          for index from 1
          do (funcall before-action action index)
             (let ((result (eval-plan session (list action))))
               (push result results)
               (funcall after-action action index result)
               (unless (eq (eval-result-status result) :success)
                 (return))))
    (setf results (nreverse results))
    (let ((last (car (last results))))
      (make-eval-result
       :status (if last (eval-result-status last) :success)
       :value (and last (eval-result-value last))
       :output (apply #'concatenate 'string (mapcar #'eval-result-output results))
       :error-output (apply #'concatenate 'string
                            (mapcar #'eval-result-error-output results))
       :condition (and last (eval-result-condition last))
       :exit-code (and last (eval-result-exit-code last))))))
