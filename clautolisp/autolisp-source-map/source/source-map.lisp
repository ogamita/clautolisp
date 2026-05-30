(in-package #:clautolisp.source)

;;;; A source-position is the (start . end) pair the debugger spec §3
;;;; calls for, flattened into one struct: FILE plus the start and end
;;;; (line, column). It is printable, and SOURCE-POSITION-EQUAL gives the
;;;; value comparison the spec asks for (defstruct instances are only EQ
;;;; under EQUAL, so positions carry their own predicate).

(defstruct (source-position
            (:constructor make-source-position
                (&key file start-line start-column end-line end-column)))
  (file nil :type (or null string))
  (start-line 1 :type fixnum)
  (start-column 1 :type fixnum)
  (end-line 1 :type fixnum)
  (end-column 1 :type fixnum))

(defmethod print-object ((position source-position) stream)
  (print-unreadable-object (position stream :type t)
    (format stream "~@[~A ~]~D:~D..~D:~D"
            (source-position-file position)
            (source-position-start-line position)
            (source-position-start-column position)
            (source-position-end-line position)
            (source-position-end-column position))))

(defun source-position-equal (a b)
  "Value equality for two source-positions (or NILs)."
  (or (eq a b)
      (and (source-position-p a) (source-position-p b)
           (equal (source-position-file a) (source-position-file b))
           (= (source-position-start-line a) (source-position-start-line b))
           (= (source-position-start-column a) (source-position-start-column b))
           (= (source-position-end-line a) (source-position-end-line b))
           (= (source-position-end-column a) (source-position-end-column b)))))

(defun source-position-from-span (span)
  "Build a SOURCE-POSITION from a reader SOURCE-SPAN, or NIL if SPAN is NIL."
  (when span
    (make-source-position
     :file (source-span-source-name span)
     :start-line (source-span-start-line span)
     :start-column (source-span-start-column span)
     :end-line (source-span-end-line span)
     :end-column (source-span-end-column span))))

;;;; The position table maps a runtime object (the cons cell produced by
;;;; the reader→runtime lowering) to its source position, by EQ. Only
;;;; compound forms are recorded; atoms lower to bare CL values that
;;;; cannot carry a key, and the debugger resolves them through the
;;;; enclosing form's per-function form-id table (spec §11).

(defparameter *track-source-positions* nil
  "When non-nil, the runtime's reader→runtime lowering records each
compound form's source position into *SOURCE-POSITION-TABLE*. Bound to T
for a debug load; NIL (the default) keeps production loads allocation-free
and the table empty.")

(defvar *source-position-table* (make-hash-table :test 'eq)
  "EQ hash table: runtime form (a cons) → SOURCE-POSITION. Populated by
NOTE-POSITION during a tracked load; consulted by POSITION-OF. Holds
strong references, so it is cleared (CLEAR-SOURCE-POSITIONS) at debug
session teardown.")

(defun note-position (object span)
  "Record OBJECT's source position (derived from reader SPAN) in the
table, and return the stored SOURCE-POSITION (or NIL if SPAN is NIL)."
  (let ((position (source-position-from-span span)))
    (when position
      (setf (gethash object *source-position-table*) position))
    position))

(defun position-of (object)
  "Return the SOURCE-POSITION recorded for OBJECT, or NIL."
  (values (gethash object *source-position-table*)))

(defun clear-source-positions ()
  "Forget every recorded source position."
  (clrhash *source-position-table*))

(defun call-with-source-tracking (thunk)
  "Call THUNK with source-position tracking enabled. The table is NOT
reset (positions must survive past the load so the instrumenter can read
them); call CLEAR-SOURCE-POSITIONS explicitly to reclaim it."
  (let ((*track-source-positions* t))
    (funcall thunk)))

(defmacro with-source-tracking (() &body body)
  `(call-with-source-tracking (lambda () ,@body)))

(defun lines-of (file)
  "Return a SIMPLE-VECTOR of FILE's lines as strings (newlines stripped),
or an empty vector if FILE cannot be opened. The debugger UIs use this to
render source around a stopping point (spec §3.4)."
  (with-open-file (in file :direction :input :if-does-not-exist nil)
    (if in
        (coerce (loop for line = (read-line in nil :eof)
                      until (eq line :eof)
                      collect line)
                'simple-vector)
        (vector))))
