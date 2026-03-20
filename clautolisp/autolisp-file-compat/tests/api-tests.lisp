(in-package #:clautolisp.autolisp-file-compat.tests)

(in-suite autolisp-file-compat-suite)

(test newline-normalization
  (let ((text (format nil "a~%b~%")))
    (is (string= text (normalize-newlines text :lf)))
    (is (string= (format nil "a~C~%b~C~%" #\Return #\Return)
                 (normalize-newlines text :crlf)))
    (is (string= (format nil "a~Cb~C" #\Return #\Return)
                 (normalize-newlines text :cr)))))

(test load-single-scenario-file
  (let* ((directory (format nil "/tmp/clautolisp-file-compat-~D/" (random 1000000000)))
         (path (concatenate 'string directory "scenario.sexp")))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write '(:name "simple"
               :relative-path "fixture.txt"
               :external-format :utf-8
               :newline-mode :lf
               :input-text "abc
"
               :expected-text "abc
")
             :stream stream))
    (let ((scenarios (load-scenario-file path)))
      (is (= 1 (length scenarios)))
      (is (string= "simple"
                   (clautolisp.autolisp-file-compat:file-compat-scenario-name
                    (first scenarios))))
      (is (string= directory
                   (clautolisp.autolisp-file-compat:file-compat-scenario-root
                    (first scenarios)))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test local-roundtrip-scenario-and-report
  (let* ((directory (format nil "/tmp/clautolisp-file-compat-~D/" (random 1000000000)))
         (scenario (make-file-compat-scenario
                    :name "roundtrip"
                    :root directory
                    :relative-path "roundtrip.txt"
                    :external-format :utf-8
                    :newline-mode :lf
                    :input-text "Hello
World
"
                    :expected-text "Hello
World
"))
         (report (run-scenario scenario :runner :local))
         (artifact (clautolisp.autolisp-file-compat:file-compat-report-artifact report)))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (is (eq :local (file-compat-report-runner report)))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks report)))
    (is (string= "Hello
World
" (file-compat-artifact-text artifact)))
    (is (equal '("Hello" "World") (file-compat-artifact-lines artifact)))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test report-emission
  (let* ((directory (format nil "/tmp/clautolisp-file-compat-~D/" (random 1000000000)))
         (scenario (make-file-compat-scenario
                    :name "emit"
                    :root directory
                    :relative-path "emit.txt"
                    :external-format :utf-8
                    :newline-mode :lf
                    :input-text "x"
                    :expected-text "x"))
         (report (run-scenario scenario :runner :sbcl)))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (let ((sexp (with-output-to-string (out)
                  (emit-report report out :format :sexp)))
          (json (with-output-to-string (out)
                  (emit-report report out :format :json))))
      (is (search ":RUNNER" sexp))
      (is (search "\"runner\"" json))
      (is (search "\"sbcl\"" json)))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))
