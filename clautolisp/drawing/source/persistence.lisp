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

(defvar *default-drawing-format* nil
  "The format WRITE-DRAWING falls back to when neither an explicit FORMAT,
the drawing's own FORMAT, nor the destination's file type determines one — a
codec keyword (e.g. :dxf-ascii or :dwg), or NIL for no policy (the default in
this layer, which stays host-agnostic). A host binds it from its own default
drawing-format policy: clautolisp sets it from the CLAUTOLISPDEFAULTDRAWINGFORMAT
system variable (see cador). It is the LAST resort, so a recognised extension
or a drawing that already knows its format still wins.")

(defvar *default-drawing-version* nil
  "The version WRITE-DRAWING falls back to when neither an explicit VERSION nor
the drawing's own VERSION is given — a DXF $ACADVER keyword (e.g. :ac1032 for
DWG 2018, :ac1027 for 2013), or NIL for the codec's newest. The companion of
*DEFAULT-DRAWING-FORMAT*: clautolisp binds it from SAVEFORMAT /
CLAUTOLISPDEFAULTDRAWINGFORMAT (see cador). NOTE: the current DXF/DWG writers
record this version but still emit a fixed one — see the STUB in the codecs.")

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

(defun drawing-template-path ()
  "The DXF template a NEW drawing is built from: the structure every real
drawing has -- the standard symbol tables, the model / paper space block
records AND their block definitions, and a plausible header. It is DXF,
not DWG, so reading it needs no native library.

dwg-round-trip-loses-entities: a drawing assembled from nothing keeps its
entities in memory but loses them through a DWG round trip, because
libredwg needs an entity's owner record to resolve AND a properly formed
BLOCKS section. Both come from a real drawing's structure, which is what
this template carries (it was produced from the bundled empty drawing).
Hand-building a skeleton was tried first and is a maintenance trap: it
must then track what libredwg and AutoCAD expect."
  (asdf:system-relative-pathname :clautolisp/drawing
                                 "drawing/template/empty-drawing.dxf"))

(defun make-drawing-from-template (&key (name "Drawing.dwg") path format version)
  "A new drawing with a REAL drawing's structure, read from
DRAWING-TEMPLATE-PATH. NAME, PATH, FORMAT and VERSION override what the
template carried. Falls back to MAKE-DRAWING -- an empty shell -- when the
template cannot be read, so a program still runs (it will lose entities
through a DWG round trip, which is the state before this existed).

MAKE-DRAWING remains the right thing for a LOADER, which is about to fill
the drawing from a file; this is for a program that BUILDS one."
  (let ((template (drawing-template-path)))
    (if (not (and template (probe-file template)))
        (make-drawing :name name :path path :format format :version version)
        (handler-case
            (let ((drawing (read-drawing template :format :dxf-ascii)))
              (setf (drawing-name drawing) name
                    (drawing-path drawing) path
                    (drawing-format drawing) format)
              (when version (setf (drawing-version drawing) version))
              drawing)
          (error () (make-drawing :name name :path path
                                  :format format :version version))))))

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
format, then DESTINATION's type, then *DEFAULT-DRAWING-FORMAT* (a host's
last-resort policy); VERSION defaults to the drawing's version, then
*DEFAULT-DRAWING-VERSION*, then the codec's newest. Updates the drawing's
PATH / FORMAT / VERSION and returns it.
Signals DRAWING-FORMAT-ERROR / DRAWING-WRITE-ERROR."
  (let* ((fmt (or format (drawing-format drawing) (probe-drawing-format destination)
                  *default-drawing-format*))
         (ver (or version (drawing-version drawing) *default-drawing-version*))
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
          (funcall (getf codec :writer) drawing destination :version ver)
          (setf (drawing-path drawing) (pathname destination)
                (drawing-format drawing) fmt)
          (when ver (setf (drawing-version drawing) ver))
          drawing)
      (drawing-error (c) (error c))
      (error (c)
        (error 'drawing-write-error :destination destination :target-format fmt
               :drawing drawing :cause c
               :format-control "failed to write ~S: ~A"
               :format-arguments (list destination c))))))
