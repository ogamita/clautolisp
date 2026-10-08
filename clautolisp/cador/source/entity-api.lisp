(in-package #:clautolisp.cador)

;;;; Entity-level HAL methods for cador.
;;;;
;;;; Phase 17b/(a): these methods are now a thin AutoLISP adapter over
;;;; the clautolisp.drawing CL API, operating on the host's
;;;; ACTIVE-DRAWING. The drawing stores PURE Common-Lisp values
;;;; (REVIEW-1): no (-1 . ename) pair is stored, group code 5 is the
;;;; hexadecimal handle string, and string values are CL strings. The
;;;; AutoLISP view — the (-1 . ename) head and autolisp-string-wrapped
;;;; string values — is synthesised here, at the boundary:
;;;;
;;;;   host-entget  ⇒ find-entity            + al-view wrapping
;;;;   host-entmake ⇒ add-entity             + event signalling
;;;;   host-entmod  ⇒ modify-entity          + event signalling
;;;;   host-entdel  ⇒ entity-deleted-status  toggle + events
;;;;
;;;; The storage mechanics (handle allocation, the entity table,
;;;; creation order, the deleted flag) live once in clautolisp.drawing.

;;; --- ENAME <-> handle helpers ------------------------------------

(defun handle->ename (host handle)
  "Return the AutoLISP ENAME that denotes HANDLE on HOST, interning it so
the same handle always yields the same (EQ) ename object within a
drawing. Vendor AutoLISP has this identity — two enames for the same
entity are EQ / EQUAL — so the portable idioms (eq (entlast) (entlast)),
 (eq ename (car sel)) and (member ename enames) work. The cache is
drained whenever the host's active drawing is replaced, so a handle from
a closed drawing can never alias a fresh drawing's entities.
 (ename-eq-identity.issue)"
  (let ((cache   (cador-ename-cache host))
        (drawing (cador-active-drawing host)))
    (unless (eq drawing (cador-ename-cache-drawing host))
      (clrhash cache)
      (setf (cador-ename-cache-drawing host) drawing))
    (or (gethash handle cache)
        (setf (gethash handle cache)
              (clautolisp.autolisp-runtime:make-autolisp-ename
               :value handle :document drawing)))))

(defun ename->handle (ename operator-name &optional host)
  "Extract the hex handle string from an AutoLISP ENAME, signalling
an :invalid-ename runtime error if ENAME is not an ename, and -- given HOST --
:cross-document-dereference when ENAME belongs to another open drawing
(cador-multidocument-host C5: a handle is document-tagged; in AutoCAD an
ename is only valid in the drawing it came from)."
  (unless (typep ename 'clautolisp.autolisp-runtime:autolisp-ename)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-ename
     "~A expects an ENAME, got ~S."
     operator-name ename))
  (when host (%check-ename-document host ename operator-name))
  (clautolisp.autolisp-runtime:autolisp-ename-value ename))

(defun %check-ename-document (host ename operator-name)
  (let ((document (clautolisp.autolisp-runtime:autolisp-ename-document ename)))
    (when (and document (not (eq document (cador-active-drawing host))))
      (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
       :cross-document-dereference
       "~A: ENAME ~A belongs to another drawing (~A), not the current one."
       operator-name (clautolisp.autolisp-runtime:autolisp-ename-value ename)
       (ignore-errors (clautolisp.drawing:drawing-name document))))))

(defun group-code-equal-p (a b)
  "Equality predicate for DXF group-code keys: both are usually
integers, but real AutoLISP corpora occasionally encode them as
small reals when read from a file. (Also used by selection-api.)"
  (or (eql a b) (and (numberp a) (numberp b) (= a b))))

;;; --- AutoLISP <-> pure-CL boundary converter --------------------

(defun al->pure-value (value)
  "Convert an AutoLISP runtime value to the pure CL value stored in
the drawing: autolisp-string -> string, autolisp-ename -> its handle
string; conses recurse; everything else passes through."
  (typecase value
    (clautolisp.autolisp-runtime:autolisp-string
     (clautolisp.autolisp-runtime:autolisp-string-value value))
    (clautolisp.autolisp-runtime:autolisp-ename
     (clautolisp.autolisp-runtime:autolisp-ename-value value))
    (cons (cons (al->pure-value (car value)) (al->pure-value (cdr value))))
    (t value)))

(defun pure->al-value (value)
  "Convert a stored pure CL value to its AutoLISP view: CL string ->
autolisp-string; conses recurse; everything else passes through.
(Enames are reconstructed where the group code is known: the -1 head by
ENTITY->AL-VIEW, the DXF pointer codes by PURE-PAIR->AL-PAIR.)"
  (typecase value
    (string (clautolisp.autolisp-runtime:make-autolisp-string value))
    (cons (cons (pure->al-value (car value)) (pure->al-value (cdr value))))
    (t value)))

;;; --- DXF pointer group codes ------------------------------------
;;;
;;; The drawing stores every object reference as the hex handle STRING
;;; it names (that is what DXF writes and what clautolisp.drawing keys
;;; its tables on). AutoLISP does not see those strings: ENTGET (and so
;;; DICTSEARCH / DICTNEXT / TBLSEARCH / TBLNEXT, which return the same
;;; view) translates the POINTER group codes into ENTITY NAMES, per the
;;; DXF reference's group-code value types:
;;;   330-339 soft-pointer ID      340-349 hard-pointer ID
;;;   350-359 soft-owner ID        360-369 hard-owner ID
;;;   390-399 handle of the plot-style-name object (hard pointer)
;;;   480-481 hard-pointer handle
;;; 5 / 105 (the object's own handle) and the xdata 1005 stay strings.
;;;
;;; MEASURED 2026-10-08 (probes/sources/probe-entget-pointers.lsp; jobs
;;; 17026569911 AutoCAD 2022, 17026569912 BricsCAD V25 Windows,
;;; 17026569913 BricsCAD V26 macOS) -- the vendors agree on:
;;;   - every pointer code above reads back as an ENAME;
;;;   - a pointer to an ERASED object stays the same (EQ) ename, whose
;;;     entget is nil;
;;;   - a handle STRING in a pointer code is REFUSED by entmakex and
;;;     entmod with an error (AutoCAD "bad DXF group: (340 . "2A2")",
;;;     BricsCAD "bad argument type <(340 . "95")> ; expected ENTITYNAME
;;;     at [invalid DXF/XED data]");
;;; and differ on:
;;;   - 320-329: AutoCAD keeps them handle STRINGS (and refuses an ename
;;;     there: "bad DXF group"); BricsCAD treats them as pointers (ENAME
;;;     on read, a string refused);
;;;   - the null pointer: AutoCAD lists the named-object dictionary's
;;;     owner as (330 . <Entity name: 0>); BricsCAD omits the pair.
;;; Per product: BricsCAD dialects follow BricsCAD; every other dialect
;;; (autocad, clautolisp, strict, lax) follows AutoCAD, the normative
;;; reference. A string where an ename is required (or the reverse) is
;;; refused under the vendor dialects, as there; clautolisp and strict
;;; accept it (the pre-2.3.7 contract) with an [entmake-pointer-value]
;;; warning, lax accepts it silently -- the policy of %INVALID-INSERT-POLICY.
;;; (issues/closed/cador-entget-pointer-codes-are-handle-strings.issue)

(defun %group-code-integer (code)
  (and (realp code) (= code (round code)) (round code)))

(defun dxf-pointer-group-code-p (code)
  "True iff the DXF group CODE carries an object POINTER on every vendor
(an ID that ENTGET returns as an ENAME): 330-369, 390-399, 480-481."
  (let ((c (%group-code-integer code)))
    (and c (or (<= 330 c 369) (<= 390 c 399) (<= 480 c 481)))))

(defun dxf-arbitrary-handle-group-code-p (code)
  "True iff CODE is one of the 320-329 \"arbitrary object handle\" codes:
strings on AutoCAD, enames on BricsCAD (measured 2026-10-08)."
  (let ((c (%group-code-integer code)))
    (and c (<= 320 c 329))))

(defun %current-product ()
  "The vendor product of the active dialect (:autocad / :bricscad), or NIL
for clautolisp / strict / lax."
  (let ((dialect (ignore-errors
                  (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (and dialect (clautolisp.autolisp-reader:autolisp-dialect-product dialect))))

(defun %ename-group-code-p (code product)
  "True iff PRODUCT's ENTGET shows group CODE as an ENAME."
  (or (dxf-pointer-group-code-p code)
      (and (eq product :bricscad) (dxf-arbitrary-handle-group-code-p code))))

(defun %null-handle-p (value)
  (and (stringp value) (string= value "0")))

(defun pure-pair->al-pair (host pair &optional (product (%current-product)))
  "The AutoLISP view of one stored group-code PAIR, or :OMIT. An ename
code's handle string becomes the ENAME HANDLE->ENAME interns for it --
also for a handle naming no live object (an erased target: ENTGET of it
is nil, as on both vendors). The null handle \"0\" is (330 . <Entity
name: 0>) on AutoCAD and omitted on BricsCAD. Every other value goes
through PURE->AL-VALUE."
  (cond
    ((not (consp pair)) pair)
    ((and (%ename-group-code-p (car pair) product)
          (stringp (cdr pair))
          (plusp (length (cdr pair))))
     (if (and (eq product :bricscad) (%null-handle-p (cdr pair)))
         :omit
         (cons (car pair) (handle->ename host (cdr pair)))))
    (t (cons (car pair) (pure->al-value (cdr pair))))))

(defun pure-data->al-view (host data)
  "The AutoLISP view of the stored group-code list DATA: PURE-PAIR->AL-PAIR
on each top-level pair (an xdata (-3 ...) cell is not a pointer code, so
its 1005 handles stay strings)."
  (let ((product (%current-product)))
    (loop for pair in data
          for view = (pure-pair->al-pair host pair product)
          unless (eq view :omit) collect view)))

;;; The write side: ENTMAKE / ENTMAKEX / ENTMOD data.

(defun %al-pair-text (code value)
  "CODE . VALUE printed the way the vendors' error messages show it."
  (format nil "(~A . ~A)" code
          (typecase value
            (clautolisp.autolisp-runtime:autolisp-string
             (format nil "~S" (clautolisp.autolisp-runtime:autolisp-string-value value)))
            (string (format nil "~S" value))
            (clautolisp.autolisp-runtime:autolisp-ename
             (format nil "<Entity name: ~A>"
                     (clautolisp.autolisp-runtime:autolisp-ename-value value)))
            (t (princ-to-string value)))))

(defun %bad-pointer-pair (pair product)
  "PAIR (an AutoLISP group-code pair) if its value has the wrong kind for
PRODUCT's group-code typing -- a string where an ENAME is required, or an
ename in a 320-329 string code (AutoCAD) -- else NIL."
  (and (consp pair)
       (let ((code (car pair)) (value (cdr pair)))
         (cond
           ((%ename-group-code-p code product)
            (and (or (typep value 'clautolisp.autolisp-runtime:autolisp-string)
                     (stringp value))
                 pair))
           ((dxf-arbitrary-handle-group-code-p code)
            (and (typep value 'clautolisp.autolisp-runtime:autolisp-ename) pair))
           (t nil)))))

(defun emit-entmake-pointer-value-warning (operator-name pair)
  (format *error-output*
          "~&[entmake-pointer-value] ~A: ~A -- AutoCAD and BricsCAD refuse ~
this group (a pointer code takes an ENAME, AutoCAD's 320-329 a handle ~
string); clautolisp stores it as given, which is not portable.~%"
          operator-name (%al-pair-text (car pair) (cdr pair))))

(defun %vet-pointer-groups (data operator-name)
  "Apply the vendors' group-code typing to the AutoLISP DATA of an
ENTMAKE / ENTMAKEX / ENTMOD (top-level pairs; xdata is not concerned).
Under an AutoCAD or BricsCAD dialect a mistyped pair is an error, worded
as that vendor words it; clautolisp and strict warn and proceed; lax
proceeds silently."
  (when (listp data)
    (let* ((product (%current-product))
           (bad (loop for pair in data
                      thereis (%bad-pointer-pair pair product))))
      (when bad
        (multiple-value-bind (action warn-p)
            (%invalid-insert-policy
             (clautolisp.autolisp-runtime:current-evaluation-dialect-name))
          (when warn-p
            (emit-entmake-pointer-value-warning operator-name bad))
          (when (eq action :reject)
            (if (eq product :bricscad)
                (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                 :invalid-entity-data
                 "bad argument type <~A> ; expected ENTITYNAME at [invalid DXF/XED data]"
                 (%al-pair-text (car bad) (cdr bad)))
                (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
                 :invalid-entity-data
                 "bad DXF group: ~A"
                 (%al-pair-text (car bad) (cdr bad))))))))))

(defun al-data->pure (data operator-name)
  "Convert an AutoLISP DXF group-code list to a pure-CL list. The
integer group code of each pair is kept; the value is converted."
  (unless (listp data)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-entity-data
     "~A expects a DXF group-code list, got ~S."
     operator-name data))
  (mapcar (lambda (pair)
            (if (consp pair)
                (cons (car pair) (al->pure-value (cdr pair)))
                pair))
          data))

;;; --- XData (extended data) helpers ------------------------------
;;;
;;; XData rides in an entity's group-code list as a single (-3 . groups)
;;; cell (DXF group -3), where GROUPS is a list of per-application
;;; groups, each an (APPNAME . xdata-pairs) list; the xdata pairs use
;;; group codes >= 1000 (1000 string, 1001 appname, 1002 brace, 1005
;;; handle, 1010 point, 1040 real, 1070 int16, 1071 int32, ...).
;;;
;;; The vendor contract: (entget ename) WITHOUT an application list
;;; suppresses xdata entirely; (entget ename '("APP" ...)) appends only
;;; the requested applications' xdata; the wildcard "*" requests all.

(defun xdata-cell-p (pair)
  "True iff PAIR is the (-3 . groups) xdata cell of an entity."
  (and (consp pair) (group-code-equal-p (car pair) -3)))

(defun %applist-names (applist)
  "Unwrap the AutoLISP application-name list APPLIST (a list of strings
/ autolisp-strings) to a list of CL strings. NIL yields NIL."
  (loop for item in applist
        collect (typecase item
                  (clautolisp.autolisp-runtime:autolisp-string
                   (clautolisp.autolisp-runtime:autolisp-string-value item))
                  (string item)
                  (t (princ-to-string item)))))

(defun %filter-xdata-groups (groups names)
  "GROUPS is the pure (APPNAME . pairs) list of an entity's xdata. Keep
only those whose APPNAME is requested by NAMES (a list of CL strings);
\"*\" requests all."
  (if (member "*" names :test #'string=)
      groups
      (remove-if-not (lambda (grp)
                       (and (consp grp) (stringp (car grp))
                            (member (car grp) names :test #'string-equal)))
                     groups)))

(defun entity->al-view (host entity &optional applist)
  "The AutoLISP entget / entmake view of a stored ENTITY-HANDLE: the
(-1 . ename) head, the wrapped ordinary group codes, and — only when
APPLIST (a list of registered application names) is supplied — the
matching xdata appended as a trailing (-3 ...) cell. Without APPLIST
the xdata is suppressed, matching the vendor ENTGET contract. HOST
supplies the ename intern cache for the (-1 . ename) head."
  (let* ((data (entity-handle-data entity))
         (ordinary (remove-if #'xdata-cell-p data))
         (xdata-cell (find-if #'xdata-cell-p data))
         (names (%applist-names applist))
         (kept (and xdata-cell names
                    (%filter-xdata-groups (cdr xdata-cell) names))))
    (append
     (list (cons -1 (handle->ename host (entity-handle-id entity))))
     (pure-data->al-view host ordinary)
     (when kept
       (list (cons -3 (pure->al-value kept)))))))

(defun extract-modified-handle (data operator-name &optional host)
  "Return the hex handle of the entity DATA refers to, from its
(-1 . <ENAME>) entry, signalling :invalid-entity-data if missing (and,
given HOST, :cross-document-dereference for another drawing's ename)."
  (dolist (pair data)
    (when (and (consp pair) (group-code-equal-p (car pair) -1)
               (typep (cdr pair) 'clautolisp.autolisp-runtime:autolisp-ename))
      (return-from extract-modified-handle
        (ename->handle (cdr pair) operator-name host))))
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :invalid-entity-data
   "~A requires the modified entity's (-1 . <ENAME>) entry in the data list."
   operator-name))

;;; --- Compatibility helpers (kept; used by selection-api etc.) ----

(defun cador-allocate-handle (host)
  "Allocate the next hex handle string for HOST's active drawing and
bump its seed. Retained for API compatibility; the entity methods now
let clautolisp.drawing:ADD-ENTITY allocate internally."
  (format nil "~X" (clautolisp.drawing:allocate-handle
                    (cador-active-drawing host))))

(defun safe-find-entity (drawing handle &key include-deleted)
  "Like clautolisp.drawing:find-entity, but a malformed handle (one
that is not valid hexadecimal — e.g. a fabricated ENAME or HANDENT
argument) is treated as simply not found (nil) rather than signalled.
This is the AutoLISP contract: entget / handent on garbage return nil
and set ERRNO, they do not raise."
  (handler-case
      (clautolisp.drawing:find-entity drawing handle
                                      :include-deleted include-deleted)
    (clautolisp.drawing:drawing-error () nil)))

(defun cador-find-entity-by-handle (host handle)
  "Return the live ENTITY-HANDLE stored under HANDLE, or nil if no
such entity exists or it has been deleted."
  (safe-find-entity (cador-active-drawing host) handle))

(defun current-document ()
  (clautolisp.autolisp-runtime:evaluation-context-current-document
   (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- Host method implementations ---------------------------------

(defmethod host-entget ((host cador) ename &optional applist)
  (let* ((handle (ename->handle ename 'entget host))
         (entity (and (or (stringp handle) (integerp handle))
                      (safe-find-entity (cador-active-drawing host) handle))))
    (cond
      (entity (entity->al-view host entity applist))
      (t
       ;; A symbol-table record's ename (from tblobjname) is
       ;; entget-able on the vendors: the record's group-code view,
       ;; (-1 . ename) head, and for a BLOCK record the (-2 . first
       ;; entity) walk entry.
       (let ((record (%find-table-record-by-id host handle)))
         (and record
              (cons (cons -1 ename)
                    (table-record-al-view+extras host record))))))))

(defun %data-type-string (data)
  "The (0 . TYPE) string of the pure group-code list DATA, or NIL."
  (dolist (pair data nil)
    (when (and (consp pair) (group-code-equal-p (car pair) 0) (stringp (cdr pair)))
      (return (cdr pair)))))

(defun %data-group-value (data code)
  "The value of the first CODE group in the pure group-code list DATA,
or NIL when absent."
  (dolist (pair data nil)
    (when (and (consp pair) (group-code-equal-p (car pair) code))
      (return (cdr pair)))))

(defun main-space-entity-p (entity)
  "True when ENTITY belongs to model or paper space rather than to a
block definition's contents. ssget's whole-database scan, entlast and
the top-level entnext walk only main-space entities, as the vendors do;
block contents are reached through their block (tblobjname + entnext,
or the ActiveX block collection)."
  (let ((owner (entity-handle-block entity)))
    (or (null owner)
        (string-equal owner "*Model_Space")
        (string-equal owner "*Paper_Space"))))

(defun %block-entity-handles (host name)
  "Hex handles of the live entities owned by block NAME, oldest first.
Model-space entities are those with a NIL owner (plus any explicitly
owned by *Model_Space); other blocks own by name. Subentities (ATTRIB /
VERTEX / SEQEND runs) are not members — vendor space and block
collections enumerate only their top-level entities."
  (let ((model-p (string-equal name "*Model_Space")))
    (loop for handle in (reverse (cador-creation-order host))
          for entity = (cador-find-entity-by-handle host handle)
          when (and entity
                    (not (member (entity-handle-kind entity)
                                 '(:attrib :vertex :seqend)))
                    (let ((owner (entity-handle-block entity)))
                      (if owner
                          (string-equal owner name)
                          model-p)))
            collect handle)))

;;; --- Shared entity utilities (property bridge + command engine) --

(defun %entity-group-value (entity code)
  (dolist (pair (entity-handle-data entity) nil)
    (when (and (consp pair) (group-code-equal-p (car pair) code))
      (return (cdr pair)))))

(defun %entity-set-group (entity code value)
  "Set the first CODE group of ENTITY's data to VALUE, appending the
group when absent (the entmod convention)."
  (let ((pair (find-if (lambda (pair)
                         (and (consp pair)
                              (group-code-equal-p (car pair) code)))
                       (entity-handle-data entity))))
    (if pair
        (setf (cdr pair) value)
        (setf (entity-handle-data entity)
              (append (entity-handle-data entity)
                      (list (cons code value)))))
    value))

(defun %entity-subentity-handles (host entity)
  "Handles of the live subentities owned (group 330) by ENTITY, oldest
first — the ATTRIB…SEQEND run of an INSERT, the VERTEX…SEQEND run of a
POLYLINE."
  (let ((id (entity-handle-id entity)))
    (loop for handle in (reverse (cador-creation-order host))
          for sub = (cador-find-entity-by-handle host handle)
          when (and sub
                    (let ((owner (%entity-group-value sub 330)))
                      (and owner (string-equal owner id))))
            collect handle)))

(defun %entity-map-point-groups (entity function
                                 &optional (codes '(10 11 12 13)))
  "Apply FUNCTION — a point-list -> point-list transform — to EVERY
occurrence of the point groups CODES in ENTITY's data. A LWPOLYLINE
carries one 10 group per vertex; transforming only the first corrupts
the geometry (the bas/haut discrimination bug, 1.8.19)."
  (dolist (pair (entity-handle-data entity))
    (when (and (consp pair)
               (member (car pair) codes :test #'group-code-equal-p)
               (consp (cdr pair)))
      (setf (cdr pair) (funcall function (cdr pair))))))

(defun %entity-translate (entity dx dy dz)
  (%entity-map-point-groups
   entity
   (lambda (p)
     (let ((x (+ (coerce (first p) 'double-float) dx))
           (y (+ (coerce (second p) 'double-float) dy)))
       ;; Preserve the point's arity: LWPOLYLINE vertices are 2D.
       (if (cddr p)
           (list x y (+ (coerce (third p) 'double-float) dz))
           (list x y))))))

(defun %entity-rotate-one (entity bx by angle)
  (let ((c (cos angle)) (s (sin angle)))
    (%entity-map-point-groups
     entity
     (lambda (p)
       (let ((x (- (coerce (first p) 'double-float) bx))
             (y (- (coerce (second p) 'double-float) by)))
         (let ((rx (+ bx (- (* c x) (* s y))))
               (ry (+ by (+ (* s x) (* c y)))))
           (if (cddr p)
               (list rx ry (coerce (third p) 'double-float))
               (list rx ry))))))
    (when (member (entity-handle-kind entity)
                  '(:text :mtext :attrib :attdef :insert))
      (%entity-set-group entity 50
                         (+ (coerce (or (%entity-group-value entity 50) 0.0d0)
                                    'double-float)
                            angle)))))

(defun %clone-entity-with-run (host entity)
  "Duplicate ENTITY (and its subentity run, owners remapped) in the
same container; returns the new ENTITY-HANDLE."
  (let* ((drawing (cador-active-drawing host))
         (new (clautolisp.drawing:add-entity
               drawing (copy-tree (entity-handle-data entity))
               :block (entity-handle-block entity))))
    (dolist (handle (%entity-subentity-handles host entity))
      (let ((sub (cador-find-entity-by-handle host handle)))
        (when sub
          (let ((data (copy-tree (entity-handle-data sub))))
            (dolist (pair data)
              (when (and (consp pair) (group-code-equal-p (car pair) 330))
                (setf (cdr pair) (entity-handle-id new))))
            (clautolisp.drawing:add-entity drawing data
                                           :block (entity-handle-block sub))))))
    new))

(defun table-record-al-view+extras (host record)
  "The tblsearch / tblnext / entget view of a symbol-table RECORD: its
wrapped group-code data, plus — for a BLOCK record — the vendors'
(-2 . <first-entity ename>) group, the entry point of the classic
block-contents walk ((entnext (cdr (assoc -2 (tblsearch \"BLOCK\" n)))).
SPEC-UNCERTAIN: on the vendors an *empty* block's -2 names its ENDBLK
entity; the host stores no ENDBLK and omits the group
(deferred-spec-research.issue)."
  (let ((view (pure-data->al-view host (symbol-table-record-data record))))
    (if (eq (symbol-table-record-kind record) :block-record)
        (let ((first-handle
                (first (%block-entity-handles
                        host (symbol-table-record-name record)))))
          (if first-handle
              (append view (list (cons -2 (handle->ename host first-handle))))
              view))
        view)))

;;; --- Vendor-divergence policy (autolisp-spec ch.25) -------------
;;;
;;; D1 (R13+ ENTMAKE subclass markers) and D3 (ENTMOD on a non-graphical
;;; object) are both divergences the autolisp-spec RESOLVES in AutoCAD's
;;; favour: AutoCAD's documented behaviour is normative, BricsCAD's is a
;;; recognised-but-NOT-condoned divergence (see the ENTMAKE / ENTMAKEX /
;;; ENTMOD *** clautolisp notes in the spec, and ch.25 "Behavior versus
;;; warning, and the divergence taxonomy"). The per-dialect resolution:
;;;   normative behaviour (AutoCAD's: reject / no-op) -- autocad,
;;;                                                      clautolisp, strict
;;;   deviant   behaviour (BricsCAD's: accept / apply) -- bricscad, lax
;;;   warns -- bricscad (the deviant dialect, "not condoned") AND strict
;;;            (any divergence is unsafe to rely on); autocad, clautolisp
;;;            and lax are silent.

(defun %resolved-divergence-policy (dialect-name)
  "For a vendor divergence the autolisp-spec resolves in AutoCAD's favour
(BricsCAD the non-condoned deviant), classify the active DIALECT-NAME and
return two values:
  ACTION -- :normative (perform AutoCAD's documented behaviour: reject /
            no-op) or :deviant (perform BricsCAD's: accept / apply);
  WARN-P -- T iff a portability warning is due.
lax -> deviant, silent; bricscad -> deviant + warn; strict -> normative +
warn (any divergence is unsafe); autocad / clautolisp / unknown ->
normative, silent."
  (case (clautolisp.autolisp-reader:autolisp-dialect-template-name dialect-name)
    ((:lax)                    (values :deviant   nil))
    ((:bricscad-v26 :bricscad) (values :deviant   t))
    ((:strict)                 (values :normative t))
    (t                         (values :normative nil))))

(defun emit-entmake-marker-divergence-warning (type missing)
  "Advisory to *ERROR-OUTPUT*: TYPE's ENTMAKE data omits the R13+ subclass
markers MISSING. The autolisp-spec (per AutoCAD) requires them; BricsCAD's
acceptance of marker-less input is a recognised, non-condoned divergence."
  (format *error-output*
          "~&[entmake-subclass-marker] ~A is an R13+ entity; the ~
autolisp-spec (per AutoCAD) requires the ~{(100 . ~S)~^, ~} subclass ~
marker~P in the ENTMAKE / ENTMAKEX data. BricsCAD accepts them omitted, ~
but that divergence is not portable and not condoned: the create returns ~
nil under autocad, clautolisp and strict.~%"
          type missing (length missing)))

;;; --- Invalid INSERT (cador-entmakex-invalid-insert.issue) ---------
;;;
;;; An INSERT whose group-2 block name does not resolve to a BLOCK_RECORD is
;;; rejected by BOTH AutoCAD and BricsCAD (entmake/entmakex return nil, nothing
;;; is added to the database). This is NOT a vendor divergence — the vendors
;;; agree. cador historically kept a permissive construction mode that accepted
;;; such an INSERT, which hid invalid DXF fixtures until the suite reached a
;;; real CAD. Now: the vendor dialects reject it (match the vendor); clautolisp
;;; keeps the permissive mode but emits [entmakex-invalid-insert]; lax accepts
;;; silently; strict accepts but warns (a divergence of any kind is unsafe).

(defun %pure-group-string (data code)
  "The string value of group CODE in the pure group-code list DATA, or NIL."
  (dolist (pair data nil)
    (when (and (consp pair) (group-code-equal-p (car pair) code)
               (stringp (cdr pair)))
      (return (cdr pair)))))

(defun %vendor-dialect-p (dialect-name)
  "True when DIALECT-NAME is an AutoCAD or BricsCAD dialect (any version)."
  (let ((name (and (symbolp dialect-name) (symbol-name dialect-name))))
    (and name (or (search "AUTOCAD" name) (search "BRICSCAD" name)) t)))

(defun %invalid-insert-policy (dialect-name)
  "For an INSERT whose group-2 block name is undefined, classify DIALECT-NAME.
Returns (values ACTION WARN-P): ACTION is :reject (return nil, no entity — what
AutoCAD and BricsCAD do) or :accept (cador's permissive construction mode).
Vendor dialects reject; lax accepts silently; clautolisp and strict accept and
warn (strict warns on any divergence)."
  (cond
    ((%vendor-dialect-p dialect-name) (values :reject nil))
    ((eq dialect-name :lax)           (values :accept nil))
    (t                                (values :accept t))))

(defun emit-entmakex-invalid-insert-warning (block-name)
  "Advisory to *ERROR-OUTPUT*: cador accepted an INSERT that AutoCAD and
BricsCAD reject — its group-2 block BLOCK-NAME is undefined."
  (format *error-output*
          "~&[entmakex-invalid-insert] cador accepted an INSERT rejected by ~
AutoCAD and BricsCAD: block ~A is undefined (its group-2 name resolves to no ~
BLOCK_RECORD); the create returns nil under the autocad and bricscad ~
dialects.~%"
          (or block-name "(unnamed)")))

(defun %invalid-insert-p (host pure)
  "True when PURE is an INSERT whose group-2 block name does not resolve to a
BLOCK_RECORD in HOST — the immediately checkable INSERT invariant the vendors
enforce at create time."
  (let ((type (%data-type-string pure)))
    (and type (string-equal type "INSERT")
         (let ((block-name (%pure-group-string pure 2)))
           (or (null block-name)
               (not (cador-find-table-record host :block-record block-name)))))))

(defun %host-add-entity (host data operator-name &optional owner)
  "Shared worker for HOST-ENTMAKE / HOST-ENTMAKEX. Validate + normalise
DATA against the entity-family registry (clautolisp.drawing), add the
entity to the active drawing, fire the object-appended reactor events,
and return (values ENTITY ENAME). Returns (values NIL NIL) when the
data does not describe a creatable entity — the vendor ENTMAKE/ENTMAKEX
contract is to return nil (and set ERRNO), NOT to raise, on a bad
group-code list. Only a genuinely non-list argument raises, and that is
caught upstream in the builtin (REQUIRE-PROPER-LIST).

Divergence D1: an R13+ entity whose data omits its (100 . \"AcDb...\")
subclass markers is REJECTED (nil) under the normative dialects (autocad,
clautolisp, strict) per the autolisp-spec, and ACCEPTED (markers
synthesised) under the deviant/lenient dialects (bricscad, lax). strict
and bricscad additionally warn."
  (when (member operator-name '(entmake entmakex))
    (%vet-pointer-groups data operator-name))
  (let* ((pure (al-data->pure data operator-name))
         (drawing (cador-active-drawing host))
         (missing-markers (clautolisp.drawing:entity-dxf-missing-markers pure)))
    ;; An INSERT referencing an undefined block is rejected by both vendors
    ;; (cador-entmakex-invalid-insert.issue). Only ENTMAKE / ENTMAKEX are
    ;; validated here — the command-engine INSERT stand-in stays permissive.
    (when (and (member operator-name '(entmake entmakex))
               (%invalid-insert-p host pure))
      (multiple-value-bind (action warn-p)
          (%invalid-insert-policy
           (clautolisp.autolisp-runtime:current-evaluation-dialect-name))
        (when warn-p
          (emit-entmakex-invalid-insert-warning (%pure-group-string pure 2)))
        (when (eq action :reject)
          (return-from %host-add-entity (values nil nil)))))
    (when missing-markers
      (multiple-value-bind (action warn-p)
          (%resolved-divergence-policy
           (clautolisp.autolisp-runtime:current-evaluation-dialect-name))
        (when warn-p
          (emit-entmake-marker-divergence-warning (%data-type-string pure)
                                                  missing-markers))
        (when (eq action :normative)
          (return-from %host-add-entity (values nil nil)))))
    (multiple-value-bind (normalised reason)
        (clautolisp.drawing:validate-entity-dxf pure)
      (declare (ignore reason))
      (when (and normalised (eq (%current-product) :bricscad))
        (setf normalised (%bricscad-xrecord-drop-explicit-280 pure normalised)))
      (if (null normalised)
          (values nil nil)
          (let* ((owned (%link-subentity-owner host normalised))
                 (entity (handler-case
                             (clautolisp.drawing:add-entity
                              drawing owned
                              ;; OWNER (InsertBlock's target space), or
                              ;; the block whose entmake definition run
                              ;; is open — NIL = model space.
                              :block (or owner
                                         (car (cador-open-block-definition
                                               host))))
                           (clautolisp.drawing:drawing-error () nil))))
            (if (null entity)
                (values nil nil)
                (let ((ename (handle->ename host (entity-handle-id entity)))
                      (document (current-document)))
                  (%update-open-complex host entity normalised)
                  (clautolisp.autolisp-runtime:signal-document-event
                   document :acdb :vlr-objectappended (list ename))
                  (clautolisp.autolisp-runtime:signal-document-event
                   document :acdb :vlr-objectreappended (list ename))
                  (values entity ename))))))))

;;; --- Complex-entity ownership (330 owner of subentities) --------
;;;
;;; A POLYLINE / INSERT opens a run of subentities (VERTEX / ATTRIB)
;;; terminated by a SEQEND. When the run is open, each subentity's
;;; owner (group 330) is the header's handle unless the caller supplied
;;; one, matching the AutoCAD/BricsCAD create-sequence contract; the
;;; SEQEND closes the run. ENTNEXT then walks header -> subentities ->
;;; seqend naturally, since they are in creation order.

(defun %data-has-code-p (data code)
  (dolist (pair data nil)
    (when (and (consp pair) (group-code-equal-p (car pair) code))
      (return t))))

(defun %link-subentity-owner (host normalised)
  "If NORMALISED is a subentity (VERTEX / ATTRIB / SEQEND) created while
a complex header's run is open, and it carries no explicit (330 . owner)
group, append the header's handle as its owner. Returns the possibly
augmented data."
  (let* ((type (%data-type-string normalised))
         (family (clautolisp.drawing:find-entity-family type))
         (open (cador-open-complex-handle host)))
    (if (and family
             (clautolisp.drawing:entity-family-subentity-p family)
             open
             (not (%data-has-code-p normalised 330)))
        (append normalised (list (cons 330 open)))
        normalised)))

(defun %update-open-complex (host entity normalised)
  "Update the host's open-complex run state after ENTITY was created
from NORMALISED: a POLYLINE / INSERT opens a run (records its handle);
a SEQEND closes it."
  (let* ((type (%data-type-string normalised))
         (family (clautolisp.drawing:find-entity-family type)))
    (cond
      ((and family (clautolisp.drawing:entity-family-complex-p family))
       (setf (cador-open-complex-handle host)
             (clautolisp.drawing:entity-handle-id entity)))
      ((and type (string-equal type "SEQEND"))
       (setf (cador-open-complex-handle host) nil)))))

;;; --- Block-definition creation through ENTMAKE -------------------
;;;
;;; The vendor contract (AutoLISP Reference, entmake): entmake of a
;;; (0 . "BLOCK") header opens a block definition; the entities entmade
;;; next belong to it; entmake of (0 . "ENDBLK") completes it — the
;;; definition is added to the block table and entmake returns the
;;; block's NAME (not an entity list). An anonymous block is requested
;;; with name "*U" plus bit 0 of the 70 flags; the actual "*U<n>" name
;;; is allocated at open and returned by the closing ENDBLK.

(defun %allocate-anonymous-block-name (host)
  "A fresh \"*U<n>\" anonymous-block name not present in the
:block-record table."
  (loop for n from 0
        for name = (format nil "*U~D" n)
        unless (cador-find-table-record host :block-record name)
          return name))

(defun %entmake-open-block (host pure)
  "ENTMAKE of a (0 . \"BLOCK\") header: open a block-definition run.
Returns the echoed header on success; NIL (the vendor entmake failure
value) when the header names no block. A definition left open by an
interrupted factory (an error between BLOCK and ENDBLK, swallowed by
the caller's *error*) is ABANDONED — its collected entities stay
orphaned under the abandoned name, never registered — so one failed
factory cannot silently break every later one. SPEC-UNCERTAIN: the
vendors' recovery from an abandoned entmake block sequence is not
probed (deferred-spec-research.issue)."
  (let ((name (%data-group-value pure 2))
        (flags (or (%data-group-value pure 70) 0)))
    (when (cador-open-block-definition host)
      (setf (cador-open-block-definition host) nil))
    (cond
      ((not (and (stringp name) (plusp (length name)))) nil)
      (t
       (when (and (integerp flags) (logbitp 0 flags)
                  (string-equal name "*U"))
         (setf name (%allocate-anonymous-block-name host)))
       ;; Redefinition: the new run replaces the old definition — its
       ;; previous contents are erased now, so the entities entmade
       ;; before the ENDBLK are the whole new content.
       (when (cador-find-table-record host :block-record name)
         (loop for handle in (clautolisp.drawing:drawing-creation-order
                              (cador-active-drawing host))
               for entity = (gethash handle (cador-entities host))
               when (and entity
                         (entity-handle-block entity)
                         (string-equal (entity-handle-block entity) name))
                 do (setf (entity-handle-deleted-p entity) t)))
       ;; (NAME HEADER RECORD). The block-record is created NOW and added to
       ;; the table at ENDBLK: ENTMAKEX of the BLOCK must return the block's
       ;; ename at once (measured on AutoCAD and BricsCAD), and it has to be
       ;; the same ename TBLOBJNAME gives once the definition is closed.
       (setf (cador-open-block-definition host)
             (list name pure (make-symbol-table-record :kind :block-record
                                                       :name name :data pure)))
       (pure-data->al-view host pure)))))

(defun %open-block-ename (host)
  "The ename of the block definition being built, or NIL."
  (let ((open (cador-open-block-definition host)))
    (and open (table-record->ename host (third open)))))

(defun %entmake-close-block (host)
  "ENTMAKE of (0 . \"ENDBLK\"): complete the open block definition.
Registers it in the :block-record table and the drawing's block
registry, and returns the block's name (the vendor contract); NIL when
no definition is open."
  (let ((open (cador-open-block-definition host)))
    (and open
         (let ((name (first open))
               (header (second open)))
           (cador-add-table-record host (third open))
           (clautolisp.drawing:add-block (cador-active-drawing host)
                                         name header)
           (setf (cador-open-block-definition host) nil)
           (clautolisp.autolisp-runtime:make-autolisp-string name)))))

(defmethod host-entmake ((host cador) data)
  ;; ENTMAKE returns the entget-style view (the (-1 . ename) head +
  ;; wrapped data) on success, nil on failure. The AutoLISP builtin
  ;; layer decides what the user ultimately sees (see BUILTIN-ENTMAKE).
  ;; BLOCK / ENDBLK are the block-definition pseudo-entities, not
  ;; database entities — see above.
  (let* ((pure (al-data->pure data 'entmake))
         (type (%data-type-string pure)))
    (cond
      ((and type (string-equal type "BLOCK"))
       (%entmake-open-block host pure))
      ((and type (string-equal type "ENDBLK"))
       (%entmake-close-block host))
      (t
       (multiple-value-bind (entity ename) (%host-add-entity host data 'entmake)
         (declare (ignore ename))
         (and entity (entity->al-view host entity)))))))

(defmethod host-entmakex ((host cador) data)
  ;; ENTMAKEX's distinguishing contract: return the new entity's ENAME
  ;; (feedable straight into entget/entmod/entdel), not the DXF list.
  ;; See issues/closed/entmakex-returns-list.issue.
  ;;
  ;; BLOCK / ENDBLK open and close a block definition exactly as ENTMAKE
  ;; does -- MEASURED (probe-results 20261003T124252Z AutoCAD,
  ;; 20261003T124144Z / 124441Z BricsCAD; probes/sources/probe-block-walk.lsp):
  ;;   BLOCK  -> the block's ENAME on both vendors (the one TBLOBJNAME
  ;;             returns once it is closed);
  ;;   members-> their enames, inside the definition;
  ;;   ENDBLK -> NIL on AutoCAD, the block's NAME on BricsCAD -- a
  ;;             divergence, followed per the dialect's product.
  ;; This used to refuse both (nil), so no block was ever defined and the
  ;; members landed in model space.
  (let* ((pure (al-data->pure data 'entmakex))
         (type (%data-type-string pure)))
    (cond
      ((and type (string-equal type "BLOCK"))
       (and (%entmake-open-block host pure)
            (%open-block-ename host)))
      ((and type (string-equal type "ENDBLK"))
       (let ((name (%entmake-close-block host)))
         (and name (%bricscad-dialect-for-entmakex-p) name)))
      (t
       (multiple-value-bind (entity ename) (%host-add-entity host data 'entmakex)
         (declare (ignore entity))
         ename)))))

(defun %bricscad-dialect-for-entmakex-p ()
  (let ((dialect (ignore-errors
                  (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (and dialect
         (eq :bricscad (clautolisp.autolisp-reader:autolisp-dialect-product dialect)))))

;;; --- Divergence D3: ENTMOD on a non-graphical object -----------
;;;
;;; ENTMOD on a non-graphical object (XRECORD, DICTIONARY — an AcDbObject,
;;; not an AcDbEntity) is a NO-OP on real AutoCAD, which DOCUMENTS the
;;; restriction ("Dictionary entry contents cannot be modified through
;;; entmod"); BricsCAD documents and applies the opposite. The
;;; autolisp-spec resolves this divergence in AutoCAD's favour (no-op is
;;; normative; BricsCAD's application is not condoned), so it is gated
;;; exactly like D1 via %RESOLVED-DIVERGENCE-POLICY: normative dialects
;;; (autocad, clautolisp, strict) no-op; deviant/lenient (bricscad, lax)
;;; apply; strict and bricscad warn.

(defun %entmod-target-nongraphical-p (host handle)
  "True iff HANDLE names a live NON-GRAPHICAL object (XRECORD /
DICTIONARY — graphical-p nil in the entity-family registry). The D3
gate predicate: entmod on these is the divergent case."
  (let* ((entity (safe-find-entity (cador-active-drawing host) handle))
         (type   (and entity (%data-type-string (entity-handle-data entity))))
         (family (and type (clautolisp.drawing:find-entity-family type))))
    (and family (not (clautolisp.drawing:entity-family-graphical-p family)))))

(defun emit-entmod-object-divergence-warning (type)
  "Advisory to *ERROR-OUTPUT*: ENTMOD on TYPE (a non-graphical object).
The autolisp-spec (per AutoCAD) specifies entmod does not modify
dictionary/xrecord entry contents — it is a no-op. BricsCAD applies it,
a recognised, non-condoned divergence."
  (format *error-output*
          "~&[entmod-nongraphical] entmod on ~A: the autolisp-spec (per ~
AutoCAD) specifies entmod does not modify a non-graphical object's ~
contents (XRECORD, DICTIONARY) — it is a no-op; such objects are edited ~
via the object protocol (vlax-put) or the dict* functions. BricsCAD ~
applies the change, but that divergence is not portable and not ~
condoned: it is a no-op under autocad, clautolisp and strict.~%"
          type))

(defun %xdata-pair-valid-p (host code value)
  "Whether one xdata pair names something that exists, as the vendors
check on ENTMOD: a 1005 handle must name an object, a 1003 layer name a
layer. Other codes are not checked."
  (let ((string (if (typep value 'clautolisp.autolisp-runtime:autolisp-string)
                    (clautolisp.autolisp-runtime:autolisp-string-value value)
                    value)))
    (cond ((group-code-equal-p code 1005)
           (and (stringp string)
                (safe-find-entity (cador-active-drawing host) string)
                t))
          ((group-code-equal-p code 1003)
           (and (stringp string)
                (cador-find-table-record host :layer string)
                t))
          (t t))))

(defun %vet-entmod-xdata (host pure)
  "Apply the vendors' ENTMOD xdata checks to PURE. Measured
(probes/sources/probe-xdata.lsp, 2026-10-03): AutoCAD REJECTS the whole
ENTMOD -- returns nil, nothing changes -- when a 1005 handle names no
object or a 1003 names no layer. BricsCAD accepts the dangling handle,
and for the missing layer returns the list but silently drops that
application's xdata. Returns PURE (possibly with groups dropped), or
:REJECT."
  (let ((cell (find-if #'xdata-cell-p pure)))
    (if (null cell)
        pure
        (let* ((bricscad (eq :deviant
                             (%resolved-divergence-policy
                              (clautolisp.autolisp-runtime:current-evaluation-dialect-name))))
               (kept '()))
          (dolist (group (cdr cell))
            (let ((bad-handle nil) (bad-layer nil))
              (when (consp group)
                (dolist (pair (cdr group))
                  (when (and (consp pair)
                             (not (%xdata-pair-valid-p host (car pair) (cdr pair))))
                    (if (group-code-equal-p (car pair) 1005)
                        (setf bad-handle t)
                        (setf bad-layer t)))))
              (cond ((and (not bricscad) (or bad-handle bad-layer))
                     (return-from %vet-entmod-xdata :reject))
                    ((and bricscad bad-layer))   ; dropped silently
                    (t (push group kept)))))
          (substitute (cons (car cell) (nreverse kept)) cell pure)))))

(defun %xrecord-marker-position (data)
  (position-if (lambda (pair)
                 (and (consp pair) (group-code-equal-p (car pair) 100)
                      (stringp (cdr pair))
                      (string-equal (cdr pair) "AcDbXrecord")))
               data))

(defun %bricscad-xrecord-drop-explicit-280 (supplied normalised)
  "BricsCAD V25 / V26 (MEASURED 2026-10-08, probe-entget-pointers.lsp, jobs
17026569912 / 17026569913): an XRECORD entmade with an explicit 280 right
after (100 . \"AcDbXrecord\") reads back with NO 280 at all -- the pair
is consumed as the cloning flag and not listed -- while one entmade without
it reads back with (280 . 1). AutoCAD lists the supplied value. Returns
NORMALISED without that 280 when SUPPLIED (the pure create data) had one."
  (let ((type (%data-type-string supplied))
        (marker (%xrecord-marker-position supplied)))
    (if (and type (string-equal type "XRECORD") marker
             (let ((next (nth (1+ marker) supplied)))
               (and (consp next) (group-code-equal-p (car next) 280))))
        (let ((at (%xrecord-marker-position normalised)))
          (if at
              (append (subseq normalised 0 (1+ at))
                      (nthcdr (+ 2 at) normalised))
              normalised))
        normalised)))

(defmethod host-entmod ((host cador) data)
  (%vet-pointer-groups data 'entmod)
  (let* ((handle (extract-modified-handle data 'entmod host))
         (pure (%vet-entmod-xdata host (al-data->pure data 'entmod)))
         (drawing (cador-active-drawing host)))
    (when (eq pure :reject)
      (return-from host-entmod nil))
    ;; D3: entmod on a non-graphical object diverges — AutoCAD (normative)
    ;; no-ops, BricsCAD (deviant) applies. Apply the resolved policy first.
    (when (%entmod-target-nongraphical-p host handle)
      (multiple-value-bind (action warn-p)
          (%resolved-divergence-policy
           (clautolisp.autolisp-runtime:current-evaluation-dialect-name))
        (when warn-p
          (emit-entmod-object-divergence-warning
           (or (%data-type-string pure) "the object")))
        (when (eq action :normative)
          (return-from host-entmod nil))))         ; no-op
    (let ((entity (handler-case (clautolisp.drawing:modify-entity drawing handle pure)
                    (clautolisp.drawing:drawing-error () nil))))
      (when entity
        (let ((document (current-document))
              (ename (handle->ename host handle)))
          (clautolisp.autolisp-runtime:signal-document-event
           document :acdb :vlr-objectmodified (list ename))
          (clautolisp.autolisp-runtime:signal-document-event
           document :object :vlr-modified (list ename)))
        (entity->al-view host entity)))))

(defmethod host-entdel ((host cador) ename)
  (let* ((handle (ename->handle ename 'entdel host))
         (drawing (cador-active-drawing host))
         (entity (safe-find-entity drawing handle :include-deleted t)))
    (when entity
      ;; AutoLISP's entdel is a toggle: a second call undeletes.
      (let ((now (setf (clautolisp.drawing:entity-deleted-status drawing handle)
                       (not (clautolisp.drawing:entity-deleted-status
                             drawing handle))))
            (document (current-document)))
        (let ((event (if now :vlr-objecterased :vlr-objectunerased)))
          (clautolisp.autolisp-runtime:signal-document-event
           document :acdb event (list ename))
          (clautolisp.autolisp-runtime:signal-document-event
           document :object event (list ename))))
      ename)))

(defmethod host-entupd ((host cador) ename)
  (let* ((handle (ename->handle ename 'entupd host)))
    (and (safe-find-entity (cador-active-drawing host) handle)
         ename)))

(defmethod host-entlast ((host cador))
  ;; Most recently created main-space MAIN entity that is not deleted:
  ;; block-definition contents are never entlast, and neither are
  ;; subentities (ATTRIB / VERTEX / SEQEND) — the vendor contract, so
  ;; (entlast) after an attribute-bearing insert names the INSERT.
  ;; creation-order is newest-first.
  (let ((drawing (cador-active-drawing host)))
    (loop for handle in (clautolisp.drawing:drawing-creation-order drawing)
          for entity = (clautolisp.drawing:find-entity drawing handle)
          when (and entity
                    (main-space-entity-p entity)
                    (not (member (entity-handle-kind entity)
                                 '(:attrib :vertex :seqend))))
            return (handle->ename host handle)
          finally (return nil))))

(defun %entity-container-key (entity)
  "The container an ENTITY-HANDLE lives in, for the entnext walk:
:MAIN for model / paper space, the upcased block name for
block-definition contents."
  (if (main-space-entity-p entity)
      :main
      (string-upcase (entity-handle-block entity))))

(defun %find-table-record-by-id (host id)
  "The SYMBOL-TABLE-RECORD (any kind) whose id matches ID (an ename
value from tblobjname), or NIL."
  (let ((found nil))
    (maphash (lambda (kind table)
               (declare (ignore kind))
               (maphash (lambda (name record)
                          (declare (ignore name))
                          (when (string= (string (symbol-table-record-id record))
                                         (string id))
                            (setf found record)))
                        table))
             (cador-tables host))
    found))

(defun %find-block-record-by-id (host id)
  "The :block-record SYMBOL-TABLE-RECORD whose id matches ID (an ename
value from tblobjname), or NIL."
  (let ((record (%find-table-record-by-id host id)))
    (and record
         (eq (symbol-table-record-kind record) :block-record)
         record)))

(defmethod host-entnext ((host cador) ename)
  ;; (entnext)       -> first non-deleted main-space entity, or nil.
  ;; (entnext ENAME) -> next non-deleted entity in the SAME container
  ;;                    (main space, or the same block definition).
  ;; (entnext TBL)   -> TBL a block table-record ename (tblobjname
  ;;                    "BLOCK" name): the block's first entity — the
  ;;                    canonical ATTDEF walk. SPEC-UNCERTAIN: whether
  ;;                    the vendor walk ends on an ENDBLK entity; the
  ;;                    cador stores none and returns nil after the last
  ;;                    owned entity (deferred-spec-research.issue).
  (let* ((drawing (cador-active-drawing host))
         (order (reverse (clautolisp.drawing:drawing-creation-order drawing))))
    (flet ((first-live-in (handles container)
             (loop for handle in handles
                   for entity = (clautolisp.drawing:find-entity drawing handle)
                   when (and entity
                             (equal container (%entity-container-key entity)))
                     return (handle->ename host handle)
                   finally (return nil))))
      (if (null ename)
          (first-live-in order :main)
          (let* ((needle (ename->handle ename 'entnext host))
                 ;; A table-record ename's value is not an entity
                 ;; handle (hex string) — don't feed it to the entity
                 ;; lookup, fall through to the block-record branch.
                 (entity (and (or (stringp needle) (integerp needle))
                              (safe-find-entity drawing needle
                                                :include-deleted t))))
            (if entity
                (first-live-in (rest (member needle order :test #'string=))
                               (%entity-container-key entity))
                (let ((record (%find-block-record-by-id host needle)))
                  (and record
                       (first-live-in
                        order
                        (string-upcase (symbol-table-record-name record)))))))))))

(defmethod host-handent ((host cador) handle-string)
  (let ((value
         (etypecase handle-string
           (string handle-string)
           (clautolisp.autolisp-runtime:autolisp-string
            (clautolisp.autolisp-runtime:autolisp-string-value handle-string)))))
    (and (safe-find-entity (cador-active-drawing host) value)
         (handle->ename host value))))
