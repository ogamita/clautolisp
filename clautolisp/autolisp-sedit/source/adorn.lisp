;;;; clautolisp/autolisp-sedit/source/adorn.lisp
;;;;
;;;; The adorned-tree domain (sedit spec §6.1). Structure (atoms, lists,
;;;; comments, files, directories) is kept separate from the ADORNMENT α —
;;;; newlines, attached comments, column info — which carries formatting
;;;; without affecting structure or equality. Phase 1 threads α opaquely; the
;;;; Phase 3 pretty-printer is what fills it in and reproduces the source text.

(in-package #:clautolisp.sedit)

;;; Nodes share a NODE base carrying the adornment; every concrete node is one
;;; of the five domain shapes. BOA constructors keep call sites terse.

(defstruct (node (:constructor nil))    ; abstract: never instantiated directly
  (adornment nil))

(defstruct (atom-node (:include node)
                      (:constructor make-atom-node (value &key adornment)))
  ;; a Lisp datum: symbol, number, string, …
  value)

(defstruct (list-node (:include node)
                      (:constructor make-list-node (children &key adornment)))
  (children '() :type list))            ; ordered child NODES

(defstruct (comment-node (:include node)
                         (:constructor make-comment-node (text &key adornment)))
  (text "" :type string))

(defstruct (file-node (:include node)
                      (:constructor make-file-node (name children &key adornment modified)))
  name                                  ; namestring / pathname
  (children '() :type list)             ; top-level forms + comments
  ;; §6.3: a mutation inside a File marks it modified, driving save-on-leave.
  (modified nil))

(defstruct (dir-node (:include node)
                     (:constructor make-dir-node (name entries &key adornment)))
  name
  (entries '() :type list))             ; files + sub-dirs (+ ".." pseudo-entry)

;;; --- uniform access over branch nodes (List / File / Dir) -----------------

(defun branch-node-p (node)
  "True when NODE has descendable children (a list, file, or directory)."
  (typecase node
    (list-node t)
    (file-node t)
    (dir-node t)
    (t nil)))

(defun node-children (node)
  "NODE's ordered children, or NIL for a leaf (atom / comment)."
  (typecase node
    (list-node (list-node-children node))
    (file-node (file-node-children node))
    (dir-node (dir-node-entries node))
    (t nil)))

(defun node-with-children (node children)
  "A structure-preserving copy of branch NODE with its children replaced by
CHILDREN (adornment and labels — name, modified — kept). Signals for a leaf.
This is the zipper's PLATE: it never marks a File modified (that is a mutation's
job, not navigation's)."
  (typecase node
    (list-node (make-list-node children :adornment (node-adornment node)))
    (file-node (make-file-node (file-node-name node) children
                               :adornment (node-adornment node)
                               :modified (file-node-modified node)))
    (dir-node (make-dir-node (dir-node-name node) children
                             :adornment (node-adornment node)))
    (t (error "node-with-children: ~S is a leaf and has no children" node))))

(defun node-level-of-children (node)
  "The level tag of NODE's children (spec §6.2 level tags): a list's children
are :sexp, a file's are :form, a directory's are :file. NIL for a leaf."
  (typecase node
    (list-node :sexp)
    (file-node :form)
    (dir-node :file)
    (t nil)))

;;; --- plain sexp <-> adorned tree (construction + structural comparison) ---

(defun sexp->tree (x)
  "Build an adorned tree of atoms and lists from a plain Lisp sexp X (proper
lists only). Adornment is left empty; used to seed editing and tests."
  (if (consp x)
      (make-list-node (mapcar #'sexp->tree x))
      (make-atom-node x)))

(defun tree->sexp (node)
  "The plain Lisp sexp NODE denotes, dropping adornment. Inverse of SEXP->TREE on
comment-free code trees; used for structural comparison. Comment nodes yield NIL
and File/Dir map to the sexp list of their children."
  (typecase node
    (atom-node (atom-node-value node))
    (list-node (mapcar #'tree->sexp (list-node-children node)))
    (comment-node nil)
    (file-node (mapcar #'tree->sexp (file-node-children node)))
    (dir-node (mapcar #'tree->sexp (dir-node-entries node)))
    (t node)))
