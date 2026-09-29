(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; deferred-clautolisp-out-of-dialect-warnings: a VENDOR-ONLY operator (per
;;;; the spec's Availability, operator-availability.lisp) called out of its
;;;; owner's dialect emits ONE `[vendor-operator]' notice per session, at its
;;;; first call. Spec ch.25 case 1: every dialect warns except the owner's and
;;;; lax. The register entry "vendor-operator" is the specification.

(defun %vendor-run (dialect-name source)
  "Run SOURCE with the core builtins under DIALECT-NAME; (values RESULT
STDERR)."
  (reset-autolisp-symbol-table)
  (let ((*error-output* (make-string-output-stream)))
    (values (run-autolisp-string
             source
             :setup-fn #'install-core-into
             :dialect (clautolisp.autolisp-reader:find-autolisp-dialect dialect-name))
            (get-output-stream-string *error-output*))))

(defun %occurrences (needle haystack)
  (loop with start = 0
        for pos = (search needle haystack :start2 start)
        while pos
        count t
        do (setf start (1+ pos))))

(defparameter +bricscad-call+ "(vle-nth0 '(1 2 3))"
  "A call of a BricsCAD-only operator (spec ch.24) clautolisp implements.")

(test vendor-operator-table-marks-the-builtins
  (is (eq :bricscad (clautolisp.autolisp-runtime:vendor-only-operator-owner "VLE-NTH0")))
  (is (eq :bricscad (clautolisp.autolisp-runtime:vendor-only-operator-owner "vle-nth0"))
      "case-insensitive")
  (is (eq :autocad (clautolisp.autolisp-runtime:vendor-only-operator-owner "ACAD_STRLSORT")))
  (is (null (clautolisp.autolisp-runtime:vendor-only-operator-owner "CAR")) "portable"))

(test vendor-operator-table-keeps-the-mislabelled-core-operators-out
  ;; The spec build's first parser read only the vendor a line STARTED with, so
  ;; `- AutoCAD 2022, BricsCAD V25 and V26: verified' made these AutoCAD-only
  ;; -- and LOAD would have warned under --bricscad. Fixed in
  ;; build-paged-spec.el; this pins it.
  (dolist (name '("LOAD" "FINDFILE" "READ-CHAR" "WRITE-CHAR" "VL-DIRECTORY-FILES"
                  "DEFUN-Q" "CLAL-FILE-ENCODING"))
    (is (null (clautolisp.autolisp-runtime:vendor-only-operator-owner name)) "~A" name)))

(test vendor-operator-warns-exactly-once-under-strict
  ;; The ticket's acceptance test: under --strict, a BricsCAD-only operator
  ;; warns once; the second call is silent.
  (multiple-value-bind (result stderr)
      (%vendor-run :strict (format nil "~A ~A ~A" +bricscad-call+ +bricscad-call+ +bricscad-call+))
    (is (eql 1 result))
    (is (eql 1 (%occurrences "[vendor-operator]" stderr)) "~S" stderr)
    (is (search "VLE-NTH0 is a BricsCAD-only operator, not portable to strict" stderr))))

(test vendor-operator-is-silent-under-its-owner-and-lax
  (dolist (dialect '(:bricscad :bricscad-v25 :bricscad-mac :lax))
    (multiple-value-bind (result stderr) (%vendor-run dialect +bricscad-call+)
      (is (eql 1 result))
      (is (not (search "[vendor-operator]" stderr)) "~A: ~S" dialect stderr))))

(test vendor-operator-warns-under-the-other-vendor-and-clautolisp
  (dolist (dialect '(:autocad :autocad-2022 :clautolisp))
    (multiple-value-bind (result stderr) (%vendor-run dialect +bricscad-call+)
      (declare (ignore result))
      (is (eql 1 (%occurrences "[vendor-operator]" stderr)) "~A: ~S" dialect stderr))))

(test vendor-operator-autocad-operator-warns-under-bricscad
  (multiple-value-bind (result stderr)
      (%vendor-run :bricscad "(acad_strlsort '(\"b\" \"a\"))")
    (declare (ignore result))
    (is (search "ACAD_STRLSORT is a AutoCAD-only operator" stderr) "~S" stderr))
  (multiple-value-bind (result stderr)
      (%vendor-run :autocad "(acad_strlsort '(\"b\" \"a\"))")
    (declare (ignore result))
    (is (not (search "[vendor-operator]" stderr)))))

(test vendor-operator-silenced-by-the-variable
  (multiple-value-bind (result stderr)
      (%vendor-run :strict (format nil "(setq *AUTOLISP-WARN-OUT-OF-DIALECT* nil) ~A" +bricscad-call+))
    (is (eql 1 result))
    (is (not (search "[vendor-operator]" stderr)) "~S" stderr))
  ;; any non-nil value keeps it on
  (multiple-value-bind (result stderr)
      (%vendor-run :strict (format nil "(setq *AUTOLISP-WARN-OUT-OF-DIALECT* T) ~A" +bricscad-call+))
    (declare (ignore result))
    (is (search "[vendor-operator]" stderr))))

(test vendor-operator-portable-calls-say-nothing
  (multiple-value-bind (result stderr) (%vendor-run :strict "(car (list 1 2)) (+ 1 2)")
    (is (eql 3 result))
    (is (not (search "[vendor-operator]" stderr)))))

(test vendor-operator-error-mode-signals
  (reset-autolisp-symbol-table)
  (let ((strict-error (clautolisp.autolisp-reader:make-autolisp-dialect
                       :name :strict :portability-warning-mode :error)))
    (is (eq :non-portable-construct
            (handler-case
                (let ((*error-output* (make-string-output-stream)))
                  (run-autolisp-string +bricscad-call+
                                       :setup-fn #'install-core-into
                                       :dialect strict-error)
                  :no-error)
              (clautolisp.autolisp-runtime:autolisp-runtime-error (c)
                (clautolisp.autolisp-runtime:autolisp-runtime-error-code c)))))))
