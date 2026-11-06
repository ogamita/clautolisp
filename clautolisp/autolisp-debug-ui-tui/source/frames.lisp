(in-package #:clautolisp.ui.tui)

;;;; Frames (TUI module spec §4). A FRAME is a set of windows shown in one GUI
;;;; unit (what a GUI calls a window):
;;;;   tty-frame — a dumb line-discipline terminal: one implicit window and an
;;;;               implicit minibuffer (line discipline). No screen backend.
;;;;   vdt-frame — a 2D cursor-addressable terminal: a TUI-SCREEN backend
;;;;               (ncurses / PDCurses / the mock), several windows.
;;;; One frame is SELECTED at a time. clautolisp starts in a single tty-frame
;;;; "autolisp"; a vdt-frame is entered temporarily (sedit, aldo) and left on
;;;; resume — select-frame does the 2D enter/leave via the screen protocol.
;;;;
;;;; This layer is clautolisp-independent; the =clal-= AutoLISP wrappers live in
;;;; clautolisp. Windows (§5) and their layout tree are added on top.

(defstruct (frame (:constructor %make-frame) (:predicate framep))
  (name "" :type string)
  (device :tty :type (member :tty :vdt))
  (width 80 :type fixnum)
  (height 24 :type fixnum)
  (minibuffer-p nil)      ; T when the frame carries a minibuffer window
  (screen nil)            ; the TUI-SCREEN backend of a :vdt frame, else NIL
  (windows '())           ; window objects (§5), set up by the window API
  (layout nil)            ; the layout tree over WINDOWS
  (selected-window nil))  ; the frame's active window

;; Concise printers: frames and windows point at each other (window-frame ↔
;; frame-windows), so the default structure printer would recurse forever.
(defmethod print-object ((f frame) stream)
  (print-unreadable-object (f stream :type t :identity t)
    (format stream "~S ~A" (frame-name f) (frame-device f))))

(defvar *frames* '() "All live frames, most-recently-created first.")
(defvar *selected-frame* nil "The currently active frame, or NIL.")

(defun frame-list () (copy-list *frames*))
(defun selected-frame () *selected-frame*)

(defun make-frame (&optional options)
  "Create a frame per OPTIONS, an alist of: =name=, =width=, =height=,
=(minibuffer . t|nil)=, =(device . tty|vdt)=, and — for a vdt frame — =(screen
. TUI-SCREEN)=. Adds it to the frame list; does NOT select it. A vdt frame with
a screen takes its size from the screen (TUI-SIZE) unless width/height are
given."
  (flet ((opt (key default) (let ((c (assoc key options))) (if c (cdr c) default))))
    (let* ((device (opt :device :tty))
           (screen (opt :screen nil))
           (frame (%make-frame :name (opt :name (string-downcase (symbol-name device)))
                               :device device
                               :minibuffer-p (and (opt :minibuffer nil) t)
                               :screen screen)))
      (when (and (eq device :vdt) screen)
        (multiple-value-bind (rows cols) (tui-size screen)
          (setf (frame-height frame) rows (frame-width frame) cols)))
      (when (assoc :width options)  (setf (frame-width frame)  (opt :width 80)))
      (when (assoc :height options) (setf (frame-height frame) (opt :height 24)))
      (push frame *frames*)
      frame)))

(defun set-frame-name (frame string) (setf (frame-name frame) string))
(defun set-frame-width (frame n) (setf (frame-width frame) n))
(defun set-frame-height (frame n) (setf (frame-height frame) n))

(defun frame-minibuffer (frame)
  "The frame's minibuffer window, or NIL."
  (find :minibuffer (frame-windows frame) :key #'window-role))

(defun select-frame (frame)
  "Make FRAME the selected frame (§4.1). A vdt frame enters 2D mode
(TUI-START on its screen); leaving a vdt frame for another leaves 2D mode
(TUI-STOP on the previous screen), which restores the tty page."
  (let ((prev *selected-frame*))
    (when (and prev (not (eq prev frame))
               (eq (frame-device prev) :vdt) (frame-screen prev))
      (tui-stop (frame-screen prev)))
    (setf *selected-frame* frame)
    (when (and (eq (frame-device frame) :vdt) (frame-screen frame))
      (tui-start (frame-screen frame)))
    frame))

(defun delete-frame (frame)
  "Remove FRAME from the frame list and delete it (§4.1). If it was selected,
selects another frame."
  (when (and (eq (frame-device frame) :vdt) (frame-screen frame))
    (tui-stop (frame-screen frame)))
  (setf *frames* (remove frame *frames*))
  (when (eq *selected-frame* frame)
    (setf *selected-frame* (first *frames*))
    (when *selected-frame* (select-frame *selected-frame*)))
  nil)

(defun terminal-device-supports-vdt-p (&optional screen)
  "Whether a vdt frame can be created/used. With a SCREEN argument, whether that
backend is usable; the CLI passes the resolved curses screen (libncurses /
PDCurses loadable, a real terminal). NIL means stay on tty."
  (and screen t))

(defun ensure-initial-tty-frame ()
  "Make and select the initial tty-frame \"autolisp\" if no frame exists yet."
  (or *selected-frame*
      (select-frame (make-frame '((name . "autolisp") (device . tty))))))

(defun reset-frames ()
  "Drop all frames (for tests / a fresh session)."
  (setf *frames* '() *selected-frame* nil))
