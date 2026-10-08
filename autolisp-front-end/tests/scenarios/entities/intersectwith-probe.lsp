;;;; intersectwith-probe.lsp -- measure the ActiveX entity method
;;;; IntersectWith on each target (clautolisp vs BricsCAD vs AutoCAD).
;;;;
;;;; Background: issues/open/cador-intersectwith-missing.issue. The vendor
;;;; reference documents
;;;;     RetVal = object.IntersectWith(IntersectObject, ExtendOption)
;;;; ExtendOption 0 acExtendNone, 1 acExtendThisEntity, 2 acExtendOtherEntity,
;;;; 3 acExtendBoth; RetVal a VARIANT (array of doubles) X1 Y1 Z1 X2 ...,
;;;; EMPTY when the objects do not meet. It says nothing about the ORDER of
;;;; the points, tangency, overlapping curves, a crossing at a polyline
;;;; vertex, or how far a polyline extends. This probe measures all of that
;;;; for LINE / CIRCLE / ARC / ELLIPSE / LWPOLYLINE / POLYLINE pairs, each
;;;; under the four extend options, through both call forms:
;;;;     (vla-IntersectWith a b n)            -> VARIANT
;;;;     (vlax-invoke a 'IntersectWith b n)   -> plain list or nil
;;;;
;;;; Every result line is machine-readable and greppable:
;;;;     IWPROBE <pair>.<option>.<field>=<value>
;;;; with <field> one of
;;;;     VLA-TYPE     (type RESULT) of the vla- call, or ERROR:<message>
;;;;     VARIANT-TYPE (vlax-variant-type RESULT)
;;;;     VALUE-TYPE   (type (vlax-variant-value RESULT))
;;;;     LBOUND UBOUND  vlax-safearray-get-l-bound / -u-bound, dimension 1
;;;;     TOLIST       (vlax-safearray->list ...) -- called EVEN WHEN EMPTY,
;;;;                  so an engine that errors on an empty array says so
;;;;     INVOKE       the vlax-invoke result (numbers at 6 decimals), or
;;;;                  ERROR:<message>
;;;; The run ends with "IWPROBE-DONE". Each call runs under
;;;; vl-catch-all-apply, with every argument computed INSIDE the caught
;;;; lambda, so one failure is one line, never a dead run. The entities are
;;;; erased at the end.
;;;;
;;;; Geometry (all in the XY plane unless said):
;;;;   L-diag  (0,0)-(10,10)      L-anti (0,10)-(10,0)    cross at (5,5)
;;;;   L-par   (0,1)-(10,11)      parallel to L-diag
;;;;   L-col   (5,5)-(15,15)      collinear, overlapping L-diag
;;;;   L-skew  (0,10,1)-(10,0,1)  crosses L-diag in plan, 1 unit above
;;;;   L-a     (0,0)-(4,0)        L-b (6,-2)-(6,-1): meet at (6,0) only when
;;;;                              BOTH are extended
;;;;   L-c     (6,-1)-(6,1)       meets L-a extended at (6,0)
;;;;   C5      circle (0,0) r5
;;;;   L-x     (-10,0)-(10,0)     L-xr (10,0)-(-10,0) reversed
;;;;   L-tan   (-10,5)-(10,5)     tangent to C5 at (0,5)
;;;;   L-out   (-10,7)-(10,7)     misses C5
;;;;   L-in    (-1,0)-(1,0)       inside C5, meets it only extended
;;;;   L-v     (0,-10)-(0,10)     vertical through C5's centre
;;;;   A-up    arc (0,0) r5 0..pi (upper half)
;;;;   L-y3    (-10,3)-(10,3)     meets A-up at (-4,3) (4,3)
;;;;   L-ym3   (-10,-3)-(10,-3)   meets A-up only when the arc is extended
;;;;   C-r6    circle (6,0) r5    meets C5 at (3,4) (3,-4)
;;;;   C-tan   circle (10,0) r5   tangent to C5 at (5,0)
;;;;   C-far   circle (20,0) r5   misses C5
;;;;   C-in    circle (0,0) r3    concentric with C5
;;;;   A-left  arc (6,0) r5 pi/2..3pi/2; with A-up: (3,4) on both, (3,-4)
;;;;           only on A-left
;;;;   A-low   arc (0,0) r5 pi..2pi   A-right arc (6,0) r5 -pi/2..pi/2:
;;;;           (3,-4) on A-low only, (3,4) on neither
;;;;   PL      LWPOLYLINE open (-3,-3) (-3,3) [bulge -1] (3,3) (3,-3): a
;;;;           line, a clockwise half circle over the top through (0,6), a
;;;;           line
;;;;   PLC     the same, closed
;;;;   P2D     the same as a heavy 2D POLYLINE (VERTEX run)
;;;;   L-ym5   (-10,-5)-(10,-5)   misses PL; meets its first / last span
;;;;           extended (straight down from (-3,-3) and (3,-3))
;;;;   L-y5    (-10,5)-(10,5)     meets PL's arc span at (-2.236,5) (2.236,5)
;;;;   L-yv    (-10,3)-(10,3)     passes through PL's vertices (-3,3) (3,3)
;;;;   EL      ELLIPSE (0,0) major (8,0) ratio 0.5

(defun iwp-out (iwp-key iwp-val)
  (princ (strcat "IWPROBE " iwp-key "=" iwp-val "\n"))
  (princ))

(defun iwp-str (iwp-x)
  (cond ((null iwp-x) "nil")
        ((eq (type iwp-x) 'STR) iwp-x)
        ((eq (type iwp-x) 'REAL) (rtos iwp-x 2 6))
        ((eq (type iwp-x) 'LIST)
         (strcat "(" (iwp-join (mapcar 'iwp-str iwp-x)) ")"))
        (t (vl-princ-to-string iwp-x))))

(defun iwp-join (iwp-strings / iwp-acc)
  (setq iwp-acc "")
  (foreach iwp-s iwp-strings
    (setq iwp-acc (if (= iwp-acc "") iwp-s (strcat iwp-acc " " iwp-s))))
  iwp-acc)

(defun iwp-err (iwp-e)
  (strcat "ERROR:" (vl-catch-all-error-message iwp-e)))

(defun iwp-vla (iwp-ename / iwp-obj)
  ;; The VLA-object of IWP-ENAME, or nil (an engine without COM).
  (setq iwp-obj (vl-catch-all-apply 'vlax-ename->vla-object (list iwp-ename)))
  (if (vl-catch-all-error-p iwp-obj)
      (progn (iwp-out "VLAX-ENAME->VLA-OBJECT" (iwp-err iwp-obj)) nil)
      iwp-obj))

(defun iwp-make (iwp-dxf / iwp-en)
  ;; The VLA-object of a fresh entity, or nil.
  (setq iwp-en (vl-catch-all-apply 'entmakex (list iwp-dxf)))
  (if (and iwp-en (not (vl-catch-all-error-p iwp-en)))
      (progn
        (setq *iwp-enames* (cons iwp-en *iwp-enames*))
        (iwp-vla iwp-en))
      (progn
        (iwp-out "ENTMAKEX" (if iwp-en (iwp-err iwp-en) "nil"))
        nil)))

(defun iwp-call (iwp-pair iwp-a iwp-b iwp-opt / iwp-pre iwp-v iwp-sa iwp-lb iwp-ub iwp-l iwp-inv)
  (setq iwp-pre (strcat iwp-pair "." (itoa iwp-opt) "."))
  (cond
    ((null iwp-a) (iwp-out (strcat iwp-pre "VLA-TYPE") "NO-BASE-OBJECT"))
    ((null iwp-b) (iwp-out (strcat iwp-pre "VLA-TYPE") "NO-OTHER-OBJECT"))
    (t
     ;; --- the vla- form ------------------------------------------------
     (setq iwp-v (vl-catch-all-apply
                  (function (lambda () (vla-intersectwith iwp-a iwp-b iwp-opt)))
                  '()))
     (if (vl-catch-all-error-p iwp-v)
         (iwp-out (strcat iwp-pre "VLA-TYPE") (iwp-err iwp-v))
         (progn
           (iwp-out (strcat iwp-pre "VLA-TYPE") (iwp-str (type iwp-v)))
           (if (eq (type iwp-v) 'VARIANT)
               (progn
                 (iwp-out (strcat iwp-pre "VARIANT-TYPE")
                          (iwp-str (vl-catch-all-apply 'vlax-variant-type (list iwp-v))))
                 (setq iwp-sa (vlax-variant-value iwp-v))
                 (iwp-out (strcat iwp-pre "VALUE-TYPE") (iwp-str (type iwp-sa))))
               (setq iwp-sa iwp-v))
           (if (eq (type iwp-sa) 'SAFEARRAY)
               (progn
                 (setq iwp-lb (vl-catch-all-apply 'vlax-safearray-get-l-bound (list iwp-sa 1)))
                 (setq iwp-ub (vl-catch-all-apply 'vlax-safearray-get-u-bound (list iwp-sa 1)))
                 (iwp-out (strcat iwp-pre "LBOUND")
                          (if (vl-catch-all-error-p iwp-lb) (iwp-err iwp-lb) (iwp-str iwp-lb)))
                 (iwp-out (strcat iwp-pre "UBOUND")
                          (if (vl-catch-all-error-p iwp-ub) (iwp-err iwp-ub) (iwp-str iwp-ub)))
                 (setq iwp-l (vl-catch-all-apply 'vlax-safearray->list (list iwp-sa)))
                 (iwp-out (strcat iwp-pre "TOLIST")
                          (if (vl-catch-all-error-p iwp-l) (iwp-err iwp-l) (iwp-str iwp-l)))))))
     ;; --- the vlax-invoke form -----------------------------------------
     (setq iwp-inv (vl-catch-all-apply
                    (function (lambda () (vlax-invoke iwp-a 'IntersectWith iwp-b iwp-opt)))
                    '()))
     (iwp-out (strcat iwp-pre "INVOKE")
              (if (vl-catch-all-error-p iwp-inv) (iwp-err iwp-inv) (iwp-str iwp-inv)))))
  (princ))

(defun iwp-pair (iwp-name iwp-a iwp-b / iwp-o)
  (setq iwp-o 0)
  (while (<= iwp-o 3)
    (iwp-call iwp-name iwp-a iwp-b iwp-o)
    (setq iwp-o (1+ iwp-o))))

(defun iwp-line (iwp-p iwp-q)
  (iwp-make (list '(0 . "LINE") (cons 10 iwp-p) (cons 11 iwp-q))))

(defun iwp-circle (iwp-c iwp-r)
  (iwp-make (list '(0 . "CIRCLE") (cons 10 iwp-c) (cons 40 iwp-r))))

(defun iwp-arc (iwp-c iwp-r iwp-a0 iwp-a1)
  (iwp-make (list '(0 . "ARC") (cons 10 iwp-c) (cons 40 iwp-r)
                  (cons 50 iwp-a0) (cons 51 iwp-a1))))

(defun iwp-lwpoly (iwp-closed)
  (iwp-make (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") '(100 . "AcDbPolyline")
                  '(90 . 4) (cons 70 iwp-closed)
                  '(10 -3.0 -3.0) '(42 . 0.0)
                  '(10 -3.0 3.0) '(42 . -1.0)
                  '(10 3.0 3.0) '(42 . 0.0)
                  '(10 3.0 -3.0) '(42 . 0.0))))

(defun iwp-heavy-poly ( / iwp-ok)
  (setq iwp-ok (vl-catch-all-apply
                (function
                 (lambda ()
                   (entmake '((0 . "POLYLINE") (66 . 1) (10 0.0 0.0 0.0) (70 . 0)))
                   (entmake '((0 . "VERTEX") (10 -3.0 -3.0 0.0)))
                   (entmake '((0 . "VERTEX") (10 -3.0 3.0 0.0) (42 . -1.0)))
                   (entmake '((0 . "VERTEX") (10 3.0 3.0 0.0)))
                   (entmake '((0 . "VERTEX") (10 3.0 -3.0 0.0)))
                   (entmake '((0 . "SEQEND")))))
                '()))
  (if (and iwp-ok (not (vl-catch-all-error-p iwp-ok)))
      (progn
        ;; entlast after SEQEND is the POLYLINE header on both vendors.
        (setq *iwp-enames* (cons (entlast) *iwp-enames*))
        (iwp-vla (entlast)))
      nil))

(defun iwp-ellipse ()
  (iwp-make (list '(0 . "ELLIPSE") '(100 . "AcDbEntity") '(100 . "AcDbEllipse")
                  '(10 0.0 0.0 0.0) '(11 8.0 0.0 0.0) '(210 0.0 0.0 1.0)
                  '(40 . 0.5) '(41 . 0.0) (cons 42 (* 2 pi)))))

(defun iwp-run ( / l-diag l-anti l-par l-col l-skew l-a l-b l-c c5 l-x l-xr
                   l-tan l-out l-in l-v a-up l-y3 l-ym3 c-r6 c-tan c-far c-in
                   a-left a-low a-right pl plc p2d l-ym5 l-y5 el)
  (vl-load-com)
  (iwp-out "PRODUCT" (iwp-str (getvar "PRODUCT")))
  (iwp-out "ACADVER" (iwp-str (getvar "ACADVER")))
  (iwp-out "PLATFORM" (iwp-str (getvar "PLATFORM")))
  (iwp-out "acExtendNone" (iwp-str (vl-catch-all-apply 'eval (list 'acExtendNone))))
  (iwp-out "acExtendThisEntity" (iwp-str (vl-catch-all-apply 'eval (list 'acExtendThisEntity))))
  (iwp-out "acExtendOtherEntity" (iwp-str (vl-catch-all-apply 'eval (list 'acExtendOtherEntity))))
  (iwp-out "acExtendBoth" (iwp-str (vl-catch-all-apply 'eval (list 'acExtendBoth))))
  (setq *iwp-enames* nil)

  (setq l-diag (iwp-line '(0.0 0.0 0.0) '(10.0 10.0 0.0)))
  (iwp-out "VLA-OBJECT" (iwp-str (type l-diag)))
  (setq l-anti (iwp-line '(0.0 10.0 0.0) '(10.0 0.0 0.0)))
  (setq l-par  (iwp-line '(0.0 1.0 0.0) '(10.0 11.0 0.0)))
  (setq l-col  (iwp-line '(5.0 5.0 0.0) '(15.0 15.0 0.0)))
  (setq l-skew (iwp-line '(0.0 10.0 1.0) '(10.0 0.0 1.0)))
  (setq l-a    (iwp-line '(0.0 0.0 0.0) '(4.0 0.0 0.0)))
  (setq l-b    (iwp-line '(6.0 -2.0 0.0) '(6.0 -1.0 0.0)))
  (setq l-c    (iwp-line '(6.0 -1.0 0.0) '(6.0 1.0 0.0)))
  (setq c5     (iwp-circle '(0.0 0.0 0.0) 5.0))
  (setq l-x    (iwp-line '(-10.0 0.0 0.0) '(10.0 0.0 0.0)))
  (setq l-xr   (iwp-line '(10.0 0.0 0.0) '(-10.0 0.0 0.0)))
  (setq l-tan  (iwp-line '(-10.0 5.0 0.0) '(10.0 5.0 0.0)))
  (setq l-out  (iwp-line '(-10.0 7.0 0.0) '(10.0 7.0 0.0)))
  (setq l-in   (iwp-line '(-1.0 0.0 0.0) '(1.0 0.0 0.0)))
  (setq l-v    (iwp-line '(0.0 -10.0 0.0) '(0.0 10.0 0.0)))
  (setq a-up   (iwp-arc '(0.0 0.0 0.0) 5.0 0.0 pi))
  (setq l-y3   (iwp-line '(-10.0 3.0 0.0) '(10.0 3.0 0.0)))
  (setq l-ym3  (iwp-line '(-10.0 -3.0 0.0) '(10.0 -3.0 0.0)))
  (setq c-r6   (iwp-circle '(6.0 0.0 0.0) 5.0))
  (setq c-tan  (iwp-circle '(10.0 0.0 0.0) 5.0))
  (setq c-far  (iwp-circle '(20.0 0.0 0.0) 5.0))
  (setq c-in   (iwp-circle '(0.0 0.0 0.0) 3.0))
  (setq a-left (iwp-arc '(6.0 0.0 0.0) 5.0 (/ pi 2) (* 1.5 pi)))
  (setq a-low  (iwp-arc '(0.0 0.0 0.0) 5.0 pi (* 2 pi)))
  (setq a-right (iwp-arc '(6.0 0.0 0.0) 5.0 (* 1.5 pi) (/ pi 2)))
  (setq pl     (iwp-lwpoly 0))
  (setq plc    (iwp-lwpoly 1))
  (setq p2d    (iwp-heavy-poly))
  (iwp-out "POLYLINE-OBJECT"
           (iwp-str (if p2d
                        (vl-catch-all-apply
                         (function (lambda () (vla-get-objectname p2d))) '())
                        nil)))
  (setq l-ym5  (iwp-line '(-10.0 -5.0 0.0) '(10.0 -5.0 0.0)))
  (setq l-y5   (iwp-line '(-10.0 5.0 0.0) '(10.0 5.0 0.0)))
  (setq el     (iwp-ellipse))

  ;; LINE x LINE
  (iwp-pair "LINE-LINE-CROSS" l-diag l-anti)
  (iwp-pair "LINE-LINE-PARALLEL" l-diag l-par)
  (iwp-pair "LINE-LINE-COLLINEAR" l-diag l-col)
  (iwp-pair "LINE-LINE-SKEWZ" l-diag l-skew)
  (iwp-pair "LINE-LINE-EXTBOTH" l-a l-b)
  (iwp-pair "LINE-LINE-EXTBASE" l-a l-c)
  (iwp-pair "LINE-LINE-EXTBASE-SWAPPED" l-c l-a)
  ;; LINE x CIRCLE
  (iwp-pair "LINE-CIRCLE-TWO" l-x c5)
  (iwp-pair "LINE-CIRCLE-TWO-REVERSED" l-xr c5)
  (iwp-pair "CIRCLE-LINE-TWO" c5 l-x)
  (iwp-pair "CIRCLE-LINE-VERTICAL" c5 l-v)
  (iwp-pair "LINE-CIRCLE-TANGENT" l-tan c5)
  (iwp-pair "LINE-CIRCLE-NONE" l-out c5)
  (iwp-pair "LINE-CIRCLE-INSIDE" l-in c5)
  ;; LINE x ARC
  (iwp-pair "LINE-ARC-TWO" l-y3 a-up)
  (iwp-pair "LINE-ARC-EXTARC" l-ym3 a-up)
  (iwp-pair "ARC-LINE-EXTARC" a-up l-ym3)
  (iwp-pair "LINE-ARC-ENDS" l-x a-up)
  ;; CIRCLE x CIRCLE
  (iwp-pair "CIRCLE-CIRCLE-TWO" c5 c-r6)
  (iwp-pair "CIRCLE-CIRCLE-TWO-SWAPPED" c-r6 c5)
  (iwp-pair "CIRCLE-CIRCLE-TANGENT" c5 c-tan)
  (iwp-pair "CIRCLE-CIRCLE-NONE" c5 c-far)
  (iwp-pair "CIRCLE-CIRCLE-CONCENTRIC" c5 c-in)
  ;; ARC x ARC
  (iwp-pair "ARC-ARC-ONE" a-up a-left)
  (iwp-pair "ARC-ARC-ONE-SWAPPED" a-left a-up)
  (iwp-pair "ARC-ARC-NONE" a-low a-right)
  ;; LINE x LWPOLYLINE (and the heavy POLYLINE)
  (iwp-pair "PLINE-LINE-TWO" pl l-x)
  (iwp-pair "LINE-PLINE-TWO" l-x pl)
  (iwp-pair "PLINE-LINE-ARCSPAN" pl l-y5)
  (iwp-pair "LINE-PLINE-ARCSPAN" l-y5 pl)
  (iwp-pair "PLINE-LINE-VERTICES" pl l-y3)
  (iwp-pair "PLINE-LINE-EXTENDED" pl l-ym5)
  (iwp-pair "LINE-PLINE-EXTENDED" l-ym5 pl)
  (iwp-pair "PLINECLOSED-LINE-EXTENDED" plc l-ym5)
  (iwp-pair "PLINECLOSED-LINE-TWO" plc l-x)
  (iwp-pair "PLINE-CIRCLE" pl c5)
  (iwp-pair "POLYLINE2D-LINE-TWO" p2d l-x)
  (iwp-pair "POLYLINE2D-LINE-ARCSPAN" p2d l-y5)
  (iwp-pair "POLYLINE2D-LINE-EXTENDED" p2d l-ym5)
  ;; ELLIPSE
  (iwp-pair "ELLIPSE-LINE" el l-x)
  (iwp-pair "ELLIPSE-CIRCLE" el c5)

  ;; --- clean up -----------------------------------------------------
  (foreach iwp-en *iwp-enames*
    (vl-catch-all-apply 'entdel (list iwp-en)))
  (princ))

(vl-catch-all-apply 'iwp-run nil)
(princ "IWPROBE-DONE\n")
(princ)
