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

;;; --- The paginated, spatially-culled entity dump ------------------
;;;
;;; A drawing may hold 5000+ entities; we iterate the pure entity VALUES (cheap)
;;; to count and cull, but only the SHOWN page ever becomes ui-entity nodes,
;;; which then replace the cad-view's children (the lazy one-page-at-a-time
;;; mirror). The provider closure recorded on the dump-descriptor re-runs the
;;; same filter for next/previous/page(n) without materialising the rest.

(defun %entity-page-provider (cad-view drawing window)
  "A (PAGE PAGE-SIZE) -> (values page-nodes total) closure over DRAWING's
entities, culled to WINDOW (NIL = no cull), mirroring the shown page into
CAD-VIEW's children (the lazy mirror)."
  (lambda (page page-size)
    (let ((matches '()))
      (when drawing
        (map-entities
         (lambda (e)
           (when (or (null window)
                     (%bbox-intersects-p (entity-bounding-box e) window))
             (push e matches)))
         drawing))
      (setf matches (nreverse matches))
      (let* ((total (length matches))
             (start (* (1- page) page-size))
             (page-vals (when (and (>= page 1) (< start total))
                          (subseq matches start (min total (+ start page-size)))))
             (nodes (mapcar #'entity->ui-entity page-vals)))
        ;; Replace the view's children with just this page's mirrored nodes.
        (dolist (n (ui-children cad-view)) (setf (ui-parent n) nil))
        (setf (ui-children cad-view) nodes)
        (dolist (n nodes) (setf (ui-parent n) cad-view))
        (values nodes total)))))

(defun dump-entities (cad-view &key (page 1) (page-size 50) window (path "")
                                    (stream *standard-output*))
  "Dump CAD-VIEW's entities as a paginated, D<n>-addressable list, spatially
culled to WINDOW (a (x1 y1 x2 y2) world rectangle) or, when WINDOW is NIL, to
the view's viewport bounds, or, when neither is set, not at all. Only the shown
page is mirrored into ui-entity nodes; the dump is registered with a provider so
next/previous/page(n) re-page lazily. Returns the DUMP-DESCRIPTOR."
  (let* ((drawing (ui-cad-view-drawing cad-view))
         (effective-window (or window (viewport-bounds (ui-viewport cad-view))))
         (provider (%entity-page-provider cad-view drawing effective-window)))
    (multiple-value-bind (nodes total) (funcall provider page page-size)
      (let ((descriptor (register-dump cad-view :path path :items nodes
                                       :total total :page page :page-size page-size
                                       :provider provider)))
        (dump-header path total :shown (length nodes) :page-size page-size
                     :number (dump-descriptor-number descriptor) :stream stream)
        (dolist (n nodes)
          (format stream "  ~A~%" (%node-dump-line n)))
        descriptor))))
