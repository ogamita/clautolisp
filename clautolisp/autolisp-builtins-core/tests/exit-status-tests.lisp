(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; clautolisp exit-status channel:
;;;;   (autolisp-set-status N) / (autolisp-status) / (quit [status])
;;;; See issues/open/autolisp-set-status-and-quit-status.issue and the
;;;; builtins in autolisp-builtins-core/source/api.lisp.

(defun %exit-status-context (dialect-name)
  "Fresh evaluation context whose session carries a DIALECT-NAME
descriptor, so the out-of-dialect gate resolves deterministically."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((ctx     (clautolisp.autolisp-runtime:current-evaluation-context))
         (session (clautolisp.autolisp-runtime:evaluation-context-session ctx)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-dialect session)
          (clautolisp.autolisp-reader:make-autolisp-dialect :name dialect-name))
    ctx))

(defmacro %with-captured-error-output ((var) &body body)
  "Run BODY with *error-output* bound to a string sink; VAR is the
captured string afterwards."
  `(let ((,var (with-output-to-string (*error-output*) ,@body)))
     ,var))

;;; --- storage / reader --------------------------------------------

(test exit-status-defaults-to-zero
  (%exit-status-context :clautolisp)
  (is (eql 0 (autolisp-exit-status)))
  (is (eql 0 (clautolisp.autolisp-builtins-core::builtin-autolisp-status))))

(test autolisp-set-status-stores-and-returns
  (%exit-status-context :clautolisp)
  (is (eql 5 (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 5)))
  (is (eql 5 (autolisp-exit-status)))
  (is (eql 5 (clautolisp.autolisp-builtins-core::builtin-autolisp-status))))

(test autolisp-set-status-truncates-reals
  (%exit-status-context :clautolisp)
  (is (eql 2 (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 2.9d0)))
  (is (eql 2 (autolisp-exit-status))))

(test autolisp-set-status-rejects-non-numbers
  (%exit-status-context :clautolisp)
  (handler-case
      (progn
        (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status
         (make-autolisp-string "nope"))
        (is nil "expected a non-number status to signal"))
    (autolisp-runtime-error (c)
      (is (eq :invalid-integer-argument (autolisp-runtime-error-code c))))))

;;; --- quit / exit carry the status --------------------------------

(test quit-without-arg-uses-stored-status
  (%exit-status-context :clautolisp)
  (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 7)
  (handler-case
      (progn (clautolisp.autolisp-builtins-core::builtin-quit)
             (is nil "expected quit to signal termination"))
    (autolisp-termination (c)
      (is (eq :quit (autolisp-termination-kind c)))
      (is (eql 7 (autolisp-termination-status c))))))

(test quit-with-explicit-status-overrides-and-records
  (%exit-status-context :clautolisp)
  (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 7)
  (handler-case
      (progn (clautolisp.autolisp-builtins-core::builtin-quit 3)
             (is nil "expected quit to signal termination"))
    (autolisp-termination (c)
      (is (eql 3 (autolisp-termination-status c)))))
  ;; the explicit status is also recorded on the session.
  (is (eql 3 (autolisp-exit-status))))

(test exit-without-arg-defaults-to-zero
  (%exit-status-context :clautolisp)
  (handler-case
      (progn (clautolisp.autolisp-builtins-core::builtin-exit)
             (is nil "expected exit to signal termination"))
    (autolisp-termination (c)
      (is (eq :exit (autolisp-termination-kind c)))
      (is (eql 0 (autolisp-termination-status c))))))

;;; --- out-of-dialect diagnostic -----------------------------------

(test set-status-is-silent-under-clautolisp-dialect
  (%exit-status-context :clautolisp)
  (let ((out (%with-captured-error-output (o)
               (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 1))))
    (is (zerop (length out)))))

(test set-status-warns-under-strict-dialect
  (%exit-status-context :strict)
  (let ((out (%with-captured-error-output (o)
               (clautolisp.autolisp-builtins-core::builtin-autolisp-set-status 1))))
    (is (plusp (length out)))
    (is (search "exit-status-extension" out))
    ;; the call still takes effect despite the warning.
    (is (eql 1 (autolisp-exit-status)))))

(test quit-with-status-warns-under-bricscad-but-no-arg-is-silent
  ;; supplying the status arg is the extension; bare (quit) is standard.
  (%exit-status-context :bricscad-v26)
  (let ((warned
          (%with-captured-error-output (o)
            (handler-case
                (clautolisp.autolisp-builtins-core::builtin-quit 4)
              (autolisp-termination () nil))))
        (silent
          (%with-captured-error-output (o)
            (handler-case
                (clautolisp.autolisp-builtins-core::builtin-quit)
              (autolisp-termination () nil)))))
    (is (search "exit-status-extension" warned))
    (is (zerop (length silent)))))
