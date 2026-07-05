;;;; clautolisp/autolisp-sedit/source/state.lisp
;;;;
;;;; The editor machine state S = (Loc, mode, clip, undo-save) (sedit spec §6.5)
;;;; and the single-level undo (§6.4). The pure §6.3 transitions (edit.lisp) are
;;;; loc → loc; this layer threads them through the state, recording an undo
;;;; point before every mutation and leaving it untouched on motion / copy.
;;;;
;;;; Undo is a SWAP, not an inverse edit: the slot holds the pre-mutation Loc,
;;;; and because the tree is persistent that snapshot is O(1) and shares all
;;;; unchanged structure. `undo' exchanges the live Loc with the saved one and
;;;; stores the just-undone Loc back, so a second `undo' redoes — one mechanism,
;;;; self-inverse, for every kind of edit (§6.4).

(in-package #:clautolisp.sedit)

;;; --- the undo slot (§6.4: UndoSlot ::= Empty | Saved op Loc) ---------------

(defstruct (undo-record (:constructor make-undo-record (op loc)))
  op                           ; the operation descriptor: (KEYWORD . consumed…)
  loc)                         ; the location just before OP ran

(defun undo-op-name (op)
  "The lower-case name of an operation descriptor OP — the word for the status
line, e.g. \"insert\" for (:insert σ)."
  (string-downcase (symbol-name (first op))))

;;; --- the machine state (§6.5) ---------------------------------------------

(defstruct (sedit-state (:constructor make-sedit-state (loc &key clip (mode :edit) undo)))
  loc                          ; the current location (Loc)
  (clip nil)                   ; the editor clipboard: an adorned node, or NIL
  (mode :edit)                 ; :edit | :nav — Phase 5 switches; Phase 1/2 :edit
  (undo nil))                  ; the undo slot: NIL (Empty) or an undo-record

(defun state-focus (state)
  "The selected node of STATE."
  (loc-focus (sedit-state-loc state)))

(defun sedit-can-undo-p (state)
  "True when STATE has a recorded mutation to undo (or redo)."
  (and (sedit-state-undo state) t))

(defun sedit-undo-description (state)
  "The word for the pending undo/redo (\"insert\", \"cut\", …), or NIL."
  (let ((slot (sedit-state-undo state)))
    (and slot (undo-op-name (undo-record-op slot)))))

;;; --- recording: fill the slot BEFORE mutating (§6.4) ----------------------

(defun %record-and-apply (state op transition)
  "Record OP and the pre-mutation Loc into the undo slot, then apply TRANSITION
(a function Loc → Loc) to the state's Loc (§6.4 recording rule). The previous
Saved is overwritten — one level. Returns STATE."
  (let ((pre (sedit-state-loc state)))
    (setf (sedit-state-loc state) (funcall transition pre)
          (sedit-state-undo state) (make-undo-record op pre)))
  state)

;;; --- state-level mutations (§6.3, each records an undo point) --------------

(defun sedit-insert (state sigma)
  "Insert SIGMA before the selection and select it."
  (%record-and-apply state (list :insert sigma) (lambda (loc) (edit-insert loc sigma))))

(defun sedit-add (state sigma)
  "Add SIGMA after the selection and select it."
  (%record-and-apply state (list :add sigma) (lambda (loc) (edit-add loc sigma))))

(defun sedit-replace (state sigma)
  "Replace the selection with SIGMA and select it."
  (%record-and-apply state (list :replace sigma) (lambda (loc) (edit-replace loc sigma))))

(defun sedit-delete (state)
  "Delete the selection, selecting the next sibling (or the parent)."
  (%record-and-apply state (list :delete) #'edit-delete))

(defun sedit-wrap (state)
  "Wrap the selection in a new list and select it."
  (%record-and-apply state (list :wrap) #'edit-wrap))

(defun sedit-splice (state)
  "Splice the selected list into its parent, selecting the first child."
  (%record-and-apply state (list :splice) #'edit-splice))

(defun sedit-slurp (state)
  "Extend the selected list with the following sibling."
  (%record-and-apply state (list :slurp) #'edit-slurp))

(defun sedit-barf (state)
  "Expel the selected list's last element as its following sibling."
  (%record-and-apply state (list :barf) #'edit-barf))

(defun sedit-split (state)
  "Split the parent list before the selection into two sibling lists."
  (%record-and-apply state (list :split) #'edit-split))

(defun sedit-join (state)
  "Join two adjacent sibling lists (the inverse of split)."
  (%record-and-apply state (list :join) #'edit-join))

;;; --- clipboard: copy is non-mutating; cut/paste record undo (§6.3/§6.4) ---

(defun sedit-copy (state)
  "Copy the selection to the clipboard (spec §6.3). Non-mutating — it leaves the
undo slot untouched. Returns STATE."
  (setf (sedit-state-clip state) (loc-focus (sedit-state-loc state)))
  state)

(defun sedit-cut (state)
  "Cut the selection to the clipboard, then delete it — selecting the next
sibling (spec §6.3). Records an undo point; the swap restores the Loc but not
the clipboard (§6.4). Returns STATE."
  (setf (sedit-state-clip state) (loc-focus (sedit-state-loc state)))
  (%record-and-apply state (list :cut) #'edit-delete))

(defun sedit-paste (state)
  "Replace the selection with the clipboard contents (spec §6.3). Records an undo
point. Signals on an empty clipboard; returns STATE."
  (let ((clip (sedit-state-clip state)))
    (unless clip (error "paste: the clipboard is empty"))
    (%record-and-apply state (list :paste clip) (lambda (loc) (edit-replace loc clip)))))

;;; --- motions: never touch the undo slot (§6.4) ----------------------------

(defun %move (state motion)
  "Apply MOTION (Loc → Loc-or-NIL) to the state's Loc, leaving it unchanged when
MOTION has no target. Motions do not record undo (§6.4). Returns STATE."
  (let ((next (funcall motion (sedit-state-loc state))))
    (when next (setf (sedit-state-loc state) next)))
  state)

(defun sedit-down  (state) (%move state #'loc-down))
(defun sedit-up    (state) (%move state #'loc-up))
(defun sedit-left  (state) (%move state #'loc-left))
(defun sedit-right (state) (%move state #'loc-right))
(defun sedit-first (state) (%move state #'loc-first))
(defun sedit-last  (state) (%move state #'loc-last))
(defun sedit-skip  (state n) (%move state (lambda (loc) (loc-skip loc n))))

;;; --- undo: the swap (§6.4) -------------------------------------------------

(defun sedit-undo (state)
  "Undo the last mutation, or redo it on a second call — the §6.4 swap. Exchange
the live Loc with the saved pre-mutation Loc and store the just-undone Loc back,
keeping the descriptor, so `undo' is self-inverse (a second `undo' redoes). The
file-modified marker rides along with the snapshotted tree, so it reverts and
re-applies with the swap. A no-op on an empty slot. Returns STATE."
  (let ((slot (sedit-state-undo state)))
    (when slot
      (let ((current (sedit-state-loc state)))
        (setf (sedit-state-loc state) (undo-record-loc slot)
              (sedit-state-undo state) (make-undo-record (undo-record-op slot) current)))))
  state)
