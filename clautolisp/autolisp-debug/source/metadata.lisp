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

;;;; Globally-stable poll-point ids (command reference §2 / DN-11): each poll
;;;; point (FID, FORM-ID) is assigned a stable integer, assigned once and never
;;;; reused within a session, so the user can designate a poll point / its
;;;; breakpoint by a bare number (ppN) in every UI.

(defvar *poll-point-id-counter* 0 "Source of fresh, never-reused poll-point ids.")
(defvar *poll-point-id->location* (make-hash-table :test 'eql)
  "poll-point id (fixnum) → (FID . FORM-ID).")
(defvar *location->poll-point-id* (make-hash-table :test 'equal)
  "(FID FORM-ID) list → poll-point id.")

(defun poll-point-id (fid form-id)
  "The globally-stable poll-point id for (FID, FORM-ID); assigns a fresh one on
first request."
  (let ((key (list fid form-id)))
    (or (gethash key *location->poll-point-id*)
        (let ((id (incf *poll-point-id-counter*)))
          (setf (gethash key *location->poll-point-id*) id
                (gethash id *poll-point-id->location*) (cons fid form-id))
          id))))

(defun poll-point-location (id)
  "Return (values FID FORM-ID) for poll-point ID, or NIL if it is unknown."
  (let ((loc (gethash id *poll-point-id->location*)))
    (when loc (values (car loc) (cdr loc)))))

(defun assign-poll-point-ids (metadata)
  "Assign stable poll-point ids to every poll point of METADATA."
  (let ((fid (function-debug-metadata-function-id metadata)))
    (dotimes (form-id (function-debug-metadata-poll-point-count metadata))
      (poll-point-id fid form-id))))

(defun register-metadata (metadata)
  (setf (gethash (function-debug-metadata-function-id metadata)
                 *function-id-registry*)
        metadata)
  (assign-poll-point-ids metadata)
  metadata)

(defun metadata-for-function-id (fid)
  "Return the function-debug-metadata for FID, or NIL."
  (values (gethash fid *function-id-registry*)))

(defun metadata-for-usubr (usubr)
  "Return USUBR's function-debug-metadata, or NIL if un-instrumented."
  (autolisp-usubr-debug-metadata usubr))

(defun all-function-metadata ()
  "A list of every registered function-debug-metadata (all instrumented
functions). Order is unspecified."
  (let ((result '()))
    (maphash (lambda (fid metadata) (declare (ignore fid)) (push metadata result))
             *function-id-registry*)
    result))

(defun wildcard-name-match-p (pattern name)
  "True when NAME matches the wcmatch wildcard PATTERN, case-insensitively: =*=
matches any run of characters, =?= matches exactly one (command reference §2
rbreak). Self-contained so the debug engine stays free of a builtins-core
dependency."
  (let ((pattern (string-upcase pattern))
        (name (string-upcase name)))
    (labels ((m (pp ss)
               (cond
                 ((= pp (length pattern)) (= ss (length name)))
                 ((char= #\* (char pattern pp))
                  (or (m (1+ pp) ss)
                      (and (< ss (length name)) (m pp (1+ ss)))))
                 ((char= #\? (char pattern pp))
                  (and (< ss (length name)) (m (1+ pp) (1+ ss))))
                 ((and (< ss (length name)) (char= (char pattern pp) (char name ss)))
                  (m (1+ pp) (1+ ss)))
                 (t nil))))
      (m 0 0))))

(defun functions-matching (pattern)
  "A list of every instrumented function whose name matches the wcmatch wildcard
PATTERN (command reference §2 rbreak)."
  (remove-if-not (lambda (md) (wildcard-name-match-p pattern (function-debug-metadata-name md)))
                 (all-function-metadata)))

(defun metadata-for-name (name)
  "The function-debug-metadata of the instrumented function called NAME
(case-insensitive), or NIL. If several functions share a name (redefinition),
the most-recently-registered wins."
  (let ((best nil))
    (maphash (lambda (fid metadata)
               (when (string-equal (function-debug-metadata-name metadata) name)
                 (when (or (null best)
                           (> fid (function-debug-metadata-function-id best)))
                   (setf best metadata))))
             *function-id-registry*)
    best))

(defun reset-function-id-registry ()
  "Forget every registered function metadata and reset the id counter.
Used by tests and at session teardown."
  (clrhash *function-id-registry*)
  (setf *function-id-counter* 0)
  (clrhash *poll-point-id->location*)
  (clrhash *location->poll-point-id*)
  (setf *poll-point-id-counter* 0))

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
