;;;; autolisp-front-end/tools/run-alfe-conformance/source/main.lisp
;;;;
;;;; Standalone runner for the alfe conformance corpus. Mirrors what
;;;; the FiveAM CONFORMANCE-CORPUS-PASSES test does, but wrapped as a
;;;; CLI tool so `make conformance` (or a CI job) can invoke it
;;;; outside the FiveAM context.
;;;;
;;;; Invocation:
;;;;
;;;;   run-alfe-conformance [DIRECTORY]
;;;;
;;;; When DIRECTORY is omitted, the runner uses the bundled
;;;; tests/scenarios/ directory. Exit codes:
;;;;
;;;;   0  every scenario passed or was skipped.
;;;;   1  at least one scenario failed.
;;;;   2  setup error (corpus not found, etc.).

(defpackage #:alfe.tools.run-alfe-conformance
  (:use #:cl)
  (:export #:main))

(in-package #:alfe.tools.run-alfe-conformance)

(defun parse-argv (argv)
  "Tiny argv parser. We accept one positional arg (the directory) and
the usual --help."
  (let ((positional nil)
        (help-p nil))
    (loop for arg in argv
          do (cond ((or (string= arg "--help") (string= arg "-h"))
                    (setf help-p t))
                   (t (push arg positional))))
    (values (nreverse positional) help-p)))

(defun print-usage (stream)
  (format stream
          "~&Usage: run-alfe-conformance [DIRECTORY]~%~
           ~%~
           Run every .sexp scenario found under DIRECTORY (or the~%~
           bundled tests/scenarios/ when none is given) through alfe's~%~
           in-process CLI, and report pass / fail / skipped counts.~%~
           ~%~
           Exit codes: 0 = green; 1 = failures; 2 = setup error.~%"))

(defun main (&optional argv)
  (multiple-value-bind (positional help-p)
      (parse-argv (or argv (rest sb-ext:*posix-argv*)))
    (when help-p
      (print-usage *standard-output*)
      (uiop:quit 0))
    (handler-case
        (let* ((directory (first positional))
               (results (alfe.conformance:run-scenarios :directory directory))
               (exit (alfe.conformance:summarise-results results)))
          (uiop:quit exit))
      (error (probe)
        (format *error-output*
                "~&run-alfe-conformance: setup error: ~A~%" probe)
        (uiop:quit 2)))))
