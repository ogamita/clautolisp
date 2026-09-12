;;;; clautolisp/autolisp-dcl/source/ncurses-renderer.lisp
;;;;
;;;; Full-screen ncurses DCL renderer (dcl-ncurses-renderer.issue), parallel to
;;;; the line-oriented terminal.lisp. It draws against the dependency-free
;;;; tui-core screen protocol (clautolisp.ui.tui) — so it runs over a real
;;;; curses screen OR a mock screen (headless tests) — and reuses the runtime
;;;; action/$reason plumbing and the terminal renderer's value-tile helpers, so
;;;; tile values and $reason codes are IDENTICAL to the line renderer; only the
;;;; presentation (2-D, focus-highlighted) and the input (keys, not a typed
;;;; command line) differ.
;;;;
;;;; SLICE 1: the modal loop, a 2-D :row/:column layout, text/button rendering,
;;;; focus navigation (arrows + Tab), Enter/Space activation, accept/cancel and
;;;; Esc. The remaining interactive widgets' full keyboard input (typing into an
;;;; edit_box, slider Left/Right, in-list selection) lands in later slices;
;;;; Enter/Space already fires their action via the shared value-tile helper.

(in-package #:clautolisp.autolisp-dcl)

;;; --- per-tile one-line rendering ----------------------------------------

(defun %ncurses-tile-line (tile dialog)
  "Render TILE to a single display string, reading its live value from DIALOG's
state. Mirrors the line renderer's tile vocabulary."
  (let* ((type (dcl-tile-type tile))
         (key (terminal-tile-key tile))
         (label (or (tile-attribute tile "label") ""))
         (val (and key (gethash key (dcl-dialog-state dialog)))))
    (flet ((labelled (s) (if (plusp (length label)) (format nil "~A: ~A" label s) s)))
      (case type
        (:text (if (plusp (length label)) label (or val "")))
        ((:button :image-button)
         (format nil "[ ~A ]" (if (plusp (length label)) label (or key ""))))
        (:edit-box (labelled (or val "")))
        (:toggle (format nil "[~A] ~A" (if (equal val "1") "x" " ") label))
        (:radio-button (format nil "(~A) ~A" (if (equal val "1") "*" " ") label))
        (:popup-list (labelled (format nil "[~A]" (or val ""))))
        (:list-box (if (plusp (length label)) (format nil "~A:" label) "(list)"))
        (:slider (labelled (or val "")))
        (:image (format nil "[image ~A]" (or key "")))
        (t (if (plusp (length label)) label (format nil "<~(~A~)>" type)))))))

;;; --- 2-D layout over the tile tree --------------------------------------
;;; A placement is (ROW COL WIDTH TEXT TILE): TILE is the interactive tile (for
;;; focus/activation) or NIL for a static line (e.g. a container label).

(defun %ncurses-layout (tile top left width dialog)
  "Lay TILE's subtree out in the rectangle starting at (TOP,LEFT) of the given
WIDTH. :column-family containers stack children vertically; :row-family place
them side by side, splitting the width. Returns (values PLACEMENTS ROWS-USED)."
  (let ((type (dcl-tile-type tile)))
    (cond
      ((member type '(:dialog :column :boxed-column :radio-column :concatenation))
       (let ((row top) (acc '()) (label (tile-attribute tile "label")))
         (when (and (member type '(:dialog :boxed-column))
                    label (plusp (length label)))
           (setf acc (list (list row left width label nil)))
           (incf row))
         (dolist (child (dcl-tile-children tile))
           (multiple-value-bind (ps used) (%ncurses-layout child row left width dialog)
             (setf acc (nconc acc ps))
             (incf row (max 1 used))))
         (values acc (- row top))))
      ((member type '(:row :boxed-row :radio-row))
       (let* ((kids (dcl-tile-children tile))
              (n (max 1 (length kids)))
              (cw (max 1 (floor width n)))
              (acc '()) (maxused 1) (col left))
         (dolist (child kids)
           (multiple-value-bind (ps used) (%ncurses-layout child top col cw dialog)
             (setf acc (nconc acc ps))
             (setf maxused (max maxused used))
             (incf col cw)))
         (values acc maxused)))
      ((eq type :spacer) (values '() 1))
      (t (values (list (list top left width (%ncurses-tile-line tile dialog) tile))
                 1)))))

;;; --- rendering + the modal loop -----------------------------------------

(defun %ncurses-render (screen dialog ring focus)
  "Clear and redraw DIALOG's tiles; the focused interactive tile (RING[FOCUS])
is drawn with the :selection face."
  (clautolisp.ui.tui:tui-clear screen)
  (multiple-value-bind (rows cols) (clautolisp.ui.tui:tui-size screen)
    (declare (ignore rows))
    (let ((focus-key (and ring (car (nth focus ring)))))
      (dolist (p (%ncurses-layout (dcl-dialog-tile dialog) 0 0 (max 1 cols) dialog))
        (destructuring-bind (row col width text tile) p
          (declare (ignore width))
          (clautolisp.ui.tui:tui-put
           screen row col text
           :attr (if (and tile focus-key
                          (equal (terminal-tile-key tile) focus-key))
                     :selection :normal))))))
  (clautolisp.ui.tui:tui-refresh screen))

(defun %ncurses-finish (dialog status)
  "Mark DIALOG done with STATUS (mirrors dcl-runtime-done-dialog on the object)."
  (unless (dcl-dialog-finished-p dialog)
    (setf (dcl-dialog-status dialog) status
          (dcl-dialog-finished-p dialog) t))
  status)

(defun %ncurses-cancel (dialog)
  "Cancel DIALOG: fire a registered `cancel' action if one exists (e.g. an
ok_cancel cluster), then finish with status 0."
  (terminal-fire-registered dialog "cancel")
  (%ncurses-finish dialog 0))

(defun %ncurses-activate (dialog tile key)
  "Activate the focused TILE (Enter/Space). Buttons fire their action and may
return a terminal status (accept->1 / cancel->0); toggle/radio/list flip or
select via the shared value-tile helper (parity with the line renderer's bare
key press); an edit_box / slider COMMITS its current value (reason lost-focus)
— we never route those through terminal-handle-value-tile with a nil value,
which would block on a stdin prompt. Returns a status integer to exit on, or
NIL to keep looping."
  (case (dcl-tile-type tile)
    ((:button :image-button) (terminal-handle-button dialog tile key))
    ((:toggle :radio-button :list-box :popup-list)
     (terminal-handle-value-tile dialog tile key nil :activate)
     nil)
    ((:edit-box :slider)
     (terminal-set-and-fire dialog key
                            (gethash key (dcl-dialog-state dialog) "")
                            :reason-lost-focus)
     nil)
    (t nil)))

;;; --- value-widget keyboard input (slice 2) ------------------------------

(defun %ncurses-edit-insert (dialog key char)
  "Append CHAR to edit_box KEY's value and fire reason-changed."
  (terminal-set-and-fire dialog key
                         (concatenate 'string
                                      (gethash key (dcl-dialog-state dialog) "")
                                      (string char))
                         :reason-changed))

(defun %ncurses-edit-backspace (dialog key)
  "Delete the last character of edit_box KEY's value (reason-changed)."
  (let ((cur (gethash key (dcl-dialog-state dialog) "")))
    (when (plusp (length cur))
      (terminal-set-and-fire dialog key (subseq cur 0 (1- (length cur)))
                             :reason-changed))))

(defun %ncurses-slider-step (dialog tile key delta)
  "Move slider KEY by DELTA, clamped to its min_value/max_value (reason-changed)."
  (let* ((mn (or (tile-attribute tile "min_value") 0))
         (mx (or (tile-attribute tile "max_value") 100))
         (cur (or (ignore-errors
                    (parse-integer (gethash key (dcl-dialog-state dialog) "0")
                                   :junk-allowed t))
                  0))
         (new (min mx (max mn (+ cur delta)))))
    (terminal-set-and-fire dialog key (princ-to-string new) :reason-changed)))

(defun ncurses-run-dialog (dialog screen)
  "Drive DIALOG's interaction as a full-screen modal loop over SCREEN (a tui-core
screen — real curses or a mock). Returns the dialog's terminal status (1 OK /
0 Cancel). EOF on the key stream cancels, so the loop always terminates."
  (let* ((ring (terminal-collect-interactive-keys (dcl-dialog-tile dialog)))
         (focus 0)
         (n (length ring)))
    (clautolisp.ui.tui:tui-start screen)
    (unwind-protect
         (loop
           (when (dcl-dialog-finished-p dialog)
             (return (dcl-dialog-status dialog)))
           (%ncurses-render screen dialog ring focus)
           (let* ((key (clautolisp.ui.tui:tui-read-key screen))
                  (cell (and (plusp n) (nth focus ring)))
                  (ftile (and cell (cdr cell)))
                  (fkey (and cell (car cell)))
                  (ftype (and ftile (dcl-tile-type ftile))))
             (cond
               ((eq key :eof) (return (%ncurses-finish dialog 0)))
               ((eq key :escape) (%ncurses-cancel dialog))
               ;; edit_box: a printable character types into the value, Backspace
               ;; deletes. (#\Tab is not graphic, so it still navigates; #\Space
               ;; types a space here rather than activating.)
               ((and (eq ftype :edit-box) (characterp key) (graphic-char-p key))
                (%ncurses-edit-insert dialog fkey key))
               ((and (eq ftype :edit-box) (eq key :backspace))
                (%ncurses-edit-backspace dialog fkey))
               ;; slider: Left/Right step within min/max.
               ((and (eq ftype :slider) (member key '(:left :right)))
                (%ncurses-slider-step dialog ftile fkey (if (eq key :right) 1 -1)))
               ;; focus navigation.
               ((or (eq key :down) (and (characterp key) (char= key #\Tab)))
                (when (plusp n) (setf focus (mod (1+ focus) n))))
               ((eq key :up)
                (when (plusp n) (setf focus (mod (1- focus) n))))
               ;; activate the focused tile.
               ((or (eq key :enter) (and (characterp key) (char= key #\Space)))
                (when cell
                  (let ((status (%ncurses-activate dialog ftile fkey)))
                    (when status (%ncurses-finish dialog status)))))
               (t nil))))
      (clautolisp.ui.tui:tui-stop screen))))

;;; --- renderer object (NOT installed at load; the CLI selects it) --------

(defun make-ncurses-renderer (&key screen)
  "Build a dcl-renderer that drives dialogs full-screen over SCREEN (a tui-core
screen). Unlike the terminal renderer this does NOT self-install — installation
is opt-in via the CLI's --dcl ncurses selection (see dcl-ncurses-renderer.issue
slice 4)."
  (unless screen (error "MAKE-NCURSES-RENDERER requires a :SCREEN."))
  (make-dcl-renderer
   :open-fn (lambda (dialog) (declare (ignore dialog)) nil)
   :close-fn (lambda (dialog) (declare (ignore dialog)) nil)
   :set-tile-fn (lambda (dialog key value) (declare (ignore dialog key value)) nil)
   :focus-fn (lambda (dialog key) (declare (ignore dialog key)) nil)
   :mode-fn (lambda (dialog key mode) (declare (ignore dialog key mode)) nil)
   :populate-list-fn (lambda (dialog key op idx items)
                       (declare (ignore dialog key op idx items)) nil)
   :image-paint-fn (lambda (dialog key primitives)
                     (declare (ignore dialog key primitives)) nil)
   :run-fn (lambda (dialog) (ncurses-run-dialog dialog screen))))
