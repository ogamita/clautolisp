;;;; cador/source/viewports.lisp
;;;;
;;;; Viewports: VPORTS, CVPORT and the -VPORTS command, as measured by
;;;; probes/sources/probe-viewports.lsp -- suite vports (MR !417; AutoCAD 2022
;;;; job 16937174509, BricsCAD V25 Windows job 16937174513, BricsCAD V26
;;;; macOS job 16937174510) and suite vports-options (MR !418; jobs
;;;; 16941077236, 16941077240, 16941077237):
;;;;
;;;;   - a drawing starts with ONE tiled viewport, number 2 (CVPORT 2):
;;;;     (vports) => ((2 (0.0 0.0) (1.0 1.0))) on both products -- not the
;;;;     ((1 ...)) of the documentation's example;
;;;;   - (vports) lists the current viewport first, then the others by number;
;;;;   - -VPORTS 2 / 3 / 4 divide the CURRENT viewport into pieces (the
;;;;     tables below, per product and orientation): the current viewport
;;;;     takes the first piece, the others the smallest unused numbers (>= 2)
;;;;     in piece order. AutoCAD keeps the right / top / bottom-right piece
;;;;     for the current viewport, BricsCAD the left / bottom / bottom-left;
;;;;     the default orientation is Vertical for 2 and Right for 3 on both;
;;;;   - SIngle leaves one viewport over the whole screen: AutoCAD keeps the
;;;;     LOWEST-NUMBERED viewport OTHER than the current one (so a split then
;;;;     SIngle moves CVPORT), BricsCAD the lowest-numbered one;
;;;;   - Toggle maximises the current viewport, a second Toggle restores the
;;;;     layout; (setvar "CVPORT" n) makes tiled viewport n current;
;;;;   - Save NAME records the layout (a VPORT table record NAME); Restore NAME
;;;;     rebuilds it, the current viewport's number on the saved current piece
;;;;     and the smallest unused numbers on the rest; Delete NAME removes it;
;;;;   - TILEMODE 0: CVPORT 1, and (vports) is the sheet, viewport 1, then the
;;;;     layout's floating viewport 2 at (25.7 19.5) (231.3 175.5) on both;
;;;;     viewport 1's corners are the products' own display extents, kept as
;;;;     measured: AutoCAD (0.0 0.0) (15.8893 9.0), BricsCAD (-28.613 -13.59)
;;;;     (285.613 208.59).
;;;; Join was not measured (it picks viewports) and changes nothing.

(in-package #:clautolisp.cador)

(defun %viewport-product ()
  "The product whose measured viewport behaviour applies: :BRICSCAD under a
BricsCAD dialect, :AUTOCAD otherwise (strict / clautolisp follow AutoCAD)."
  (let ((dialect (ignore-errors (clautolisp.autolisp-runtime:current-evaluation-dialect))))
    (if (and dialect (eq :bricscad (clautolisp.autolisp-reader:autolisp-dialect-product dialect)))
        :bricscad
        :autocad)))

(defun cador-model-viewports (host)
  "HOST's current document's tiled viewports, (ID LLX LLY URX URY), the
current one first."
  (or (%cador-model-viewports host)
      (setf (%cador-model-viewports host) (list (list 2 0d0 0d0 1d0 1d0)))))

(defun cador-tilemode (host)
  (let ((cell (ignore-errors (cador-sysvar host "TILEMODE"))))
    (if (and cell (eql 0 (sysvar-cell-value cell))) 0 1)))

(defun cador-current-viewport-id (host)
  "CVPORT: 1 (the sheet) in paper space, else the current tiled viewport."
  (if (zerop (cador-tilemode host))
      1
      (first (first (cador-model-viewports host)))))

(defun %paper-sheet-viewport ()
  (if (eq (%viewport-product) :bricscad)
      (list 1 (list -28.613d0 -13.59d0) (list 285.613d0 208.59d0))
      (list 1 (list 0d0 0d0) (list 15.8893d0 9d0))))

(defmethod host-viewports ((host cador))
  (if (zerop (cador-tilemode host))
      (list (%paper-sheet-viewport)
            (list 2 (list 25.7d0 19.5d0) (list 231.3d0 175.5d0)))
      (mapcar (lambda (v)
                (destructuring-bind (id llx lly urx ury) v
                  (list id (list llx lly) (list urx ury))))
              (cador-model-viewports host))))

(defparameter *viewport-pieces*
  ;; (PRODUCT OPTION . PIECES): each piece (FX0 FY0 FX1 FY1) is a fraction of
  ;; the current viewport; the first is the current viewport's.
  (let ((a 1/3) (b 2/3) (h 1/2))
    `((:autocad :2v (,h 0 1 1) (0 0 ,h 1))
      (:autocad :2h (0 ,h 1 1) (0 0 1 ,h))
      (:autocad :3v (,b 0 1 1) (0 0 ,a 1) (,a 0 ,b 1))
      (:autocad :3h (0 ,b 1 1) (0 0 1 ,a) (0 ,a 1 ,b))
      (:autocad :3a (0 ,h 1 1) (0 0 ,h ,h) (,h 0 1 ,h))
      (:autocad :3b (0 0 1 ,h) (,h ,h 1 1) (0 ,h ,h 1))
      (:autocad :3l (0 0 ,h 1) (,h ,h 1 1) (,h 0 1 ,h))
      (:autocad :3r (,h 0 1 1) (0 ,h ,h 1) (0 0 ,h ,h))
      (:autocad :4 (,h 0 1 ,h) (,h ,h 1 1) (0 ,h ,h 1) (0 0 ,h ,h))
      (:bricscad :2v (0 0 ,h 1) (,h 0 1 1))
      (:bricscad :2h (0 0 1 ,h) (0 ,h 1 1))
      (:bricscad :3v (0 0 ,a 1) (,a 0 ,b 1) (,b 0 1 1))
      (:bricscad :3h (0 0 1 ,a) (0 ,a 1 ,b) (0 ,b 1 1))
      (:bricscad :3a (0 ,h 1 1) (0 0 ,h ,h) (,h 0 1 ,h))
      (:bricscad :3b (0 0 1 ,h) (0 ,h ,h 1) (,h ,h 1 1))
      (:bricscad :3l (0 0 ,h 1) (,h 0 1 ,h) (,h ,h 1 1))
      (:bricscad :3r (,h 0 1 1) (0 0 ,h ,h) (0 ,h ,h 1))
      (:bricscad :4 (0 0 ,h ,h) (,h 0 1 ,h) (0 ,h ,h 1) (,h ,h 1 1)))))

(defun %sort-viewports (viewports)
  "VIEWPORTS with the first (the current one) kept first, the rest by number."
  (cons (first viewports) (sort (copy-list (rest viewports)) #'< :key #'first)))

(defun %unused-viewport-ids (count used)
  "COUNT smallest viewport numbers >= 2 not in USED."
  (loop for id from 2
        unless (member id used) collect id into ids
        until (= (length ids) count)
        finally (return ids)))

(defun %number-pieces (current-id rectangles others)
  "Viewports for RECTANGLES (LLX LLY URX URY): the first gets CURRENT-ID, the
rest the smallest numbers unused by CURRENT-ID and OTHERS (viewports)."
  (let ((ids (cons current-id
                   (%unused-viewport-ids (1- (length rectangles))
                                         (cons current-id (mapcar #'first others))))))
    (mapcar #'cons ids rectangles)))

(defun %vports-divide (host option)
  (let ((pieces (cddr (find-if (lambda (row) (and (eq (first row) (%viewport-product))
                                                  (eq (second row) option)))
                                *viewport-pieces*))))
    (when pieces
      (destructuring-bind ((id llx lly urx ury) &rest others) (cador-model-viewports host)
        (let* ((w (- urx llx)) (h (- ury lly))
               (rectangles (mapcar (lambda (piece)
                                     (destructuring-bind (fx0 fy0 fx1 fy1) piece
                                       (list (+ llx (* w (float fx0 1d0))) (+ lly (* h (float fy0 1d0)))
                                             (+ llx (* w (float fx1 1d0))) (+ lly (* h (float fy1 1d0))))))
                                   pieces)))
          (setf (%cador-viewport-toggle host) nil
                (%cador-model-viewports host)
                (%sort-viewports (append (%number-pieces id rectangles others) others))))))))

(defun %vports-single (host)
  (let* ((viewports (cador-model-viewports host))
         ;; AutoCAD: the lowest-numbered viewport other than the current one;
         ;; BricsCAD: the lowest-numbered one (probe-viewports).
         (id (if (and (eq (%viewport-product) :autocad) (rest viewports))
                 (reduce #'min (mapcar #'first (rest viewports)))
                 (reduce #'min (mapcar #'first viewports)))))
    (setf (%cador-viewport-toggle host) nil
          (%cador-model-viewports host) (list (list id 0d0 0d0 1d0 1d0)))))

(defun %vports-toggle (host)
  (let ((saved (%cador-viewport-toggle host)))
    (if saved
        (setf (%cador-model-viewports host) saved
              (%cador-viewport-toggle host) nil)
        (let ((viewports (cador-model-viewports host)))
          (when (rest viewports)
            (setf (%cador-viewport-toggle host) viewports
                  (%cador-model-viewports host)
                  (list (list (first (first viewports)) 0d0 0d0 1d0 1d0))))))))

(defun %vports-save (host name)
  (let ((viewports (cador-model-viewports host)))
    (setf (gethash name (%cador-viewport-configurations host)) (copy-tree viewports))
    (destructuring-bind (id llx lly urx ury) (first viewports)
      (declare (ignore id))
      (cador-add-table-record
       host (make-symbol-table-record
             :kind :vport :name name
             :data (list (cons 0 "VPORT") (cons 2 name) (cons 70 0)
                         (list 10 llx lly) (list 11 urx ury)))))))

(defun %vports-restore (host name)
  (let ((saved (gethash name (%cador-viewport-configurations host))))
    (when saved
      (let ((id (first (first (cador-model-viewports host)))))
        (setf (%cador-viewport-toggle host) nil
              (%cador-model-viewports host)
              (%sort-viewports (%number-pieces id (mapcar #'rest saved) '())))))))

(defun %vports-delete (host name)
  (remhash name (%cador-viewport-configurations host))
  (remhash name (cador-table host :vport)))

(defun cador-set-current-viewport (host id)
  "Make tiled viewport ID current, as (setvar \"CVPORT\" ID) does; T if it is
one of the current layout's."
  (let* ((viewports (cador-model-viewports host))
         (viewport (find id viewports :key #'first)))
    (when (and viewport (= 1 (cador-tilemode host)))
      (setf (%cador-model-viewports host)
            (%sort-viewports (cons viewport (remove viewport viewports))))
      t)))

(defun %vports-orientation-option (count token)
  "The piece-table key for COUNT viewports and orientation TOKEN (\"\" or
absent: the default -- Vertical for 2, Right for 3)."
  (let ((default (or (null token) (equal token ""))))
    (ecase count
      (2 (cond ((or default (%command-option-p token "V" "VERTICAL")) :2v)
               ((%command-option-p token "H" "HORIZONTAL") :2h)))
      (3 (cond ((or default (%command-option-p token "R" "RIGHT")) :3r)
               ((%command-option-p token "V" "VERTICAL") :3v)
               ((%command-option-p token "H" "HORIZONTAL") :3h)
               ((%command-option-p token "A" "ABOVE") :3a)
               ((%command-option-p token "B" "BELOW") :3b)
               ((%command-option-p token "L" "LEFT") :3l))))))

;;; -VPORTS in model space: 2 [orientation], 3 [orientation], 4, SIngle,
;;; Toggle, Save NAME, Restore NAME, Delete NAME (measured); Join is not.
(defun %cmd-vports (host tokens)
  (let ((option (pop tokens)))
    (flet ((count-option (n) (or (eql option n) (%command-option-p option (princ-to-string n)))))
      (when (= 1 (cador-tilemode host))
        (cond ((or (count-option 2) (count-option 3))
               (let ((orientation (%vports-orientation-option
                                   (if (count-option 2) 2 3) (first tokens))))
                 (when tokens (pop tokens))
                 (when orientation (%vports-divide host orientation))))
              ((count-option 4) (%vports-divide host :4))
              ((%command-option-p option "SI" "SINGLE") (%vports-single host))
              ((%command-option-p option "T" "TOGGLE") (%vports-toggle host))
              ((%command-option-p option "S" "SAVE")
               (let ((name (pop tokens))) (when (stringp name) (%vports-save host name))))
              ((%command-option-p option "R" "RESTORE")
               (let ((name (pop tokens))) (when (stringp name) (%vports-restore host name))))
              ((%command-option-p option "D" "DELETE")
               (let ((name (pop tokens))) (when (stringp name) (%vports-delete host name))))))))
  tokens)

(define-cador-command "-VPORTS" '%cmd-vports)
