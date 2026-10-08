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
the pieces owned by such a head (VERTEX, ATTRIB, SEQEND). SINCE-R13-P
flags the entities AutoCAD introduced at R13, which REQUIRE their
(100 . \"AcDb...\") subclass markers to be supplied in the ENTMAKE data
— see the divergence-D1 handling in the host adapter."
  (name        ""  :type string)
  (kind        nil :type symbol)
  (required    '() :type list)
  (subclasses  '() :type list)
  (defaults    '() :type list)
  (graphical-p t   :type boolean)
  (complex-p   nil :type boolean)
  (subentity-p nil :type boolean)
  (since-r13-p nil :type boolean))

(defvar *entity-families* (make-hash-table :test #'equal)
  "Registry mapping an uppercase group-0 type string to its
ENTITY-FAMILY descriptor.")

(defun register-entity-family (name &key required subclasses defaults
                                         (graphical-p t) complex-p subentity-p
                                         since-r13-p)
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
           :subentity-p subentity-p
           :since-r13-p since-r13-p))))

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
    :subclasses '("AcDbEllipse")
    :since-r13-p t)                    ; R13 — AutoCAD demands the AcDb markers
  (register-entity-family "RAY"
    :required '(10 11)                 ; 10 base point, 11 unit direction
    :subclasses '("AcDbRay")
    :since-r13-p t)                    ; R13
  (register-entity-family "XLINE"
    :required '(10 11)                 ; 10 base point, 11 unit direction
    :subclasses '("AcDbXline")
    :since-r13-p t)                    ; R13
  ;; --- Polylines ---
  (register-entity-family "LWPOLYLINE"
    ;; 90 vertex count, 70 polyline flags; 10 repeated per vertex.
    :required '(90 70)
    :subclasses '("AcDbPolyline")
    :since-r13-p t)                    ; R14 — post-R12, same marker contract
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
    :subclasses '("AcDbSpline")
    :since-r13-p t)                    ; R13
  ;; --- Text family ---
  (register-entity-family "TEXT"
    :required '(10 40 1)               ; 10 insertion, 40 height, 1 text
    :subclasses '("AcDbText" "AcDbText"))  ; AutoCAD stamps AcDbText twice (mid + tail)
  (register-entity-family "MTEXT"
    :required '(10 40 1)               ; 10 insertion, 40 nominal height, 1 text
    :subclasses '("AcDbMText")
    :since-r13-p t)                    ; R13
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
  ;; SINCE-R13-P: MEASURED 2026-10-08 (probe-entget-pointers.lsp, jobs
  ;; 17026569911 / 12 / 13): AutoCAD 2022 refuses an XRECORD whose ENTMAKEX
  ;; data lacks (100 . "AcDbXrecord") (returns nil); BricsCAD V25 / V26
  ;; synthesise the marker -- divergence D1, like the R13+ entities.
  (register-entity-family "XRECORD"
    :required '()
    :subclasses '("AcDbXrecord")
    :graphical-p nil
    :since-r13-p t)
  (register-entity-family "DICTIONARY"
    :required '()
    :subclasses '("AcDbDictionary")
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

;;; --- The default groups the vendors list for polylines -------------
;;;
;;; Measured (probes/sources/probe-commands.lsp, AutoCAD 2022 and BricsCAD
;;; V26, identical): ENTGET of an LWPOLYLINE lists 43 38 39 after 70 and,
;;; for EVERY vertex, 10 40 41 42 91 -- a constant-width polyline (DONUT,
;;; 43 0.5) repeats the width in each vertex's 40 / 41; a POLYLINE header
;;; lists 40 41 71 72 73 74 75 after 70; a VERTEX lists 10 40 41 42 70 50
;;; 71 72 73 74. Values the data supplies are kept; the rest default to 0.

(defun %group-value (data code default)
  (let ((cell (assoc code data)))
    (if cell (cdr cell) default)))

(defun %complete-lwpolyline (data)
  (let* ((first-vertex (position 10 data :key #'car))
         (header (subseq data 0 (or first-vertex (length data))))
         (body (if first-vertex (subseq data first-vertex) '()))
         (width (%group-value header 43 0.0d0))
         (head (loop for g in header
                     unless (member (car g) '(43 38 39)) collect g
                     when (eql (car g) 70)
                       append (list (cons 43 width)
                                    (cons 38 (%group-value header 38 0.0d0))
                                    (cons 39 (%group-value header 39 0.0d0)))))
         (vertices '()) (trailer '()))
    ;; Split the body into per-vertex group runs and whatever follows them.
    (let ((current nil))
      (dolist (g body)
        (cond ((eql (car g) 10)
               (when current (push (nreverse current) vertices))
               (setf current (list g)))
              ((member (car g) '(40 41 42 91)) (push g current))
              (t (push g trailer))))
      (when current (push (nreverse current) vertices)))
    (append head
            (loop for v in (nreverse vertices)
                  append (list (first v)
                               (cons 40 (%group-value (rest v) 40 width))
                               (cons 41 (%group-value (rest v) 41 width))
                               (cons 42 (%group-value (rest v) 42 0.0d0))
                               (cons 91 (%group-value (rest v) 91 0))))
            (nreverse trailer))))

(defun %complete-in-order (data anchor defaults)
  "DATA with the (CODE . DEFAULT) DEFAULTS it lacks inserted right after
the ANCHOR group (or at the end), in the order given."
  (let ((missing (remove-if (lambda (d) (assoc (car d) data)) defaults)))
    (if (null missing)
        data
        (let ((pos (position anchor data :key #'car)))
          (if pos
              (append (subseq data 0 (1+ pos)) missing (subseq data (1+ pos)))
              (append data missing))))))

(defun %complete-vertex (data)
  (let* ((ordered '(10 40 41 42 70 50 71 72 73 74))
         (filled (loop for code in ordered
                       collect (or (assoc code data)
                                   (cons code (if (member code '(40 41 42 50)) 0.0d0 0)))))
         (pos (or (position-if (lambda (g) (member (car g) ordered)) data)
                  (length data)))
         (before (remove-if (lambda (g) (member (car g) ordered)) (subseq data 0 pos)))
         (after (remove-if (lambda (g) (member (car g) ordered)) (subseq data pos))))
    ;; The ordered block takes the place of the first of its codes; every
    ;; other group keeps its relative position.
    (append before filled after)))

(defun %complete-polyline-groups (type data)
  (cond ((string-equal type "LWPOLYLINE") (%complete-lwpolyline data))
        ((string-equal type "POLYLINE")
         (%complete-in-order data 70 '((40 . 0.0d0) (41 . 0.0d0)
                                       (71 . 0) (72 . 0) (73 . 0) (74 . 0) (75 . 0))))
        ((string-equal type "VERTEX") (%complete-vertex data))
        (t data)))

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
                 (%complete-polyline-groups
                  type
                  (%inject-defaults with-layer (entity-family-defaults family))))
               ;; Every DXF entity carries the AcDbEntity base subclass
               ;; marker (AcDbObject for a non-graphical object) ahead of
               ;; its per-class markers. Only the ABSENT ones are added: data
               ;; that already has them (every command-made LWPOLYLINE) got
               ;; them twice (entmake-duplicates-subclass-markers).
               ;;
               ;; A non-graphical OBJECT (XRECORD, DICTIONARY) shows no
               ;; AcDbObject marker in ENTGET -- the DXF reference lists
               ;; only its own subclass marker -- and an XRECORD's marker
               ;; must PRECEDE its data groups, not trail them; that case
               ;; is %COMPLETE-XRECORD-HEADER's.
               (graphical (entity-family-graphical-p family))
               (present (loop for pair in with-defaults
                              when (and (consp pair) (eql (car pair) 100)
                                        (stringp (cdr pair)))
                                collect (cdr pair)))
               (with-subclasses
                 (cond
                   ((string-equal type "XRECORD")
                    (%complete-xrecord-header with-defaults))
                   (t
                    (append with-defaults
                            (loop for m in (if graphical
                                               (cons "AcDbEntity"
                                                     (entity-family-subclasses family))
                                               (entity-family-subclasses family))
                                  unless (member m present :test #'string=)
                                    collect (cons 100 m)))))))
          (values with-subclasses nil))))))

;;; --- XRECORD header ------------------------------------------------
;;;
;;; ENTGET of an XRECORD on AutoCAD reads
;;;   (-1 . e) (0 . "XRECORD") (5 . h) [(102 . "{ACAD_REACTORS") ... (102 . "}")]
;;;   (330 . owner) (100 . "AcDbXrecord") (280 . 1) <the data groups ...>
;;; The (280 . 1) -- the DXF "duplicate record cloning flag", 1 = keep
;;; existing -- is supplied by the database when the ENTMAKE data omits it,
;;; and code that reads an xrecord back skips it positionally: SCHMS's
;;; xrecord decoder takes (cddr (member '(100 . "AcDbXrecord") data)), so
;;; without it the first data group was eaten ("Nom de classe attendu",
;;; issues/closed/cador-entget-pointer-codes-are-handle-strings.issue).
;;; MEASURED 2026-10-08 (probes/sources/probe-entget-pointers.lsp, jobs
;;; 17026569911 AutoCAD 2022, 17026569912 / 17026569913 BricsCAD V25 / V26):
;;; both vendors read back (100 . "AcDbXrecord") (280 . 1) <data>. A 280
;;; supplied right after the marker is the flag: AutoCAD lists it as given;
;;; BricsCAD lists no 280 at all then (applied per product in cador,
;;; %BRICSCAD-XRECORD-DROP-EXPLICIT-280). Without the marker AutoCAD refuses
;;; the create and BricsCAD synthesises marker + 280 (divergence D1, so
;;; XRECORD is SINCE-R13-P).

(defun %complete-xrecord-header (data)
  "DATA (an XRECORD create list) with (100 . \"AcDbXrecord\") (280 . 1)
ahead of the data groups: the 280 is inserted right after an existing
marker unless a 280 already follows it; a missing marker (lenient
dialects only -- the strict ones reject it upstream) is inserted with the
280 after the leading header groups (0 5 102 330 360)."
  (let ((marker (position-if (lambda (pair)
                               (and (consp pair) (%group-code= (car pair) 100)
                                    (stringp (cdr pair))
                                    (string-equal (cdr pair) "AcDbXrecord")))
                             data)))
    (if marker
        (let ((next (nth (1+ marker) data)))
          (if (and (consp next) (%group-code= (car next) 280))
              data
              (append (subseq data 0 (1+ marker))
                      (list (cons 280 1))
                      (nthcdr (1+ marker) data))))
        (let ((pos (or (position-if-not
                        (lambda (pair)
                          (and (consp pair) (realp (car pair))
                               (member (round (car pair)) '(-1 0 5 102 330 360))))
                        data)
                       (length data))))
          (append (subseq data 0 pos)
                  (list (cons 100 "AcDbXrecord") (cons 280 1))
                  (nthcdr pos data))))))

;;; --- Divergence D1: R13+ subclass-marker contract ---------------
;;;
;;; Real AutoCAD REQUIRES the (100 . "AcDbEntity") + per-class
;;; (100 . "AcDb<Type>") subclass markers to be present in the ENTMAKE /
;;; ENTMAKEX data for the entities it introduced at R13+ (ELLIPSE,
;;; LWPOLYLINE, RAY, XLINE, MTEXT, SPLINE, ...); marker-less data is
;;; rejected (entmakex -> nil). BricsCAD is lenient — it synthesises the
;;; markers — and clautolisp historically followed BricsCAD (see
;;; VALIDATE-ENTITY-DXF, which appends the markers as defaults). These
;;; helpers speak PURE CL only and make no dialect decision: they report
;;; which required markers are ABSENT from the SUPPLIED data, and the
;;; host adapter applies the active dialect's policy (reject / warn /
;;; accept). Pre-R12 entities (LINE, CIRCLE, TEXT, ...) are unaffected.

(defun entity-family-expected-markers (family)
  "The ordered subclass-marker strings a marker-strict host (AutoCAD)
requires in the ENTMAKE data for a FAMILY create: the base AcDbEntity
marker (none for a non-graphical object) followed by the per-class
SUBCLASSES."
  (if (entity-family-graphical-p family)
      (cons "AcDbEntity" (entity-family-subclasses family))
      ;; An OBJECT carries no AcDbObject marker in DXF / ENTGET; AutoCAD
      ;; accepts an XRECORD with only (100 . "AcDbXrecord") (measured).
      (entity-family-subclasses family)))

(defun %marker-present-p (data marker)
  "True iff DATA carries a (100 . MARKER) subclass-marker pair
(case-insensitive on the marker string)."
  (dolist (pair data nil)
    (when (and (consp pair) (%group-code= (car pair) 100)
               (stringp (cdr pair)) (string-equal (cdr pair) marker))
      (return t))))

(defun entity-dxf-missing-markers (data)
  "For AutoCAD's R13+ subclass-marker contract: the list of expected
(100 . \"AcDb...\") subclass-marker strings ABSENT from the supplied
pure-CL DXF list DATA. NIL when the (0 . TYPE) type is unknown,
pre-R13, or the data already carries every marker — i.e. NIL means
\"AutoCAD would accept this create; no divergence.\" Pure: the
reject / warn / accept decision is the caller's (the host adapter,
per the active dialect)."
  (let* ((type (%group-0-type data))
         (family (and type (find-entity-family type))))
    (when (and family (entity-family-since-r13-p family))
      (remove-if (lambda (m) (%marker-present-p data m))
                 (entity-family-expected-markers family)))))
