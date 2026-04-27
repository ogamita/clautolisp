;;;; autolisp-test/tools/diff-reports.lisp
;;;;
;;;; Compare N autolisp-test reports and produce a human- and
;;;; machine-readable diff. Common Lisp tool, intentionally separate
;;;; from the harness (which is pure AutoLISP). This tool is meant
;;;; to be invoked from outside any AutoLISP environment.
;;;;
;;;; Usage:
;;;;
;;;;   sbcl --script autolisp-test/tools/diff-reports.lisp \
;;;;        autolisp-test/results/clautolisp/.../report.sexp \
;;;;        autolisp-test/results/bricscad/.../report.sexp
;;;;
;;;; The diff lists:
;;;;   - tests where the status differs across reports;
;;;;   - tests present in some reports but not others;
;;;;   - per-subset verdict differences from the verdict matrix.

(in-package "COMMON-LISP-USER")

(defun read-report-records (path)
  "Read every top-level s-expression in PATH and return them as a list."
  (with-open-file (stream path :direction :input)
    (loop with eof = '#:eof
          for record = (read stream nil eof)
          until (eq record eof)
          collect record)))

(defun report-impl (records)
  "Return the implementation name (string or symbol) from a report's
RUN-START record."
  (let ((start (find 'run-start records :key #'car)))
    (when start
      (cdr (assoc 'impl-name start)))))

(defun report-version (records)
  (let ((start (find 'run-start records :key #'car)))
    (when start
      (cdr (assoc 'version start)))))

(defun report-test-results (records)
  "Return a hash table keyed by test name -> status symbol."
  (let ((table (make-hash-table :test 'equal)))
    (dolist (r records)
      (when (eq (car r) 'test-result)
        (setf (gethash (cdr (assoc 'name r)) table)
              (cdr (assoc 'status r)))))
    table))

(defun report-verdicts (records)
  "Return an alist of subset-name -> verdict symbol from VERDICT records."
  (loop for r in records
        when (eq (car r) 'verdict)
        collect (cons (cdr (assoc 'subset r))
                      (cdr (assoc 'verdict r)))))

(defun all-test-names (tables)
  (let ((names (make-hash-table :test 'equal)))
    (dolist (table tables)
      (maphash (lambda (k v) (declare (ignore v))
                              (setf (gethash k names) t))
               table))
    (loop for k being the hash-keys of names collect k)))

(defun summarize-test-divergences (paths reports)
  (let* ((tables (mapcar #'report-test-results reports))
         (names  (sort (all-test-names tables) #'string<))
         (impls  (mapcar #'report-impl reports)))
    (format t "~&~%--- Per-test divergences ---~%")
    (loop with diff-count = 0
          for name in names
          for statuses = (mapcar (lambda (table)
                                   (gethash name table :missing))
                                 tables)
          when (not (apply #'eql statuses))
          do (incf diff-count)
             (format t "  ~A~%" name)
             (loop for impl in impls
                   for status in statuses
                   do (format t "    ~12A : ~A~%" impl status))
          finally (format t "  ~D divergent tests across ~D reports.~%"
                          diff-count (length paths)))))

(defun summarize-verdict-divergences (reports)
  (let* ((all-verdicts (mapcar #'report-verdicts reports))
         (subsets (sort (remove-duplicates
                         (loop for v in all-verdicts
                               nconc (mapcar #'car v))
                         :test #'equal)
                        #'string<))
         (impls (mapcar #'report-impl reports)))
    (format t "~&~%--- Per-subset verdict divergences ---~%")
    (dolist (subset subsets)
      (let ((per-impl-verdicts
             (mapcar (lambda (v) (or (cdr (assoc subset v :test #'equal))
                                     :missing))
                     all-verdicts)))
        (when (not (apply #'eql per-impl-verdicts))
          (format t "  ~A~%" subset)
          (loop for impl in impls
                for verdict in per-impl-verdicts
                do (format t "    ~12A : ~A~%" impl verdict)))))))

(defun main (paths)
  (when (< (length paths) 2)
    (format *error-output*
            "~&Usage: diff-reports.lisp REPORT1 REPORT2 [REPORT3 ...]~%")
    (uiop:quit 2))
  (let ((reports (mapcar #'read-report-records paths)))
    (format t "~&autolisp-test report diff~%")
    (format t "  ~D reports compared:~%" (length paths))
    (loop for path in paths
          for r in reports
          do (format t "    ~A  (~A ~A)~%"
                     path (or (report-impl r) "?") (or (report-version r) "?")))
    (summarize-test-divergences paths reports)
    (summarize-verdict-divergences reports)))

(let ((args
       #+sbcl (cdr sb-ext:*posix-argv*)
       #+ccl (ccl:command-line-arguments)
       #-(or sbcl ccl) nil))
  (main args))
