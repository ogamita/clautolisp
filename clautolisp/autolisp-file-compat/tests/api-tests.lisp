(in-package #:clautolisp.autolisp-file-compat.tests)

(in-suite autolisp-file-compat-suite)

(defun fresh-test-directory ()
  (loop
    with base = (uiop:ensure-directory-pathname (uiop:temporary-directory))
    for attempt from 0
    for candidate = (uiop:ensure-directory-pathname
                     (merge-pathnames
                      (format nil "clautolisp-file-compat-test-~36R-~36R/"
                              (get-universal-time)
                              attempt)
                      base))
    unless (probe-file candidate)
      do (return (namestring candidate))))

(test newline-normalization
  (let ((text (format nil "a~%b~%")))
    (is (string= text (normalize-newlines text :lf)))
    (is (string= (format nil "a~C~%b~C~%" #\Return #\Return)
                 (normalize-newlines text :crlf)))
    (is (string= (format nil "a~Cb~C" #\Return #\Return)
                 (normalize-newlines text :cr)))))

(test load-single-scenario-file
  (let* ((directory (fresh-test-directory))
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
  (let* ((directory (fresh-test-directory))
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
  (let* ((directory (fresh-test-directory))
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
  (let* ((directory (fresh-test-directory))
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
  (let* ((directory (fresh-test-directory))
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

(test builtin-findfile-scenario
  (let* ((scenario (make-file-compat-scenario
                    :name "findfile"
                    :kind :builtin
                    :setup-files '((:type :directory :relative-path "support/")
                                   (:relative-path "support/example.txt"
                                    :input-text "hello"))
                    :current-directory "cwd/"
                    :support-paths '("support/")
                    :builtin-name "FINDFILE"
                    :arguments '("example.txt")
                    :expected-value '(:workspace-relative "support/example.txt"))))
    (let ((report (run-builtin-scenario scenario)))
      (is (every #'file-compat-check-passed-p
                 (file-compat-report-checks report))))))

(test builtin-file-copy-scenario
  (let* ((scenario (make-file-compat-scenario
                    :name "file-copy"
                    :kind :builtin
                    :setup-files '((:relative-path "source.txt"
                                    :input-text "copy me"))
                    :builtin-name "VL-FILE-COPY"
                    :arguments '("source.txt" "target.txt")
                    :expected-value 7
                    :artifact-relative-path "target.txt"
                    :expected-artifact-exists-p t
                    :expected-text "copy me"))
         (report (run-builtin-scenario scenario)))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks report)))
    (is (string= "copy me"
                 (file-compat-artifact-text
                  (file-compat-report-artifact report))))))

(test builtin-prin1-and-read-scenarios
  (let* ((prin1-scenario (make-file-compat-scenario
                          :name "prin1"
                          :kind :builtin
                          :builtin-name "VL-PRIN1-TO-STRING"
                          :arguments '((:list 1 (:symbol "FOO") "bar"))
                          :expected-value '(:string "(1 FOO \"bar\")")))
         (read-scenario (make-file-compat-scenario
                         :name "read"
                         :kind :builtin
                         :builtin-name "READ"
                         :arguments '("(1 FOO \"bar\")")
                         :expected-value '(:list 1 (:symbol "FOO") "bar"))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario prin1-scenario))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario read-scenario))))))

(test builtin-multi-step-stream-scenarios
  (let* ((write-read-scenario
           (make-file-compat-scenario
            :name "write-read-line"
            :kind :builtin
            :steps '((:builtin-name "OPEN"
                      :arguments ("sample.txt" "w")
                      :bind "out")
                     (:builtin-name "WRITE-LINE"
                      :arguments ("alpha" (:ref "out")))
                     (:builtin-name "CLOSE"
                      :arguments ((:ref "out")))
                     (:builtin-name "OPEN"
                      :arguments ("sample.txt" "r")
                      :bind "in")
                     (:builtin-name "READ-LINE"
                      :arguments ((:ref "in"))
                      :bind "line")
                     (:builtin-name "CLOSE"
                      :arguments ((:ref "in"))))
            :result-ref "line"
            :expected-value '(:string "alpha")
            :artifact-relative-path "sample.txt"
            :expected-text "alpha
"))
         (read-char-scenario
           (make-file-compat-scenario
            :name "read-char-sequence"
            :kind :builtin
            :setup-files '((:relative-path "chars.txt" :input-text "AZ"))
            :steps '((:builtin-name "OPEN"
                      :arguments ("chars.txt" "r")
                      :bind "in")
                     (:builtin-name "READ-CHAR"
                      :arguments ((:ref "in"))
                      :bind "first"
                      :expected-value 65)
                     (:builtin-name "READ-CHAR"
                      :arguments ((:ref "in"))
                      :bind "second"
                      :expected-value 90)
                     (:builtin-name "READ-CHAR"
                      :arguments ((:ref "in"))
                      :bind "eof"
                      :expected-value (:nil))
                     (:builtin-name "CLOSE"
                      :arguments ((:ref "in"))))
            :result-ref "second"
            :expected-value 90)))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario write-read-scenario))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario read-char-scenario))))))

(test declarative-multi-step-stream-and-printer-scenarios
  (dolist (path '("autolisp-file-compat/scenarios/streams/open-write-read-line-basic.sexp"
                  "autolisp-file-compat/scenarios/streams/open-read-char-sequence.sexp"
                  "autolisp-file-compat/scenarios/streams/open-append-read-lines.sexp"
                  "autolisp-file-compat/scenarios/streams/open-append-read-lines-utf8.sexp"
                  "autolisp-file-compat/scenarios/streams/open-write-char-read-char.sexp"
                  "autolisp-file-compat/scenarios/streams/open-write-read-line-utf8.sexp"
                  "autolisp-file-compat/scenarios/printers/file-print-read-lines.sexp"
                  "autolisp-file-compat/scenarios/printers/file-printer-read-lines.sexp"
                  "autolisp-file-compat/scenarios/printers/file-printer-sequence.sexp"
                  "autolisp-file-compat/scenarios/printers/file-prin1-read-roundtrip.sexp"))
    (dolist (scenario (load-scenario-file path))
      (is (every #'file-compat-check-passed-p
                 (file-compat-report-checks
                  (run-scenario scenario :runner :local)))))))

(test builtin-rename-size-and-predicate-scenarios
  (let* ((rename-scenario (make-file-compat-scenario
                           :name "rename"
                           :kind :builtin
                           :setup-files '((:relative-path "old.txt"
                                           :input-text "rename me"))
                           :builtin-name "VL-FILE-RENAME"
                           :arguments '("old.txt" "new.txt")
                           :expected-value '(:symbol "T")
                           :artifact-relative-path "new.txt"
                           :expected-text "rename me"))
         (size-scenario (make-file-compat-scenario
                         :name "size"
                         :kind :builtin
                         :setup-files '((:relative-path "sized.txt"
                                         :input-text "12345"))
                         :builtin-name "VL-FILE-SIZE"
                         :arguments '("sized.txt")
                         :expected-value 5))
         (mktemp-scenario (make-file-compat-scenario
                           :name "mktemp"
                           :kind :builtin
                           :setup-files '((:type :directory :relative-path "tmp/"))
                           :builtin-name "VL-FILENAME-MKTEMP"
                           :arguments '("case-" "tmp/" ".dat")
                           :expected-value '(:predicate :path-under-workspace "tmp/"
                                                       :suffix ".dat"
                                                       :exists-p nil)))
         (systime-scenario (make-file-compat-scenario
                            :name "systime"
                            :kind :builtin
                            :setup-files '((:relative-path "stamp.txt"
                                            :input-text "stamp"))
                            :builtin-name "VL-FILE-SYSTIME"
                            :arguments '("stamp.txt")
                            :expected-value '(:predicate :list-length 7))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario rename-scenario))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario size-scenario))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario mktemp-scenario))))
    (is (every #'file-compat-check-passed-p
               (file-compat-report-checks
                (run-builtin-scenario systime-scenario))))))

(test declarative-builtin-scenario-files
  (dolist (path '("autolisp-file-compat/scenarios/paths/findfile-basic.sexp"
                  "autolisp-file-compat/scenarios/paths/findfile-missing.sexp"
                  "autolisp-file-compat/scenarios/paths/findtrustedfile-missing.sexp"
                  "autolisp-file-compat/scenarios/paths/directory-files-basic.sexp"
                  "autolisp-file-compat/scenarios/paths/directory-files-directories-only.sexp"
                  "autolisp-file-compat/scenarios/paths/directory-files-files-only.sexp"
                  "autolisp-file-compat/scenarios/paths/directory-files-no-match.sexp"
                  "autolisp-file-compat/scenarios/paths/directory-files-subdir-backslash.sexp"
                  "autolisp-file-compat/scenarios/paths/file-directory-p-backslash.sexp"
                  "autolisp-file-compat/scenarios/paths/findfile-directory-prefix.sexp"
                  "autolisp-file-compat/scenarios/paths/findtrustedfile-directory-prefix.sexp"
                  "autolisp-file-compat/scenarios/printers/vl-prin1-to-string-basic.sexp"
                  "autolisp-file-compat/scenarios/printers/vl-princ-to-string-basic.sexp"
                  "autolisp-file-compat/scenarios/printers/file-print-read-lines.sexp"
                  "autolisp-file-compat/scenarios/printers/file-printer-read-lines.sexp"
                  "autolisp-file-compat/scenarios/printers/file-printer-sequence.sexp"
                  "autolisp-file-compat/scenarios/printers/file-prin1-read-roundtrip.sexp"
                  "autolisp-file-compat/scenarios/streams/open-missing-for-read.sexp"
                  "autolisp-file-compat/scenarios/streams/open-unsupported-encoding.sexp"
                  "autolisp-file-compat/scenarios/streams/open-write-read-line-basic.sexp"
                  "autolisp-file-compat/scenarios/streams/open-read-char-sequence.sexp"
                  "autolisp-file-compat/scenarios/streams/open-append-read-lines.sexp"
                  "autolisp-file-compat/scenarios/streams/open-append-read-lines-utf8.sexp"
                  "autolisp-file-compat/scenarios/streams/open-write-char-read-char.sexp"
                  "autolisp-file-compat/scenarios/streams/open-write-read-line-utf8.sexp"
                  "autolisp-file-compat/scenarios/mutations/mkdir-basic.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-copy-append.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-copy-directory-destination.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-copy-existing-target.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-copy-missing-source.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-delete-backslash.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-delete-missing.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-rename-basic.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-rename-existing-destination.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-rename-missing-source.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-size-basic.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-size-backslash.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-size-directory.sexp"
                  "autolisp-file-compat/scenarios/mutations/file-systime-basic.sexp"
                  "autolisp-file-compat/scenarios/mutations/filename-mktemp-basic.sexp"
                  "autolisp-file-compat/scenarios/paths/filename-components-basic.sexp"
                  "autolisp-file-compat/scenarios/paths/filename-components-backslash.sexp"))
    (dolist (scenario (load-scenario-file path))
      (is (every #'file-compat-check-passed-p
                 (file-compat-report-checks
                  (run-scenario scenario :runner :local)))))))
