(in-package #:clautolisp.drawing)

;;;; The entity-family registry and the ENTMAKE/ENTMAKEX validation +
;;;; normalisation pass (schms-parity, issue entity-mutation-parity).
;;;;
;;;; AutoCAD / BricsCAD's ENTMAKE and ENTMAKEX do NOT accept an
;;;; arbitrary group-code list: each entity type has a set of REQUIRED
;;;; group codes, and creation fails (returns nil, sets ERRNO 36 "bad
;;;; entity type") when a required code is missing or the group-0 type
;;;; marker is absent / unknown. On success the entity is stored with
;;;; the vendor-supplied defaults filled in (the layer, the AcDbEntity /
;;;; per-class subclass markers), which is why an ENTGET immediately
;;;; after an ENTMAKE shows more group codes than were supplied.
;;;;
;;;; This module encodes that contract as data (the *ENTITY-FAMILIES*
;;;; registry) and applies it in VALIDATE-ENTITY-DXF, which the host
;;;; adapter calls on the ENTMAKE / ENTMAKEX path. It speaks pure CL
;;;; values only (group codes are numbers, strings are CL strings): the
;;;; AutoLISP wrapping/unwrapping happens in the host adapter, above.
;;;;
;;;; Group-code semantics are per the AutoCAD DXF reference (entities
;;;; section). Non-obvious codes are cited inline. The well-known
;;;; common codes: 0 = entity type, 5 = handle, 6 = linetype name,
;;;; 8 = layer, 48 = linetype scale, 62 = ACI colour, 100 = subclass
;;;; marker, 210 = extrusion direction, 330 = owner (soft pointer),
;;;; 410 = layout/paper-space name, 67 = model(0)/paper(1) space.

;;; --- The family descriptor --------------------------------------

(defstruct (entity-family (:constructor %make-entity-family))
  "One creatable DXF entity type. NAME is the (0 . NAME) marker
(uppercase). KIND is the interned keyword. REQUIRED is the list of
group codes (numbers) that MUST appear in the supplied data for the
create to succeed. SUBCLASSES is the ordered list of (100 . marker)
subclass-marker strings the vendor stamps onto the stored entity,
after the implicit \"AcDbEntity\". DEFAULTS is an alist of
(code . value) pairs injected when the code is absent from the
supplied data. GRAPHICAL-P is nil for the non-graphical objects that
carry no AcDbEntity subclass / layer. COMPLEX-P flags the entities
that head a subentity sequence (POLYLINE, INSERT); SUBENTITY-P flags
the pieces owned by such a head (VERTEX, ATTRIB, SEQEND)."
  (name        ""  :type string)
  (kind        nil :type symbol)
  (required    '() :type list)
  (subclasses  '() :type list)
  (defaults    '() :type list)
  (graphical-p t   :type boolean)
  (complex-p   nil :type boolean)
  (subentity-p nil :type boolean))

(defvar *entity-families* (make-hash-table :test #'equal)
  "Registry mapping an uppercase group-0 type string to its
ENTITY-FAMILY descriptor.")

(defun register-entity-family (name &key required subclasses defaults
                                         (graphical-p t) complex-p subentity-p)
  "Register (or replace) the ENTITY-FAMILY for the group-0 type NAME."
  (let ((up (string-upcase name)))
    (setf (gethash up *entity-families*)
          (%make-entity-family
           :name up
           :kind (intern up "KEYWORD")
           :required required
           :subclasses subclasses
           :defaults defaults
           :graphical-p graphical-p
           :complex-p complex-p
           :subentity-p subentity-p))))

(defun find-entity-family (name)
  "The ENTITY-FAMILY for the group-0 type string NAME (case-insensitive),
or NIL when the type is not in the registry."
  (and (stringp name) (gethash (string-upcase name) *entity-families*)))

(defun entity-family-names ()
  "A sorted list of the registered group-0 type strings."
  (sort (loop for k being the hash-key of *entity-families* collect k)
        #'string<))

;;; --- The registry -----------------------------------------------
;;;
;;; Required codes reflect the minimum the vendor demands; optional
;;; geometry (bulges, extrusion, colour, ...) is accepted but not
;;; required. The subclass markers reproduce the DXF-reference class
;;; hierarchy so ENTGET output carries the (100 . ...) markers portable
;;; code inspects.

(defun %install-entity-families ()
  (clrhash *entity-families*)
  ;; --- Curves / simple geometry ---
  (register-entity-family "LINE"
    :required '(10 11)                 ; 10 start, 11 end point
    :subclasses '("AcDbLine"))
  (register-entity-family "POINT"
    :required '(10)                    ; 10 location
    :subclasses '("AcDbPoint"))
  (register-entity-family "CIRCLE"
    :required '(10 40)                 ; 10 centre, 40 radius
    :subclasses '("AcDbCircle"))
  (register-entity-family "ARC"
    :required '(10 40 50 51)           ; 50 start angle, 51 end angle (rad in AutoLISP)
    :subclasses '("AcDbCircle" "AcDbArc"))
  (register-entity-family "ELLIPSE"
    ;; 10 centre, 11 major-axis endpoint (relative to centre),
    ;; 40 minor/major ratio, 41 start param, 42 end param.
    :required '(10 11 40 41 42)
    :subclasses '("AcDbEllipse"))
  (register-entity-family "RAY"
    :required '(10 11)                 ; 10 base point, 11 unit direction
    :subclasses '("AcDbRay"))
  (register-entity-family "XLINE"
    :required '(10 11)                 ; 10 base point, 11 unit direction
    :subclasses '("AcDbXline"))
  ;; --- Polylines ---
  (register-entity-family "LWPOLYLINE"
    ;; 90 vertex count, 70 polyline flags; 10 repeated per vertex.
    :required '(90 70)
    :subclasses '("AcDbPolyline"))
  (register-entity-family "POLYLINE"
    ;; The heavyweight polyline: a header entity owning VERTEX
    ;; subentities terminated by a SEQEND. 70 polyline flags;
    ;; 66 "vertices follow" is 1 for a POLYLINE by definition.
    :required '(70)
    :subclasses '("AcDb2dPolyline")    ; AcDb3dPolyline when 70 bit 8 set — see clautolisp note
    :complex-p t)
  (register-entity-family "VERTEX"
    :required '(10)                    ; 10 vertex location
    :subclasses '("AcDbVertex" "AcDb2dVertex")
    :subentity-p t)
  (register-entity-family "SEQEND"
    :required '()                      ; terminates a POLYLINE / INSERT subentity run
    :subclasses '()
    :subentity-p t)
  ;; --- Spline ---
  (register-entity-family "SPLINE"
    ;; 70 flags, 71 degree, 72 #knots, 73 #control pts, 74 #fit pts;
    ;; 40 repeated per knot, 10 repeated per control point.
    :required '(70 71 72 73)
    :subclasses '("AcDbSpline"))
  ;; --- Text family ---
  (register-entity-family "TEXT"
    :required '(10 40 1)               ; 10 insertion, 40 height, 1 text
    :subclasses '("AcDbText" "AcDbText"))  ; AutoCAD stamps AcDbText twice (mid + tail)
  (register-entity-family "MTEXT"
    :required '(10 40 1)               ; 10 insertion, 40 nominal height, 1 text
    :subclasses '("AcDbMText"))
  (register-entity-family "ATTDEF"
    ;; 10 insertion, 40 height, 1 default value, 2 tag, 3 prompt,
    ;; 70 attribute flags.
    :required '(10 40 1 2 3 70)
    :subclasses '("AcDbText" "AcDbAttributeDefinition"))
  (register-entity-family "ATTRIB"
    ;; 10 insertion, 40 height, 1 value, 2 tag, 70 flags. Owned by an
    ;; INSERT; terminated (with its siblings) by a SEQEND.
    :required '(10 40 1 2 70)
    :subclasses '("AcDbText" "AcDbAttribute")
    :subentity-p t)
  ;; --- Block reference ---
  (register-entity-family "INSERT"
    ;; 2 block name, 10 insertion point. When 66 = 1, ATTRIB
    ;; subentities follow, terminated by a SEQEND.
    :required '(2 10)
    :subclasses '("AcDbBlockReference")
    :complex-p t)
  ;; --- Filled / faceted primitives ---
  (register-entity-family "3DFACE"
    :required '(10 11 12 13)           ; four corner points
    :subclasses '("AcDbFace"))
  (register-entity-family "SOLID"
    :required '(10 11 12 13)           ; four corner points (3rd/4th may repeat)
    :subclasses '("AcDbTrace"))
  (register-entity-family "TRACE"
    :required '(10 11 12 13)
    :subclasses '("AcDbTrace"))
  ;; --- Non-graphical objects reachable by ENTMAKE / ENTMAKEX ---
  (register-entity-family "XRECORD"
    :required '()
    :subclasses '("AcDbXrecord")
    :graphical-p nil))

(%install-entity-families)

;;; --- Validation + normalisation ---------------------------------

(defun %has-code-p (data code)
  (dolist (pair data nil)
    (when (and (consp pair) (%group-code= (car pair) code))
      (return t))))

(defun %group-0-type (data)
  "The (0 . TYPE) string in DATA, or NIL."
  (dolist (pair data nil)
    (when (and (consp pair) (%group-code= (car pair) 0) (stringp (cdr pair)))
      (return (cdr pair)))))

(defun %missing-required (family data)
  "The first required group code of FAMILY absent from DATA, or NIL."
  (dolist (code (entity-family-required family) nil)
    (unless (%has-code-p data code)
      (return code))))

(defun %inject-defaults (data defaults)
  "DATA with each (code . value) of DEFAULTS appended when its code is
absent."
  (append data
          (loop for (code . value) in defaults
                unless (%has-code-p data code)
                  collect (cons code value))))

(defun validate-entity-dxf (data)
  "Validate + normalise the pure-CL DXF group-code list DATA against the
entity-family registry, for the ENTMAKE / ENTMAKEX creation path.

Returns (values NORMALISED nil) on success, where NORMALISED is DATA
with the vendor defaults filled in (layer, subclass markers) ready for
storage; or (values NIL REASON) when the data does not describe a
creatable entity — a missing / non-string (0 . TYPE) marker, or a
registered family with a required group code absent. REASON is a short
human string (for diagnostics; the AutoLISP layer maps failure to nil
+ ERRNO 36 and never surfaces the string to user code).

An UNREGISTERED group-0 type is accepted and passed through unchanged
(minus normalisation): clautolisp cannot enumerate every DXF entity the
vendor knows, so it is permissive about types it has no descriptor for
rather than rejecting a valid client entity. See the *** clautolisp
note on ENTMAKE in the spec."
  (unless (listp data)
    (return-from validate-entity-dxf (values nil "entity data is not a list")))
  (let ((type (%group-0-type data)))
    (unless type
      (return-from validate-entity-dxf
        (values nil "missing (0 . \"TYPE\") entity-type marker")))
    (let ((family (find-entity-family type)))
      (unless family
        ;; Unknown-but-plausible type: accept as-is (permissive).
        (return-from validate-entity-dxf (values data nil)))
      (let ((missing (%missing-required family data)))
        (when missing
          (return-from validate-entity-dxf
            (values nil (format nil "~A requires group code ~A"
                                (entity-family-name family) missing))))
        ;; Success: fill defaults. For graphical entities default the
        ;; layer to "0" and stamp the subclass markers the vendor adds.
        (let* ((with-layer
                 (if (and (entity-family-graphical-p family)
                          (not (%has-code-p data 8)))
                     (%inject-defaults data '((8 . "0")))
                     data))
               (with-defaults
                 (%inject-defaults with-layer (entity-family-defaults family)))
               ;; Every DXF entity carries the AcDbEntity base subclass
               ;; marker (AcDbObject for a non-graphical object) ahead of
               ;; its per-class markers.
               (base-marker
                 (if (entity-family-graphical-p family) "AcDbEntity" "AcDbObject"))
               (with-subclasses
                 (append with-defaults
                         (mapcar (lambda (m) (cons 100 m))
                                 (cons base-marker
                                       (entity-family-subclasses family))))))
          (values with-subclasses nil))))))
