;;;; The cadgui protocol: the surface the embedded-ECL Qt6 shell calls.
;;;; cadgui-2-qt6-gui-host.issue slices C/E/F (CL side); slice D is input.lisp.
;;;;
;;;; The boundary is NARROW and crosses only on regen and input:
;;;;   cadgui-display-list / cadgui-extents  -- pull, once per regen (C/F)
;;;;   cadgui-eval-command                   -- run the command line (E); its
;;;;                                            getpoint/entsel read the canvas
;;;;                                            through the slice-D input stream
;;;; plus model builders so a demo / the shell can populate the drawing through
;;;; the real cador engine.

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
  "Number of drawable primitives currently in the scene (a coarse regen signal)."
  (length (cadgui-display-list)))

(defun cadgui-regen-serial ()
  "The active drawing's monotonic modification serial (DRAWING-DBTICK): it
changes on EVERY database change and never resets. The shell reads it before
and after a command and regens (re-exports + repaints) only when it changed --
cheaper and more reliable than re-pulling the whole display list or than DBMOD
(a sticky bitfield whose value does not change on repeated same-kind edits).
Returns 0 when there is no active drawing."
  (let* ((host (cadgui-session-host (cadgui-session-or-start)))
         (drawing (clautolisp.cador:cador-active-drawing host)))
    (if drawing (clautolisp.drawing:drawing-dbtick drawing) 0)))

(defun cadgui-selection-geometry ()
  "The display-list item(s) of the current GUI selection -- the entity most
recently picked by (entsel) from the canvas -- for the shell to overdraw
HIGHLIGHTED, or NIL. Same (:POLYLINE HANDLE LAYER ACI CLOSED POINTS) format as
cadgui-display-list, so no handle correlation is needed: the shell draws this
geometry on top of the scene in the highlight style. A deleted selection yields
NIL."
  (let* ((host (cadgui-session-host (cadgui-session-or-start)))
         (entity (clautolisp.cador:cador-last-pick host)))
    (when entity
      (let ((item (clautolisp.cador:cador-entity-scene-item host entity)))
        (and item (list item))))))

(defun cadgui-selection ()
  "The handle string(s) of the current GUI selection, or NIL (the HANDLE fields
of cadgui-selection-geometry)."
  (mapcar #'second (cadgui-selection-geometry)))

;;; --- model builders: populate the model via the REAL cador HAL --------

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

;;; --- command evaluation (slice E) -------------------------------------
;;; cadgui-eval-command evaluates an AutoLISP string against the active drawing
;;; through the REAL engine (run-autolisp-string + the core builtins, with the
;;; session host bound to our cador document). So a typed LISP C: command, or
;;; (command ...) / (entmake ...), runs and DRAWS; and any getpoint/entsel it
;;; performs reads the canvas through the slice-D input stream. Returns the new
;;; scene entity count, so the shell knows a regen (repaint) is due.

(defun %cadgui-setup-context (context host)
  "run-autolisp-string setup-fn: install the core builtins and bind the fresh
session's host to our persistent cador document, so commands draw on it."
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (clautolisp.autolisp-runtime:set-runtime-session-host
   (clautolisp.autolisp-runtime:evaluation-context-session context)
   host))

(defun cadgui-eval-command (string)
  "Evaluate STRING as AutoLISP against the active drawing and return the new
scene entity count (the regen signal)."
  (let ((host (cadgui-session-host (cadgui-session-or-start))))
    (clautolisp.autolisp-runtime:run-autolisp-string
     string
     :setup-fn (lambda (context) (%cadgui-setup-context context host))))
  (cadgui-entity-count))
