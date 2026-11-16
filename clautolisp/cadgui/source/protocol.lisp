;;;; The cadgui protocol: the surface the embedded-ECL Qt6 shell calls.
;;;; cadgui-2-qt6-gui-host.issue slices C/D/E/F (CL side).
;;;;
;;;; The boundary is deliberately NARROW and crosses only on regen and input:
;;;;   cadgui-display-list / cadgui-extents  -- pull, once per regen (slices C/F)
;;;;   cadgui-supply-point / -entity         -- the shell pushes an input value
;;;;                                            for a blocked command (slice D)
;;;;   cadgui-eval-command                   -- run the command line (slice E)
;;;; plus model builders so a demo / the shell can populate the drawing through
;;;; the real cador engine without the full AutoLISP eval.

(in-package #:clautolisp.cadgui)

(declaim (inline %df))
(defun %df (x) (coerce x 'double-float))

;;; --- scene: what the shell pulls to paint (slices C/F) ----------------

(defun cadgui-display-list ()
  "The display list of the active session's drawing -- the surface the Qt shell
paints: a list of (:POLYLINE HANDLE LAYER ACI CLOSED (X0 Y0 X1 Y1 ...)) in world
coordinates. Crosses the ECL boundary once per regen, never per frame."
  (clautolisp.cador:cador-scene-display-list
   (cadgui-session-host (cadgui-session-or-start))))

(defun cadgui-extents ()
  "(XMIN YMIN XMAX YMAX) of the active drawing's geometry, or NIL when empty.
Drives zoom-extents."
  (clautolisp.cador:cador-scene-extents
   (cadgui-session-host (cadgui-session-or-start))))

(defun cadgui-entity-count ()
  "Number of drawable primitives currently in the scene."
  (length (cadgui-display-list)))

;;; --- model builders: populate the model via the REAL cador HAL --------
;;; Same path commands use (host-entmake), so what renders is the genuine engine
;;; state, not a GUI-side mock. The full AutoLISP command eval is slice E.

(defun cadgui-add-line (x1 y1 x2 y2 &key (layer "0") color)
  "Add a LINE to the active drawing through the cador HAL. Returns its ename."
  (let ((host (cadgui-session-host (cadgui-session-or-start))))
    (clautolisp.autolisp-host:host-entmake
     host
     (append (list (cons 0 "LINE") (cons 8 layer))
             (when color (list (cons 62 color)))
             (list (cons 10 (list (%df x1) (%df y1) 0d0))
                   (cons 11 (list (%df x2) (%df y2) 0d0)))))))

(defun cadgui-add-circle (cx cy r &key (layer "0") color)
  "Add a CIRCLE to the active drawing through the cador HAL. Returns its ename."
  (let ((host (cadgui-session-host (cadgui-session-or-start))))
    (clautolisp.autolisp-host:host-entmake
     host
     (append (list (cons 0 "CIRCLE") (cons 8 layer))
             (when color (list (cons 62 color)))
             (list (cons 10 (list (%df cx) (%df cy) 0d0)) (cons 40 (%df r)))))))

;;; --- interactive input (slice D scaffold) -----------------------------
;;; A command blocked in getpoint/entsel/ssget sets *cadgui-pending-input* to
;;; the TYPE it awaits; the shell reads it to set the canvas mode, and on a
;;; mouse event calls cadgui-supply-* with a typed value. The nested Qt event
;;; loop (validated by spike-ecl-embed/interactive.cpp) is the shell-side half;
;;; feeding the value back through cador's read-prompt-line chokepoint so the
;;; blocked (getpoint) RESUMES is the remainder of slice D.

(defvar *cadgui-pending-input* nil
  "NIL, or a keyword (:point / :entity / :selection) naming what the active
command is blocked awaiting -- the shell reads it to set the canvas mode.")

(defvar *cadgui-last-supplied* nil
  "The last value the shell supplied, as a typed list -- the scaffold's stand-in
for resuming the parked read.")

(defun cadgui-pending-input () *cadgui-pending-input*)

(defun cadgui-supply-point (x y)
  "The shell supplies a picked world point for a blocked (getpoint). Returns the
typed value (:point X Y)."
  (setf *cadgui-last-supplied* (list :point (%df x) (%df y))))

(defun cadgui-supply-entity (handle)
  "The shell supplies a picked entity (by its scene HANDLE string) for a blocked
(entsel). Returns (:entity HANDLE)."
  (setf *cadgui-last-supplied* (list :entity handle)))

;;; --- command evaluation (slice E scaffold) ----------------------------

(defun cadgui-eval-command (string)
  "Evaluate STRING against the active drawing and return the new scene entity
count, so the shell knows a regen is due. Scaffold: the full repl-loop /
AutoLISP eval path (so a typed LISP C: command runs, and (command ...) draws) is
the slice-E remainder; model builders above cover the demo path meanwhile."
  (declare (ignore string))
  (cadgui-entity-count))
