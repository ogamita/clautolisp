(in-package #:clautolisp.autolisp-reader.tools.read-autolisp)

(defparameter *verbose-p* nil
  "Set by -v/--verbose; switches on the per-file `;;; FILE …' banner
and prints a one-line completion summary on stderr after each file
has been read. The default behaviour (no banner, no summary) keeps
the tool's stdout pipeable into the next stage of a build.")

(define-condition read-autolisp-usage-error (simple-error)
  ()
  (:documentation "A command-line usage error: exit status EX_USAGE."))

(defun usage-error (control &rest arguments)
  (error 'read-autolisp-usage-error
         :format-control control :format-arguments arguments))

(defun usage ()
  (format t "~&Usage: read-autolisp [options] file.lsp ...~%")
  (format t "Options:~%")
  (format t "  --strict                      Use strict token mode (default).~%")
  (format t "  --lax                         Use lax token mode.~%")
  (format t "  --warn-on-integer-overflow    Warn when int32 overflow reads as real.~%")
  (format t "  --extended-string-escapes     Enable implementation-defined backslash escapes in strings.~%")
  (format t "  --canonical-case MODE         MODE is upcase, downcase, or preserve.~%")
  (format t "  --external-format FORMAT      Use FORMAT when opening files.~%")
  (format t "  -v, --verbose                 Print a per-file banner and a completion summary.~%")
  (format t "  -V, --version                 Print the version string and exit.~%")
  (format t "  -h, --help                    Show this help and exit.~%"))

(defun print-version ()
  (format t "~&read-autolisp ~A~%" *version*))

(defun parse-canonical-case (string)
  (let ((keyword (intern (string-upcase string) "KEYWORD")))
    (unless (member keyword '(:UPCASE :DOWNCASE :PRESERVE))
      (usage-error "Invalid canonical case ~S. Expected upcase, downcase, or preserve."
                   string))
    keyword))

(defun parse-external-format (string)
  (labels ((keywordize (name)
             (intern (string-upcase name) "KEYWORD")))
    (cond
      ((zerop (length string))
       (usage-error "Invalid empty external format."))
      ((or (char= (char string 0) #\:)
           (char= (char string 0) #\())
       (let ((value (handler-case (let ((*read-eval* nil))
                                    (read-from-string string))
                      (error ()
                        (usage-error "Invalid external format ~S." string)))))
         (unless (typep value '(or keyword cons))
           (usage-error "Invalid external format ~S." string))
         value))
      (t
       (keywordize string)))))

(defun parse-arguments (arguments)
  (let ((token-mode :strict)
        (warn-on-integer-overflow-p nil)
        (extended-string-escapes-p nil)
        (canonical-case :upcase)
        (external-format nil)
        (verbose-p nil)
        (files '()))
    (loop while arguments
          for argument = (pop arguments)
          do (cond
               ((or (string= argument "--help")
                    (string= argument "-h"))
                (usage)
                (quit 0))
               ((or (string= argument "--version")
                    (string= argument "-V"))
                (print-version)
                (quit 0))
               ((or (string= argument "--verbose")
                    (string= argument "-v"))
                (setf verbose-p t))
               ((string= argument "--strict")
                (setf token-mode :strict))
               ((string= argument "--lax")
                (setf token-mode :lax))
               ((string= argument "--warn-on-integer-overflow")
                (setf warn-on-integer-overflow-p t))
               ((string= argument "--extended-string-escapes")
                (setf extended-string-escapes-p t))
               ((string= argument "--canonical-case")
                (unless arguments
                  (usage-error "Missing argument after --canonical-case."))
                (setf canonical-case (parse-canonical-case (pop arguments))))
               ((string= argument "--external-format")
                (unless arguments
                  (usage-error "Missing argument after --external-format."))
                (setf external-format
                      (parse-external-format (pop arguments))))
               ((and (> (length argument) 0)
                     (char= (char argument 0) #\-))
                (usage-error "Unknown option ~S." argument))
               (t
                (push argument files))))
    (unless files
      (usage-error "No input files provided."))
    (values
     (make-reader-options
      :token-mode token-mode
      :warn-on-integer-overflow-p warn-on-integer-overflow-p
      :extended-string-escapes-p extended-string-escapes-p
      :canonical-case canonical-case)
     external-format
     (nreverse files)
     verbose-p)))

(defun span->string (span)
  (if (null span)
      "<unknown>"
      (format nil "~A:~D:~D-~D:~D"
              (or (source-span-source-name span) "<source>")
              (source-span-start-line span)
              (source-span-start-column span)
              (source-span-end-line span)
              (source-span-end-column span))))

(defun report-diagnostic (diagnostic)
  (format *error-output* "~&~A ~A at ~A: ~A~%"
          (string-upcase (string (diagnostic-severity diagnostic)))
          (diagnostic-code diagnostic)
          (span->string (diagnostic-span diagnostic))
          (diagnostic-message diagnostic)))

(defun diagnostics-have-errors-p (diagnostics)
  (loop for diagnostic in diagnostics
        thereis (eq :error (diagnostic-severity diagnostic))))

(defun autolisp-object->cl (object)
  (typecase object
    (symbol-object
     (intern (symbol-object-canonical-name object) "COMMON-LISP-USER"))
    (string-object
     (string-object-value object))
    (integer-object
     (integer-object-value object))
    (real-object
     (real-object-value object))
    (quote-object
     (list 'quote (autolisp-object->cl (quote-object-object object))))
    (cons-object
     (let ((elements (mapcar #'autolisp-object->cl (cons-object-elements object))))
       (if (cons-object-dotted-p object)
           (append-proper-and-tail elements
                                   (autolisp-object->cl (cons-object-tail object)))
           elements)))
    (t
     (error "Unsupported reader object ~S." object))))

(defun append-proper-and-tail (elements tail)
  (if (null elements)
      tail
      (cons (first elements)
            (append-proper-and-tail (rest elements) tail))))

(defun process-file (path options external-format)
  (let* ((start (get-internal-real-time))
         (result (if external-format
                     (read-forms-from-file path
                                           :options options
                                           :external-format external-format
                                           :source-name path)
                     (read-forms-from-file path
                                           :options options
                                           :source-name path)))
         (diagnostics (read-result-diagnostics result))
         (objects (read-result-objects result)))
    (dolist (diagnostic diagnostics)
      (report-diagnostic diagnostic))
    (when *verbose-p*
      (format t "~&;;; FILE ~A~%" path))
    (dolist (object objects)
      (pprint (autolisp-object->cl object))
      (terpri))
    (when *verbose-p*
      (let ((elapsed (/ (float (- (get-internal-real-time) start))
                        internal-time-units-per-second)))
        (format *error-output*
                "~&read-autolisp: ~A — ~D form~:P, ~D diagnostic~:P in ~,3F s~%"
                path
                (length objects)
                (length diagnostics)
                elapsed)))
    (not (diagnostics-have-errors-p diagnostics))))

(defun decoding-error-p (condition)
  "True when CONDITION is a character decoding error (bytes not valid in
the encoding), recognised by class name: SBCL's
SB-INT:STREAM-DECODING-ERROR, babel's CHARACTER-DECODING-ERROR, ..."
  (some (lambda (class)
          (search "DECODING-ERROR" (symbol-name (class-name class))))
        (ignore-errors
         (let ((class (class-of condition)))
           #+sbcl (sb-mop:class-precedence-list class)
           #+ccl (ccl:class-precedence-list class)
           #-(or sbcl ccl) (list class)))))

(defun condition-diagnostic (condition)
  "The reader DIAGNOSTIC CONDITION carries, or NIL: the reader signals a
SIMPLE-ERROR whose first format argument is the diagnostic when it cannot
go on (an unbalanced parenthesis at end of file)."
  (and (typep condition 'simple-condition)
       (let ((first (first (simple-condition-format-arguments condition))))
         (and (typep first 'diagnostic) first))))

(defun exit-status-for-condition (condition)
  "The exit status for CONDITION (sysexits-exit-statuses.issue): a usage
error is EX_USAGE, a file that cannot be opened EX_NOINPUT, bytes that
are not valid in the encoding EX_DATAERR, another I/O error EX_IOERR, and
anything else an internal error, EX_SOFTWARE. A reader error that stops
the reader is EX_DATAERR, like the ones it recovers from."
  (cond
    ((typep condition 'read-autolisp-usage-error) clautolisp.sysexits:+ex-usage+)
    ((condition-diagnostic condition)            clautolisp.sysexits:+ex-dataerr+)
    ((typep condition 'file-error)               clautolisp.sysexits:+ex-noinput+)
    ((decoding-error-p condition)                clautolisp.sysexits:+ex-dataerr+)
    ((typep condition 'stream-error)             clautolisp.sysexits:+ex-ioerr+)
    (t                                           clautolisp.sysexits:+ex-software+)))

(defun main (&rest argv)
  "The read-autolisp program. Exit status (sysexits-exit-statuses.issue):
0 when every file was read without a reader error; EX_DATAERR (65) when a
file has a reader error; EX_USAGE (64), EX_NOINPUT (66), EX_IOERR (74) or
EX_SOFTWARE (70) per EXIT-STATUS-FOR-CONDITION."
  (handler-case
      (multiple-value-bind (options external-format files verbose-p)
          (parse-arguments (rest argv))
        (let ((*verbose-p* verbose-p)
              (all-succeeded-p t))
          (dolist (path files)
            (unless (process-file path options external-format)
              (setf all-succeeded-p nil)))
          (unless all-succeeded-p
            (finish-output)
            (quit clautolisp.sysexits:+ex-dataerr+)))
        (finish-output)
        clautolisp.sysexits:+ex-ok+)
    (error (error)
      ;; A reader error that stops the reader is reported like the ones it
      ;; recovers from, not as the printed diagnostic structure.
      (let ((diagnostic (condition-diagnostic error)))
        (if diagnostic
            (report-diagnostic diagnostic)
            (format *error-output* "~&ERROR: ~A~%" error)))
      (finish-output *error-output*)
      (quit (exit-status-for-condition error)))))
