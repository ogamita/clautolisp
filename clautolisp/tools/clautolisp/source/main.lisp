(in-package #:clautolisp.tools.clautolisp)

;;;; clautolisp — standalone AutoLISP evaluator.
;;;;
;;;; Reads an AutoLISP source file (or `-x EXPR` snippet), evaluates
;;;; every form in a fresh runtime session under a chosen dialect,
;;;; and exits with a meaningful status code.
;;;;
;;;; Authored as part of Phase 6 of the implementation plan.

(defun usage ()
  (format t "~&Usage: clautolisp [options] FILE.lsp~%")
  (format t "       clautolisp [options] -x EXPRESSION~%")
  (format t "Options:~%")
  (format t "  --dialect NAME     One of: strict (default), autocad-2026, bricscad-v26.~%")
  (format t "  --strict           Shorthand for --dialect strict.~%")
  (format t "  --autocad          Shorthand for --dialect autocad-2026.~%")
  (format t "  --bricscad         Shorthand for --dialect bricscad-v26.~%")
  (format t "  -x EXPRESSION      Evaluate EXPRESSION instead of reading a file.~%")
  (format t "  --help             Show this help and exit.~%"))

(defun resolve-dialect (name-or-keyword)
  (let ((dialect (find-autolisp-dialect name-or-keyword)))
    (unless dialect
      (error "Unknown dialect ~S. Expected one of: strict, autocad-2026, bricscad-v26."
             name-or-keyword))
    dialect))

(defun parse-arguments (arguments)
  "Returns (values dialect mode payload). MODE is :file, :expression
or :missing-input. PAYLOAD is the FILE path or EXPRESSION string."
  (let ((dialect (autolisp-dialect-strict))
        (mode :missing-input)
        (payload nil))
    (loop while arguments
          for argument = (pop arguments)
          do (cond
               ((string= argument "--help")
                (usage)
                (quit 0))
               ((string= argument "--dialect")
                (unless arguments
                  (error "Missing argument after --dialect."))
                (setf dialect (resolve-dialect (pop arguments))))
               ((string= argument "--strict")
                (setf dialect (autolisp-dialect-strict)))
               ((string= argument "--autocad")
                (setf dialect (autolisp-dialect-autocad-2026)))
               ((string= argument "--bricscad")
                (setf dialect (autolisp-dialect-bricscad-v26)))
               ((string= argument "-x")
                (unless arguments
                  (error "Missing expression after -x."))
                (setf mode :expression)
                (setf payload (pop arguments)))
               ((and (> (length argument) 0)
                     (char= (char argument 0) #\-))
                (error "Unknown option ~S." argument))
               (t
                (when (eq mode :missing-input)
                  (setf mode :file)
                  (setf payload argument)))))
    (values dialect mode payload)))

(defun span->string (span)
  (if (null span)
      "<unknown>"
      (format nil "~A:~D:~D-~D:~D"
              (or (source-span-source-name span) "<source>")
              (source-span-start-line span)
              (source-span-start-column span)
              (source-span-end-line span)
              (source-span-end-column span))))

(defun report-runtime-error (condition)
  (format *error-output* "~&clautolisp: runtime error: ~A: ~A~%"
          (autolisp-runtime-error-code condition)
          (autolisp-runtime-error-message condition)))

(defun report-termination (condition)
  (format *error-output* "~&clautolisp: terminated by ~A~%"
          (autolisp-termination-kind condition)))

(defun report-error (condition)
  (format *error-output* "~&clautolisp: ~A~%" condition))

(defun run-with-input (dialect mode payload)
  ;; Builtins must be installed once before any evaluation; they
  ;; share the global symbol table that fresh sessions also use.
  (install-core-builtins)
  (handler-case
      (ecase mode
        (:file
         (run-autolisp-file payload :dialect dialect))
        (:expression
         (run-autolisp-string payload :dialect dialect)))
    (autolisp-runtime-error (condition)
      (report-runtime-error condition)
      (quit 1))
    (autolisp-termination (condition)
      (report-termination condition)
      (quit 0))
    (file-error (condition)
      (report-error condition)
      (quit 2))))

(defun main (&rest argv)
  (handler-case
      (multiple-value-bind (dialect mode payload)
          (parse-arguments (rest argv))
        (cond
          ((eq mode :missing-input)
           (usage)
           (quit 2))
          (t
           (run-with-input dialect mode payload)
           (finish-output)
           (quit 0))))
    (error (error)
      (report-error error)
      (finish-output *error-output*)
      (quit 1))))
