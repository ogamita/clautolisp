(in-package #:clautolisp.cadtui)

;;;; Tree builders for the two hosting configurations (Phase 1 slice 2).
;;;;
;;;; --host cadtui instantiates the full tree; --host cador the degenerate one
;;;; reduced to /application/console (no menu-bar, empty drawings[]) — cador is
;;;; a UI-tree configuration of cadtui, not separate code (spec §Architecture,
;;;; cadtui/CLAUDE.md). The CLI --host routing that selects between them is
;;;; Phase 4; these builders are the Phase-1 stand-in and the thing the dumps
;;;; and (Phase 3) address tests are built over.
;;;;
;;;; CHILDREN is the canonical tree the dump/navigation walker traverses; the
;;;; typed convenience slots (an application's MENUBAR/CONSOLE) are set to point
;;;; at the same objects for direct access, but nothing in Phase 1 depends on
;;;; them.

(defun make-application-tree ()
  "Build the full --host cadtui skeleton: an /application root carrying an
(empty) menu-bar and the application console. drawings[] is empty until a
drawing is opened (Phase 4). Returns the root UI-APPLICATION."
  (let ((app (make-instance 'ui-application :key "application")))
    (add-child app (make-instance 'ui-menubar :key "menu-bar"))
    (add-child app (make-instance 'ui-console :key "console"))
    (setf (ui-menubar-slot app) (ui-find-child app "menu-bar")
          (ui-console-slot app) (ui-find-child app "console"))
    app))

(defun make-cador-tree ()
  "Build the degenerate --host cador configuration: an /application root with
only the application console — no menu-bar, empty drawings[]. Returns the root
UI-APPLICATION."
  (let ((app (make-instance 'ui-application :key "application")))
    (add-child app (make-instance 'ui-console :key "console"))
    (setf (ui-console-slot app) (ui-find-child app "console"))
    app))
