(in-package #:clautolisp.ui.ncurses)

;;;; Debugger-specific window identities for the four-pane ncurses UI. The
;;;; GENERIC layout-tree machinery — layout-leaves / window-cycle / layout-rects
;;;; / window-neighbor / tree-swap-leaves / tree-resize / tree-balance /
;;;; tree-remove-leaf / tree-split-active / the rect helpers — lives in the
;;;; tui-core module (clautolisp.ui.tui, autolisp-debug-ui-tui/source/layout.lisp)
;;;; and is inherited here through :USE. It now works over WINDOW OBJECTS: the
;;;; UI's four panes are real tui-core WINDOWs held in a vdt-frame, and the
;;;; layout tree tiles those objects. A window's semantic id is its ROLE
;;;; (:stack :source :interactor :repl); its title is its NAME.

(defparameter +window-roles+ '(:stack :source :interactor :repl)
  "The four debugger panes, in reading order (creation order in the frame).")

(defparameter +window-titles+
  '((:stack . "stack") (:source . "source")
    (:interactor . "interactor") (:repl . "repl")))

(defun role-title (role)
  (or (cdr (assoc role +window-titles+)) (string-downcase (symbol-name role))))

(defun build-debugger-windows (frame)
  "Create the four debugger panes as tui-core WINDOWs in FRAME (roles in
+window-roles+), returning them as an alist (ROLE . WINDOW). Uses the window
API (make-window targets the selected frame), then installs the canonical 2x2
layout over the window objects and selects the interactor pane."
  (let ((*selected-frame* frame))
    (let ((windows (loop for role in +window-roles+
                         collect (cons role
                                       (make-window (list (cons :name (role-title role))
                                                          (cons :role role)))))))
      (flet ((w (role) (cdr (assoc role windows))))
        (setf (frame-layout frame) (default-layout windows)
              (frame-selected-window frame) (w :interactor)))
      windows)))

(defun default-layout (windows)
  "The canonical 2x2 over the window objects: (stack | source) above
(interactor | repl). WINDOWS is an alist (ROLE . WINDOW)."
  (flet ((w (role) (cdr (assoc role windows))))
    (list :horizontal 1/2
          (list :vertical 1/2 (w :stack) (w :source))
          (list :vertical 1/2 (w :interactor) (w :repl)))))
