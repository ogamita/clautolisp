(in-package #:clautolisp.cador)

;;;; Entity-level HAL methods for MockHost.
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
              (clautolisp.autolisp-runtime:make-autolisp-ename :value handle)))))

(defun ename->handle (ename operator-name)
  "Extract the hex handle string from an AutoLISP ENAME, signalling
an :invalid-ename runtime error if ENAME is not an ename."
  (unless (typep ename 'clautolisp.autolisp-runtime:autolisp-ename)
    (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
     :invalid-ename
     "~A expects an ENAME, got ~S."
     operator-name ename))
  (clautolisp.autolisp-runtime:autolisp-ename-value ename))

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
(Enames are reconstructed only for the -1 head, by ENTITY->AL-VIEW.)"
  (typecase value
    (string (clautolisp.autolisp-runtime:make-autolisp-string value))
    (cons (cons (pure->al-value (car value)) (pure->al-value (cdr value))))
    (t value)))

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
     (mapcar (lambda (pair)
               (if (consp pair)
                   (cons (car pair) (pure->al-value (cdr pair)))
                   pair))
             ordinary)
     (when kept
       (list (cons -3 (pure->al-value kept)))))))

(defun extract-modified-handle (data operator-name)
  "Return the hex handle of the entity DATA refers to, from its
(-1 . <ENAME>) entry, signalling :invalid-entity-data if missing."
  (dolist (pair data)
    (when (and (consp pair) (group-code-equal-p (car pair) -1)
               (typep (cdr pair) 'clautolisp.autolisp-runtime:autolisp-ename))
      (return-from extract-modified-handle
        (clautolisp.autolisp-runtime:autolisp-ename-value (cdr pair)))))
  (clautolisp.autolisp-runtime:signal-autolisp-runtime-error
   :invalid-entity-data
   "~A requires the modified entity's (-1 . <ENAME>) entry in the data list."
   operator-name))

;;; --- Compatibility helpers (kept; used by selection-api etc.) ----

(defun cador-allocate-handle (mock)
  "Allocate the next hex handle string for MOCK's active drawing and
bump its seed. Retained for API compatibility; the entity methods now
let clautolisp.drawing:ADD-ENTITY allocate internally."
  (format nil "~X" (clautolisp.drawing:allocate-handle
                    (cador-active-drawing mock))))

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

(defun cador-find-entity-by-handle (mock handle)
  "Return the live ENTITY-HANDLE stored under HANDLE, or nil if no
such entity exists or it has been deleted."
  (safe-find-entity (cador-active-drawing mock) handle))

(defun current-document ()
  (clautolisp.autolisp-runtime:evaluation-context-current-document
   (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- Host method implementations ---------------------------------

(defmethod host-entget ((host cador) ename &optional applist)
  (let* ((handle (ename->handle ename 'entget))
         (entity (safe-find-entity (cador-active-drawing host) handle)))
    (and entity (entity->al-view host entity applist))))

(defun %data-type-string (data)
  "The (0 . TYPE) string of the pure group-code list DATA, or NIL."
  (dolist (pair data nil)
    (when (and (consp pair) (group-code-equal-p (car pair) 0) (stringp (cdr pair)))
      (return (cdr pair)))))

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
  (case dialect-name
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

(defun %host-add-entity (host data operator-name)
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
  (let* ((pure (al-data->pure data operator-name))
         (drawing (cador-active-drawing host))
         (missing-markers (clautolisp.drawing:entity-dxf-missing-markers pure)))
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
      (if (null normalised)
          (values nil nil)
          (let* ((owned (%link-subentity-owner host normalised))
                 (entity (handler-case
                             (clautolisp.drawing:add-entity drawing owned)
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

(defmethod host-entmake ((host cador) data)
  ;; ENTMAKE returns the entget-style view (the (-1 . ename) head +
  ;; wrapped data) on success, nil on failure. The AutoLISP builtin
  ;; layer decides what the user ultimately sees (see BUILTIN-ENTMAKE).
  (multiple-value-bind (entity ename) (%host-add-entity host data 'entmake)
    (declare (ignore ename))
    (and entity (entity->al-view host entity))))

(defmethod host-entmakex ((host cador) data)
  ;; ENTMAKEX's distinguishing contract: return the new entity's ENAME
  ;; (feedable straight into entget/entmod/entdel), not the DXF list.
  ;; See issues/closed/entmakex-returns-list.issue.
  (multiple-value-bind (entity ename) (%host-add-entity host data 'entmakex)
    (declare (ignore entity))
    ename))

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

(defmethod host-entmod ((host cador) data)
  (let* ((handle (extract-modified-handle data 'entmod))
         (pure (al-data->pure data 'entmod))
         (drawing (cador-active-drawing host)))
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
  (let* ((handle (ename->handle ename 'entdel))
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
  (let* ((handle (ename->handle ename 'entupd)))
    (and (safe-find-entity (cador-active-drawing host) handle)
         ename)))

(defmethod host-entlast ((host cador))
  ;; Most recently created entity that is not deleted. creation-order
  ;; is newest-first.
  (let ((drawing (cador-active-drawing host)))
    (loop for handle in (clautolisp.drawing:drawing-creation-order drawing)
          when (clautolisp.drawing:find-entity drawing handle)
            return (handle->ename host handle)
          finally (return nil))))

(defmethod host-entnext ((host cador) ename)
  ;; (entnext)       -> first non-deleted entity, or nil.
  ;; (entnext ENAME) -> next non-deleted entity after ENAME, or nil.
  (let* ((drawing (cador-active-drawing host))
         (order (reverse (clautolisp.drawing:drawing-creation-order drawing))))
    (flet ((first-live (handles)
             (loop for handle in handles
                   when (clautolisp.drawing:find-entity drawing handle)
                     return (handle->ename host handle)
                   finally (return nil))))
      (if (null ename)
          (first-live order)
          (let* ((needle (ename->handle ename 'entnext))
                 (tail (member needle order :test #'string=)))
            (first-live (rest tail)))))))

(defmethod host-handent ((host cador) handle-string)
  (let ((value
         (etypecase handle-string
           (string handle-string)
           (clautolisp.autolisp-runtime:autolisp-string
            (clautolisp.autolisp-runtime:autolisp-string-value handle-string)))))
    (and (safe-find-entity (cador-active-drawing host) value)
         (handle->ename host value))))
