(in-package #:clautolisp.autolisp-reader.tools.read-autolisp)

(defun usage ()
  (format t "~&Usage: read-autolisp [options] file.lsp ...~%")
  (format t "Options:~%")
  (format t "  --strict                      Use strict token mode (default).~%")
  (format t "  --lax                         Use lax token mode.~%")
  (format t "  --warn-on-integer-overflow    Warn when int32 overflow reads as real.~%")
  (format t "  --canonical-case MODE         MODE is upcase, downcase, or preserve.~%")
  (format t "  --external-format FORMAT      Use FORMAT when opening files.~%")
  (format t "  --help                        Show this help and exit.~%"))

(defun parse-canonical-case (string)
  (let ((keyword (intern (string-upcase string) "KEYWORD")))
    (unless (member keyword '(:UPCASE :DOWNCASE :PRESERVE))
      (error "Invalid canonical case ~S. Expected upcase, downcase, or preserve."
             string))
    keyword))

(defun parse-external-format (string)
  (labels ((keywordize (name)
             (intern (string-upcase name) "KEYWORD")))
    (cond
      ((zerop (length string))
       (error "Invalid empty external format."))
      ((or (char= (char string 0) #\:)
           (char= (char string 0) #\())
       (let ((value (read-from-string string)))
         (unless (typep value '(or keyword cons))
           (error "Invalid external format ~S." string))
         value))
      (t
       (keywordize string)))))

(defun parse-arguments (arguments)
  (let ((token-mode :strict)
        (warn-on-integer-overflow-p nil)
        (canonical-case :upcase)
        (external-format nil)
        (files '()))
    (loop while arguments
          for argument = (pop arguments)
          do (cond
               ((string= argument "--help")
                (usage)
                (quit 0))
               ((string= argument "--strict")
                (setf token-mode :strict))
               ((string= argument "--lax")
                (setf token-mode :lax))
               ((string= argument "--warn-on-integer-overflow")
                (setf warn-on-integer-overflow-p t))
               ((string= argument "--canonical-case")
                (unless arguments
                  (error "Missing argument after --canonical-case."))
                (setf canonical-case (parse-canonical-case (pop arguments))))
               ((string= argument "--external-format")
                (unless arguments
                  (error "Missing argument after --external-format."))
                (setf external-format
                      (parse-external-format (pop arguments))))
               ((and (> (length argument) 0)
                     (char= (char argument 0) #\-))
                (error "Unknown option ~S." argument))
               (t
                (push argument files))))
    (unless files
      (error "No input files provided."))
    (values
     (make-reader-options
      :token-mode token-mode
      :warn-on-integer-overflow-p warn-on-integer-overflow-p
      :canonical-case canonical-case)
     external-format
     (nreverse files))))

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
  (let* ((result (if external-format
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
    (format t "~&;;; FILE ~A~%" path)
    (dolist (object objects)
      (pprint (autolisp-object->cl object))
      (terpri))
    (not (diagnostics-have-errors-p diagnostics))))

(defun main (&rest argv)
  (handler-case
      (multiple-value-bind (options external-format files)
          (parse-arguments (rest argv))
        (let ((all-succeeded-p t))
          (dolist (path files)
            (unless (process-file path options external-format)
              (setf all-succeeded-p nil)))
          (unless all-succeeded-p
            (quit 1)))
        (finish-output)
        0)
    (error (error)
      (format *error-output* "~&ERROR: ~A~%" error)
      (finish-output *error-output*)
      (quit 1))))
