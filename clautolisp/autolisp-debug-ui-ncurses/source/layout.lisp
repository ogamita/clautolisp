(in-package #:clautolisp.ui.ncurses)

;;;; Window layout tree for the four-pane ncurses UI (ncurses-windows.issue).
;;;;
;;;; A layout is a binary tree of splits over the four debugger windows:
;;;;
;;;;   leaf         a window id keyword — :stack :source :interactor :repl
;;;;   :horizontal  (:horizontal RATIO ABOVE BELOW) — ABOVE stacked over BELOW.
;;;;                The separator IS ABOVE's status line, so no row is spent on
;;;;                it (ncurses-windows.issue "display": horizontal separations
;;;;                use the status line).
;;;;   :vertical    (:vertical RATIO LEFT RIGHT) — LEFT and RIGHT side by side
;;;;                with a one-column "|" separator between them.
;;;;
;;;; RATIO (0<r<1) is the fraction of the split's primary dimension given to
;;;; the first child. Every layout has exactly the four leaves, each once.

(defparameter +window-ids+ '(:stack :source :interactor :repl))

(defparameter +window-titles+
  '((:stack . "stack") (:source . "source")
    (:interactor . "interactor") (:repl . "repl")))

(defun window-title (id)
  (or (cdr (assoc id +window-titles+)) (string-downcase (symbol-name id))))

(defun default-layout ()
  "The canonical 2x2: (stack | source) above (interactor | repl)."
  (list :horizontal 1/2
        (list :vertical 1/2 :stack :source)
        (list :vertical 1/2 :interactor :repl)))

(defun layout-leaves (tree)
  "The window ids in reading order: left-to-right, top-to-bottom."
  (if (keywordp tree)
      (list tree)
      (destructuring-bind (split ratio a b) tree
        (declare (ignore split ratio))
        (append (layout-leaves a) (layout-leaves b)))))

(defun window-cycle (tree current &optional (delta 1))
  "The window DELTA steps from CURRENT in reading order, wrapping around."
  (let* ((order (layout-leaves tree))
         (pos (or (position current order) 0)))
    (nth (mod (+ pos delta) (length order)) order)))

(defun layout-rects (tree top left height width)
  "Compute window rectangles for TREE within (TOP LEFT HEIGHT WIDTH).
Return (values ALIST VLINES): ALIST maps each window id to a rectangle
(list TOP LEFT HEIGHT WIDTH); VLINES is a list of (COL TOP HEIGHT) vertical
separator segments. HEIGHT should already exclude the minibuffer row.

Each window's bottom row is its status line; a window therefore needs at
least 1 content row + 1 status row, and a :vertical split spends one column
on the \"|\" separator."
  (labels ((rec (node top left height width alist vlines)
             (if (keywordp node)
                 (values (acons node (list top left height width) alist) vlines)
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
                          (rec b (+ top ah) left bh width al vl)))))))))
    (rec tree top left height width '() '())))

;;;; --- window moves: swap, reset, resize (ncurses-windows.issue) ------

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
  "The window id next to ACTIVE in DIRECTION (:right :left :above :below), with
wrap-around within ACTIVE's row/column (ncurses-windows.issue), or NIL when
ACTIVE has no row/column mate."
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

(defun tree-swap-leaves (tree a b)
  "Exchange the two leaf window ids A and B in TREE."
  (cond ((eq tree a) b)
        ((eq tree b) a)
        ((keywordp tree) tree)
        (t (destructuring-bind (split ratio x y) tree
             (list split ratio (tree-swap-leaves x a b) (tree-swap-leaves y a b))))))

(defun clamp-ratio (r) (max 1/8 (min 7/8 r)))

(defun tree-resize (tree active delta)
  "Adjust the ratio of the split directly enclosing leaf ACTIVE by DELTA
(positive grows ACTIVE), clamped. Returns a new tree; no cascade to outer
splits yet."
  (labels ((rec (node)
             (if (keywordp node)
                 node
                 (destructuring-bind (split ratio a b) node
                   (cond ((eq a active) (list split (clamp-ratio (+ ratio delta)) a b))
                         ((eq b active) (list split (clamp-ratio (- ratio delta)) a b))
                         (t (list split ratio (rec a) (rec b))))))))
    (rec tree)))

(defun tree-balance (tree active)
  "Set the split directly enclosing ACTIVE back to an even 1/2, leaving the
other splits' ratios untouched."
  (labels ((rec (node)
             (if (keywordp node)
                 node
                 (destructuring-bind (split ratio a b) node
                   (if (or (eq a active) (eq b active))
                       (list split 1/2 a b)
                       (list split ratio (rec a) (rec b)))))))
    (rec tree)))

(defun tree-remove-leaf (tree leaf)
  "Remove LEAF, collapsing its parent split into LEAF's sibling."
  (if (keywordp tree)
      tree
      (destructuring-bind (split ratio a b) tree
        (cond ((eq a leaf) b)
              ((eq b leaf) a)
              (t (list split ratio (tree-remove-leaf a leaf) (tree-remove-leaf b leaf)))))))

(defun tree-split-active (tree active next split-type)
  "Replace ACTIVE's leaf with (SPLIT-TYPE 1/2 ACTIVE NEXT) after removing NEXT
from elsewhere, so the window count stays four (ncurses-windows.issue: C-w 2 /
C-w 3 open a split and re-home the next window into it)."
  (let ((pruned (tree-remove-leaf tree next)))
    (labels ((rec (node)
               (cond ((eq node active) (list split-type 1/2 active next))
                     ((keywordp node) node)
                     (t (destructuring-bind (s r a b) node
                          (list s r (rec a) (rec b)))))))
      (rec pruned))))
