;;;; clautolisp/autolisp-sedit/source/zipper.lisp
;;;;
;;;; The Huet zipper (sedit spec §6.2). A LOC is (focus, ctx): FOCUS is the
;;;; selected node, CTX is the path back to the root (NIL at the root). Each CTX
;;;; frame keeps the PARENT branch node (its children slot refilled by PLATE on
;;;; ascent), the LEFT siblings (reversed — nearest first) and the RIGHT siblings
;;;; (in order). Motions are O(1) and share every untouched subtree, which is
;;;; what makes the one-slot undo of Phase 2 an O(1) snapshot.

(in-package #:clautolisp.sedit)

(defstruct (ctx (:constructor make-ctx (parent left right up)))
  parent                       ; the parent branch node (children refilled on up)
  (left '() :type list)        ; left siblings, reversed (nearest first)
  (right '() :type list)       ; right siblings, in order
  up)                          ; the enclosing ctx, or NIL at the root frame

(defstruct (loc (:constructor make-loc (focus ctx)))
  focus                        ; the selected node
  ctx)                         ; a ctx, or NIL when the focus is the root

(defun node->loc (node)
  "The location whose focus is the root NODE (no context)."
  (make-loc node nil))

(defun loc-at-root-p (loc)
  "True when the focus is the whole tree (no containing context)."
  (null (loc-ctx loc)))

(defun loc-level (loc)
  "The level tag of the focus's siblings (spec §6.2): :sexp inside a list, :form
inside a file, :file inside a directory, or :root at the top."
  (let ((ctx (loc-ctx loc)))
    (if ctx (node-level-of-children (ctx-parent ctx)) :root)))

;;; --- primitive motions (§6.2) ---------------------------------------------

(defun loc-down (loc)
  "Descend to the first child of the focus; NIL for a leaf or an empty branch."
  (let ((node (loc-focus loc)))
    (when (branch-node-p node)
      (let ((children (node-children node)))
        (when children
          (make-loc (first children)
                    (make-ctx node '() (rest children) (loc-ctx loc))))))))

(defun %same-list-p (a b)
  "True when lists A and B have the same elements in order (EQ elementwise)."
  (and (= (length a) (length b)) (every #'eq a b)))

(defun loc-up (loc)
  "Ascend to the parent; NIL at the root. When the children are unchanged (pure
navigation) the ORIGINAL parent node is returned, so its verbatim text survives;
only a real change rebuilds it (dropping the now-stale text, §6.7)."
  (let ((ctx (loc-ctx loc)))
    (when ctx
      (let* ((parent (ctx-parent ctx))
             (children (revappend (ctx-left ctx) (cons (loc-focus loc) (ctx-right ctx)))))
        (make-loc (if (%same-list-p children (node-children parent))
                      parent
                      (node-with-children parent children))
                  (ctx-up ctx))))))

(defun loc-right (loc)
  "Select the next sibling; past the last one, ascend to the parent (spec §6.2)."
  (let ((ctx (loc-ctx loc)))
    (if (and ctx (ctx-right ctx))
        (make-loc (first (ctx-right ctx))
                  (make-ctx (ctx-parent ctx)
                            (cons (loc-focus loc) (ctx-left ctx))
                            (rest (ctx-right ctx))
                            (ctx-up ctx)))
        (loc-up loc))))

(defun loc-left (loc)
  "Select the previous sibling; before the first one, ascend (spec §6.2)."
  (let ((ctx (loc-ctx loc)))
    (if (and ctx (ctx-left ctx))
        (make-loc (first (ctx-left ctx))
                  (make-ctx (ctx-parent ctx)
                            (rest (ctx-left ctx))
                            (cons (loc-focus loc) (ctx-right ctx))
                            (ctx-up ctx)))
        (loc-up loc))))

;;; Non-ascending sibling steps back FIRST / LAST / SKIP, which stay at the
;;; current level and clamp at the ends rather than ascending.

(defun %sibling-right (loc)
  (let ((ctx (loc-ctx loc)))
    (when (and ctx (ctx-right ctx))
      (make-loc (first (ctx-right ctx))
                (make-ctx (ctx-parent ctx)
                          (cons (loc-focus loc) (ctx-left ctx))
                          (rest (ctx-right ctx))
                          (ctx-up ctx))))))

(defun %sibling-left (loc)
  (let ((ctx (loc-ctx loc)))
    (when (and ctx (ctx-left ctx))
      (make-loc (first (ctx-left ctx))
                (make-ctx (ctx-parent ctx)
                          (rest (ctx-left ctx))
                          (cons (loc-focus loc) (ctx-right ctx))
                          (ctx-up ctx))))))

(defun loc-first (loc)
  "Select the leftmost sibling (identity at the root or when already leftmost)."
  (let ((prev (%sibling-left loc)))
    (if prev (loc-first prev) loc)))

(defun loc-last (loc)
  "Select the rightmost sibling (identity at the root or when already rightmost)."
  (let ((next (%sibling-right loc)))
    (if next (loc-last next) loc)))

(defun loc-skip (loc n)
  "Move N siblings — N>0 right, N<0 left — clamped at the ends (no ascent)."
  (cond ((zerop n) loc)
        ((plusp n) (let ((next (%sibling-right loc)))
                     (if next (loc-skip next (1- n)) loc)))
        (t (let ((prev (%sibling-left loc)))
             (if prev (loc-skip prev (1+ n)) loc)))))

;;; --- whole-tree helpers ---------------------------------------------------

(defun loc-root (loc)
  "The root node the LOC is a zipper into (ascend fully)."
  (loop for l = loc then up
        for up = (loc-up l)
        while up
        finally (return (loc-focus l))))

(defun loc-path (loc)
  "The child-index path from the root down to the focus (NIL at the root)."
  (loop for l = loc then (loc-up l)
        for ctx = (loc-ctx l)
        while ctx
        collect (length (ctx-left ctx)) into indices
        finally (return (nreverse indices))))

(defun loc-follow (root path)
  "Navigate from the root NODE to the location named by PATH, a list of child
indices (as returned by LOC-PATH). Signals if PATH leaves the tree."
  (let ((loc (node->loc root)))
    (dolist (index path loc)
      (let ((down (loc-down loc)))
        (unless down (error "loc-follow: cannot descend at ~S" (loc-focus loc)))
        (setf loc (loc-skip down index))
        (unless (= index (length (ctx-left (loc-ctx loc))))
          (error "loc-follow: index ~D out of range" index))))))
