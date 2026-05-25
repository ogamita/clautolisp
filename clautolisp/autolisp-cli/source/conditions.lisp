(in-package #:clautolisp.autolisp-cli)

(define-condition cli-usage-error (simple-error)
  ((option :initarg :option :reader cli-usage-error-option :initform nil)
   (message :initarg :message :reader cli-usage-error-message :initform ""))
  (:report (lambda (condition stream)
             (if (cli-usage-error-option condition)
                 (format stream "~A: ~A"
                         (cli-usage-error-option condition)
                         (cli-usage-error-message condition))
                 (format stream "~A" (cli-usage-error-message condition)))))
  (:documentation
   "Signalled when an option is unknown, missing a required argument,
mutually exclusive with one already seen, or carries a value the
parser cannot interpret. Tools translate this into a usage banner +
exit code."))
