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
           #:cli-usage-error
           #:cli-usage-error-message
           #:cli-usage-error-option
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
the condition into an exit-code-3 failure."))

(define-condition backend-bootstrap-error (backend-error)
  ()
  (:default-initargs :phase :bootstrap :code :bootstrap-failed)
  (:documentation
   "The backend was discoverable but could not be brought up to the
READY state (engine launch failed, runtime LSP failed to load, no
status.txt READY within the timeout). Maps to exit code 4."))

(define-condition backend-protocol-error (backend-error)
  ()
  (:default-initargs :phase :protocol :code :protocol-failure)
  (:documentation
   "The file-IPC protocol (or in-process equivalent) tripped over an
unexpected status, malformed message, or polling timeout. Distinct
from a bootstrap error: the engine reached READY but then misbehaved
on a subsequent request."))

(define-condition backend-eval-error (backend-error)
  ()
  (:default-initargs :phase :eval :code :user-error)
  (:documentation
   "User-script evaluation reported failure (an AutoLISP runtime error
escaped to the top level, --main exited with a non-zero result, etc.).
Maps to exit code 1."))

;; CLI-USAGE-ERROR moved to clautolisp.autolisp-cli; alfe re-exports
;; the same condition class via this package's defpackage above.

(defun exit-code-for-condition (condition)
  "Map a condition to the alfe exit-code policy documented in
alfe-cli.issue. Unknown conditions get exit code 1 so the CLI never
exits 0 on an error path."
  (typecase condition
    (cli-usage-error          2)
    (backend-not-available    3)
    (backend-bootstrap-error  4)
    (backend-protocol-error   4)
    (backend-eval-error       1)
    (backend-error            1)
    (t                        1)))
