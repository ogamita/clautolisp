(in-package #:clautolisp.cadtui)

;;;; Addressing: find-node and absolute-path target resolution (Phase 1 slice 3).
;;;;
;;;; Targets are addressed by ABSOLUTE paths from /application (spec §5.2):
;;;;   chemin  ::= "/" segment ("/" segment)*
;;;;   segment ::= role ":" cle | role "[" indice "]" | mot-cle
;;;; A segment is one of:
;;;;   - role:cle       one child with that (singular) role and key, e.g.
;;;;                    entite:deadface, poignee:2, menu:Dessiner
;;;;   - role[indice]   the indice-th (1-based) child of a role, addressed by the
;;;;                    container's plural name, e.g. dessins[2], alertes[1]
;;;;   - a keyword      application (the root), dessin-actif (= dessins[1]),
;;;;                    or a bare node name matched by key or role (e.g. console,
;;;;                    vue-cad)
;;;; Addressing never depends on the keyboard focus — a path resolves the same
;;;; whatever window is active (spec §5 principles 1-2). Deferred to Phase 2:
;;;; the D<n>.cle relative references, a bare key resolved in the last dump, and
;;;; the vue / selection-active shortcut keywords.

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
  '(("dessins"      . :dessin)
    ("bandeaux"     . :bandeau)
    ("boutons"      . :bouton)
    ("onglets"      . :onglet)
    ("panneaux"     . :panneau)
    ("menus-locaux" . :menu)
    ("menus"        . :menu)
    ("items"        . :item)
    ("entites"      . :entite)
    ("poignees"     . :poignee)
    ("alertes"      . :alerte)
    ("dialogues"    . :dialogue)
    ("tuiles"       . :tuile))
  "Maps a container's plural path name (as used in ROLE[indice]) to the singular
role keyword of the children it holds.")

(defun %role-keyword (role-string)
  "The role keyword named by ROLE-STRING (case-insensitive), e.g. \"entite\" =>
:ENTITE, \"vue-cad\" => :VUE-CAD."
  (intern (string-upcase role-string) :keyword))

(defun %role-name (node)
  "NODE's role rendered as a lowercase string, e.g. :dessin => \"dessin\"."
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
  "Resolve the keyword segments handled in Phase 1: dessin-actif (the first
:dessin child). Returns a node or NIL when SEGMENT is not such a keyword."
  (declare (ignore path))
  (when (string-equal segment "dessin-actif")
    (or (find :dessin (ui-children node) :key #'ui-role)
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
      ;; a Phase-1 keyword (dessin-actif).
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

(defun resolve-target (root path)
  "Resolve the absolute PATH (from /application) to a node under ROOT, or signal
TARGET-NOT-FOUND / AMBIGUOUS-TARGET. PATH must start with \"/\"; a relative or
D<n> reference is deferred to Phase 2 and reported as not found."
  (unless (and (plusp (length path)) (char= (char path 0) #\/))
    (error 'target-not-found :path path :segment path))
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
