;;;; clautolisp/autolisp-sedit/source/adorn.lisp
;;;;
;;;; The adorned-tree domain (sedit spec §6.1). Structure (atoms, lists,
;;;; comments, files, directories) is kept separate from the ADORNMENT α —
;;;; newlines, attached comments, column info — which carries formatting
;;;; without affecting structure or equality. Phase 1 threads α opaquely; the
;;;; Phase 3 pretty-printer is what fills it in and reproduces the source text.

(in-package #:clautolisp.sedit)

;;; The adornment α (Phase 3): the formatting a node carries without affecting
;;; its structure. TEXT is the node's verbatim source slice — its presence makes
;;; printing byte-preserving (unparse emits it as-is); the source position is
;;; kept for reference. A mutation drops the adornment of every rebuilt node
;;; (its text is stale), so an edited subtree re-lays-out from the indent rules
;;; while untouched subtrees keep their exact source.

(defstruct (adornment (:constructor make-adornment
                          (&key text file start-line start-col end-line end-col)))
  text                                  ; the node's verbatim source, or NIL
  file start-line start-col end-line end-col)

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
CHILDREN, keeping the labels (name, modified) but DROPPING the adornment: once
the children change, the node's verbatim text is stale, so a rebuilt node
re-lays-out from the indent rules (§6.7). Signals for a leaf. This is the
zipper's PLATE; it never marks a File modified (that is a mutation's job, not
navigation's), and LOC-UP keeps the original node — text intact — when the
children are unchanged."
  (typecase node
    (list-node (make-list-node children))
    (file-node (make-file-node (file-node-name node) children
                               :modified (file-node-modified node)))
    (dir-node (make-dir-node (dir-node-name node) children))
    (t (error "node-with-children: ~S is a leaf and has no children" node))))

(defun node-text (node)
  "NODE's verbatim source text if known (byte-preserving printing), else NIL. A
comment's text is its own content string; other nodes carry it in the adornment."
  (typecase node
    (comment-node (comment-node-text node))
    (t (let ((a (node-adornment node))) (and a (adornment-text a))))))

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
  "The plain Lisp sexp NODE denotes, dropping adornment and comments. Inverse of
SEXP->TREE on comment-free code trees; used for structural comparison. Comment
children are skipped (they are structure but carry no sexp value); a lone comment
node yields NIL; File/Dir map to the sexp list of their non-comment children."
  (typecase node
    (atom-node (atom-node-value node))
    (list-node (mapcar #'tree->sexp (remove-if #'comment-node-p (list-node-children node))))
    (comment-node nil)
    (file-node (mapcar #'tree->sexp (remove-if #'comment-node-p (file-node-children node))))
    (dir-node (mapcar #'tree->sexp (dir-node-entries node)))
    (t node)))
