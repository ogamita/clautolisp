;;;; cador scene view -- the DRAWABLE view of the model, the render peer of the
;;;; selection view (selection-api.lisp). Walks the current (model) space and
;;;; tessellates each graphical entity to a world-space polyline, producing a
;;;; DISPLAY LIST a GUI canvas (the cadgui host) paints. Host-agnostic: it reads
;;;; the cador model only, no Qt, so it is unit-tested headless.
;;;;
;;;; cadgui-2-qt6-gui-host.issue slice B.

(in-package #:clautolisp.cador)

(defun %scene-df (x) (coerce (%ss-num x) 'double-float))

(defun %scene-flatten (points)
  "A list of (X Y) pairs -> a flat (X0 Y0 X1 Y1 ...) of double-floats."
  (loop for (x y) in points collect (%scene-df x) collect (%scene-df y)))

(defun %scene-entity-points (host entity)
  "(values FLAT-POINTS CLOSED-P) tracing ENTITY as a world-space polyline, or
(values NIL NIL) when it has no drawable geometry. CIRCLE is sampled to a
closed polyline; LINE/ARC/LWPOLYLINE/POINT use the exact outline; anything else
(TEXT/MTEXT/INSERT/...) falls back to its bounding-box rectangle placeholder."
  (case (entity-handle-kind entity)
    (:circle
     (let ((c (%entity-group-value entity 10)) (r (%entity-group-value entity 40)))
       (if (and c (realp r))
           (values (%scene-flatten (%ss-arc-points (%ss-num (first c)) (%ss-num (second c))
                                                   (%ss-num r) 0d0 (coerce (* 2 pi) 'double-float)))
                   t)
           (values nil nil))))
    (t
     (multiple-value-bind (points closed) (%ss-entity-outline entity)
       (if points
           (values (%scene-flatten points) (and closed t))
           (let ((box (%ss-entity-box host entity)))
             (if box
                 (destructuring-bind (x0 y0 x1 y1) box
                   (values (list (%scene-df x0) (%scene-df y0) (%scene-df x1) (%scene-df y0)
                                 (%scene-df x1) (%scene-df y1) (%scene-df x0) (%scene-df y1))
                           t))
                 (values nil nil))))))))

(defun %scene-entity-display-item (host handle entity)
  "The (:POLYLINE HANDLE LAYER ACI CLOSED POINTS) display item for ENTITY under
HANDLE (a string), or NIL when ENTITY has no drawable geometry."
  (multiple-value-bind (points closed) (%scene-entity-points host entity)
    (when points
      (list :polyline
            handle
            (let ((layer (%entity-group-value entity 8)))
              (if (stringp layer) layer "0"))
            (let ((aci (%entity-group-value entity 62)))
              (if (integerp aci) aci 256))
            closed
            points))))

(defun cador-scene-display-list (host &optional (drawing (cador-active-drawing host)))
  "The display list of DRAWING's (model) space graphical entities: a list of
  (:POLYLINE HANDLE LAYER ACI CLOSED (X0 Y0 X1 Y1 ...))
in world coordinates, in creation order (back to front). HANDLE is the entity's
creation-order handle as a string (for pick correlation/highlight), LAYER its
layer name, ACI its colour index (256 = BYLAYER, 0 = BYBLOCK), CLOSED whether
the polyline closes, and the last element the flat double-float coordinates.
The render peer of HOST-SSGET \"X\"; the whole surface the cadgui canvas needs.
DRAWING defaults to the active one; pass a specific open document's drawing to
render it without making it current (a multi-document GUI renders each window's
own drawing while another document is active)."
  (let ((prims '()))
    (dolist (handle (reverse (clautolisp.drawing:drawing-creation-order drawing)))
      (let ((entity (clautolisp.drawing:find-entity drawing handle)))
        (when (and entity
                   (not (entity-handle-deleted-p entity))
                   (main-space-entity-p entity)
                   (clautolisp.drawing:graphical-entity-p entity))
          (let ((item (%scene-entity-display-item host (princ-to-string handle) entity)))
            (when item (push item prims))))))
    (nreverse prims)))

(defun cador-entity-scene-item (host entity)
  "The display-list item (:POLYLINE ...) for a single live graphical ENTITY --
the selection-highlight peer of CADOR-SCENE-DISPLAY-LIST -- or NIL. Same
tessellation, so the shell overdraws the exact same outline, highlighted."
  (when (and entity
             (not (entity-handle-deleted-p entity))
             (clautolisp.drawing:graphical-entity-p entity))
    (%scene-entity-display-item host (clautolisp.drawing:entity-handle-string entity) entity)))

(defun cador-scene-extents (host &optional (drawing (cador-active-drawing host)))
  "(XMIN YMIN XMAX YMAX) of DRAWING's model-space graphical geometry as
double-floats, or NIL when the space is empty. Drives zoom-extents. DRAWING
defaults to the active one; pass a specific open document's drawing to measure
it without making it current."
  (let (xmin ymin xmax ymax)
    (dolist (handle (clautolisp.drawing:drawing-creation-order drawing))
      (let ((entity (clautolisp.drawing:find-entity drawing handle)))
        (when (and entity
                   (not (entity-handle-deleted-p entity))
                   (main-space-entity-p entity)
                   (clautolisp.drawing:graphical-entity-p entity))
          (let ((box (%ss-entity-box host entity)))
            (when box
              (destructuring-bind (x0 y0 x1 y1) box
                (setf xmin (if xmin (min xmin x0) x0)
                      ymin (if ymin (min ymin y0) y0)
                      xmax (if xmax (max xmax x1) x1)
                      ymax (if ymax (max ymax y1) y1))))))))
    (and xmin (list (coerce xmin 'double-float) (coerce ymin 'double-float)
                    (coerce xmax 'double-float) (coerce ymax 'double-float)))))
