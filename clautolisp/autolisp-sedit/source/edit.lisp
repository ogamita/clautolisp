;;;; clautolisp/autolisp-sedit/source/edit.lisp
;;;;
;;;; Editing transitions (sedit spec §6.3). Each mutation is Loc → Loc; the
;;;; mutated focus becomes the new selection (every editing command selects its
;;;; result). Because the tree is persistent, a mutation shares all untouched
;;;; structure with the pre-mutation loc — the basis of the O(1) one-slot undo
;;;; of Phase 2.

(in-package #:clautolisp.sedit)

;;; --- file-modified marking (§6.3) -----------------------------------------

(defun %mark-enclosing-file-modified (ctx)
  "Return the CTX chain with the nearest enclosing File node marked modified
(§6.3: a mutation inside a File marks it modified, driving save-on-leave §5.8).
Only the frames up to that File are rebuilt; the rest — and the whole chain when
there is no File — is shared unchanged (returned EQ)."
  (cond
    ((null ctx) nil)
    ((file-node-p (ctx-parent ctx))
     (if (file-node-modified (ctx-parent ctx))
         ctx
         (make-ctx (make-file-node (file-node-name (ctx-parent ctx))
                                   (file-node-children (ctx-parent ctx))
                                   :adornment (node-adornment (ctx-parent ctx))
                                   :modified t)
                   (ctx-left ctx) (ctx-right ctx) (ctx-up ctx))))
    (t (let ((up (%mark-enclosing-file-modified (ctx-up ctx))))
         (if (eq up (ctx-up ctx))
             ctx
             (make-ctx (ctx-parent ctx) (ctx-left ctx) (ctx-right ctx) up))))))

(defun %mark-file (focus)
  "If FOCUS is an unmodified File (e.g. after deleting its last form), a copy
marked modified; else FOCUS unchanged."
  (if (and (file-node-p focus) (not (file-node-modified focus)))
      (make-file-node (file-node-name focus) (file-node-children focus)
                      :adornment (node-adornment focus) :modified t)
      focus))

(defun %mutated (loc)
  "Post-process a mutation's result LOC: mark the enclosing File modified,
whether the File is above the focus (in the context) or is the focus itself."
  (make-loc (%mark-file (loc-focus loc))
            (%mark-enclosing-file-modified (loc-ctx loc))))

;;; --- insert / add / replace / delete (§6.3) -------------------------------

(defun edit-insert (loc sigma)
  "Insert node SIGMA before the focus and select it (spec §6.3)."
  (let ((ctx (loc-ctx loc)))
    (unless ctx (error "insert: the focus has no container (it is the root)"))
    (%mutated (make-loc sigma
                        (make-ctx (ctx-parent ctx) (ctx-left ctx)
                                  (cons (loc-focus loc) (ctx-right ctx)) (ctx-up ctx))))))

(defun edit-add (loc sigma)
  "Add node SIGMA after the focus and select it (spec §6.3)."
  (let ((ctx (loc-ctx loc)))
    (unless ctx (error "add: the focus has no container (it is the root)"))
    (%mutated (make-loc sigma
                        (make-ctx (ctx-parent ctx)
                                  (cons (loc-focus loc) (ctx-left ctx))
                                  (ctx-right ctx) (ctx-up ctx))))))

(defun edit-replace (loc sigma)
  "Replace the focus with node SIGMA and select it (spec §6.3); works at the root."
  (%mutated (make-loc sigma (loc-ctx loc))))

(defun edit-delete (loc)
  "Remove the focus, selecting the next sibling, or the parent if it was last
(spec §6.3, DELETE). Signals at the root."
  (let ((ctx (loc-ctx loc)))
    (unless ctx (error "delete: cannot delete the root"))
    (%mutated
     (if (ctx-right ctx)
         (make-loc (first (ctx-right ctx))
                   (make-ctx (ctx-parent ctx) (ctx-left ctx)
                             (rest (ctx-right ctx)) (ctx-up ctx)))
         (make-loc (node-with-children (ctx-parent ctx) (reverse (ctx-left ctx)))
                   (ctx-up ctx))))))

;;; --- structural: wrap / splice / slurp / barf / split / join (§6.3) -------

(defun edit-wrap (loc)
  "Wrap the focus in a new one-element list and select that list — (… a …) →
(… (a) …) (spec §6.3)."
  (%mutated (make-loc (make-list-node (list (loc-focus loc))) (loc-ctx loc))))

(defun edit-splice (loc)
  "Splice the selected list's children into its parent, selecting the first
child (spec §6.3). The inverse of WRAP. Signals on a non-list or at the root."
  (let ((node (loc-focus loc)) (ctx (loc-ctx loc)))
    (unless (list-node-p node) (error "splice: the selection is not a list"))
    (unless ctx (error "splice: cannot splice the root"))
    (let ((xs (list-node-children node)))
      (if (null xs)
          (edit-delete loc)                 ; empty list: just remove it
          (%mutated
           (make-loc (first xs)
                     (make-ctx (ctx-parent ctx) (ctx-left ctx)
                               (append (rest xs) (ctx-right ctx)) (ctx-up ctx))))))))

(defun edit-slurp (loc)
  "Extend the selected list with the following sibling, keeping the list selected
(spec §6.3). A non-list selection is wrapped first. Signals with no next sibling."
  (let ((node (loc-focus loc)) (ctx (loc-ctx loc)))
    (unless (and ctx (ctx-right ctx)) (error "slurp: no following sibling to slurp"))
    (if (list-node-p node)
        (%mutated
         (make-loc (make-list-node
                    (append (list-node-children node) (list (first (ctx-right ctx))))
                    :adornment (node-adornment node))
                   (make-ctx (ctx-parent ctx) (ctx-left ctx)
                             (rest (ctx-right ctx)) (ctx-up ctx))))
        (edit-slurp (edit-wrap loc)))))

(defun edit-barf (loc)
  "Expel the selected list's last element as its following sibling, keeping the
shrunk list selected (spec §6.3). The inverse of SLURP. Signals on a non-list,
an empty list, or at the root."
  (let ((node (loc-focus loc)) (ctx (loc-ctx loc)))
    (unless (list-node-p node) (error "barf: the selection is not a list"))
    (unless ctx (error "barf: cannot barf at the root"))
    (let ((xs (list-node-children node)))
      (unless xs (error "barf: the selection is empty"))
      (%mutated
       (make-loc (make-list-node (butlast xs) :adornment (node-adornment node))
                 (make-ctx (ctx-parent ctx) (ctx-left ctx)
                           (cons (car (last xs)) (ctx-right ctx)) (ctx-up ctx)))))))

(defun edit-split (loc)
  "Split the parent list before the focus into two sibling lists, selecting the
focus (now first of the second list) (spec §6.3). When the focus is first, no
empty left list is created. The parent must itself sit in a container. Signals
otherwise."
  (let ((ctx1 (loc-ctx loc)))
    (unless ctx1 (error "split: the focus has no parent"))
    (let ((parent (ctx-parent ctx1)) (ctx2 (ctx-up ctx1)))
      (unless (list-node-p parent) (error "split: the parent is not a list"))
      (unless ctx2 (error "split: the parent has no container to split into"))
      (let* ((ls (ctx-left ctx1)) (rs (ctx-right ctx1))
             (focus (loc-focus loc))
             (adorn (node-adornment parent))
             (left-list (when ls (make-list-node (reverse ls) :adornment adorn)))
             (right-list (make-list-node (cons focus rs) :adornment adorn)))
        (%mutated
         (make-loc focus
                   (make-ctx right-list '() rs
                             (make-ctx (ctx-parent ctx2)
                                       (if left-list
                                           (cons left-list (ctx-left ctx2))
                                           (ctx-left ctx2))
                                       (ctx-right ctx2)
                                       (ctx-up ctx2)))))))))

(defun edit-join (loc)
  "Join two adjacent sibling lists, the inverse of SPLIT (spec §6.3). If the
focus is a list, merge it with its left-sibling list and select the merge; if
the focus is inside a list whose left sibling is a list, merge those two and keep
the focus selected inside the merge. Signals when there is no adjacent list."
  (let ((focus (loc-focus loc)) (ctx1 (loc-ctx loc)))
    (cond
      ;; the focus is itself a list with a left-sibling list -> merge, select it
      ((and (list-node-p focus) ctx1 (ctx-left ctx1)
            (list-node-p (first (ctx-left ctx1))))
       (let* ((l1 (first (ctx-left ctx1)))
              (merged (make-list-node (append (list-node-children l1)
                                              (list-node-children focus))
                                      :adornment (node-adornment l1))))
         (%mutated
          (make-loc merged (make-ctx (ctx-parent ctx1) (rest (ctx-left ctx1))
                                     (ctx-right ctx1) (ctx-up ctx1))))))
      ;; the focus is inside a list whose left sibling is a list -> merge those
      ;; two, keeping the focus selected inside the merge
      ((and ctx1 (list-node-p (ctx-parent ctx1)) (ctx-up ctx1)
            (ctx-left (ctx-up ctx1))
            (list-node-p (first (ctx-left (ctx-up ctx1)))))
       (let* ((l2 (ctx-parent ctx1))
              (ctx2 (ctx-up ctx1))
              (l1 (first (ctx-left ctx2)))
              (l1-children (list-node-children l1))
              (merged (make-list-node (append l1-children (list-node-children l2))
                                      :adornment (node-adornment l1))))
         (%mutated
          (make-loc focus
                    (make-ctx merged
                              (append (reverse l1-children) (ctx-left ctx1))
                              (ctx-right ctx1)
                              (make-ctx (ctx-parent ctx2) (rest (ctx-left ctx2))
                                        (ctx-right ctx2) (ctx-up ctx2)))))))
      (t (error "join: no adjacent sibling list to join")))))

;;; --- editor state + clipboard (§6.3 copy/cut/paste, §6.5 state) -----------

(defstruct (sedit-state (:constructor make-sedit-state (loc &key clip (mode :edit))))
  loc                          ; the current location
  (clip nil)                   ; the editor clipboard: an adorned node, or NIL
  (mode :edit))                ; :edit | :nav — Phase 5 switches; Phase 1 is :edit

(defun state-focus (state)
  "The selected node of STATE."
  (loc-focus (sedit-state-loc state)))

(defun sedit-copy (state)
  "Copy the selection to the clipboard (spec §6.3). Non-mutating; returns STATE."
  (setf (sedit-state-clip state) (loc-focus (sedit-state-loc state)))
  state)

(defun sedit-cut (state)
  "Cut the selection to the clipboard, then delete it — selecting the next
sibling (spec §6.3). Returns STATE."
  (setf (sedit-state-clip state) (loc-focus (sedit-state-loc state))
        (sedit-state-loc state) (edit-delete (sedit-state-loc state)))
  state)

(defun sedit-paste (state)
  "Replace the selection with the clipboard contents (spec §6.3). The tree is
immutable, so the pasted node may be shared. Signals on an empty clipboard;
returns STATE."
  (let ((clip (sedit-state-clip state)))
    (unless clip (error "paste: the clipboard is empty"))
    (setf (sedit-state-loc state) (edit-replace (sedit-state-loc state) clip)))
  state)
