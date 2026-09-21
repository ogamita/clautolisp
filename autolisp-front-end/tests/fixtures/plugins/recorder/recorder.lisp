;;;; Fixture plug-in for tests/plugin-tests.lisp: registers a handler for
;;;; every hook in the catalogue and records what it was called with, in
;;;; call order, in *EVENTS* (newest first). Handlers change nothing.

(defpackage #:alfe.plugin.recorder (:use #:cl #:alfe.plugin)
  (:export #:*events*))
(in-package #:alfe.plugin.recorder)

(defvar *events* '()
  "Entries (HOOK . DETAILS-PLIST), newest first.")

;; Each (re)load starts a fresh recording.
(setf *events* '())

(define-plugin "recorder"
  :version "0.1.0"
  :description "Record every hook it is called for."
  :options ((:flag "--recorder" :activates t :doc "Record the hooks.")))

(dolist (entry +hook-points+)
  (let ((hook (first entry))
        (kind (second entry)))
    (register-hook "recorder" hook
                   (lambda (ctx value &rest details)
                     (declare (ignore ctx))
                     (push (list* hook
                                  :value (typecase value
                                           (list (length value))
                                           (string (length value))
                                           (number value)
                                           (t (type-of value)))
                                  details)
                           *events*)
                     (if (eq kind :filter) value nil)))))
