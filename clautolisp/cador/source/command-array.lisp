(in-package #:clautolisp.cador)

;;;; Arrays, DIVIDE / MEASURE, ADDSELECTED and JOIN (alref Phase 4 S2 / S4).
;;;;
;;;; Built against probes/sources/probe-commands.lsp (BricsCAD V26, job
;;;; 16914406700; AutoCAD 2022 alongside). The ORDER copies are created in
;;;; is part of what was measured -- ENTNEXT walks it:
;;;;   -ARRAY rectangular  row by row    (0,0) (3,0) (6,0) (0,2) (3,2) (6,2)
;;;;   ARRAYRECT          column by column (0,0) (0,2) (3,0) (3,2) ...
;;;;   3DARRAY            rows, then columns, then levels innermost
;;;;   polar              counter-clockwise from the original
;;;; The original stays the first item. The array commands are modelled
;;;; NON-associative (plain copies); an associative array is an array object
;;;; the headless model does not hold.

(defun %copy-translated (host entity dx dy &optional (dz 0.0d0))
  (let ((clone (%clone-entity-with-run host entity)))
    (%entity-translate clone dx dy dz)
    (dolist (h (%entity-subentity-handles host clone))
      (let ((sub (cador-find-entity-by-handle host h)))
        (when sub (%entity-translate sub dx dy dz))))
    clone))

(defun %copy-rotated (host entity cx cy angle rotate-items)
  "A copy of ENTITY turned by ANGLE about (CX CY): moved along the circle,
and itself rotated when ROTATE-ITEMS."
  (let ((clone (%clone-entity-with-run host entity)))
    (dolist (x (cons clone (loop for h in (%entity-subentity-handles host clone)
                                 for sub = (cador-find-entity-by-handle host h)
                                 when sub collect sub)))
      (if rotate-items
          (%entity-rotate-one x cx cy angle)
          ;; Move the item's reference point only, keeping its orientation.
          (let* ((p (%entity-group-value x 10))
                 (c (cos angle)) (s (sin angle))
                 (rx (- (first p) cx)) (ry (- (second p) cy)))
            (%entity-translate x (- (+ cx (- (* c rx) (* s ry))) (first p))
                               (- (+ cy (+ (* s rx) (* c ry))) (second p)) 0.0d0))))
    clone))

(defun %rect-array (host entities rows cols row-gap col-gap &key column-major)
  (let ((cells (if column-major
                   (loop for c below cols append (loop for r below rows collect (list r c)))
                   (loop for r below rows append (loop for c below cols collect (list r c))))))
    (dolist (cell cells)
      (destructuring-bind (r c) cell
        (unless (and (zerop r) (zerop c))
          (dolist (e entities)
            (%copy-translated host e (* c col-gap) (* r row-gap))))))))

(defun %polar-array (host entities center items fill rotate)
  (let ((step (if (>= (abs fill) 360) (/ fill items) (/ fill (max 1 (1- items))))))
    (loop for i from 1 below items
          for angle = (* i step (/ pi 180))
          do (dolist (e entities)
               (%copy-rotated host e (first center) (second center) angle rotate)))))

;;; -ARRAY: selection, then _Rectangular rows cols row-gap col-gap, or
;;; _Polar center items fill-angle rotate?.
(defun %cmd-classic-array (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (cond
      ((%command-option-p (first rest) "r" "rectangular")
       (pop rest)
       (let ((rows (%command-token-number (pop rest)))
             (cols (%command-token-number (pop rest))))
         (when (and rows cols)
           (let ((row-gap (if (> rows 1) (%command-token-number (pop rest)) 0))
                 (col-gap (if (> cols 1) (%command-token-number (pop rest)) 0)))
             (%rect-array host entities (round rows) (round cols)
                          (or row-gap 0) (or col-gap 0))))))
      ((%command-option-p (first rest) "p" "polar")
       (pop rest)
       (let ((center (%command-token-point (pop rest)))
             (items (%command-token-number (pop rest)))
             (fill (%command-token-number (pop rest)))
             (rotate (not (%command-option-p (first rest) "n" "no"))))
         (when (%command-option-p (first rest) "y" "yes" "n" "no") (pop rest))
         (when (and center items fill)
           (%polar-array host entities center (round items) fill rotate)))))
    rest))

;;; ARRAYRECT / ARRAYPOLAR / ARRAY: selection (ARRAY then a type), then
;;; option / value pairs until _X or RETURN.
(defun %take-array-options (tokens)
  "Consume the array option loop; returns (values PLIST REMAINING)."
  (let ((opts '()))
    (loop
      (let ((token (first tokens)))
        (cond ((null tokens) (return))
              ((or (equal token "") (%command-option-p token "x" "exit")) (pop tokens) (return))
              ((%command-option-p token "as" "associative")
               (pop tokens)
               (setf (getf opts :associative) (not (%command-option-p (pop tokens) "n" "no"))))
              ((%command-option-p token "cou" "count")
               (pop tokens)
               (setf (getf opts :cols) (%command-token-number (pop tokens))
                     (getf opts :rows) (%command-token-number (pop tokens))))
              ((%command-option-p token "s" "spacing")
               (pop tokens)
               (setf (getf opts :col-gap) (%command-token-number (pop tokens))
                     (getf opts :row-gap) (%command-token-number (pop tokens))))
              ((%command-option-p token "col" "columns")
               (pop tokens)
               (setf (getf opts :cols) (%command-token-number (pop tokens))
                     (getf opts :col-gap) (%command-token-number (pop tokens))))
              ((%command-option-p token "r" "rows")
               (pop tokens)
               (setf (getf opts :rows) (%command-token-number (pop tokens))
                     (getf opts :row-gap) (%command-token-number (pop tokens))))
              ((%command-option-p token "i" "items")
               (pop tokens) (setf (getf opts :items) (%command-token-number (pop tokens))))
              ((%command-option-p token "f" "fill")
               (pop tokens) (setf (getf opts :fill) (%command-token-number (pop tokens))))
              ((%command-option-p token "rot" "rotate")
               (pop tokens)
               (setf (getf opts :rotate) (not (%command-option-p (pop tokens) "n" "no"))))
              (t (return)))))
    (values opts tokens)))

(defun %run-rect-array (host entities opts &key (column-major t))
  (%rect-array host entities
               (round (or (getf opts :rows) 3)) (round (or (getf opts :cols) 4))
               (or (getf opts :row-gap) 1.0d0) (or (getf opts :col-gap) 1.0d0)
               :column-major column-major))

(defun %cmd-arrayrect (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (multiple-value-bind (opts rest) (%take-array-options rest)
      (%run-rect-array host entities opts)
      rest)))

(defun %cmd-arraypolar (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (let ((center (%command-token-point (first rest))))
      (unless center (return-from %cmd-arraypolar rest))
      (pop rest)
      (multiple-value-bind (opts rest) (%take-array-options rest)
        (%polar-array host entities center (round (or (getf opts :items) 6))
                      (or (getf opts :fill) 360)
                      (if (member :rotate opts) (getf opts :rotate) t))
        rest))))

(defun %cmd-array (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (cond ((%command-option-p (first rest) "r" "rectangular")
           (pop rest)
           (multiple-value-bind (opts rest) (%take-array-options rest)
             ;; Measured: ARRAY _R makes its copies column by column on
             ;; AutoCAD, row by row on BricsCAD (ARRAYRECT is column by
             ;; column on both).
             (%run-rect-array host entities opts
                              :column-major (not (%command-bricscad-p)))
             rest))
          ((%command-option-p (first rest) "po" "polar")
           (pop rest)
           (let ((center (%command-token-point (pop rest))))
             (multiple-value-bind (opts rest) (%take-array-options rest)
               (when center
                 (%polar-array host entities center (round (or (getf opts :items) 6))
                               (or (getf opts :fill) 360)
                               (if (member :rotate opts) (getf opts :rotate) t)))
               rest)))
          (t rest))))

;;; 3DARRAY _Rectangular: rows columns levels, then the three distances.
(defun %cmd-3darray (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (when (%command-option-p (first rest) "r" "rectangular")
      (pop rest)
      (let* ((rows (round (or (%command-token-number (pop rest)) 1)))
             (cols (round (or (%command-token-number (pop rest)) 1)))
             (levels (round (or (%command-token-number (pop rest)) 1)))
             (dy (if (> rows 1) (or (%command-token-number (pop rest)) 0) 0))
             (dx (if (> cols 1) (or (%command-token-number (pop rest)) 0) 0))
             (dz (if (> levels 1) (or (%command-token-number (pop rest)) 0) 0)))
        (loop for r below rows
              do (loop for c below cols
                       do (loop for l below levels
                                unless (= 0 r c l)
                                  do (dolist (e entities)
                                       (%copy-translated host e (* c dx) (* r dy) (* l dz))))))))
    rest))

;;; --- DIVIDE / MEASURE: POINTs along an object ------------------------
;;; Measured on BricsCAD: DIVIDE (0,0)-(4,0) into 4 -> POINTs at 1 2 3;
;;; MEASURE by 1.5 -> POINTs at 1.5 and 3, from the start.

(defun %outline-length (segments)
  (reduce #'+ (mapcar (lambda (s) (%vlen (%v- (second s) (first s)))) segments)))

(defun %point-at-length (segments d)
  (loop for (a b) in segments
        for len = (%vlen (%v- b a))
        do (if (<= d len)
               (return (%v+ a (%v* (/ d (if (zerop len) 1 len)) (%v- b a))))
               (decf d len))
        finally (return (second (car (last segments))))))

(defun %place-points (host entity distances)
  (let ((outline (%entity-outline host entity))
        (layer (%entity-group-value entity 8)))
    (dolist (d distances)
      (let ((p (%point-at-length outline d)))
        (%command-entity host (list (cons 0 "POINT") (cons 8 layer)
                                    (cons 10 (list (first p) (second p) 0.0d0))))))))

(defun %cmd-divide (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host (list (first tokens)))
    (declare (ignore rest))
    (let ((n (%command-token-number (second tokens))))
      (when (and entities n (>= n 2))
        (let* ((e (first entities))
               (len (%outline-length (%entity-outline host e))))
          (%place-points host e (loop for i from 1 below (round n)
                                      collect (* len (/ i (round n)))))))
      (nthcdr (if (and entities n) 2 1) tokens))))

(defun %cmd-measure (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host (list (first tokens)))
    (declare (ignore rest))
    (let ((step (%command-token-number (second tokens))))
      (when (and entities step (plusp step))
        (let* ((e (first entities))
               (len (%outline-length (%entity-outline host e))))
          (%place-points host e (loop for d = step then (+ d step)
                                      while (< d (- len 1d-9)) collect d))))
      (nthcdr (if (and entities step) 2 1) tokens))))

;;; --- ADDSELECTED: a new object of the selected one's kind --------------
;;; Measured: a circle selected, then "5,5" "2" -> a CIRCLE at (5,5) r 2,
;;; with the selected object's layer and properties.
(defun %cmd-addselected (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host (list (first tokens)))
    (declare (ignore rest))
    (let ((source (first entities)))
      (if (null source)
          tokens
          (let* ((command (case (entity-handle-kind source)
                            (:circle "CIRCLE") (:line "LINE") (:arc "ARC")
                            (:lwpolyline "PLINE") (:point "POINT") (:text "TEXT")
                            (:ellipse "ELLIPSE") (:spline "SPLINE")))
                 (handler (and command (gethash command *cador-commands*))))
            (if (null handler)
                (rest tokens)
                (let ((before (%selectable-entities host))
                      (remaining (funcall handler host (rest tokens))))
                  ;; The new object takes the source's layer and properties.
                  (dolist (e (set-difference (%selectable-entities host) before))
                    (%entity-set-group e 8 (%entity-group-value source 8))
                    (dolist (code *property-codes*)
                      (let ((v (%entity-group-value source code)))
                        (when v (%entity-set-property e code v)))))
                  remaining)))))))

;;; --- JOIN: collinear LINEs become one ------------------------------------
;;; Measured on BricsCAD: (0,0)-(2,0) + (2,0)-(4,0) -> ONE LINE (0,0)-(4,0),
;;; the first selected kept, the others erased.
(defun %cmd-join (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (let ((lines (remove-if-not (lambda (e) (eq (entity-handle-kind e) :line)) entities)))
      (when (>= (length lines) 2)
        (let* ((first (first lines))
               (a (%xy (%entity-group-value first 10)))
               (dir (%vunit (%v- (%xy (%entity-group-value first 11)) a)))
               (collinear
                 (every (lambda (e)
                          (every (lambda (code)
                                   (let ((v (%v- (%xy (%entity-group-value e code)) a)))
                                     (< (abs (- (* (first v) (second dir))
                                                (* (second v) (first dir))))
                                        1d-9)))
                                 '(10 11)))
                        lines)))
          (when collinear
            (let* ((params (loop for e in lines
                                 append (loop for code in '(10 11)
                                              collect (reduce #'+ (mapcar #'* dir
                                                                          (%v- (%xy (%entity-group-value e code)) a))))))
                   (lo (reduce #'min params)) (hi (reduce #'max params))
                   (z (or (third (%entity-group-value first 10)) 0.0d0)))
              (%entity-set-group first 10 (append (%v+ a (%v* lo dir)) (list z)))
              (%entity-set-group first 11 (append (%v+ a (%v* hi dir)) (list z)))
              (dolist (e (rest lines)) (%erase-entity-and-run host e)))))))
    rest))

(define-cador-command "-ARRAY"      '%cmd-classic-array)
(define-cador-command "ARRAYRECT"   '%cmd-arrayrect)
(define-cador-command "ARRAYPOLAR"  '%cmd-arraypolar)
(define-cador-command "ARRAY"       '%cmd-array)
(define-cador-command "3DARRAY"     '%cmd-3darray)
(define-cador-command "DIVIDE"      '%cmd-divide)
(define-cador-command "MEASURE"     '%cmd-measure)
(define-cador-command "ADDSELECTED" '%cmd-addselected)
(define-cador-command "JOIN"        '%cmd-join)

;;; --- FLATTEN (Express Tools): every point onto Z = 0 ------------------
;;; Measured on BricsCAD: (0,0,1)-(2,0,3) -> (0,0,0)-(2,0,0). (A headless
;;; AutoCAD has no Express Tools; a full install flattens the same way.)
(defun %cmd-flatten (host tokens)
  (multiple-value-bind (entities rest) (%command-selection host tokens)
    (when (%command-option-p (first rest) "y" "yes" "n" "no") (pop rest))
    (dolist (e entities)
      (%entity-map-point-groups
       e (lambda (p) (if (cddr p) (list (first p) (second p) 0.0d0) p)))
      (when (%entity-group-value e 38) (%entity-set-group e 38 0.0d0)))
    rest))

(define-cador-command "FLATTEN" '%cmd-flatten)
