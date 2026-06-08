(in-package #:clautolisp.drawing)

;;;; Drawing persistence dispatch (Phase 17b).
;;;;
;;;; READ-DRAWING / WRITE-DRAWING / PROBE-DRAWING-FORMAT and the codec
;;;; registry they dispatch through. No file codec ships in 17b: DXF
;;;; arrives in 17c and DWG (libredwg) in 17e, each registering itself
;;;; here. Until a codec is registered for a format, READ/WRITE-DRAWING
;;;; signal DRAWING-FORMAT-ERROR. The API surface does not change when a
;;;; codec lands.
;;;;
;;;; Codec contract:
;;;;   reader : (lambda (source)               -> drawing)
;;;;   writer : (lambda (drawing destination &key version) -> *)
;;;; A reader/writer may signal a DRAWING-ERROR directly (passed
;;;; through) or any other condition (wrapped as DRAWING-READ-ERROR /
;;;; DRAWING-WRITE-ERROR).

(defvar *drawing-codecs* (make-hash-table)
  "Format keyword -> plist (:reader fn :writer fn).")

(defun register-drawing-codec (format &key reader writer)
  "Register READER and/or WRITER for FORMAT (a keyword). Either may be
NIL. Returns FORMAT."
  (let ((existing (gethash format *drawing-codecs*)))
    (setf (gethash format *drawing-codecs*)
          (list :reader (or reader (getf existing :reader))
                :writer (or writer (getf existing :writer)))))
  format)

(defun find-drawing-codec (format)
  (gethash format *drawing-codecs*))

(defun probe-drawing-format (source)
  "Best-effort guess of SOURCE's drawing format, by file type. Returns
a format keyword or NIL. Binary-DXF vs ASCII-DXF content sniffing
arrives with the DXF codec (Phase 17c); for now .dxf maps to
:dxf-ascii."
  (let ((type (pathname-type (pathname source))))
    (when type
      (cond ((string-equal type "dxf") :dxf-ascii)
            ((or (string-equal type "dwg")
                 (string-equal type "dwt")) ; DWT template == DWG format
             :dwg)
            (t nil)))))

(defun read-drawing (source &key format)
  "Read SOURCE (a pathname / namestring) into a fresh DRAWING. FORMAT
overrides the sniffed format. Sets the drawing's PATH (absolute) and
FORMAT. Signals DRAWING-FORMAT-ERROR if the format is unknown or has no
reader, DRAWING-READ-ERROR on a codec parse failure."
  (let* ((fmt (or format (probe-drawing-format source)))
         (codec (and fmt (find-drawing-codec fmt))))
    (unless fmt
      (error 'drawing-format-error :location source
             :format-control "cannot determine the drawing format of ~S"
             :format-arguments (list source)))
    (unless (getf codec :reader)
      (error 'drawing-format-error :bad-format fmt :location source
             :format-control "no reader codec registered for format ~S"
             :format-arguments (list fmt)))
    (handler-case
        (let ((drawing (funcall (getf codec :reader) source)))
          (setf (drawing-path drawing) (or (ignore-errors (truename source))
                                           (pathname source)))
          ;; A codec may set DRAWING-FORMAT precisely (e.g. the DXF
          ;; reader distinguishes :dxf-ascii from :dxf-binary by the
          ;; file's sentinel); only fall back to the dispatched FMT.
          (unless (drawing-format drawing)
            (setf (drawing-format drawing) fmt))
          drawing)
      (drawing-error (c) (error c))
      (error (c)
        (error 'drawing-read-error :source source :source-format fmt :cause c
               :format-control "failed to read ~S: ~A"
               :format-arguments (list source c))))))

(defun write-drawing (drawing destination &key format version)
  "Write DRAWING to DESTINATION. FORMAT defaults to the drawing's
format then DESTINATION's type; VERSION defaults to the drawing's
version then the codec's newest. Updates the drawing's PATH / FORMAT /
VERSION and returns it. Signals DRAWING-FORMAT-ERROR / DRAWING-WRITE-ERROR."
  (let* ((fmt (or format (drawing-format drawing) (probe-drawing-format destination)))
         (codec (and fmt (find-drawing-codec fmt))))
    (unless fmt
      (error 'drawing-format-error :location destination :drawing drawing
             :format-control "cannot determine the output format for ~S"
             :format-arguments (list destination)))
    (unless (getf codec :writer)
      (error 'drawing-format-error :bad-format fmt :location destination :drawing drawing
             :format-control "no writer codec registered for format ~S"
             :format-arguments (list fmt)))
    (handler-case
        (progn
          (funcall (getf codec :writer) drawing destination :version version)
          (setf (drawing-path drawing) (pathname destination)
                (drawing-format drawing) fmt)
          (when version (setf (drawing-version drawing) version))
          drawing)
      (drawing-error (c) (error c))
      (error (c)
        (error 'drawing-write-error :destination destination :target-format fmt
               :drawing drawing :cause c
               :format-control "failed to write ~S: ~A"
               :format-arguments (list destination c))))))
