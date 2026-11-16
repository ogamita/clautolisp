;;;; probes/sources/probe-ssget-window-crossing.lsp
;;;;
;;;; ssget-crossing-selection-unsupported: which entities (ssget "_W" P1 P2)
;;;; and (ssget "_C" P1 P2) select, natively, so cador's window / crossing
;;;; can be compared before parity is claimed. The geometry is the cador
;;;; test's (clautolisp/cador/tests/selection-tests.lisp, seed-window-crossing)
;;;; around the rectangle (0,0)-(10,10):
;;;;
;;;;   LINE-INSIDE, LINE-THROUGH (neither endpoint inside), LINE-OUTSIDE,
;;;;   CIRCLE-INSIDE, CIRCLE-CROSSING, CIRCLE-AROUND (encloses the rectangle),
;;;;   ARC-PARTLY (-45..+45 degrees, radius 3, about the origin),
;;;;   SQUARE-AROUND (a closed LWPOLYLINE with no vertex or edge inside).
;;;;
;;;; Each case records the sorted NAMES selected (each entity carries its name
;;;; as XDATA-free layer "SSWC-<NAME>"), so the record does not depend on
;;;; entity names. SPEC-UNCERTAIN: native window / crossing may depend on the
;;;; view (an entity off screen); the batch session's view is the drawing's.
;;;; Everything made is deleted at the end.
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d;
;;;; the case name is the exact expression. Parameter names are unique.

(defun cad-probe--wc-make (cad-probe--wc-name cad-probe--wc-data)
  (entmakex (append cad-probe--wc-data
                    (list (cons 8 (strcat "SSWC-" cad-probe--wc-name))))))

(defun cad-probe--wc-seed ( / made)
  (setq made
    (list
     (cad-probe--wc-make "LINE-INSIDE" '((0 . "LINE") (10 1.0 1.0 0.0) (11 2.0 2.0 0.0)))
     (cad-probe--wc-make "LINE-THROUGH" '((0 . "LINE") (10 -5.0 5.0 0.0) (11 15.0 5.0 0.0)))
     (cad-probe--wc-make "LINE-OUTSIDE" '((0 . "LINE") (10 20.0 20.0 0.0) (11 30.0 30.0 0.0)))
     (cad-probe--wc-make "CIRCLE-INSIDE" '((0 . "CIRCLE") (10 5.0 5.0 0.0) (40 . 1.0)))
     (cad-probe--wc-make "CIRCLE-CROSSING" '((0 . "CIRCLE") (10 10.0 5.0 0.0) (40 . 2.0)))
     (cad-probe--wc-make "CIRCLE-AROUND" '((0 . "CIRCLE") (10 5.0 5.0 0.0) (40 . 50.0)))
     (cad-probe--wc-make "ARC-PARTLY" '((0 . "ARC") (10 0.0 0.0 0.0) (40 . 3.0)
                                        (50 . 5.497787143782138) (51 . 0.7853981633974483)))
     (cad-probe--wc-make "SQUARE-AROUND" '((0 . "LWPOLYLINE") (100 . "AcDbEntity")
                                           (100 . "AcDbPolyline") (90 . 4) (70 . 1)
                                           (10 -1.0 -1.0) (10 11.0 -1.0)
                                           (10 11.0 11.0) (10 -1.0 11.0)))))
  made)

(defun cad-probe--wc-names (cad-probe--wc-ss / i out layer)
  ;; The sorted names of the probe's entities in the selection set.
  (if (= (type cad-probe--wc-ss) 'PICKSET)
      (progn
        (setq i 0)
        (repeat (sslength cad-probe--wc-ss)
          (setq layer (cdr (assoc 8 (entget (ssname cad-probe--wc-ss i)))))
          (if (and layer (wcmatch layer "SSWC-*"))
              (setq out (cons (substr layer 6) out)))
          (setq i (1+ i)))
        (vl-sort out '<))
      cad-probe--wc-ss))

(defun cad-probe--wc (cad-probe--wc-case)
  (cad-probe-capture "ssget-window-crossing" cad-probe--wc-case
    (function (lambda () (vl-prin1-to-string (eval (read cad-probe--wc-case)))))))

(defun cad-probe-run-ssget-window-crossing-probes ( / cad-probe--wc-made)
  (cad-probe-note "ssget-window-crossing" "legend"
    "sorted names selected around the rectangle (0,0)-(10,10); see the header for the geometry")
  (setq cad-probe--wc-made (cad-probe--wc-seed))
  (cad-probe--wc "(length (vl-remove nil cad-probe--wc-made))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_W\" '(0.0 0.0) '(10.0 10.0)))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_C\" '(0.0 0.0) '(10.0 10.0)))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_C\" '(10.0 10.0) '(0.0 0.0)))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_C\" '(0.0 0.0) '(10.0 10.0) '((0 . \"LINE\"))))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_C\" '(100.0 100.0) '(101.0 101.0)))")
  (cad-probe--wc "(cad-probe--wc-names (ssget \"_W\" '(0.0 0.0 0.0) '(10.0 10.0 0.0)))")
  (foreach e cad-probe--wc-made (if e (vl-catch-all-apply 'entdel (list e))))
  (princ))
