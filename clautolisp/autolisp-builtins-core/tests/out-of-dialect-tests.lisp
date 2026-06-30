(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Out-of-dialect operator warnings, end-to-end through the real
;;;; evaluator and the real core-builtin registry
;;;; (deferred-clautolisp-out-of-dialect-warnings.issue).
;;;;
;;;; The runtime-layer tests pin the parser / predicate / dedup with a
;;;; synthetic subr. Here we drive a genuine builtin (STRCAT) through
;;;; RUN-AUTOLISP-STRING with a fixture availability table that pretends
;;;; STRCAT is BricsCAD-only, proving the warning fires from the real
;;;; subr-dispatch path and that evaluation is unaffected.

(defun %capture-out-of-dialect (form-source &key dialect (op-flags "B"))
  "Evaluate FORM-SOURCE under DIALECT (a keyword) with an availability
table mapping STRCAT -> OP-FLAGS, returning (values RESULT WARNINGS) where
WARNINGS is the number of [out-of-dialect] diagnostics emitted."
  (let* ((sink (make-string-output-stream))
         (table (make-hash-table :test #'equal))
         (dialect-struct
          (or (clautolisp.autolisp-reader:find-autolisp-dialect dialect)
              (error "Unknown dialect keyword ~S" dialect))))
    (setf (gethash "STRCAT" table) op-flags)
    (let* ((clautolisp.autolisp-runtime:*autolisp-operator-availability* table)
           (clautolisp.autolisp-runtime:*out-of-dialect-diagnostic-stream* sink)
           (clautolisp.autolisp-runtime:*autolisp-warn-out-of-dialect* t)
           (result (run-autolisp-string
                    form-source
                    :dialect dialect-struct
                    :setup-fn #'%install-mock-host-and-core))
           (text (get-output-stream-string sink))
           (count 0)
           (start 0))
      (loop for pos = (search "[out-of-dialect]" text :start2 start)
            while pos do (incf count) (setq start (1+ pos)))
      (values result count text))))

(test out-of-dialect-builtin-warns-once-under-strict
  (reset-autolisp-symbol-table)
  (multiple-value-bind (result warnings text)
      (%capture-out-of-dialect "(strcat \"a\" \"b\")" :dialect :strict)
    ;; Evaluation is unaffected: STRCAT still runs and returns "ab".
    (is (string= "ab" (autolisp-string-value result)))
    ;; …and exactly one advisory was printed, naming the operator.
    (is (= 1 warnings))
    (is (search "STRCAT" text))))

(test out-of-dialect-builtin-dedups-within-a-session
  (reset-autolisp-symbol-table)
  ;; Two calls to the same out-of-dialect operator in one run (one
  ;; session) warn exactly once.
  (multiple-value-bind (result warnings)
      (%capture-out-of-dialect "(strcat \"a\") (strcat \"b\")" :dialect :strict)
    (is (string= "b" (autolisp-string-value result)))
    (is (= 1 warnings))))

(test out-of-dialect-builtin-silent-when-in-dialect
  (reset-autolisp-symbol-table)
  ;; STRCAT flagged BricsCAD-only is in-dialect under --bricscad.
  (multiple-value-bind (result warnings)
      (%capture-out-of-dialect "(strcat \"a\" \"b\")" :dialect :bricscad-v26)
    (is (string= "ab" (autolisp-string-value result)))
    (is (= 0 warnings))))

(test out-of-dialect-builtin-silent-for-portable-op
  (reset-autolisp-symbol-table)
  ;; A portable (AB) operator never warns, even under --strict.
  (multiple-value-bind (result warnings)
      (%capture-out-of-dialect "(strcat \"a\" \"b\")" :dialect :strict :op-flags "AB")
    (is (string= "ab" (autolisp-string-value result)))
    (is (= 0 warnings))))
