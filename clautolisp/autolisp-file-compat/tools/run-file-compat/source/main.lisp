(in-package #:clautolisp.autolisp-file-compat.tools.run-file-compat)

(defun usage ()
  (format t "~&Usage: run-file-compat [options] scenario.sexp ...~%")
  (format t "Options:~%")
  (format t "  --runner-label MODE          MODE is local, sbcl, or ccl.~%")
  (format t "  --report-format FORMAT       FORMAT is sexp or json.~%")
  (format t "  --output PATH                Write the combined report to PATH.~%")
  (format t "  --help                       Show this help and exit.~%"))

(defun parse-runner-label (string)
  (let ((keyword (intern (string-upcase string) "KEYWORD")))
    (unless (member keyword '(:LOCAL :SBCL :CCL))
      (error "Invalid runner label ~S. Expected local, sbcl, or ccl." string))
    keyword))

(defun parse-report-format (string)
  (let ((keyword (intern (string-upcase string) "KEYWORD")))
    (unless (member keyword '(:SEXP :JSON))
      (error "Invalid report format ~S. Expected sexp or json." string))
    keyword))

(defun parse-arguments (arguments)
  (let ((runner-label :local)
        (report-format :sexp)
        (output-path nil)
        (scenario-paths '()))
    (loop while arguments
          for argument = (pop arguments)
          do (cond
               ((string= argument "--help")
                (usage)
                (quit 0))
               ((string= argument "--runner-label")
                (unless arguments
                  (error "Missing argument after --runner-label."))
                (setf runner-label (parse-runner-label (pop arguments))))
               ((string= argument "--report-format")
                (unless arguments
                  (error "Missing argument after --report-format."))
                (setf report-format (parse-report-format (pop arguments))))
               ((string= argument "--output")
                (unless arguments
                  (error "Missing argument after --output."))
                (setf output-path (pop arguments)))
               ((and (> (length argument) 0)
                     (char= (char argument 0) #\-))
                (error "Unknown option ~S." argument))
               (t
                (push argument scenario-paths))))
    (unless scenario-paths
      (error "No scenario files provided."))
    (values runner-label report-format output-path (nreverse scenario-paths))))

(defun run-scenario-paths (paths runner-label)
  (loop for path in paths
        append (loop for scenario in (load-scenario-file path)
                     collect (run-scenario scenario :runner runner-label))))

(defun emit-report-list (reports stream report-format)
  (ecase report-format
    (:sexp
     (let ((*print-pretty* t))
       (pprint (mapcar #'clautolisp.autolisp-file-compat:report->plist reports)
               stream)))
    (:json
     (write-char #\[ stream)
     (loop for report in reports
           for firstp = t then nil
           do (unless firstp
                (write-string ", " stream))
              (emit-report report stream :format :json))
     (write-char #\] stream))))

(defun main (&rest argv)
  (handler-case
      (multiple-value-bind (runner-label report-format output-path scenario-paths)
          (parse-arguments (rest argv))
        (let ((reports (run-scenario-paths scenario-paths runner-label)))
          (if output-path
              (with-open-file (stream output-path
                                      :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create)
                (emit-report-list reports stream report-format))
              (emit-report-list reports *standard-output* report-format))
          (finish-output))
        0)
    (error (condition)
      (format *error-output* "~&ERROR: ~A~%" condition)
      (finish-output *error-output*)
      (quit 1))))
