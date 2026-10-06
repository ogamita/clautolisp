;;;; autolisp-front-end/source/error.lisp
;;;;
;;;; Condition hierarchy for the alfe front-end. The class graph is
;;;; specified by ../issues/open/alfe-backend-interface.issue (the
;;;; "Conditions hierarchy" section) and consumed by alfe.cli to map
;;;; failures onto the documented exit codes (cf. alfe-cli.issue
;;;; "Exit codes").
;;;;
;;;; Every condition carries a structured plist with at least
;;;;   :backend  — the backend symbol (:clautolisp / :bricscad / …)
;;;;   :phase    — :detect / :bootstrap / :eval / :shutdown / nil
;;;;   :code     — a short keyword identifying the failure mode
;;;;   :message  — a human-readable message
;;;;   :detail   — backend-private detail (signal-specific plist or nil)
;;;;
;;;; The plist lives in the `details` slot so callers can introspect
;;;; without depending on subclass-specific accessors. The printer
;;;; renders message + code + backend; full details are only shown by
;;;; the CLI's --debug path.

(defpackage #:alfe.error
  (:use #:cl)
  ;; cli-usage-error is owned by clautolisp.autolisp-cli (single
  ;; definition shared by both clautolisp and alfe). alfe re-exports
  ;; it from alfe.error so existing callers and the FiveAM tests can
  ;; keep importing it from alfe.error.
  (:import-from #:clautolisp.autolisp-cli
                #:cli-error
                #:cli-error-status
                #:cli-usage-error
                #:cli-usage-error-message
                #:cli-usage-error-option)
  (:export #:backend-error
           #:backend-error-backend
           #:backend-error-phase
           #:backend-error-code
           #:backend-error-message
           #:backend-error-details
           #:backend-not-available
           #:backend-bootstrap-error
           #:backend-protocol-error
           #:backend-eval-error
           #:plugin-error
           #:plugin-error-plugin
           #:plugin-error-hook
           #:cli-error
           #:cli-error-status
           #:cli-usage-error
           #:cli-usage-error-message
           #:cli-usage-error-option
           #:backend-error-exit-status
           #:exit-code-for-condition))

(in-package #:alfe.error)

(define-condition backend-error (error)
  ((backend  :initarg :backend  :reader backend-error-backend  :initform nil)
   (phase    :initarg :phase    :reader backend-error-phase    :initform nil)
   (code     :initarg :code     :reader backend-error-code     :initform :unknown)
   (message  :initarg :message  :reader backend-error-message  :initform "")
   (details  :initarg :details  :reader backend-error-details  :initform nil))
  (:documentation
   "Parent class for every error raised by an alfe backend. Subclasses
specialise the failure phase but keep the same structured payload, so
alfe.cli's exit-code mapper can treat them uniformly.")
  (:report
   (lambda (condition stream)
     (format stream
             "alfe ~@[~A ~]backend error~@[ (phase ~A)~]: ~A~@[ [~A]~]"
             (backend-error-backend condition)
             (backend-error-phase condition)
             (backend-error-message condition)
             (let ((code (backend-error-code condition)))
               (unless (eq code :unknown) code))))))

(define-condition backend-not-available (backend-error)
  ()
  (:default-initargs :phase :detect :code :not-available)
  (:documentation
   "Signalled by a backend's DETECT generic when the engine cannot be
found on the host system (no binary, no install path, no environment
hint). The CLI default-resolver catches this to try the next backend;
when the user *asked* for this backend explicitly, the CLI converts
the condition into an EX_UNAVAILABLE (69) failure."))

(define-condition backend-bootstrap-error (backend-error)
  ()
  (:default-initargs :phase :bootstrap :code :bootstrap-failed)
  (:documentation
   "The backend was discoverable but could not be brought up to the
READY state (engine launch failed, runtime LSP failed to load, no
status.txt READY within the timeout). Its exit status depends on its
CODE (BACKEND-ERROR-EXIT-STATUS): EX_UNAVAILABLE (69) in general,
EX_TEMPFAIL (75) for a READY timeout, EX_USAGE (64) for a bad option
value, EX_CANTCREAT (73) for a workdir that cannot be created."))

(define-condition backend-protocol-error (backend-error)
  ()
  (:default-initargs :phase :protocol :code :protocol-failure)
  (:documentation
   "The file-IPC protocol (or in-process equivalent) tripped over an
unexpected status, malformed message, or polling timeout. Distinct
from a bootstrap error: the engine reached READY but then misbehaved
on a subsequent request. Exit status EX_PROTOCOL (76), or EX_TEMPFAIL
(75) when the engine was busy."))

(define-condition backend-eval-error (backend-error)
  ()
  (:default-initargs :phase :eval :code :user-error)
  (:documentation
   "User-script evaluation reported failure (an AutoLISP runtime error
escaped to the top level, --main exited with a non-zero result, etc.).
Maps to exit status 1 (the program failed; not a sysexits code)."))

(define-condition plugin-error (backend-error)
  ((plugin :initarg :plugin :reader plugin-error-plugin :initform nil)
   (hook   :initarg :hook   :reader plugin-error-hook   :initform nil))
  (:default-initargs :phase :plugin :code :plugin-failed)
  (:documentation
   "A plug-in's hook handler signalled an ordinary Lisp error. The plug-in
is named so the user knows whose code failed, and the condition is a
BACKEND-ERROR so the CLI maps it like the other run-time failures: exit
status EX_SOFTWARE (70) -- a plug-in is part of the program, and its Lisp
error is an internal error. (A handler that signals CLI-ERROR or a
BACKEND-ERROR itself is not wrapped: it chose its exit status.)")
  (:report
   (lambda (condition stream)
     (format stream "plug-in ~A~@[, hook ~S~]: ~A"
             (plugin-error-plugin condition)
             (plugin-error-hook condition)
             (backend-error-message condition)))))

;; CLI-USAGE-ERROR moved to clautolisp.autolisp-cli; alfe re-exports
;; the same condition class via this package's defpackage above.

(defun backend-error-exit-status (condition)
  "The <sysexits.h> exit status for the backend error CONDITION, by class
and CODE (sysexits-exit-statuses.issue)."
  (let ((code (backend-error-code condition)))
    (typecase condition
      (plugin-error clautolisp.sysexits:+ex-software+)
      ;; The engine is not on this host: no binary, unsupported OS, no
      ;; automation server.
      (backend-not-available clautolisp.sysexits:+ex-unavailable+)
      (backend-bootstrap-error
       (case code
         ;; The CAD never published READY in time.
         (:ready-timeout clautolisp.sysexits:+ex-tempfail+)
         ;; An option value the engine refuses, or one it requires.
         ((:unknown-dialect :unknown-host :host-needs-subprocess :no-dwg)
          clautolisp.sysexits:+ex-usage+)
         (:cannot-create-workdir clautolisp.sysexits:+ex-cantcreat+)
         ;; A program, an installation file or the engine itself could not
         ;; be brought up: :no-accoreconsole, :no-subprocess-binary,
         ;; :no-launch-command, :runtime-asset-missing, :epure-script-*,
         ;; :process-exited-before-ready, :bootstrap-failed, ...
         (t clautolisp.sysexits:+ex-unavailable+)))
      (backend-protocol-error
       (case code
         ;; The control or stdin slot stayed busy: retrying may work.
         ((:stdin-busy :control-busy) clautolisp.sysexits:+ex-tempfail+)
         (t clautolisp.sysexits:+ex-protocol+)))
      ;; The user's program failed.
      (t clautolisp.sysexits:+exit-autolisp-error+))))

(defun exit-code-for-condition (condition)
  "Map a condition ending an alfe run to its process exit status, the
<sysexits.h> codes of clautolisp.sysexits (sysexits-exit-statuses.issue):

  CLI-ERROR                  its status: EX_USAGE (64) for a usage error,
                             EX_NOINPUT (66) for a file an option names...
  BACKEND-NOT-AVAILABLE      EX_UNAVAILABLE (69)
  BACKEND-BOOTSTRAP-ERROR    EX_UNAVAILABLE (69), EX_TEMPFAIL (75), ...
  BACKEND-PROTOCOL-ERROR     EX_PROTOCOL (76), EX_TEMPFAIL (75)
  PLUGIN-ERROR               EX_SOFTWARE (70)
  BACKEND-EVAL-ERROR         1 (the user's program failed)
  any other error            CLAUTOLISP.AUTOLISP-CLI:ENGINE-EXIT-STATUS --
                             EX_NOINPUT for a file error, EX_DATAERR for a
                             source the reader refuses, else EX_SOFTWARE (70).

Never 0: an error path never exits successfully."
  (typecase condition
    (cli-error     (cli-error-status condition))
    (backend-error (backend-error-exit-status condition))
    (t             (clautolisp.autolisp-cli:engine-exit-status condition))))
