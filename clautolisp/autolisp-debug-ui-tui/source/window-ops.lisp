(in-package #:tui-core)

;;;; Window drawing operations (TUI module spec). These act on a WINDOW's area
;;;; of its frame's screen. They are TTY-SAFE: on a tty-frame (or any window
;;;; whose frame has no vdt screen backend) they are no-ops — a caller may use
;;;; them freely, and they simply have no visible effect there, exactly as a
;;;; 2D-cursor operation cannot on a line-discipline terminal. They default to
;;;; the SELECTED-WINDOW so the debugger interactors can draw into "their" pane.

(defun window-screen (&optional (window (selected-window)))
  "The vdt screen backing WINDOW's frame, or NIL when the frame is a tty-frame
or has no backend (so the window operations are no-ops)."
  (let ((frame (and window (window-frame window))))
    (and frame (eq (frame-device frame) :vdt) (frame-screen frame))))

(defun window-vdt-p (&optional (window (selected-window)))
  "True when WINDOW draws onto a vdt screen (its operations have visible effect)."
  (and (window-screen window) t))

(defun clear-window (&optional (window (selected-window)))
  "Blank WINDOW's rectangle. A no-op on a tty-frame / backend-less window."
  (let ((screen (window-screen window))
        (rect (and window (window-rect window))))
    (when (and screen rect)
      (destructuring-bind (top left height width) rect
        (let ((blank (make-string (max 0 width) :initial-element #\Space)))
          (dotimes (r (max 0 height))
            (tui-put screen (+ top r) left blank)))))
    (when window (setf (window-cursor window) (cons 0 0))))
  window)

(defun move-cursor-to (row col &optional (window (selected-window)))
  "Move WINDOW's cursor to window-relative (ROW COL), clamped to its rectangle.
Records the logical cursor on the window and, on a vdt screen, moves the
hardware cursor (TUI-MOVE-CURSOR); a no-op-with-effect on a tty-frame (the
logical position is still recorded)."
  (when window
    (let ((rect (window-rect window)))
      (if rect
          (destructuring-bind (top left height width) rect
            (let ((r (max 0 (min (max 0 (1- height)) row)))
                  (c (max 0 (min (max 0 (1- width)) col))))
              (setf (window-cursor window) (cons r c))
              (let ((screen (window-screen window)))
                (when screen (tui-move-cursor screen (+ top r) (+ left c))))))
          (setf (window-cursor window) (cons (max 0 row) (max 0 col))))))
  window)

(defun window-put (row col string &key (face :normal) (window (selected-window)))
  "Write STRING at window-relative (ROW COL) in WINDOW, clipped to its rectangle.
A no-op on a tty-frame / backend-less window."
  (let ((screen (window-screen window))
        (rect (and window (window-rect window))))
    (when (and screen rect)
      (destructuring-bind (top left height width) rect
        (when (and (< -1 row height) (< col width))
          (let ((c (max 0 col)))
            (tui-put screen (+ top row) (+ left c)
                     (truncate-string string (- width c)) :attr face))))))
  window)
