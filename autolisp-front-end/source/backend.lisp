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
           #:read-output
           #:send-input
           #:request-control
           #:shutdown
           #:cleanup-workdir
           ;; session struct + accessors
           #:session
           #:make-session
           #:session-backend
           #:session-workdir
           #:session-dialect
           #:session-state
           #:session-handle
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
           #:eval-result-condition))

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
                                          interactive-p load-encoding)
  (:documentation
   "Bring BACKEND up to the READY state under WORKDIR, returning a
session handle (a `session` instance, or a subclass thereof). For
clautolisp this binds an evaluation context; for CAD backends this
writes the runtime LSP, launches the engine, and polls status.txt
until READY.

LOAD-ENCODING, when non-nil, is the user-facing CLI string from
`-e ENC' (e.g. \"utf-8\"). Backends that can honour a session-wide
source-file encoding apply it to their runtime; backends that
can't (CAD-resident engines whose AutoLISP runtime owns the
encoding policy) ignore it."))

(defgeneric eval-plan (session plan)
  (:documentation
   "Execute an action PLAN (list of action records built by
ALFE.BACKEND:MAKE-ACTION) against SESSION. Returns an EVAL-RESULT."))

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
  (condition     nil))
