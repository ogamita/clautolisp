;;;; autolisp-front-end/source/logging.lisp
;;;;
;;;; Minimal verbosity-aware logger for alfe. Five levels (:debug,
;;;; :verbose, :info, :warn, :error) with :info as the default. The
;;;; CLI sets *current-level* from --quiet / --verbose / --debug; every
;;;; other module calls the level-named helpers below.
;;;;
;;;; Logs go to *error-output* by default. `with-log-stream` rebinds
;;;; the destination so the file-protocol layer can also write a
;;;; structured trace to its workdir/log/ subdir (the file-protocol
;;;; ticket fills that in; this module only provides the wiring).

(defpackage #:alfe.logging
  (:use #:cl)
  (:export #:*current-level*
           #:*log-stream*
           #:set-level
           #:level<=
           #:log-debug
           #:log-verbose
           #:log-info
           #:log-warn
           #:log-error
           #:with-log-stream))

(in-package #:alfe.logging)

(defparameter *level-order*
  '(:debug :verbose :info :warn :error)
  "Most-verbose-first ordering used by LEVEL<=.")

(defparameter *current-level* :info
  "Current alfe log level. Anything strictly less verbose than this
is suppressed. The CLI sets this from --quiet (:warn) / --verbose
(:verbose) / --debug (:debug); the default is :info.")

(defparameter *log-stream* nil
  "Destination stream for alfe log output. When NIL the helpers fall
back to *error-output*; rebound by WITH-LOG-STREAM to tee into a
workdir-resident log file.")

(defun level-index (level)
  (or (position level *level-order*)
      (error "Unknown alfe log level ~S (expected one of ~S)."
             level *level-order*)))

(defun level<= (left right)
  "True iff LEFT is at most as verbose as RIGHT — i.e. once
*current-level* reaches LEFT, messages tagged RIGHT are emitted.
Used by the level-named helpers below to gate output."
  (<= (level-index left) (level-index right)))

(defun set-level (level)
  "Set *CURRENT-LEVEL* after validating LEVEL belongs to *LEVEL-ORDER*."
  (level-index level) ; signals if unknown
  (setf *current-level* level))

(defun effective-stream ()
  (or *log-stream* *error-output*))

(defun emit (label control-string arguments)
  (let ((stream (effective-stream)))
    (format stream "~&alfe[~A]: " label)
    (apply #'format stream control-string arguments)
    (terpri stream)
    (finish-output stream)))

;;; The helpers are named LOG-DEBUG / LOG-VERBOSE / LOG-INFO /
;;; LOG-WARN / LOG-ERROR to avoid colliding with the CL standard
;;; symbols DEBUG and WARN (which are package-locked under SBCL and
;;; would otherwise force every caller to fully qualify the call).

(defun log-debug (control-string &rest arguments)
  (when (level<= *current-level* :debug)
    (emit "debug" control-string arguments)))

(defun log-verbose (control-string &rest arguments)
  (when (level<= *current-level* :verbose)
    (emit "verbose" control-string arguments)))

(defun log-info (control-string &rest arguments)
  (when (level<= *current-level* :info)
    (emit "info" control-string arguments)))

(defun log-warn (control-string &rest arguments)
  (when (level<= *current-level* :warn)
    (emit "warn" control-string arguments)))

(defun log-error (control-string &rest arguments)
  ;; :error always fires, regardless of *current-level*.
  (emit "error" control-string arguments))

(defmacro with-log-stream ((stream) &body body)
  "Run BODY with *log-stream* bound to STREAM. Convenience macro used
by the file-protocol driver to tee logs into workdir/log/alfe.log."
  `(let ((*log-stream* ,stream))
     ,@body))
