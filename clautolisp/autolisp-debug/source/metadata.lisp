(in-package #:clautolisp.debug)

(defparameter *protocol-version* '(1 . 0)
  "Debug protocol version (major . minor); a UI checks the major
component at attach (spec §27).")

;;;; Per-function debug metadata (spec §7). Built by the instrumenter and
;;;; attached to the autolisp-usubr's DEBUG-METADATA slot. FORM-ID is a
;;;; dense small integer per function; the vectors below are indexed by
;;;; it. FUNCTION-ID (fid) is a stable integer identifying the function,
;;;; baked into the woven %CLAL-POLL nodes so a poll point needs no
;;;; current-function lookup (the in-image analog of the remote spec's
;;;; alfe-assigned function-ids).

(defstruct function-debug-metadata
  (function-id 0 :type fixnum)
  (name "" :type string)
  usubr
  (source-position nil)
  (form-id->position (vector) :type simple-vector)
  (form-id->kind (vector) :type simple-vector)
  (parent-form-map (vector) :type simple-vector)
  (poll-point-count 0 :type fixnum)
  (bound-names '() :type list)
  (source-text nil))

(defvar *function-id-registry* (make-hash-table :test 'eql)
  "function-id (fixnum) → function-debug-metadata.")

(defvar *function-id-counter* 0
  "Source of fresh function-ids.")

(defun next-function-id ()
  (incf *function-id-counter*))

(defun register-metadata (metadata)
  (setf (gethash (function-debug-metadata-function-id metadata)
                 *function-id-registry*)
        metadata))

(defun metadata-for-function-id (fid)
  "Return the function-debug-metadata for FID, or NIL."
  (values (gethash fid *function-id-registry*)))

(defun metadata-for-usubr (usubr)
  "Return USUBR's function-debug-metadata, or NIL if un-instrumented."
  (autolisp-usubr-debug-metadata usubr))

(defun reset-function-id-registry ()
  "Forget every registered function metadata and reset the id counter.
Used by tests and at session teardown."
  (clrhash *function-id-registry*)
  (setf *function-id-counter* 0))

;;;; Form-id → (position | kind | parent) lookups, bounds-safe.

(defun form-id-position (metadata form-id)
  (let ((vector (function-debug-metadata-form-id->position metadata)))
    (when (< -1 form-id (length vector))
      (aref vector form-id))))

(defun form-id-kind (metadata form-id)
  (let ((vector (function-debug-metadata-form-id->kind metadata)))
    (when (< -1 form-id (length vector))
      (aref vector form-id))))

(defun find-form-id-at-line (metadata line)
  "Return the form-id of the innermost recorded form whose source
position starts on LINE, or NIL. 'Innermost' = the highest form-id
(the instrumenter allocates outer forms before the sub-forms they
contain), so a breakpoint set by line lands on the most specific form."
  (let ((positions (function-debug-metadata-form-id->position metadata))
        (best nil))
    (dotimes (form-id (length positions) best)
      (let ((position (aref positions form-id)))
        (when (and (source-position-p position)
                   (= (source-position-start-line position) line))
          (setf best form-id))))))
