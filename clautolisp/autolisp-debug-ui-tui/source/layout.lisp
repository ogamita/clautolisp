(in-package #:clautolisp.ui.tui)

;;;; Window layout tree (TUI module spec §5.1). A layout is a binary tree of
;;;; splits over the windows of a frame:
;;;;
;;;;   leaf         any non-cons designator of a window — a keyword id
;;;;                (:stack …) in the debugger, or a WINDOW object in tui-core.
;;;;   :horizontal  (:horizontal RATIO ABOVE BELOW) — ABOVE stacked over BELOW.
;;;;                The separator IS ABOVE's status line, so no row is spent.
;;;;   :vertical    (:vertical RATIO LEFT RIGHT) — LEFT and RIGHT side by side
;;;;                with a one-column "|" separator between them.
;;;;
;;;; RATIO (0<r<1) is the fraction of the split's primary dimension given to the
;;;; first child. A LEAF is anything that is not a split (an atom); a SPLIT is a
;;;; list whose head is :horizontal or :vertical. This layer is
;;;; clautolisp-independent and works over any leaf value.

(defun %split-p (node)
  (and (consp node) (member (first node) '(:horizontal :vertical))))

(defun layout-leaves (tree)
  "The leaves of TREE in reading order: left-to-right, top-to-bottom."
  (if (%split-p tree)
      (destructuring-bind (split ratio a b) tree
        (declare (ignore split ratio))
        (append (layout-leaves a) (layout-leaves b)))
      (list tree)))

(defun window-cycle (tree current &optional (delta 1))
  "The leaf DELTA steps from CURRENT in reading order, wrapping around."
  (let* ((order (layout-leaves tree))
         (pos (or (position current order) 0)))
    (nth (mod (+ pos delta) (length order)) order)))

(defun layout-rects (tree top left height width)
  "Compute rectangles for the leaves of TREE within (TOP LEFT HEIGHT WIDTH).
Return (values ALIST VLINES): ALIST maps each leaf to a rectangle (list TOP
LEFT HEIGHT WIDTH); VLINES is a list of (COL TOP HEIGHT) vertical separator
segments. HEIGHT should already exclude the minibuffer row. Each window's
bottom row is its status line; a :vertical split spends one column on \"|\"."
  (labels ((rec (node top left height width alist vlines)
             (if (%split-p node)
                 (destructuring-bind (split ratio a b) node
                   (ecase split
                     (:vertical
                      (let* ((aw (max 1 (min (- width 2)
                                             (floor (* ratio (- width 1))))))
                             (sep (+ left aw))
                             (bw (- width aw 1)))
                        (multiple-value-bind (al vl)
                            (rec a top left height aw alist vlines)
                          (rec b top (+ sep 1) height bw al
                               (cons (list sep top height) vl)))))
                     (:horizontal
                      (let* ((ah (max 1 (min (- height 1)
                                             (floor (* ratio height)))))
                             (bh (- height ah)))
                        (multiple-value-bind (al vl)
                            (rec a top left ah width alist vlines)
                          (rec b (+ top ah) left bh width al vl))))))
                 (values (acons node (list top left height width) alist) vlines))))
    (rec tree top left height width '() '())))

;;;; --- rectangles + neighbour search --------------------------------

(defun rect-top (r) (first r))
(defun rect-left (r) (second r))
(defun rect-bottom (r) (+ (first r) (third r)))
(defun rect-right (r) (+ (second r) (fourth r)))

(defun rects-row-overlap-p (a b)   ; share a row (vertical spans overlap)
  (and (< (rect-top a) (rect-bottom b)) (< (rect-top b) (rect-bottom a))))
(defun rects-col-overlap-p (a b)   ; share a column (horizontal spans overlap)
  (and (< (rect-left a) (rect-right b)) (< (rect-left b) (rect-right a))))

(defun %extreme (entries key test)
  (when entries
    (reduce (lambda (x y) (if (funcall test (funcall key x) (funcall key y)) x y))
            entries)))

(defun window-neighbor (rects active direction)
  "The leaf next to ACTIVE in DIRECTION (:right :left :above :below), with
wrap-around within ACTIVE's row/column, or NIL when ACTIVE has no mate."
  (let* ((ar (cdr (assoc active rects)))
         (others (remove active rects :key #'car))
         (r (lambda (e) (cdr e))))
    (flet ((mates (overlap) (remove-if-not (lambda (e) (funcall overlap ar (funcall r e))) others)))
      (let* ((pick
              (ecase direction
                (:right (let ((m (mates #'rects-row-overlap-p)))
                          (or (%extreme (remove-if-not (lambda (e) (>= (rect-left (funcall r e)) (rect-right ar))) m)
                                        (lambda (e) (rect-left (funcall r e))) #'<)
                              (%extreme m (lambda (e) (rect-left (funcall r e))) #'<))))
                (:left  (let ((m (mates #'rects-row-overlap-p)))
                          (or (%extreme (remove-if-not (lambda (e) (<= (rect-right (funcall r e)) (rect-left ar))) m)
                                        (lambda (e) (rect-right (funcall r e))) #'>)
                              (%extreme m (lambda (e) (rect-right (funcall r e))) #'>))))
                (:below (let ((m (mates #'rects-col-overlap-p)))
                          (or (%extreme (remove-if-not (lambda (e) (>= (rect-top (funcall r e)) (rect-bottom ar))) m)
                                        (lambda (e) (rect-top (funcall r e))) #'<)
                              (%extreme m (lambda (e) (rect-top (funcall r e))) #'<))))
                (:above (let ((m (mates #'rects-col-overlap-p)))
                          (or (%extreme (remove-if-not (lambda (e) (<= (rect-bottom (funcall r e)) (rect-top ar))) m)
                                        (lambda (e) (rect-bottom (funcall r e))) #'>)
                              (%extreme m (lambda (e) (rect-bottom (funcall r e))) #'>)))))))
        (and pick (car pick))))))

;;;; --- tree edits: swap, resize, balance, remove, split -------------

(defun tree-swap-leaves (tree a b)
  "Exchange the two leaves A and B in TREE."
  (cond ((eql tree a) b)
        ((eql tree b) a)
        ((%split-p tree)
         (destructuring-bind (split ratio x y) tree
           (list split ratio (tree-swap-leaves x a b) (tree-swap-leaves y a b))))
        (t tree)))

(defun clamp-ratio (r) (max 1/8 (min 7/8 r)))

(defun tree-resize (tree active delta)
  "Adjust the ratio of the split directly enclosing leaf ACTIVE by DELTA
(positive grows ACTIVE), clamped. No cascade to outer splits yet."
  (labels ((rec (node)
             (if (%split-p node)
                 (destructuring-bind (split ratio a b) node
                   (cond ((eql a active) (list split (clamp-ratio (+ ratio delta)) a b))
                         ((eql b active) (list split (clamp-ratio (- ratio delta)) a b))
                         (t (list split ratio (rec a) (rec b)))))
                 node)))
    (rec tree)))

(defun tree-balance (tree active)
  "Set the split directly enclosing ACTIVE back to an even 1/2, leaving the
other splits' ratios untouched."
  (labels ((rec (node)
             (if (%split-p node)
                 (destructuring-bind (split ratio a b) node
                   (if (or (eql a active) (eql b active))
                       (list split 1/2 a b)
                       (list split ratio (rec a) (rec b))))
                 node)))
    (rec tree)))

(defun tree-remove-leaf (tree leaf)
  "Remove LEAF, collapsing its parent split into LEAF's sibling."
  (if (%split-p tree)
      (destructuring-bind (split ratio a b) tree
        (cond ((eql a leaf) b)
              ((eql b leaf) a)
              (t (list split ratio (tree-remove-leaf a leaf) (tree-remove-leaf b leaf)))))
      tree))

(defun tree-split-active (tree active next split-type)
  "Replace ACTIVE's leaf with (SPLIT-TYPE 1/2 ACTIVE NEXT) after removing NEXT
from elsewhere, so the window count stays constant (C-w 2 / C-w 3)."
  (let ((pruned (tree-remove-leaf tree next)))
    (labels ((rec (node)
               (cond ((eql node active) (list split-type 1/2 active next))
                     ((%split-p node)
                      (destructuring-bind (s r a b) node
                        (list s r (rec a) (rec b))))
                     (t node))))
      (rec pruned))))
