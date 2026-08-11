(in-package #:clautolisp.autolisp-reader.internal)

;;;; Host-independent single-octet external formats.
;;;;
;;;; Motivation (cp1252-codec-host-independent.issue): the codec set a
;;;; Common Lisp implementation ships is its own business, and the two
;;;; hosts clautolisp supports disagree badly. Measured on this tree:
;;;;
;;;;   encoding      SBCL 2.x   CCL 1.13
;;;;   CP-1252         yes        NO
;;;;   CP-1250/51/53/54 yes       NO
;;;;   KOI8-R          yes        NO
;;;;   CP-932          yes        yes
;;;;
;;;; So `(open f "w" "CP-1252")' — a perfectly ordinary AutoLISP call,
;;;; and the historic Windows ANSI code page at that — worked on SBCL
;;;; and signalled on CCL. That is a host artefact leaking into the
;;;; language, which is exactly what an AutoLISP implementation must
;;;; not do.
;;;;
;;;; The fix is a codec of our own, used ONLY where the host has no
;;;; codec of its own: the native path stays native (same performance,
;;;; same line-ending machinery, same error signalling) on the host
;;;; that ships the encoding, and the fallback fills the hole on the
;;;; host that doesn't.
;;;;
;;;; The tables are BUILT FROM BABEL rather than typed in by hand.
;;;; babel is already a dependency of this repository (alfe transcodes
;;;; -Esource code pages with it) and already ships identical CP-125x
;;;; tables on SBCL and CCL, so hand-maintaining a 256-entry table here
;;;; would only add a second source of truth that could drift from the
;;;; first. We ask babel once per encoding, cache the resulting 256-entry
;;;; vector, and from then on transcoding is a table index — babel is
;;;; not on the per-character path.
;;;;
;;;; Deliberately limited to SINGLE-OCTET encodings (babel's
;;;; ENC-MAX-UNITS-PER-CHAR = 1 and ENC-CODE-UNIT-SIZE = 8). That is not
;;;; a shortcut: it covers 100% of the measured gap (every encoding the
;;;; table above shows CCL missing is single-octet), and it is the range
;;;; over which a byte offset and a character offset coincide, so the
;;;; wrapper needs no decoder state and FILE-POSITION stays exact. A
;;;; multi-byte encoding the host lacks (CP-950, say — which neither
;;;; host nor babel ships) still fails the way it does today, rather
;;;; than half-working through an unstated approximation.

;;; --- external-format designator accessors ---------------------------

(defun external-format-base (external-format)
  "Return the base encoding keyword of EXTERNAL-FORMAT, or NIL.

A CL external-format designator is either a bare keyword (:CP1252) or a
list whose first element is the keyword and whose tail carries options
\(:CP1252 :NEWLINE :CRLF). RESOLVE-ENCODING-NAME produces the compound
form for the -e UTF-8-dos family, so both shapes reach OPEN."
  (cond
    ((keywordp external-format) external-format)
    ((and (consp external-format) (keywordp (first external-format)))
     (first external-format))
    (t nil)))

(defun external-format-newline (external-format)
  "Return the :NEWLINE option of EXTERNAL-FORMAT (:LF / :CR / :CRLF), or
NIL when it carries none."
  (when (consp external-format)
    (getf (rest external-format) :newline)))

(defun host-external-format-supported-p (external-format)
  "True when the running Common Lisp accepts EXTERNAL-FORMAT's base
encoding as an :EXTERNAL-FORMAT of its own.

SBCL and CCL expose introspectable registries. On any other host we
answer T, which keeps today's behaviour there: the native OPEN runs and
signals for itself if the encoding turns out to be unknown. We would
rather a new host inherit the status quo than have this file silently
take over its codec set on the strength of a probe we have not tested."
  (let ((base (external-format-base external-format)))
    (and base
         (progn
           #+sbcl
           (not (null (ignore-errors (sb-impl::get-external-format base))))
           #+ccl
           (not (null (ignore-errors (ccl:lookup-character-encoding base))))
           #-(or sbcl ccl)
           t))))

;;; --- single-octet tables, built from babel --------------------------

(defvar *single-octet-tables* (make-hash-table :test #'eq)
  "Cache of ENCODING-KEYWORD -> (DECODE-VECTOR . ENCODE-TABLE), or
\(NIL . NIL) for an encoding that is not single-octet. Populated lazily
by SINGLE-OCTET-TABLES. A race between two threads first-touching the
same encoding is benign: both compute the same tables from the same
babel data and the loser's copy is simply dropped.")

(defun %build-single-octet-tables (keyword)
  "Ask babel for KEYWORD's 256-entry mapping. Returns (values DECODE
ENCODE) — DECODE a 256-element vector of characters (NIL for a byte the
encoding leaves unmapped), ENCODE an EQL hash of char-code -> byte — or
\(values NIL NIL) when babel does not know KEYWORD or KEYWORD is not a
single-octet encoding."
  (let ((encoding (ignore-errors
                   (babel-encodings:get-character-encoding keyword))))
    (when (and encoding
               (eql 1 (babel-encodings:enc-max-units-per-char encoding))
               (eql 8 (babel-encodings:enc-code-unit-size encoding)))
      (let ((decode (make-array 256 :initial-element nil))
            (encode (make-hash-table :test #'eql))
            (buffer (make-array 1 :element-type '(unsigned-byte 8))))
        (dotimes (byte 256)
          (setf (aref buffer 0) byte)
          (let ((text (ignore-errors
                       (babel:octets-to-string buffer :encoding keyword
                                                      :errorp nil))))
            ;; A single octet of a single-octet encoding decodes to
            ;; exactly one character or to nothing at all; anything else
            ;; means we mis-classified the encoding, so leave the slot
            ;; unmapped rather than guess.
            (when (and text (= 1 (length text)))
              (let ((code (char-code (char text 0))))
                (setf (aref decode byte) (char text 0))
                ;; First byte wins: a well-formed single-octet encoding
                ;; is injective, but do not let a duplicate silently
                ;; redefine an earlier, lower-numbered mapping.
                (unless (gethash code encode)
                  (setf (gethash code encode) byte))))))
        (values decode encode)))))

(defun single-octet-tables (keyword)
  "Return (values DECODE ENCODE) for KEYWORD, or (values NIL NIL) when
KEYWORD is not a single-octet encoding babel knows. Memoised."
  (let ((entry (gethash keyword *single-octet-tables*)))
    (unless entry
      (setf entry (multiple-value-bind (decode encode)
                      (%build-single-octet-tables keyword)
                    (cons decode encode))
            (gethash keyword *single-octet-tables*) entry))
    (values (car entry) (cdr entry))))

(defun external-format-fallback (external-format)
  "Decide how EXTERNAL-FORMAT must be opened.

Returns (values DECODE ENCODE NEWLINE) when the host has no codec for it
but we can supply one, and (values NIL NIL NIL) when the native OPEN
should be used — either because the host ships the encoding (the common
case, and the one we leave strictly alone) or because we cannot supply
it either, in which case the caller gets the host's own error rather
than a substitute of ours."
  (let ((base (external-format-base external-format)))
    (if (or (null base) (host-external-format-supported-p base))
        (values nil nil nil)
        (multiple-value-bind (decode encode) (single-octet-tables base)
          (if decode
              (values decode encode (external-format-newline external-format))
              (values nil nil nil))))))

(defun external-format-available-p (external-format)
  "True when clautolisp can actually open a stream in EXTERNAL-FORMAT —
whether the host CL provides the codec or this file does.

This is the predicate every `can we do this encoding?' question in the
tree should ask. Asking the host directly (the shape this code had
before) reported CP-1252 as unavailable on CCL even once the fallback
made it work, which would have surfaced as a spurious CLI rejection of
`-e cp1252' and a spurious ENC-UNSUPPORTED-TARGET diagnostic."
  (let ((base (external-format-base external-format)))
    (and base
         (or (host-external-format-supported-p base)
             (not (null (single-octet-tables base))))
         t)))

;;; --- the transcoding streams ----------------------------------------

(define-condition unencodable-character-error (stream-error)
  ((character :initarg :character :reader unencodable-character-error-character)
   (external-format :initarg :external-format
                    :reader unencodable-character-error-external-format))
  (:report
   (lambda (condition stream)
     (format stream "Character ~S (U+~4,'0X) has no representation in ~A."
             (unencodable-character-error-character condition)
             (char-code (unencodable-character-error-character condition))
             (unencodable-character-error-external-format condition))))
  (:documentation
   "Signalled when a character written to a single-octet fallback stream
is outside the encoding's repertoire — the counterpart of the host's own
encoding error (SB-INT:STREAM-ENCODING-ERROR on SBCL), and a STREAM-ERROR
for the same reason, so callers that already handle one handle both."))

(defclass single-octet-stream ()
  ((octets :initarg :octets :reader single-octet-stream-octets)
   (encoding :initarg :encoding :reader single-octet-stream-encoding)
   (newline :initarg :newline :initform nil :reader single-octet-stream-newline)
   (openp :initform t :accessor single-octet-stream-open-p))
  (:documentation
   "Slots shared by the input and output halves: the underlying
\(UNSIGNED-BYTE 8) stream, the encoding keyword (for error reports), and
the :NEWLINE translation mode."))

(defclass single-octet-input-stream
    (single-octet-stream
     trivial-gray-streams:fundamental-character-input-stream)
  ((decode :initarg :decode :reader single-octet-stream-decode)
   (pushback :initform nil :accessor single-octet-stream-pushback)
   (byte-pushback :initform nil :accessor single-octet-stream-byte-pushback)))

(defclass single-octet-output-stream
    (single-octet-stream
     trivial-gray-streams:fundamental-character-output-stream)
  ((encode :initarg :encode :reader single-octet-stream-encode)
   (column :initform 0 :accessor single-octet-stream-column)))

(defmethod stream-element-type ((stream single-octet-stream))
  'character)

(defmethod close ((stream single-octet-stream) &key abort)
  (when (single-octet-stream-open-p stream)
    (setf (single-octet-stream-open-p stream) nil)
    (close (single-octet-stream-octets stream) :abort abort))
  t)

(defmethod open-stream-p ((stream single-octet-stream))
  (single-octet-stream-open-p stream))

;;; input

(defun %next-byte (stream)
  (let ((pushed (single-octet-stream-byte-pushback stream)))
    (cond
      (pushed (setf (single-octet-stream-byte-pushback stream) nil) pushed)
      (t (read-byte (single-octet-stream-octets stream) nil nil)))))

(defmethod trivial-gray-streams:stream-read-char
    ((stream single-octet-input-stream))
  (let ((pushed (single-octet-stream-pushback stream)))
    (cond
      (pushed
       (setf (single-octet-stream-pushback stream) nil)
       pushed)
      (t
       (let ((byte (%next-byte stream)))
         (cond
           ((null byte) :eof)
           (t
            ;; A byte the encoding leaves unmapped is passed through as
            ;; its own code point rather than dropped or rejected: the
            ;; Windows code pages define the C1 block that way in
            ;; practice, and silently losing a byte would corrupt a
            ;; round-trip the user has every right to expect.
            (let ((character (or (aref (single-octet-stream-decode stream) byte)
                                 (code-char byte))))
              (case (single-octet-stream-newline stream)
                (:crlf
                 (if (char= character #\Return)
                     (let ((next (%next-byte stream)))
                       (cond
                         ((eql next 10) #\Newline)
                         (t (when next
                              (setf (single-octet-stream-byte-pushback stream)
                                    next))
                            character)))
                     character))
                (:cr
                 (if (char= character #\Return) #\Newline character))
                (t character))))))))))

(defmethod trivial-gray-streams:stream-unread-char
    ((stream single-octet-input-stream) character)
  (setf (single-octet-stream-pushback stream) character)
  nil)

(defmethod trivial-gray-streams:stream-listen
    ((stream single-octet-input-stream))
  (or (single-octet-stream-pushback stream)
      (single-octet-stream-byte-pushback stream)
      (listen (single-octet-stream-octets stream))))

(defmethod trivial-gray-streams:stream-clear-input
    ((stream single-octet-input-stream))
  (setf (single-octet-stream-pushback stream) nil
        (single-octet-stream-byte-pushback stream) nil)
  (clear-input (single-octet-stream-octets stream))
  nil)

;;; output

(defun %encode-character (stream character)
  (or (gethash (char-code character) (single-octet-stream-encode stream))
      (error 'unencodable-character-error
             :stream stream
             :character character
             :external-format (single-octet-stream-encoding stream))))

(defmethod trivial-gray-streams:stream-write-char
    ((stream single-octet-output-stream) character)
  (let ((octets (single-octet-stream-octets stream)))
    (cond
      ((and (char= character #\Newline)
            (eq (single-octet-stream-newline stream) :crlf))
       (write-byte 13 octets)
       (write-byte 10 octets)
       (setf (single-octet-stream-column stream) 0))
      ((and (char= character #\Newline)
            (eq (single-octet-stream-newline stream) :cr))
       (write-byte 13 octets)
       (setf (single-octet-stream-column stream) 0))
      (t
       (write-byte (%encode-character stream character) octets)
       (if (char= character #\Newline)
           (setf (single-octet-stream-column stream) 0)
           (incf (single-octet-stream-column stream))))))
  character)

(defmethod trivial-gray-streams:stream-line-column
    ((stream single-octet-output-stream))
  (single-octet-stream-column stream))

(defmethod trivial-gray-streams:stream-start-line-p
    ((stream single-octet-output-stream))
  (zerop (single-octet-stream-column stream)))

(defmethod trivial-gray-streams:stream-force-output
    ((stream single-octet-output-stream))
  (force-output (single-octet-stream-octets stream))
  nil)

(defmethod trivial-gray-streams:stream-finish-output
    ((stream single-octet-output-stream))
  (finish-output (single-octet-stream-octets stream))
  nil)

;;; --- OPEN ------------------------------------------------------------

(defun %remove-from-plist (plist &rest keys)
  (loop for (key value) on plist by #'cddr
        unless (member key keys :test #'eq)
          collect key and collect value))

(defun open-with-external-format (path &rest open-args
                                  &key (direction :input) external-format
                                  &allow-other-keys)
  "CL:OPEN, with the single-octet fallback spliced in.

When the host ships EXTERNAL-FORMAT's codec — or when we have no codec
to offer either — this is CL:OPEN verbatim, including its NIL return for
a missing file under :IF-DOES-NOT-EXIST NIL. Otherwise the file is
opened as (UNSIGNED-BYTE 8) with the same options and wrapped in a
transcoding character stream, so callers see one behaviour on every
host and need not know which path they got."
  (multiple-value-bind (decode encode newline)
      (external-format-fallback external-format)
    (cond
      ((null decode)
       (apply #'open path open-args))
      (t
       (let* ((binary-args (%remove-from-plist open-args :external-format
                                                         :element-type))
              (octets (apply #'open path
                             :element-type '(unsigned-byte 8)
                             binary-args))
              (base (external-format-base external-format)))
         (when octets
           (case direction
             (:input (make-instance 'single-octet-input-stream
                                    :octets octets :decode decode
                                    :encoding base :newline newline))
             (:output (make-instance 'single-octet-output-stream
                                     :octets octets :encode encode
                                     :encoding base :newline newline))
             ;; :IO would need one object that is both halves at once.
             ;; AutoLISP OPEN has no bidirectional mode, so rather than
             ;; ship an untested half-duplex wrapper we close the file
             ;; and say plainly that this combination is not provided.
             (t
              (close octets)
              (error "~S: :DIRECTION ~S is not supported by the built-in ~
~A codec (the host CL provides no ~:*~A codec of its own)."
                     'open-with-external-format direction base)))))))))
