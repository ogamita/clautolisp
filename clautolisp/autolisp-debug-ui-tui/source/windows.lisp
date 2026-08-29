(in-package #:clautolisp.ui.tui)

;;;; Windows (TUI module spec §5). A WINDOW belongs to a frame, renders its
;;;; content into a BUFFER (a list of (STRING . FACE) lines) shown through a
;;;; per-window scroll point, and carries a status line. One window of a
;;;; vdt-frame may be the =:minibuffer= (a single bottom line). The full layout
;;;; TREE (§5.1) that tiles a frame is added when the debugger/console UIs are
;;;; wired onto this API; for now windows are held as an ordered list with a
;;;; selected window (enough for the tty-frame's single window and to build the
;;;; API surface).

(defstruct (window (:constructor %make-window) (:predicate windowp))
  (name "" :type string)
  (role nil)              ; :minibuffer, or NIL for an ordinary window
  (frame nil)
  (buffer '())            ; list of (STRING . FACE)
  (scroll (cons 0 0))     ; (SL . SC) scroll point
  (rect nil)              ; (TOP LEFT HEIGHT WIDTH), set at layout time
  (stack '())             ; the window's interactor stack (spec §6), innermost last
  (cursor (cons 0 0)))    ; (ROW . COL) logical cursor, window-relative

(defmethod print-object ((w window) stream)
  (print-unreadable-object (w stream :type t :identity t)
    (format stream "~S~@[ ~A~]" (window-name w) (window-role w))))

(defun make-window (&optional options)
  "Create a window in the selected frame (§5.2). OPTIONS: =(name . STRING)=,
=(role . :minibuffer)=. Appends it to the frame's window list; the first window
becomes the frame's selected window."
  (flet ((opt (k d) (let ((c (assoc k options))) (if c (cdr c) d))))
    (let* ((frame (selected-frame))
           (window (%make-window :name (opt :name "window")
                                 :role (opt :role nil)
                                 :frame frame)))
      (when frame
        (setf (frame-windows frame) (append (frame-windows frame) (list window)))
        (cond
          ((eq (window-role window) :minibuffer)
           ;; the minibuffer is not tiled in the layout tree — it is the frame's
           ;; reserved bottom line.
           (setf (frame-minibuffer-p frame) t))
          (t
           ;; add the window to the layout tree (a fresh window splits the
           ;; current layout side by side; the debugger UI may re-lay it out).
           (setf (frame-layout frame)
                 (if (frame-layout frame)
                     (list :vertical 1/2 (frame-layout frame) window)
                     window))))
        (unless (frame-selected-window frame)
          (setf (frame-selected-window frame) window)))
      window)))

(defun set-window-name (window string) (setf (window-name window) string))

(defun window-list (&optional frame minibufp)
  "Windows in FRAME, or in all frames when FRAME is NIL. Excludes minibuffers
unless MINIBUFP."
  (let ((frames (if frame (list frame) *frames*)))
    (loop for f in frames
          append (remove-if-not
                  (lambda (w) (or minibufp (not (eq (window-role w) :minibuffer))))
                  (frame-windows f)))))

(defun delete-window (window)
  "Remove WINDOW from its frame (§5.2)."
  (let ((frame (window-frame window)))
    (when frame
      (setf (frame-windows frame) (remove window (frame-windows frame)))
      (when (eq (frame-selected-window frame) window)
        (setf (frame-selected-window frame) (first (frame-windows frame)))))
    nil))

(defun add-window-to-frame (frame &key (name "window") role beside (split :vertical))
  "Create a window in FRAME (a SPECIFIC frame, unlike MAKE-WINDOW, which targets
the selected frame), append it to FRAME's window list, and splice it into the
layout tree BESIDE the leaf BESIDE (default: split the whole layout). A window-
manager UI that owns an isolated frame uses this to grow its layout. Returns the
new window."
  (let ((window (%make-window :name name :role role :frame frame)))
    (setf (frame-windows frame) (append (frame-windows frame) (list window)))
    (setf (frame-layout frame)
          (cond ((null (frame-layout frame)) window)
                (beside (tree-insert-beside (frame-layout frame) beside window split))
                (t (list split 1/2 (frame-layout frame) window))))
    (unless (frame-selected-window frame)
      (setf (frame-selected-window frame) window))
    window))

(defun remove-window-from-frame (frame window)
  "Remove WINDOW from FRAME's window list AND collapse it out of the layout tree
(the sibling takes its space). Reselects another window when WINDOW was selected.
Returns WINDOW."
  (setf (frame-windows frame) (remove window (frame-windows frame)))
  (when (frame-layout frame)
    (setf (frame-layout frame) (tree-remove-leaf (frame-layout frame) window)))
  (when (eq (frame-selected-window frame) window)
    (setf (frame-selected-window frame) (first (frame-windows frame))))
  window)

(defun selected-window ()
  "The active window of the selected frame, or NIL."
  (let ((frame (selected-frame))) (and frame (frame-selected-window frame))))

(defun select-window (window)
  "Make WINDOW's frame the selected frame and WINDOW that frame's selected
window (§5.2)."
  (let ((frame (window-frame window)))
    (when frame
      (select-frame frame)
      (setf (frame-selected-window frame) window))
    window))
