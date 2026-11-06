(in-package #:clautolisp.cadtui)

;;;; Addressing: find-node and absolute-path target resolution (Phase 1 slice 3).
;;;;
;;;; Targets are addressed by ABSOLUTE paths from /application (spec §5.2):
;;;;   chemin  ::= "/" segment ("/" segment)*
;;;;   segment ::= role ":" cle | role "[" indice "]" | mot-cle
;;;; A segment is one of:
;;;;   - role:cle       one child with that (singular) role and key, e.g.
;;;;                    entity:deadface, grip:2, menu:Draw
;;;;   - role[indice]   the indice-th (1-based) child of a role, addressed by the
;;;;                    container's plural name, e.g. drawings[2], alerts[1]
;;;;   - a keyword      application (the root), active-drawing (= drawings[1]),
;;;;                    or a bare node name matched by key or role (e.g. console,
;;;;                    cad-view)
;;;; Tokens are canonical English; the spec §5.2 writes the fr_FR view, which a
;;;; locale layer (Phase 7, gated on LANG) maps to these. Addressing never
;;;; depends on the keyboard focus — a path resolves the same whatever window is
;;;; active (spec §5 principles 1-2). Deferred to Phase 2: the D<n>.cle relative
;;;; references, a bare key resolved in the last dump, and the view /
;;;; active-selection shortcut keywords.

;;; --- Conditions ---------------------------------------------------

(define-condition target-not-found (cadtui-error)
  ((path    :initarg :path    :reader target-not-found-path)
   (segment :initarg :segment :reader target-not-found-segment))
  (:report (lambda (condition stream)
             (format stream "No target ~S: segment ~S did not resolve."
                     (target-not-found-path condition)
                     (target-not-found-segment condition))))
  (:documentation "Signalled when an address names no node."))

(define-condition ambiguous-target (cadtui-error)
  ((path       :initarg :path       :reader ambiguous-target-path)
   (segment    :initarg :segment    :reader ambiguous-target-segment)
   (candidates :initarg :candidates :reader ambiguous-target-candidates))
  (:report (lambda (condition stream)
             (format stream "Ambiguous target ~S: segment ~S matches ~D nodes ~
(keys: ~{~S~^, ~})."
                     (ambiguous-target-path condition)
                     (ambiguous-target-segment condition)
                     (length (ambiguous-target-candidates condition))
                     (mapcar #'ui-key (ambiguous-target-candidates condition)))))
  (:documentation "Signalled when an address segment matches more than one node
— the report lists the candidate keys so the caller can disambiguate."))

;;; --- find-node ----------------------------------------------------

(defun find-node (root predicate)
  "The first node in the subtree at ROOT (ROOT itself included, depth-first) for
which PREDICATE returns true, or NIL when none matches."
  (if (funcall predicate root)
      root
      (some (lambda (child) (find-node child predicate))
            (ui-children root))))

;;; --- Segment resolution -------------------------------------------

(defparameter *container-role-map*
  '(("drawings"      . :drawing)
    ("bands"         . :band)
    ("buttons"       . :button)
    ("ribbon-tabs"   . :ribbon-tab)
    ("ribbon-panels" . :ribbon-panel)
    ("local-menus"   . :menu)
    ("menus"         . :menu)
    ("items"         . :item)
    ("entities"      . :entity)
    ("grips"         . :grip)
    ("alerts"        . :alert)
    ("dialogs"       . :dialog)
    ("tiles"         . :tile))
  "Maps a container's plural path name (as used in ROLE[indice]) to the singular
role keyword of the children it holds. Canonical English (a locale layer maps
localised plurals to these).")

(defun %role-keyword (role-string)
  "The role keyword named by ROLE-STRING (case-insensitive), e.g. \"entity\" =>
:ENTITY, \"cad-view\" => :CAD-VIEW."
  (intern (string-upcase role-string) :keyword))

(defun %role-name (node)
  "NODE's role rendered as a lowercase string, e.g. :drawing => \"drawing\"."
  (string-downcase (symbol-name (ui-role node))))

(defun %indexed-segment (segment)
  "If SEGMENT is NAME[INDEX], return (values NAME INDEX); otherwise (values nil
nil). INDEX is a 1-based integer."
  (let ((open (position #\[ segment)))
    (if (and open (char= (char segment (1- (length segment))) #\]))
        (let ((name (subseq segment 0 open))
              (index (ignore-errors
                      (parse-integer segment :start (1+ open)
                                             :end (1- (length segment))))))
          (values name index))
        (values nil nil))))

(defun %resolve-keyword-segment (node segment path)
  "Resolve the keyword segments handled in Phase 1: active-drawing (the first
:drawing child). Returns a node or NIL when SEGMENT is not such a keyword."
  (declare (ignore path))
  (when (string-equal segment "active-drawing")
    (or (find :drawing (ui-children node) :key #'ui-role)
        :none)))       ; :none => a keyword that matched but has no target

(defun %bare-candidates (node segment)
  "Children of NODE addressable by the bare SEGMENT: those whose key prints as
SEGMENT or whose role name is SEGMENT, de-duplicated."
  (remove-duplicates
   (loop for child in (ui-children node)
         when (or (string= segment (princ-to-string (ui-key child)))
                  (string-equal segment (%role-name child)))
           collect child)))

(defun resolve-segment (node segment path)
  "Resolve one path SEGMENT relative to NODE and return the child it names.
Signals TARGET-NOT-FOUND / AMBIGUOUS-TARGET (carrying PATH) on failure."
  (multiple-value-bind (name index) (%indexed-segment segment)
    (cond
      ;; role[indice] — the index-th (1-based) child of a role.
      (name
       (let* ((role (or (cdr (assoc name *container-role-map* :test #'string=))
                        (%role-keyword name)))
              (matches (remove role (ui-children node)
                               :key #'ui-role :test-not #'eq)))
         (if (and index (<= 1 index (length matches)))
             (nth (1- index) matches)
             (error 'target-not-found :path path :segment segment))))
      ;; role:cle — the child with that role and key.
      ((position #\: segment)
       (let* ((colon (position #\: segment))
              (role (%role-keyword (subseq segment 0 colon)))
              (key (subseq segment (1+ colon)))
              (child (find-if (lambda (c)
                                (and (eq role (ui-role c))
                                     (string= key (princ-to-string (ui-key c)))))
                              (ui-children node))))
         (or child (error 'target-not-found :path path :segment segment))))
      ;; a Phase-1 keyword (active-drawing).
      (t
       (let ((kw (%resolve-keyword-segment node segment path)))
         (cond
           ((eq kw :none) (error 'target-not-found :path path :segment segment))
           (kw kw)
           ;; a bare node name matched by key or role.
           (t (let ((candidates (%bare-candidates node segment)))
                (cond
                  ((null candidates)
                   (error 'target-not-found :path path :segment segment))
                  ((rest candidates)
                   (error 'ambiguous-target :path path :segment segment
                                            :candidates candidates))
                  (t (first candidates)))))))))))

;;; --- Absolute-path resolution -------------------------------------

(defun %split-segments (path)
  "The non-empty \"/\"-separated segments of PATH."
  (let ((segments '()) (start 0) (len (length path)))
    (loop
      (let* ((slash (position #\/ path :start start))
             (segment (subseq path start (or slash len))))
        (unless (string= segment "") (push segment segments))
        (if slash (setf start (1+ slash)) (return))))
    (nreverse segments)))

(defun %resolve-absolute-path (root path)
  "Resolve an absolute /application PATH under ROOT."
  (let ((segments (%split-segments path)))
    (when (null segments)
      (error 'target-not-found :path path :segment path))
    ;; The first segment names the root itself (application, or the root's own
    ;; key / role).
    (let ((head (first segments)))
      (unless (or (string-equal head "application")
                  (string= head (princ-to-string (ui-key root)))
                  (string-equal head (%role-name root)))
        (error 'target-not-found :path path :segment head)))
    (let ((node root))
      (dolist (segment (rest segments) node)
        (setf node (resolve-segment node segment path))))))

;;; --- Relative references: D<n>.cle and bare-key-in-last-dump ------
;;;
;;; A dump gets an increasing D<n> id; any key it showed stays addressable by
;;; D<n>.cle even after other dumps or window switches (spec §5.2 lines 418-423).
;;; A bare key (no path, no D<n>) resolves in the LAST dump if unique there
;;; (lines 424-426).

(defun %split-dots (s)
  "The non-empty \".\"-separated parts of S."
  (let ((parts '()) (start 0) (len (length s)))
    (loop
      (let* ((dot (position #\. s :start start))
             (part (subseq s start (or dot len))))
        (unless (string= part "") (push part parts))
        (if dot (setf start (1+ dot)) (return))))
    (nreverse parts)))

(defun %parse-d-reference (path)
  "If PATH is D<integer>.cle(.cle)*, return (values NUMBER (cle ...)); else NIL."
  (when (and (> (length path) 1) (char-equal (char path 0) #\D))
    (let ((dot (position #\. path)))
      (when dot
        (let ((number (ignore-errors (parse-integer path :start 1 :end dot))))
          (when number
            (values number (%split-dots (subseq path (1+ dot))))))))))

(defun %split-trailing-integer (s)
  "If S is NAME<digits> with a non-empty NAME, return (values NAME INTEGER);
else (values nil nil). E.g. \"grip2\" => (values \"grip\" 2)."
  (let ((pos (length s)))
    (loop while (and (> pos 0) (digit-char-p (char s (1- pos)))) do (decf pos))
    (if (and (< pos (length s)) (> pos 0))
        (values (subseq s 0 pos) (parse-integer s :start pos))
        (values nil nil))))

(defun %resolve-in-dump (descriptor cle path)
  "Resolve the key CLE within DESCRIPTOR's recorded entries: unique -> node;
several -> AMBIGUOUS-TARGET; none -> TARGET-NOT-FOUND."
  (let ((nodes (remove-duplicates
                (loop for (k . node) in (dump-descriptor-entries descriptor)
                      when (string= k cle) collect node))))
    (cond
      ((null nodes) (error 'target-not-found :path path :segment cle))
      ((rest nodes) (error 'ambiguous-target :path path :segment cle
                                             :candidates nodes))
      (t (first nodes)))))

(defun %resolve-dotted-key (node cle path)
  "Resolve a further CLE of a D<n> reference within NODE's subtree: an exact
bare-key descendant first, else a NAME<digits> split naming the digits-th child
of role NAME (e.g. grip2 = the 2nd grip child)."
  (or (find-node node (lambda (n)
                        (and (not (eq n node))
                             (string= cle (princ-to-string (ui-key n))))))
      (multiple-value-bind (name index) (%split-trailing-integer cle)
        (when (and name index)
          (let ((matches (remove (%role-keyword name) (ui-children node)
                                  :key #'ui-role :test-not #'eq)))
            (when (<= 1 index (length matches))
              (nth (1- index) matches)))))
      (error 'target-not-found :path path :segment cle)))

(defun %resolve-d-reference (number keys path)
  (let ((descriptor (find-dump number)))
    (unless descriptor
      (error 'target-not-found :path path :segment (format nil "D~D" number)))
    (when (null keys)
      (error 'target-not-found :path path :segment path))
    (let ((node (%resolve-in-dump descriptor (first keys) path)))
      (dolist (cle (rest keys) node)
        (setf node (%resolve-dotted-key node cle path))))))

(defun %relative-segment-p (path)
  "True when PATH is a single relative segment naming a child of the root — a
role[i], a role:cle, or the active-drawing keyword (spec verb examples, e.g.
activate(drawings[2])). A plain bare key (no [ or :) is NOT one: it resolves in
the last dump."
  (or (find #\[ path)
      (find #\: path)
      (string-equal path "active-drawing")))

;;; --- General dotted-relative addressing ---------------------------
;;;
;;; A dotted address is either root-relative (drawings[1].cad-view.grips[2]) or
;;; last-dump-relative (<key>.<cle>..., e.g. an entity handle then a grip). Both
;;; must not swallow a dotted KEY (drawing filenames are keys with dots, e.g.
;;; plan.dwg): so the last-dump form tries the WHOLE string as one key first,
;;; and the root-relative form only fires when the first dotted part is itself a
;;; relative segment (role[i]/active-drawing) and no ':' segment is present.

(defun %root-dotted-p (path)
  "True when PATH is a root-relative dotted chain: it has a dot, no ':' (so no
role:cle segment whose dotted key we might split), several parts, and its first
part is a relative segment naming a child of the root."
  (and (find #\. path)
       (not (find #\: path))
       (let ((parts (%split-dots path)))
         (and (rest parts) (%relative-segment-p (first parts))))))

(defun %resolve-root-dotted (root path)
  "Resolve a root-relative dotted chain (each part a segment of the previous
node), starting from ROOT."
  (let ((node root))
    (dolist (part (%split-dots path) node)
      (setf node (resolve-segment node part path)))))

(defun %resolve-last-dump-dotted (descriptor path)
  "Resolve PATH against the last DESCRIPTOR: the WHOLE string as one key first
(so a dotted key like a filename resolves), else a dotted chain — the first part
a key in the dump, each further part a dotted-key step into that node's subtree."
  (let ((whole (ignore-errors (%resolve-in-dump descriptor path path))))
    (if whole
        whole
        (let ((parts (%split-dots path)))
          (if (rest parts)
              (let ((node (%resolve-in-dump descriptor (first parts) path)))
                (dolist (cle (rest parts) node)
                  (setf node (%resolve-dotted-key node cle path))))
              ;; single part that missed: re-signal the proper condition.
              (%resolve-in-dump descriptor path path))))))

(defun resolve-target (root path)
  "Resolve PATH to a node under ROOT, or signal TARGET-NOT-FOUND /
AMBIGUOUS-TARGET. PATH is an absolute /application path, a D<n>.cle relative
reference (against a recorded dump), a single relative segment naming a child of
the root (role[i] / role:cle / active-drawing), or a bare key (resolved in the
last dump)."
  (cond
    ((zerop (length path))
     (error 'target-not-found :path path :segment path))
    ((char= (char path 0) #\/)
     (%resolve-absolute-path root path))
    (t
     (multiple-value-bind (number keys) (%parse-d-reference path)
       (cond
         (number (%resolve-d-reference number keys path))
         ;; a root-relative dotted chain, e.g. drawings[1].cad-view.grips[2].
         ((%root-dotted-p path) (%resolve-root-dotted root path))
         ;; a single relative segment resolved against the root.
         ((%relative-segment-p path) (resolve-segment root path path))
         ;; a bare key (or a dotted key/chain) resolved in the last dump.
         (t (let ((descriptor *last-dump*))
              (unless descriptor
                (error 'target-not-found :path path :segment path))
              (%resolve-last-dump-dotted descriptor path))))))))
