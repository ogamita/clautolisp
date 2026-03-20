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
      (is (eq :portable
              (file-compat-scenario-classification (first scenarios))))
      (is (null (file-compat-scenario-tags (first scenarios))))
      (is (string= directory
                   (clautolisp.autolisp-file-compat:file-compat-scenario-root
                    (first scenarios)))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test load-multiple-scenarios-from-corpus-file
  (let* ((path "autolisp-file-compat/scenarios/basic-corpus.sexp")
         (scenarios (load-scenario-file path)))
    (is (= 2 (length scenarios)))
    (is (eq :portable (file-compat-scenario-classification (first scenarios))))
    (is (equal '(:text :lf) (file-compat-scenario-tags (first scenarios))))
    (is (eq :implementation-sensitive
            (file-compat-scenario-classification (second scenarios))))
    (is (equal '(:bytes :binary) (file-compat-scenario-tags (second scenarios))))))

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

(test byte-oriented-scenario
  (let* ((path "autolisp-file-compat/scenarios/raw-bytes.sexp")
         (scenario (first (load-scenario-file path)))
         (report (run-scenario scenario :runner :local))
         (artifact (clautolisp.autolisp-file-compat:file-compat-report-artifact report)))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks report)))
    (is (equalp #(0 1 2 3 255)
                (read-file-bytes
                 (clautolisp.autolisp-file-compat:file-compat-artifact-path artifact))))))

(test report-summary
  (let* ((directory (format nil "/tmp/clautolisp-file-compat-~D/" (random 1000000000)))
         (passing-scenario (make-file-compat-scenario
                            :name "passing"
                            :root directory
                            :relative-path "passing.txt"
                            :external-format :utf-8
                            :newline-mode :lf
                            :input-text "ok"
                            :expected-text "ok"))
         (failing-scenario (make-file-compat-scenario
                            :name "failing"
                            :root directory
                            :relative-path "failing.txt"
                            :external-format :utf-8
                            :newline-mode :lf
                            :input-text "x"
                            :expected-text "y"))
         (reports (list (run-scenario passing-scenario :runner :local)
                        (run-scenario failing-scenario :runner :local)))
         (summary (summarize-reports reports))
         (plist (summary->plist summary)))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (is (= 2 (file-compat-summary-total-scenarios summary)))
    (is (= 1 (file-compat-summary-passed-scenarios summary)))
    (is (= 1 (file-compat-summary-failed-scenarios summary)))
    (is (= 4 (file-compat-summary-total-checks summary)))
    (is (= 2 (file-compat-summary-passed-checks summary)))
    (is (= 2 (file-compat-summary-failed-checks summary)))
    (is (equal (getf plist :failed-scenarios) 1))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))

(test scenario-tag-matching
  (let ((scenario (make-file-compat-scenario
                   :name "tagged"
                   :tags '(:text :utf8 :portable))))
    (is (scenario-matches-tags-p scenario '()))
    (is (scenario-matches-tags-p scenario '(:text)))
    (is (scenario-matches-tags-p scenario '(:text :utf8)))
    (is (not (scenario-matches-tags-p scenario '(:crlf))))))

(test collect-scenario-file-paths-recursively
  (let* ((directory (format nil "/tmp/clautolisp-file-compat-~D/" (random 1000000000)))
         (nested (concatenate 'string directory "nested/"))
         (first-path (concatenate 'string directory "root.sexp"))
         (second-path (concatenate 'string nested "child.sexp")))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))
    (ensure-directories-exist second-path)
    (with-open-file (stream first-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write '(:name "root" :relative-path "root.txt" :input-text "x") :stream stream))
    (with-open-file (stream second-path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write '(:name "child" :relative-path "child.txt" :input-text "y") :stream stream))
    (let ((paths (collect-scenario-file-paths directory)))
      (is (= 2 (length paths)))
      (is (equal (sort (mapcar (lambda (path)
                                 (namestring (truename path)))
                               (list first-path second-path))
                       #'string<)
                 (sort (copy-list paths) #'string<))))
    (ignore-errors (uiop:delete-directory-tree directory :validate t))))
