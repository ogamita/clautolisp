(in-package #:clautolisp.autolisp-file-compat)

(defun normalize-newlines (text newline-mode)
  (let ((lf-normalized
          (with-output-to-string (out)
            (loop
              with length = (length text)
              for index from 0 below length
              for character = (char text index)
              do (cond
                   ((char= character #\Return)
                    (when (and (< (1+ index) length)
                               (char= #\Linefeed (char text (1+ index))))
                      (incf index))
                    (write-char #\Linefeed out))
                   (t
                    (write-char character out)))))))
    (ecase newline-mode
      (:lf
       lf-normalized)
      (:crlf
       (with-output-to-string (out)
         (loop for character across lf-normalized
               do (if (char= character #\Linefeed)
                      (write-string (string #\Return) out)
                      nil)
                  (write-char character out))))
      (:cr
       (substitute #\Return #\Linefeed lf-normalized)))))

(defun normalize-scenario-kind (value)
  (let ((kind (or value :roundtrip)))
    (unless (member kind '(:roundtrip :builtin))
      (error "Invalid scenario kind ~S." kind))
    kind))

(defun read-file-bytes (path)
  (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length stream)
                             :element-type '(unsigned-byte 8))))
      (read-sequence bytes stream)
      bytes)))

(defun write-file-bytes (path bytes)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :element-type '(unsigned-byte 8))
    (write-sequence bytes stream))
  path)

(defun read-file-text (path &key (external-format :default))
  (with-open-file (stream path
                          :direction :input
                          :external-format external-format)
    (with-output-to-string (out)
      (loop for character = (read-char stream nil nil)
            while character
            do (write-char character out)))))

(defun write-file-text (path text &key (external-format :default) (newline-mode :lf))
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format external-format)
    (write-string (normalize-newlines text newline-mode) stream))
  path)

(defun split-lines (text)
  (let ((lines '())
        (normalized (normalize-newlines text :lf)))
    (with-input-from-string (stream normalized)
      (loop for line = (read-line stream nil nil)
            while line
            do (push line lines)))
    (nreverse lines)))

(defun normalize-scenario-bytes (value)
  (typecase value
    (null
     nil)
    ((vector (unsigned-byte 8))
     value)
    (list
     (let ((vector (make-array (length value) :element-type '(unsigned-byte 8))))
       (loop for byte in value
             for index from 0
             do (setf (aref vector index) byte))
       vector))
    (t
     (error "Invalid scenario byte payload ~S." value))))

(defun normalize-classification (value)
  (let ((classification (or value :portable)))
    (unless (member classification '(:portable
                                     :implementation-sensitive
                                     :host-sensitive
                                     :product-sensitive
                                     :unknown))
      (error "Invalid scenario classification ~S." classification))
    classification))

(defun normalize-tags (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    (t
     (error "Invalid scenario tags ~S." value))))

(defun normalize-lines (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    (t
     (error "Invalid expected line list ~S." value))))

(defun normalize-setup-files (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    (t
     (error "Invalid setup file list ~S." value))))

(defun normalize-steps (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    (t
     (error "Invalid step list ~S." value))))

(defun normalize-path-list (value)
  (cond
    ((null value)
     '())
    ((listp value)
     value)
    (t
     (error "Invalid path list ~S." value))))

(defun plist->scenario (plist &key root)
  (make-file-compat-scenario
   :name (or (getf plist :name) "")
   :description (or (getf plist :description) "")
   :kind (normalize-scenario-kind (getf plist :kind))
   :root (or root (getf plist :root) "./")
   :relative-path (or (getf plist :relative-path) "")
   :classification (normalize-classification (getf plist :classification))
   :tags (normalize-tags (getf plist :tags))
   :external-format (or (getf plist :external-format) :default)
   :newline-mode (or (getf plist :newline-mode) :lf)
   :setup-files (normalize-setup-files (getf plist :setup-files))
   :current-directory (getf plist :current-directory)
   :support-paths (normalize-path-list (getf plist :support-paths))
   :trusted-paths (normalize-path-list (getf plist :trusted-paths))
   :builtin-name (getf plist :builtin-name)
   :arguments (or (getf plist :arguments) '())
   :steps (normalize-steps (getf plist :steps))
   :result-ref (getf plist :result-ref)
   :expected-value (getf plist :expected-value)
   :artifact-relative-path (getf plist :artifact-relative-path)
   :expected-artifact-exists-p (getf plist :expected-artifact-exists-p)
   :input-text (getf plist :input-text)
   :input-bytes (normalize-scenario-bytes (getf plist :input-bytes))
   :expected-text (getf plist :expected-text)
   :expected-lines (normalize-lines (getf plist :expected-lines))
   :expected-bytes (normalize-scenario-bytes (getf plist :expected-bytes))))

(defun load-scenario-file (path)
  (with-open-file (stream path :direction :input)
    (let* ((data (read stream nil nil))
           (root (namestring (uiop:pathname-directory-pathname (pathname path)))))
      (cond
        ((null data)
         '())
        ((and (listp data) (keywordp (first data)))
         (list (plist->scenario data :root root)))
        ((listp data)
         (mapcar (lambda (plist)
                   (plist->scenario plist :root root))
                 data))
        (t
         (error "Scenario file ~A does not contain a plist or list of plists."
                path))))))

(defun scenario->plist (scenario)
  (list :name (file-compat-scenario-name scenario)
        :description (file-compat-scenario-description scenario)
        :kind (file-compat-scenario-kind scenario)
        :root (file-compat-scenario-root scenario)
        :relative-path (file-compat-scenario-relative-path scenario)
        :classification (file-compat-scenario-classification scenario)
        :tags (mapcar (lambda (tag)
                        (string-downcase (symbol-name tag)))
                      (file-compat-scenario-tags scenario))
        :external-format (file-compat-scenario-external-format scenario)
        :newline-mode (file-compat-scenario-newline-mode scenario)
        :setup-files (file-compat-scenario-setup-files scenario)
        :current-directory (file-compat-scenario-current-directory scenario)
        :support-paths (file-compat-scenario-support-paths scenario)
        :trusted-paths (file-compat-scenario-trusted-paths scenario)
        :builtin-name (file-compat-scenario-builtin-name scenario)
        :arguments (file-compat-scenario-arguments scenario)
        :steps (file-compat-scenario-steps scenario)
        :result-ref (file-compat-scenario-result-ref scenario)
        :expected-value (file-compat-scenario-expected-value scenario)
        :artifact-relative-path (file-compat-scenario-artifact-relative-path scenario)
        :expected-artifact-exists-p (file-compat-scenario-expected-artifact-exists-p scenario)
        :input-text (file-compat-scenario-input-text scenario)
        :input-bytes (when (file-compat-scenario-input-bytes scenario)
                       (coerce (file-compat-scenario-input-bytes scenario) 'list))
        :expected-text (file-compat-scenario-expected-text scenario)
        :expected-lines (file-compat-scenario-expected-lines scenario)
        :expected-bytes (when (file-compat-scenario-expected-bytes scenario)
                          (coerce (file-compat-scenario-expected-bytes scenario) 'list))))

(defun summary->plist (summary)
  (list :total-scenarios (file-compat-summary-total-scenarios summary)
        :passed-scenarios (file-compat-summary-passed-scenarios summary)
        :failed-scenarios (file-compat-summary-failed-scenarios summary)
        :total-checks (file-compat-summary-total-checks summary)
        :passed-checks (file-compat-summary-passed-checks summary)
        :failed-checks (file-compat-summary-failed-checks summary)))

(defun check->plist (check)
  (list :name (file-compat-check-name check)
        :passed-p (file-compat-check-passed-p check)
        :message (file-compat-check-message check)))

(defun artifact->plist (artifact)
  (when artifact
    (list :path (namestring (pathname (file-compat-artifact-path artifact)))
          :bytes (coerce (file-compat-artifact-bytes artifact) 'list)
          :text (file-compat-artifact-text artifact)
          :lines (file-compat-artifact-lines artifact))))

(defun report->plist (report)
  (list :runner (file-compat-report-runner report)
        :scenario (scenario->plist (file-compat-report-scenario report))
        :checks (mapcar #'check->plist (file-compat-report-checks report))
        :artifact (artifact->plist (file-compat-report-artifact report))))

(defun report-passed-p (report)
  (every #'file-compat-check-passed-p
         (file-compat-report-checks report)))

(defun summarize-reports (reports)
  (let ((total-scenarios (length reports))
        (passed-scenarios 0)
        (failed-scenarios 0)
        (total-checks 0)
        (passed-checks 0)
        (failed-checks 0))
    (dolist (report reports)
      (if (report-passed-p report)
          (incf passed-scenarios)
          (incf failed-scenarios))
      (incf total-checks (length (file-compat-report-checks report)))
      (dolist (check (file-compat-report-checks report))
        (if (file-compat-check-passed-p check)
            (incf passed-checks)
            (incf failed-checks))))
    (make-file-compat-summary
     :total-scenarios total-scenarios
     :passed-scenarios passed-scenarios
     :failed-scenarios failed-scenarios
     :total-checks total-checks
     :passed-checks passed-checks
     :failed-checks failed-checks)))

(defun scenario-matches-tags-p (scenario required-tags)
  (or (null required-tags)
      (let ((available-tags (file-compat-scenario-tags scenario)))
        (every (lambda (tag)
                 (member tag available-tags))
               required-tags))))

(defun %collect-scenario-file-paths (directory)
  (append (sort (mapcar #'namestring
                        (directory (merge-pathnames "*.sexp" directory)))
                #'string<)
          (loop for child in (uiop:subdirectories directory)
                append (%collect-scenario-file-paths child))))

(defun collect-scenario-file-paths (path)
  (if (uiop:directory-exists-p path)
      (%collect-scenario-file-paths (uiop:ensure-directory-pathname path))
      (list path)))

(defun scenario-value->runtime-value (value &optional workspace-root)
  (cond
    ((null value)
     nil)
    ((stringp value)
     (clautolisp.autolisp-runtime:make-autolisp-string value))
    ((integerp value)
     value)
    ((floatp value)
     (coerce value 'double-float))
    ((and (consp value) (keywordp (first value)))
     (case (first value)
       (:nil
        nil)
       (:string
        (clautolisp.autolisp-runtime:make-autolisp-string (second value)))
       (:integer
        (second value))
       (:real
        (coerce (second value) 'double-float))
       (:symbol
        (clautolisp.autolisp-runtime:intern-autolisp-symbol (second value)))
       (:workspace-relative
        (unless workspace-root
          (error "WORKSPACE-RELATIVE value ~S requires a workspace root." value))
        (let* ((candidate (merge-pathnames (second value)
                                          (uiop:ensure-directory-pathname workspace-root)))
               (located (probe-file candidate)))
          (clautolisp.autolisp-runtime:make-autolisp-string
           (namestring (or located candidate)))))
       (:list
        (mapcar (lambda (element)
                  (scenario-value->runtime-value element workspace-root))
                (rest value)))
       (:cons
        (cons (scenario-value->runtime-value (second value) workspace-root)
              (scenario-value->runtime-value (third value) workspace-root)))
       (otherwise
        (error "Invalid scenario runtime value ~S." value))))
    ((listp value)
     (mapcar (lambda (element)
               (scenario-value->runtime-value element workspace-root))
             value))
    (t
     value)))

(defun runtime-values-equal-p (left right)
  (cond
    ((and (null left) (null right))
     t)
    ((and (consp left) (consp right))
     (and (runtime-values-equal-p (car left) (car right))
          (runtime-values-equal-p (cdr left) (cdr right))))
    ((and (numberp left) (numberp right))
     (= left right))
    ((and (typep left 'clautolisp.autolisp-runtime:autolisp-string)
          (typep right 'clautolisp.autolisp-runtime:autolisp-string))
     (string= (clautolisp.autolisp-runtime:autolisp-string-value left)
              (clautolisp.autolisp-runtime:autolisp-string-value right)))
    ((and (typep left 'clautolisp.autolisp-runtime:autolisp-symbol)
          (typep right 'clautolisp.autolisp-runtime:autolisp-symbol))
     (string= (clautolisp.autolisp-runtime:autolisp-symbol-name left)
              (clautolisp.autolisp-runtime:autolisp-symbol-name right)))
    (t
     (eql left right))))

(defun sort-string-list (strings)
  (sort (copy-list strings) #'string<))

(defun autolisp-string-list (object)
  (and (listp object)
       (every (lambda (item)
                (typep item 'clautolisp.autolisp-runtime:autolisp-string))
              object)
       (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value object)))

(defun canonicalize-path-for-comparison (path &key directoryp)
  (let* ((pathname (pathname path))
         (directory-path (uiop:ensure-directory-pathname
                          (if directoryp
                              pathname
                              (uiop:pathname-directory-pathname pathname))))
         (resolved-directory (or (probe-file directory-path)
                                 directory-path)))
    (if directoryp
        (namestring (uiop:ensure-directory-pathname resolved-directory))
        (namestring (merge-pathnames (file-namestring pathname)
                                     (uiop:ensure-directory-pathname
                                      resolved-directory))))))

(defun runtime-value-matches-predicate-p (predicate actual workspace-root)
  (let ((name (second predicate))
        (arguments (cddr predicate)))
    (case name
      (:string-non-empty
       (and (typep actual 'clautolisp.autolisp-runtime:autolisp-string)
            (> (length (clautolisp.autolisp-runtime:autolisp-string-value actual)) 0)))
      (:path-under-workspace
       (let* ((relative-path (first arguments))
              (options (rest arguments))
              (prefix-path (workspace-relative-pathname workspace-root relative-path))
              (prefix (canonicalize-path-for-comparison prefix-path :directoryp t))
              (suffix (getf options :suffix))
              (exists-p (getf options :exists-p :unspecified)))
         (and (typep actual 'clautolisp.autolisp-runtime:autolisp-string)
              (let ((value (clautolisp.autolisp-runtime:autolisp-string-value actual)))
                 (and (uiop:string-prefix-p
                       prefix
                       (canonicalize-path-for-comparison value))
                      (or (null suffix)
                          (uiop:string-suffix-p value suffix))
                      (or (eq exists-p :unspecified)
                          (eql (not (null (probe-file value)))
                              exists-p)))))))
      (:list-length
       (and (listp actual)
            (= (length actual) (first arguments))))
      (:unordered-strings
       (let ((actual-strings (autolisp-string-list actual)))
         (and actual-strings
              (equal (sort-string-list actual-strings)
                     (sort-string-list (copy-list (first arguments)))))))
      (otherwise
       (error "Unknown runtime expectation predicate ~S." name)))))

(defun runtime-expectation-matches-p (expected actual workspace-root)
  (if (and (consp expected)
           (eq (first expected) :predicate))
      (runtime-value-matches-predicate-p expected actual workspace-root)
      (runtime-values-equal-p expected actual)))

(defun compare-runtime-value (expected actual &optional workspace-root)
  (make-file-compat-check
   :name "result"
   :passed-p (runtime-expectation-matches-p expected actual workspace-root)
   :message (if (runtime-expectation-matches-p expected actual workspace-root)
                "Runtime value matches."
                "Runtime value differs.")))

(defun compare-artifact-exists (expected actual)
  (make-file-compat-check
   :name "artifact-exists"
   :passed-p (eql expected actual)
   :message (if (eql expected actual)
                "Artifact existence matches."
                "Artifact existence differs.")))

(defun scenario-temp-workspace (scenario)
  (let ((base (uiop:ensure-directory-pathname (uiop:temporary-directory))))
    (loop
      for attempt from 0
      for suffix = (format nil "~36R-~36R" (get-universal-time) attempt)
      for candidate = (uiop:ensure-directory-pathname
                       (merge-pathnames
                        (format nil "clautolisp-file-compat-~A-~A/"
                                (or (and (> (length (file-compat-scenario-name scenario)) 0)
                                         (substitute #\- #\Space
                                                     (string-downcase
                                                      (file-compat-scenario-name scenario))))
                                    "scenario")
                                suffix)
                        base))
      unless (probe-file candidate)
        do (return candidate))))

(defun workspace-relative-pathname (workspace-root relative-path)
  (merge-pathnames relative-path
                   (uiop:ensure-directory-pathname workspace-root)))

(defun setup-entry-pathname (workspace-root setup-entry)
  (workspace-relative-pathname workspace-root
                               (or (getf setup-entry :relative-path)
                                   (error "Setup entry missing :RELATIVE-PATH: ~S."
                                          setup-entry))))

(defun setup-scenario-workspace (scenario workspace-root)
  (when (file-compat-scenario-current-directory scenario)
    (ensure-directories-exist
     (merge-pathnames "sentinel"
                      (uiop:ensure-directory-pathname
                       (workspace-relative-pathname
                        workspace-root
                        (file-compat-scenario-current-directory scenario))))))
  (dolist (path (append (file-compat-scenario-support-paths scenario)
                        (file-compat-scenario-trusted-paths scenario)))
    (ensure-directories-exist
     (merge-pathnames "sentinel"
                      (uiop:ensure-directory-pathname
                       (workspace-relative-pathname workspace-root path)))))
  (dolist (setup-entry (file-compat-scenario-setup-files scenario))
    (let* ((path (setup-entry-pathname workspace-root setup-entry))
           (kind (or (getf setup-entry :type) :file))
           (external-format (or (getf setup-entry :external-format)
                                (file-compat-scenario-external-format scenario)))
           (newline-mode (or (getf setup-entry :newline-mode)
                             (file-compat-scenario-newline-mode scenario)))
           (input-bytes (normalize-scenario-bytes (getf setup-entry :input-bytes)))
           (input-text (getf setup-entry :input-text)))
      (ecase kind
        (:directory
         (ensure-directories-exist
          (merge-pathnames "sentinel"
                           (uiop:ensure-directory-pathname path))))
        (:file
         (cond
           (input-bytes
            (write-file-bytes path input-bytes))
           (input-text
            (write-file-text path input-text
                             :external-format external-format
                             :newline-mode newline-mode))
           (t
            (write-file-bytes path #()))))))))

(defun scenario-path-list (paths workspace-root)
  (mapcar (lambda (path)
            (namestring
             (uiop:ensure-directory-pathname
              (workspace-relative-pathname workspace-root path))))
          paths))

(defun find-scenario-builtin (builtin-name scenario)
  (let ((builtin (clautolisp.autolisp-builtins-core:find-core-builtin
                  (or builtin-name
                      (error "Builtin scenario ~S has no builtin name."
                             (file-compat-scenario-name scenario))))))
    (unless builtin
      (error "Unknown builtin ~S."
             builtin-name))
    builtin))

(defun step-reference-p (value)
  (and (consp value)
       (eq (first value) :ref)
       (stringp (second value))
       (null (cddr value))))

(defun resolve-scenario-argument (argument workspace-root bindings)
  (cond
    ((step-reference-p argument)
     (multiple-value-bind (value present-p)
         (gethash (second argument) bindings)
       (unless present-p
         (error "Unknown step binding ~S." (second argument)))
       value))
    ((and (listp argument)
          (not (null argument)))
     (scenario-value->runtime-value argument workspace-root))
    (t
     (scenario-value->runtime-value argument workspace-root))))

(defun call-builtin-by-name (builtin-name arguments workspace-root scenario bindings)
  (apply #'clautolisp.autolisp-runtime:call-autolisp-function
         (find-scenario-builtin builtin-name scenario)
         (mapcar (lambda (argument)
                   (resolve-scenario-argument argument workspace-root bindings))
                 arguments)))

(defun call-builtin-for-scenario (scenario workspace-root &optional bindings)
  (call-builtin-by-name (file-compat-scenario-builtin-name scenario)
                        (file-compat-scenario-arguments scenario)
                        workspace-root
                        scenario
                        (or bindings (make-hash-table :test #'equal))))

(defun step-check-name (step index)
  (let ((bind (getf step :bind)))
    (format nil "step-~D~@[~C~A~]"
            index
            (and bind #\-)
            bind)))

(defun run-builtin-scenario-steps (scenario workspace-root)
  (let ((bindings (make-hash-table :test #'equal))
        (last-result nil)
        (checks '()))
    (loop
      for step in (file-compat-scenario-steps scenario)
      for step-index from 1
      do
         (let* ((builtin-name (or (getf step :builtin-name)
                                  (error "Scenario step missing :BUILTIN-NAME in ~S."
                                         (file-compat-scenario-name scenario))))
                (arguments (or (getf step :arguments) '()))
                (result (call-builtin-by-name builtin-name
                                              arguments
                                              workspace-root
                                              scenario
                                              bindings)))
           (setf last-result result)
           (when (getf step :bind)
             (setf (gethash (getf step :bind) bindings) result))
           (when (getf step :expected-value)
             (let* ((expected (getf step :expected-value))
                    (expected-value (if (and (consp expected)
                                             (eq (first expected) :predicate))
                                        expected
                                        (scenario-value->runtime-value expected
                                                                       workspace-root)))
                    (passed-p (runtime-expectation-matches-p expected-value
                                                             result
                                                             workspace-root)))
               (push (make-file-compat-check
                      :name (step-check-name step step-index)
                      :passed-p passed-p
                      :message (if passed-p
                                   "Step result matches."
                                   "Step result differs."))
                     checks)))))
    (values
     (if (file-compat-scenario-result-ref scenario)
         (multiple-value-bind (value present-p)
             (gethash (file-compat-scenario-result-ref scenario) bindings)
           (unless present-p
             (error "Unknown scenario result binding ~S."
                    (file-compat-scenario-result-ref scenario)))
           value)
         last-result)
     checks)))

(defun json-escape-string (string)
  (with-output-to-string (out)
    (loop for character across string
          do (case character
               (#\\ (write-string "\\\\" out))
               (#\" (write-string "\\\"" out))
               (#\Backspace (write-string "\\b" out))
               (#\Formfeed (write-string "\\f" out))
               (#\Linefeed (write-string "\\n" out))
               (#\Return (write-string "\\r" out))
               (#\Tab (write-string "\\t" out))
               (t (write-char character out))))))

(defun keyword-plist-p (value)
  (and (listp value)
       (evenp (length value))
       (loop for rest on value by #'cddr
             always (keywordp (first rest)))))

(defun emit-json-value (value stream)
  (cond
    ((eq value t)
     (write-string "true" stream))
    ((null value)
     (write-string "null" stream))
    ((stringp value)
     (format stream "\"~A\"" (json-escape-string value)))
    ((keywordp value)
     (emit-json-value (string-downcase (symbol-name value)) stream))
    ((symbolp value)
     (emit-json-value (symbol-name value) stream))
    ((numberp value)
     (princ value stream))
    ((vectorp value)
     (emit-json-value (coerce value 'list) stream))
    ((keyword-plist-p value)
     (write-char #\{ stream)
     (loop for (key datum) on value by #'cddr
           for firstp = t then nil
           do (unless firstp
                (write-string ", " stream))
              (emit-json-value (string-downcase (symbol-name key)) stream)
              (write-string ": " stream)
              (emit-json-value datum stream))
     (write-char #\} stream))
    ((listp value)
     (write-char #\[ stream)
     (loop for datum in value
           for firstp = t then nil
           do (unless firstp
                (write-string ", " stream))
              (emit-json-value datum stream))
     (write-char #\] stream))
    (t
     (emit-json-value (princ-to-string value) stream))))

(defun emit-report (report stream &key (format :sexp))
  (ecase format
    (:sexp
     (let ((*print-pretty* t))
       (pprint (report->plist report) stream)))
    (:json
     (emit-json-value (report->plist report) stream))))

(defun capture-file-artifact (path &key (external-format :default))
  (let ((text (handler-case
                  (read-file-text path :external-format external-format)
                (error ()
                  nil))))
    (make-file-compat-artifact
     :path path
     :bytes (read-file-bytes path)
     :text text
     :lines (if text
                (split-lines text)
                '()))))

(defun compare-bytes (expected actual)
  (make-file-compat-check
   :name "bytes"
   :passed-p (equalp expected actual)
   :message (if (equalp expected actual)
                "Byte content matches."
                "Byte content differs.")))

(defun compare-text (expected actual)
  (make-file-compat-check
   :name "text"
   :passed-p (string= expected actual)
   :message (if (string= expected actual)
                "Decoded text matches."
                "Decoded text differs.")))

(defun compare-lines (expected actual)
  (make-file-compat-check
   :name "lines"
   :passed-p (equal expected actual)
   :message (if (equal expected actual)
                "Decoded lines match."
                "Decoded lines differ.")))

(defun scenario-pathname (scenario)
  (merge-pathnames (file-compat-scenario-relative-path scenario)
                   (pathname (file-compat-scenario-root scenario))))

(defun run-local-roundtrip-scenario (scenario)
  (let* ((path (scenario-pathname scenario))
         (external-format (file-compat-scenario-external-format scenario))
         (newline-mode (file-compat-scenario-newline-mode scenario)))
    (cond
      ((file-compat-scenario-input-bytes scenario)
       (write-file-bytes path (file-compat-scenario-input-bytes scenario)))
      ((file-compat-scenario-input-text scenario)
       (write-file-text path
                        (file-compat-scenario-input-text scenario)
                        :external-format external-format
                        :newline-mode newline-mode))
      (t
       (error "Scenario ~S has neither input text nor input bytes."
              (file-compat-scenario-name scenario))))
    (let* ((artifact (capture-file-artifact path :external-format external-format))
           (checks '()))
      (when (file-compat-scenario-expected-bytes scenario)
        (push (compare-bytes (file-compat-scenario-expected-bytes scenario)
                             (file-compat-artifact-bytes artifact))
              checks))
      (when (file-compat-scenario-expected-text scenario)
        (push (compare-text (file-compat-scenario-expected-text scenario)
                            (file-compat-artifact-text artifact))
              checks))
      (when (file-compat-scenario-expected-lines scenario)
        (push (compare-lines (file-compat-scenario-expected-lines scenario)
                             (file-compat-artifact-lines artifact))
              checks))
      (when (and (null (file-compat-scenario-expected-lines scenario))
                 (file-compat-scenario-expected-text scenario))
        (push (compare-lines (split-lines (file-compat-scenario-expected-text scenario))
                             (file-compat-artifact-lines artifact))
              checks))
      (make-file-compat-report
       :scenario scenario
       :runner :local
       :checks (nreverse checks)
       :artifact artifact))))

(defun run-builtin-scenario (scenario)
  (let* ((workspace-root (scenario-temp-workspace scenario))
         (saved-current-directory (clautolisp.autolisp-runtime:autolisp-current-directory))
         (saved-support-paths (clautolisp.autolisp-runtime:autolisp-support-paths))
         (saved-trusted-paths (clautolisp.autolisp-runtime:autolisp-trusted-paths)))
    (ensure-directories-exist
     (merge-pathnames "sentinel" workspace-root))
    (setup-scenario-workspace scenario workspace-root)
    (unwind-protect
         (progn
           (clautolisp.autolisp-runtime:set-autolisp-current-directory
            (namestring
             (uiop:ensure-directory-pathname
              (if (file-compat-scenario-current-directory scenario)
                  (workspace-relative-pathname
                   workspace-root
                   (file-compat-scenario-current-directory scenario))
                  workspace-root))))
           (clautolisp.autolisp-runtime:set-autolisp-support-paths
            (if (file-compat-scenario-support-paths scenario)
                (scenario-path-list (file-compat-scenario-support-paths scenario)
                                    workspace-root)
                (list (clautolisp.autolisp-runtime:autolisp-current-directory))))
           (clautolisp.autolisp-runtime:set-autolisp-trusted-paths
            (scenario-path-list (file-compat-scenario-trusted-paths scenario)
                                workspace-root))
           (multiple-value-bind (result checks)
               (if (file-compat-scenario-steps scenario)
                   (run-builtin-scenario-steps scenario workspace-root)
                   (values (call-builtin-for-scenario scenario workspace-root)
                           '()))
             (let* ((artifact-path (and (file-compat-scenario-artifact-relative-path scenario)
                                        (workspace-relative-pathname
                                         workspace-root
                                         (file-compat-scenario-artifact-relative-path
                                          scenario))))
                    (artifact-present-p (and artifact-path (probe-file artifact-path)))
                    (artifact-expected-p (or (file-compat-scenario-expected-artifact-exists-p scenario)
                                            (file-compat-scenario-expected-bytes scenario)
                                            (file-compat-scenario-expected-text scenario)
                                            (file-compat-scenario-expected-lines scenario)))
                    (artifact (when artifact-present-p
                                (capture-file-artifact artifact-path
                                                       :external-format
                                                       (file-compat-scenario-external-format scenario)))))
               (when (file-compat-scenario-expected-value scenario)
                 (let ((expected (file-compat-scenario-expected-value scenario)))
                   (push (compare-runtime-value
                          (if (and (consp expected)
                                   (eq (first expected) :predicate))
                              expected
                              (scenario-value->runtime-value expected workspace-root))
                          result
                          workspace-root)
                         checks)))
               (when (file-compat-scenario-artifact-relative-path scenario)
                 (push (compare-artifact-exists
                        (not (null artifact-expected-p))
                        (not (null artifact-present-p)))
                       checks))
               (when (and artifact
                          (file-compat-scenario-expected-bytes scenario))
                 (push (compare-bytes (file-compat-scenario-expected-bytes scenario)
                                      (file-compat-artifact-bytes artifact))
                       checks))
               (when (and artifact
                          (file-compat-scenario-expected-text scenario))
                 (push (compare-text (file-compat-scenario-expected-text scenario)
                                     (file-compat-artifact-text artifact))
                       checks))
               (when (and artifact
                          (file-compat-scenario-expected-lines scenario))
                 (push (compare-lines (file-compat-scenario-expected-lines scenario)
                                      (file-compat-artifact-lines artifact))
                       checks))
               (make-file-compat-report
                :scenario scenario
                :runner :local
                :checks (nreverse checks)
                :artifact artifact))))
      (clautolisp.autolisp-runtime:set-autolisp-current-directory
       saved-current-directory)
      (clautolisp.autolisp-runtime:set-autolisp-support-paths
       saved-support-paths)
      (clautolisp.autolisp-runtime:set-autolisp-trusted-paths
       saved-trusted-paths))))

(defun run-scenario (scenario &key (runner :local))
  (ecase runner
    (:local
     (ecase (file-compat-scenario-kind scenario)
       (:roundtrip
        (run-local-roundtrip-scenario scenario))
       (:builtin
        (run-builtin-scenario scenario))))
    (:sbcl
     (let ((report (run-scenario scenario :runner :local)))
       (setf (file-compat-report-runner report) :sbcl)
       report))
    (:ccl
     (let ((report (run-scenario scenario :runner :local)))
       (setf (file-compat-report-runner report) :ccl)
       report))))
