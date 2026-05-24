(in-package #:alfe.tool)

;;;; alfe — single CLI front-end driving clautolisp (in-process or
;;;; subprocess) and CAD-resident AutoLISP REPLs via a file-IPC
;;;; protocol.
;;;;
;;;; Entry point. The image's toplevel function (set by
;;;; generate-alfe.lisp) calls MAIN with the full argv list (program
;;;; name + arguments). The hand-off shape mirrors
;;;; clautolisp/tools/clautolisp/source/main.lisp so build helpers
;;;; can be shared across the two tools.
;;;;
;;;; The real CLI lives in ALFE.CLI:RUN; this MAIN is thin on purpose:
;;;; the FiveAM tests exercise RUN directly with a hand-built argv,
;;;; so the executable wrapper has no logic worth retesting.

(defun main (&rest argv)
  "Image entry point. ARGV is the full command-line argument list, of
which the first element is the program name (per UIOP). We discard it
and delegate to ALFE.CLI:RUN, then exit with its returned exit code."
  (handler-case
      (let ((exit-code (run (rest argv) :version *version*)))
        (finish-output)
        (finish-output *error-output*)
        (quit exit-code))
    (error (condition)
      (format *error-output* "~&alfe: unexpected error: ~A~%" condition)
      (finish-output *error-output*)
      (quit 1))))
