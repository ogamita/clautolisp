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
