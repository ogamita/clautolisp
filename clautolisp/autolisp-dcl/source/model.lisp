(in-package #:clautolisp.autolisp-dcl)

;;;; Data model for DCL (Dialog Control Language).
;;;;
;;;; The parsed AST is a tree of `dcl-tile` records. Each tile has:
;;;;
;;;;   - a TYPE keyword indicating its tile class (:dialog, :button,
;;;;     :edit-box, :list-box, :popup-list, :radio-button, :text,
;;;;     :image, :spacer, :row, :column, :boxed-row, :boxed-column,
;;;;     and the predefined classes ok_only / ok_cancel /
;;;;     ok_cancel_help, etc.).
;;;;
;;;;   - a KEY string (or nil), used by AutoLISP to address the tile
;;;;     via action_tile / set_tile / get_tile.
;;;;
;;;;   - an ATTRIBUTES alist (string -> value) for declared options
;;;;     (label, edit_width, value, mnemonic, alignment, …).
;;;;
;;;;   - a CHILDREN list (other tiles).
;;;;
;;;;   - a SOURCE pointer back to the dcl-source the tile came from
;;;;     (nil for predefined / runtime-created tiles).

(defstruct dcl-tile
  (type :dialog :type keyword)
  (key  nil)
  (attributes nil :type list)   ; alist of (NAME . VALUE)
  (children   nil :type list)
  (source     nil))

(defun tile-attribute (tile name &optional default)
  "Look up the attribute with case-folded NAME on TILE, returning
DEFAULT when absent."
  (let ((entry (assoc name (dcl-tile-attributes tile) :test #'string-equal)))
    (if entry (cdr entry) default)))

(defun set-tile-attribute (tile name value)
  (let ((entry (assoc name (dcl-tile-attributes tile) :test #'string-equal)))
    (cond
      (entry (setf (cdr entry) value))
      (t (push (cons name value) (dcl-tile-attributes tile))))
    value))

;;; --- Source / dialog runtime records ----------------------------

(defstruct dcl-source
  "A loaded .dcl file. ID is the AutoLISP-visible integer handle
returned by load_dialog. PATH is the source pathname (or nil for
synthesised sources). TILES is an alist from tile-class name to
the corresponding top-level dcl-tile."
  (id   0 :type integer)
  (path nil)
  (tiles nil :type list))      ; alist of (NAME-STRING . dcl-tile)

(defstruct dcl-dialog
  "A running dialog instance. SOURCE is the dcl-source it came
from. TILE is the root dcl-tile (looked up by name in SOURCE).
ACTIONS maps tile-key string to AutoLISP callable. STATUS is the
status integer passed to (done_dialog STATUS) or 0 if cancelled.
RESULT-BINDINGS is a stash of the per-tile values at done-time
(ged_tile honours them through start_dialog's return)."
  (id      0 :type integer)
  (source  nil)
  (tile    nil)
  (actions (make-hash-table :test #'equal))
  (state   (make-hash-table :test #'equal))     ; key -> current value
  (modes   (make-hash-table :test #'equal))     ; key -> mode-tile flag
  (client  (make-hash-table :test #'equal))     ; key -> client_data
  (focus   nil)
  (status  0    :type integer)
  (result-bindings nil :type list)
  (finished-p nil :type boolean))
