(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;;; Out-of-dialect operator warnings
;;;; (deferred-clautolisp-out-of-dialect-warnings.issue).
;;;;
;;;; The dialect-selection contract is: whatever the dialect, every
;;;; operator stays callable; an operator outside the selected dialect's
;;;; documented surface produces ONE advisory diagnostic per (operator,
;;;; session) when used. These tests pin the availability-data parser,
;;;; the per-dialect admission predicate, and the run-time emit/dedup
;;;; behaviour through the real function-application dispatch.

;;; --- the availability-data parser ----------------------------------

(test operator-availability-parser-reads-name-tab-flags
  (with-input-from-string
      (s (format nil "APPLY~CAB~%VLAX-CREATE-OBJECT~CB~%~
CLAUTOLISP-DOCUMENTATION~CC~%# a comment~%~%BARE-NO-FLAGS~%"
                 #\Tab #\Tab #\Tab))
    (let ((table (parse-operator-availability-stream s)))
      (is (string= "AB" (gethash "APPLY" table)))
      (is (string= "B" (gethash "VLAX-CREATE-OBJECT" table)))
      (is (string= "C" (gethash "CLAUTOLISP-DOCUMENTATION" table)))
      ;; A line with no flags column maps to the empty flag set.
      (is (string= "" (gethash "BARE-NO-FLAGS" table)))
      ;; Comments and blank lines are skipped, not interned.
      (is (null (nth-value 1 (gethash "# A COMMENT" table)))))))

(test operator-availability-parser-keeps-only-vendor-letters
  ;; Junk letters around the A/B/C set are dropped; names are upcased.
  (with-input-from-string (s (format nil "lc-op~CaXbZ~%" #\Tab))
    (let ((table (parse-operator-availability-stream s)))
      (is (string= "AB" (gethash "LC-OP" table))))))

;;; --- the per-dialect admission predicate ---------------------------

(test dialect-admits-operator-predicate-matrix
  ;; A portable (AB) operator is admitted everywhere.
  (dolist (d '(:strict :autocad-2026 :bricscad-v26 :clautolisp :lax))
    (is (dialect-admits-operator-p d "AB")))
  ;; AutoCAD-only (A): admitted under autocad and lax; out elsewhere.
  (is (dialect-admits-operator-p :autocad-2026 "A"))
  (is (dialect-admits-operator-p :lax "A"))
  (is (not (dialect-admits-operator-p :strict "A")))
  (is (not (dialect-admits-operator-p :bricscad-v26 "A")))
  (is (not (dialect-admits-operator-p :clautolisp "A")))
  ;; BricsCAD-only (B): admitted under bricscad and lax; out elsewhere.
  (is (dialect-admits-operator-p :bricscad-v26 "B"))
  (is (dialect-admits-operator-p :lax "B"))
  (is (not (dialect-admits-operator-p :strict "B")))
  (is (not (dialect-admits-operator-p :autocad-2026 "B")))
  (is (not (dialect-admits-operator-p :clautolisp "B")))
  ;; clautolisp-only (C): admitted under clautolisp and lax only.
  (is (dialect-admits-operator-p :clautolisp "C"))
  (is (dialect-admits-operator-p :lax "C"))
  (is (not (dialect-admits-operator-p :strict "C")))
  (is (not (dialect-admits-operator-p :autocad-2026 "C")))
  (is (not (dialect-admits-operator-p :bricscad-v26 "C")))
  ;; An unknown dialect never warns (admits everything).
  (is (dialect-admits-operator-p :some-future-dialect "B")))

;;; --- run-time emit + dedup through the dispatch --------------------

(defun %fixture-availability (&rest name/flags)
  "Build an availability table from a flat NAME FLAGS NAME FLAGS list."
  (let ((table (make-hash-table :test #'equal)))
    (loop for (name flags) on name/flags by #'cddr
          do (setf (gethash name table) flags))
    table))

(defun %call-op-capturing-warnings (op-name op-flags dialect-fn n)
  "Install a fresh DIALECT-FN session, register a no-op subr named
OP-NAME with availability OP-FLAGS, call it N times through the real
dispatch, and return the captured diagnostic text."
  (let* ((context (make-default-runtime-context :dialect (funcall dialect-fn)))
         (subr (make-autolisp-subr op-name (lambda (&rest _) (declare (ignore _)) nil)))
         (out (make-string-output-stream))
         (*autolisp-operator-availability* (%fixture-availability op-name op-flags))
         (*out-of-dialect-diagnostic-stream* out)
         (*autolisp-warn-out-of-dialect* t))
    (declare (ignore context))
    (dotimes (_ n) (call-autolisp-function subr))
    (get-output-stream-string out)))

(defun %count-warnings (text)
  "Number of [out-of-dialect] diagnostic lines in TEXT."
  (let ((count 0) (start 0))
    (loop for pos = (search "[out-of-dialect]" text :start2 start)
          while pos do (incf count) (setq start (+ pos 1)))
    count))

(test out-of-dialect-warns-once-under-strict-for-bricscad-only-op
  ;; The issue's headline acceptance: under --strict, a bricscad-only
  ;; operator warns exactly once; the second call is silent.
  (let ((text (%call-op-capturing-warnings
               "FAKE-BRICSCAD-OP" "B"
               #'clautolisp.autolisp-reader:autolisp-dialect-strict 2)))
    (is (= 1 (%count-warnings text)))
    (is (search "FAKE-BRICSCAD-OP" text))
    (is (search "strict" text))
    (is (search "BricsCAD" text))))

(test out-of-dialect-silent-for-in-dialect-op
  ;; A bricscad-only op is in-dialect under --bricscad: never warns.
  (let ((text (%call-op-capturing-warnings
               "FAKE-BRICSCAD-OP" "B"
               #'clautolisp.autolisp-reader:autolisp-dialect-bricscad-v26 3)))
    (is (= 0 (%count-warnings text)))))

(test out-of-dialect-silent-for-portable-op-under-strict
  (let ((text (%call-op-capturing-warnings
               "FAKE-PORTABLE-OP" "AB"
               #'clautolisp.autolisp-reader:autolisp-dialect-strict 3)))
    (is (= 0 (%count-warnings text)))))

(test out-of-dialect-clautolisp-warns-on-vendor-only-op
  ;; Under --clautolisp a vendor-specific op (no C flag) is out-of-dialect.
  (let ((text (%call-op-capturing-warnings
               "FAKE-AUTOCAD-OP" "A"
               #'clautolisp.autolisp-reader:autolisp-dialect-clautolisp 2)))
    (is (= 1 (%count-warnings text))))
  ;; …but a clautolisp extension (C) is admitted under --clautolisp.
  (let ((text (%call-op-capturing-warnings
               "FAKE-CLAL-OP" "C"
               #'clautolisp.autolisp-reader:autolisp-dialect-clautolisp 2)))
    (is (= 0 (%count-warnings text)))))

(test out-of-dialect-silent-under-lax
  (let ((text (%call-op-capturing-warnings
               "FAKE-BRICSCAD-OP" "B"
               #'clautolisp.autolisp-reader:autolisp-dialect-lax 3)))
    (is (= 0 (%count-warnings text)))))

(test out-of-dialect-suppressed-by-master-switch
  (let* ((context (make-default-runtime-context
                   :dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (subr (make-autolisp-subr "FAKE-BRICSCAD-OP"
                                   (lambda (&rest _) (declare (ignore _)) nil)))
         (out (make-string-output-stream))
         (*autolisp-operator-availability* (%fixture-availability "FAKE-BRICSCAD-OP" "B"))
         (*out-of-dialect-diagnostic-stream* out)
         (*autolisp-warn-out-of-dialect* nil))
    (declare (ignore context))
    (call-autolisp-function subr)
    (is (= 0 (%count-warnings (get-output-stream-string out))))))

(test out-of-dialect-inert-without-availability-data
  ;; With no availability table loaded the mechanism is inert: an
  ;; operator that WOULD be out-of-dialect produces no warning, because
  ;; there is no data to judge it against.
  (let* ((context (make-default-runtime-context
                   :dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (subr (make-autolisp-subr "UNKNOWN-OP"
                                   (lambda (&rest _) (declare (ignore _)) nil)))
         (out (make-string-output-stream))
         (*autolisp-operator-availability* nil)
         (*out-of-dialect-diagnostic-stream* out)
         (*autolisp-warn-out-of-dialect* t))
    (declare (ignore context))
    (call-autolisp-function subr)
    (is (= 0 (%count-warnings (get-output-stream-string out))))))

(test out-of-dialect-unknown-operator-never-warns
  ;; An operator absent from the (loaded) availability table is treated
  ;; as un-judgeable -> no warning, even under strict.
  (let* ((context (make-default-runtime-context
                   :dialect (clautolisp.autolisp-reader:autolisp-dialect-strict)))
         (subr (make-autolisp-subr "NOT-IN-TABLE"
                                   (lambda (&rest _) (declare (ignore _)) nil)))
         (out (make-string-output-stream))
         (*autolisp-operator-availability*
          (%fixture-availability "SOMETHING-ELSE" "B"))
         (*out-of-dialect-diagnostic-stream* out)
         (*autolisp-warn-out-of-dialect* t))
    (declare (ignore context))
    (call-autolisp-function subr)
    (is (= 0 (%count-warnings (get-output-stream-string out))))))
