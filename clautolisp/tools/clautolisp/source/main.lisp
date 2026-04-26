(in-package #:clautolisp.tools.clautolisp)

;;;; clautolisp — standalone AutoLISP evaluator and interactive REPL.
;;;;
;;;; Reads an AutoLISP source file (or `-x EXPR` snippet, or stdin via
;;;; the REPL), evaluates every form in a fresh runtime session under
;;;; a chosen dialect, and exits with a meaningful status code.

(defun usage ()
  (format t "~&Usage: clautolisp [options] FILE.lsp~%")
  (format t "       clautolisp [options] -x EXPRESSION~%")
  (format t "       clautolisp [options]              (interactive REPL)~%")
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
or :repl. PAYLOAD is the FILE path or EXPRESSION string (nil for :repl)."
  (let ((dialect (autolisp-dialect-strict))
        (mode :repl)
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
                (setf mode :file)
                (setf payload argument))))
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

(defun setup-builtins (context)
  "Install the core builtins into the freshly installed evaluation
context's namespace."
  (declare (ignore context))
  (install-core-builtins))

;;; --- Interactive REPL -----------------------------------------------

(defun simple-error-diagnostic (condition)
  "Return the reader's structured diagnostic carried by CONDITION (the
parser raises a `simple-error` whose first format argument is a
`diagnostic`), or nil if the condition is not shaped that way."
  (let ((arguments (simple-condition-format-arguments condition)))
    (and arguments
         (typep (first arguments) 'diagnostic)
         (first arguments))))

(defun reader-error-incomplete-p (condition)
  "True iff CONDITION reports an unexpected end of input — i.e. the
parser ran out of tokens partway through a list, dotted pair, or
other structured form. Used by the REPL to know whether to prompt
for another continuation line."
  (let ((diagnostic (simple-error-diagnostic condition)))
    (and diagnostic
         (eq :unexpected-eof (diagnostic-code diagnostic)))))

(defun read-balanced-source-from-stream (stream prompt continuation-prompt
                                                  dialect)
  "Read whole, parser-balanced AutoLISP source from STREAM, prompting
between continuation lines. Returns (values text eofp) where TEXT is
the accumulated source string (with embedded newlines) or nil when
STREAM signalled end-of-file before any input was given."
  (let ((accumulated nil))
    (loop
      (write-string (if accumulated continuation-prompt prompt))
      (finish-output)
      (let ((line (read-line stream nil :eof)))
        (cond
          ((and (eq line :eof) (null accumulated))
           (return (values nil t)))
          ((eq line :eof)
           ;; Treat a stranded continuation as end-of-input: surface
           ;; what we have (parser will surface a diagnostic).
           (return (values accumulated nil)))
          (t
           (setf accumulated
                 (if accumulated
                     (concatenate 'string accumulated (string #\Newline) line)
                     line))
           (handler-case
               (progn
                 (read-runtime-from-string
                  accumulated
                  :options (derive-reader-options-for-dialect
                            dialect :source-name "<repl>"))
                 (return (values accumulated nil)))
             (simple-error (condition)
               (unless (reader-error-incomplete-p condition)
                 (return (values accumulated nil)))))))))))

(defun repl-loop (dialect context)
  (format t "~&clautolisp REPL (~A dialect) — Ctrl-D to exit.~%"
          (autolisp-dialect-name dialect))
  (loop
    (multiple-value-bind (source eofp)
        (read-balanced-source-from-stream
         *standard-input* "_$ " "   " dialect)
      (when eofp
        (terpri)
        (return))
      (handler-case
          (let* ((options (derive-reader-options-for-dialect
                           dialect :source-name "<repl>"))
                 (forms (read-runtime-from-string source :options options))
                 (result (call-with-autolisp-error-handler
                          (lambda () (autolisp-eval-progn forms context))
                          context)))
            (format t "~A~%" (autolisp-value->string result nil)))
        (simple-error (condition)
          (let ((diagnostic (simple-error-diagnostic condition)))
            (if diagnostic
                (format *error-output* "~&; reader error: ~A: ~A~%"
                        (diagnostic-code diagnostic)
                        condition)
                (format *error-output* "~&; reader error: ~A~%" condition))))
        (autolisp-runtime-error (condition)
          (report-runtime-error condition))
        (autolisp-termination (condition)
          (report-termination condition)
          (return))))))

(defun run-repl (dialect)
  (let ((context (make-default-runtime-context :dialect dialect)))
    (setup-builtins context)
    (handler-case
        (repl-loop dialect context)
      (autolisp-termination (condition)
        (report-termination condition)
        (quit 0)))))

;;; --- Batch entry points ---------------------------------------------

(defun run-with-input (dialect mode payload)
  (handler-case
      (ecase mode
        (:file
         (run-autolisp-file payload :dialect dialect :setup-fn #'setup-builtins))
        (:expression
         (run-autolisp-string payload :dialect dialect
                              :source-name "<-x>"
                              :setup-fn #'setup-builtins))
        (:repl
         (run-repl dialect)))
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
        (run-with-input dialect mode payload)
        (finish-output)
        (quit 0))
    (error (error)
      (report-error error)
      (finish-output *error-output*)
      (quit 1))))
