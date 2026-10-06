(in-package #:clautolisp.autolisp-cli)

(define-condition cli-error (simple-error)
  ((option :initarg :option :reader cli-error-option :reader cli-usage-error-option
           :initform nil)
   (message :initarg :message :reader cli-error-message :reader cli-usage-error-message
            :initform "")
   (status :initarg :status :reader cli-error-status
           :initform clautolisp.sysexits:+ex-usage+))
  (:report (lambda (condition stream)
             (if (cli-error-option condition)
                 (format stream "~A: ~A"
                         (cli-error-option condition)
                         (cli-error-message condition))
                 (format stream "~A" (cli-error-message condition)))))
  (:documentation
   "An error the command line leads to before any program runs: an
option, or the file or drawing it names, is unusable. STATUS is the
process exit status it calls for, a <sysexits.h> code
(sysexits-exit-statuses.issue): EX_USAGE for the option itself, EX_NOINPUT
for a file it names that cannot be opened, EX_DATAERR for one that cannot
be understood, and so on. The tools report it as `PROGRAM: OPTION: MESSAGE'
and exit with STATUS."))

(define-condition cli-usage-error (cli-error)
  ()
  (:default-initargs :status clautolisp.sysexits:+ex-usage+)
  (:documentation
   "Signalled when an option is unknown, missing a required argument,
mutually exclusive with one already seen, or carries a value the
parser cannot interpret. Tools translate this into a usage banner +
exit status EX_USAGE (64)."))
