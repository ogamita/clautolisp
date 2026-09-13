(in-package #:clautolisp.cadtui)

;;;; CAD view: entities, grips, bounding boxes, the viewport (Phase 5).
;;;;
;;;; Entities live in a pure clautolisp.drawing:drawing value; cadtui mirrors
;;;; them into ui-entity / ui-grip nodes LAZILY, one dumped page at a time (a
;;;; real drawing may hold 5000+ entities, so we never materialise them all --
;;;; the filter iterates entity VALUES and only the shown page becomes nodes;
;;;; spec §Pagination / §"Navigation spatiale 2D"). Slice 1 lands the geometry
;;;; primitives + the single-entity mirror; the filter/paginate/dump-entities
;;;; driver is slice 3.

;;; --- The viewport (fenetre-visualisation) -------------------------

(defstruct viewport
  "A CAD view's visible world window + scale (the fenetre-visualisation). The
default entity dump culls to these bounds; zoom changes them, dump does not."
  (x1 0.0d0) (y1 0.0d0) (x2 0.0d0) (y2 0.0d0) (scale 1.0d0))

(defun viewport-bounds (viewport)
  "The (x1 y1 x2 y2) world rectangle of VIEWPORT, or NIL when VIEWPORT is unset."
  (when viewport
    (list (viewport-x1 viewport) (viewport-y1 viewport)
          (viewport-x2 viewport) (viewport-y2 viewport))))

;;; --- Bounding boxes + intersection --------------------------------

(defparameter +point-group-codes+ '(10 11 12 13)
  "The DXF group codes whose value is a coordinate list (x y z).")

(defun entity-bounding-box (entity)
  "The 2D bounding box (minx miny maxx maxy) over ENTITY's own point groups
(DXF codes 10/11/12/13), or NIL when it carries no coordinates. Block/insert
and text-height expansion are deferred (an approximation over own geometry)."
  (let ((xs '()) (ys '()))
    (dolist (group (entity-dxf entity))
      (when (member (car group) +point-group-codes+)
        (let ((coord (cdr group)))
          (when (and (numberp (first coord)) (numberp (second coord)))
            (push (first coord) xs)
            (push (second coord) ys)))))
    (when xs
      (list (reduce #'min xs) (reduce #'min ys)
            (reduce #'max xs) (reduce #'max ys)))))

(defun %normalise-rect (rect)
  "Order RECT's corners so x1<=x2 and y1<=y2."
  (destructuring-bind (a b c d) rect
    (list (min a c) (min b d) (max a c) (max b d))))

(defun %bbox-intersects-p (box window)
  "True when the 2D BOX (minx miny maxx maxy) overlaps WINDOW (a world
rectangle). A NIL BOX (an entity with no coordinates) never intersects a finite
window."
  (when box
    (destructuring-bind (bx1 by1 bx2 by2) (%normalise-rect box)
      (destructuring-bind (wx1 wy1 wx2 wy2) (%normalise-rect window)
        (and (<= bx1 wx2) (>= bx2 wx1)
             (<= by1 wy2) (>= by2 wy1))))))

;;; --- The single-entity mirror -------------------------------------

(defun entity->ui-entity (entity)
  "Build the ui-entity mirroring the drawing ENTITY: key = handle string,
type = DXF group 0, layer = DXF group 8, properties = the DXF alist, with a
ui-grip child (1-based index) per point group."
  (let* ((dxf (entity-dxf entity))
         (handle (entity-handle-string entity))
         (ui (make-instance 'ui-entity
                            :key handle
                            :entity-type (cdr (assoc 0 dxf))
                            :layer (cdr (assoc 8 dxf))
                            :properties dxf
                            :handles handle)))
    (let ((index 0))
      (dolist (group dxf)
        (when (member (car group) +point-group-codes+)
          (incf index)
          (add-child ui (make-instance 'ui-grip
                                       :key (princ-to-string index)
                                       :index index
                                       :point (cdr group))))))
    ui))
