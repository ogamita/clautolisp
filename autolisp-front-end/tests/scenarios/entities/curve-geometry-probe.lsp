;;;; curve-geometry-probe.lsp -- MEASURE how AutoCAD and BricsCAD answer the
;;;; curve-geometry surface (issues/open/cador-curve-length-and-sampling):
;;;; vlax-curve-* on ARC / CIRCLE / LINE / LWPOLYLINE (bulges, closed,
;;;; elevation) / 2D POLYLINE, at boundary params / dists and at points exactly
;;;; at vertices; the geometric ActiveX properties (ArcLength, TotalAngle,
;;;; Length, Area, ...); how entmake / command ARC / vla-AddArc store an
;;;; ARC's angles.
;;;;
;;;; Every case is held as TEXT and READ when it runs, then evaluated under
;;;; vl-catch-all-apply: a function an engine lacks (vla-* in AcCoreConsole,
;;;; which has no COM) is that one case's ERROR, never a refused LOAD.
;;;;
;;;; Output, one line per case, tab-separated:
;;;;   CURVE   <entity>   <expression>   <status>   <value>
;;;; status: VALUE, NIL, ERROR (value = the error message), NOENTITY (the
;;;; entity could not be built). Reals are printed with (rtos x 2 15), lists
;;;; element-wise. The run ends with a CURVE-DONE line; a report without it
;;;; died mid-way.
;;;;
;;;; In clautolisp (--clautolisp --host mock) the same file yields the
;;;; baseline column the vendor columns are compared with.

(vl-load-com)
(setvar "CMDECHO" 0)

(defun cg-fmt (v)
  (cond
    ((null v) "nil")
    ((= (type v) 'REAL) (rtos v 2 15))
    ((= (type v) 'INT) (itoa v))
    ((= (type v) 'STR) (vl-prin1-to-string v))
    ((and (= (type v) 'LIST) (vl-consp v) (not (vl-consp (cdr v))) (cdr v))
     (strcat "(" (cg-fmt (car v)) " . " (cg-fmt (cdr v)) ")"))
    ((= (type v) 'LIST)
     (strcat "(" (cg-join (mapcar 'cg-fmt v)) ")"))
    ((= (type v) 'VARIANT) (strcat "#variant " (cg-fmt (vl-catch-all-apply 'vlax-variant-value (list v)))))
    ((= (type v) 'SAFEARRAY) (strcat "#safearray " (cg-fmt (vl-catch-all-apply 'vlax-safearray->list (list v)))))
    (t (vl-prin1-to-string v))))

(defun cg-join (strings / out)
  (setq out "")
  (foreach s strings
    (setq out (if (= out "") s (strcat out " " s))))
  out)

(defun cg-case (label text / form v)
  (setq form (vl-catch-all-apply 'read (list text)))
  (if (vl-catch-all-error-p form)
      (setq v form)
      (setq v (vl-catch-all-apply 'eval (list form))))
  (princ
    (strcat "CURVE\t" label "\t" text "\t"
            (cond
              ((vl-catch-all-error-p v) (strcat "ERROR\t" (vl-catch-all-error-message v)))
              ((null v) "NIL\tnil")
              (t (strcat "VALUE\t" (cg-fmt v))))
            "\n")))

;; The questions asked of EVERY curve; `e' is the curve's ename, `o' its
;; VLA-object (nil where COM is absent).
(setq cg-common-cases
  (list
    "(vlax-curve-getStartParam e)"
    "(vlax-curve-getEndParam e)"
    "(vlax-curve-getStartPoint e)"
    "(vlax-curve-getEndPoint e)"
    "(vlax-curve-getDistAtParam e (vlax-curve-getStartParam e))"
    "(vlax-curve-getDistAtParam e (vlax-curve-getEndParam e))"
    "(vlax-curve-getDistAtParam e (- (vlax-curve-getStartParam e) 0.1))"
    "(vlax-curve-getDistAtParam e (+ (vlax-curve-getEndParam e) 0.1))"
    "(vlax-curve-getParamAtDist e 0.0)"
    "(vlax-curve-getParamAtDist e (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)))"
    "(vlax-curve-getParamAtDist e (+ (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)) 1.0e-9))"
    "(vlax-curve-getParamAtDist e (+ (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)) 1.0))"
    "(vlax-curve-getParamAtDist e -1.0)"
    "(vlax-curve-getPointAtDist e (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)))"
    "(vlax-curve-getPointAtDist e (/ (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)) 2.0))"
    "(vlax-curve-getPointAtParam e (vlax-curve-getEndParam e))"
    "(vlax-curve-getPointAtParam e (+ (vlax-curve-getEndParam e) 0.5))"
    "(vlax-curve-getPointAtParam e (- (vlax-curve-getStartParam e) 0.5))"
    "(vlax-curve-getParamAtPoint e (vlax-curve-getStartPoint e))"
    "(vlax-curve-getParamAtPoint e (vlax-curve-getEndPoint e))"
    "(vlax-curve-getDistAtPoint e (vlax-curve-getStartPoint e))"
    "(vlax-curve-getDistAtPoint e (vlax-curve-getEndPoint e))"
    "(vlax-curve-getParamAtPoint e (list (car (vlax-curve-getEndPoint e)) (cadr (vlax-curve-getEndPoint e))))"
    "(vlax-curve-getDistAtPoint e (list (car (vlax-curve-getEndPoint e)) (cadr (vlax-curve-getEndPoint e))))"
    "(vlax-curve-getParamAtPoint e (mapcar '+ (vlax-curve-getEndPoint e) '(0.0 0.0 1.0e-7)))"
    "(vlax-curve-getParamAtPoint e (mapcar '+ (vlax-curve-getEndPoint e) '(0.0 0.0 1.0e-4)))"
    "(vlax-curve-getParamAtPoint e '(1000.0 1000.0 0.0))"
    "(vlax-curve-getClosestPointTo e '(1000.0 1000.0 0.0))"
    "(vlax-curve-getClosestPointTo e '(1000.0 1000.0 0.0) T)"
    "(vlax-curve-getFirstDeriv e (vlax-curve-getStartParam e))"
    "(vlax-curve-getFirstDeriv e (vlax-curve-getEndParam e))"
    "(vlax-curve-getSecondDeriv e (vlax-curve-getStartParam e))"
    "(vlax-curve-getArea e)"
    "(vlax-curve-isClosed e)"
    "(vlax-curve-isPeriodic e)"
    "(vlax-curve-isPlanar e)"
    "(vlax-curve-getPerimeter e)"
    "(vlax-curve-getStartParam o)"
    "(vlax-curve-getDistAtParam o (vlax-curve-getEndParam o))"
    "(vla-get-ObjectName o)"
    "(vlax-get o 'Length)"
    "(vlax-get o 'Area)"
    "(vla-get-Length o)"
    "(vla-get-Area o)"))

(defun cg-curve (label maker extra / e o)
  (setq e (vl-catch-all-apply 'eval (list (read maker))))
  (if (or (null e) (vl-catch-all-error-p e))
      (princ (strcat "CURVE\t" label "\t" maker "\tNOENTITY\t"
                     (if e (vl-catch-all-error-message e) "nil") "\n"))
      (progn
        (setq o (vl-catch-all-apply 'vlax-ename->vla-object (list e)))
        (if (vl-catch-all-error-p o) (setq o nil))
        (cg-case label "(entget e)")
        (foreach text cg-common-cases (cg-case label text))
        (foreach text extra (cg-case label text)))))

(setq cg-pi/2 1.5707963267948966
      cg-pi/4 0.7853981633974483
      cg-7pi/4 5.497787143782138)

;; --- ARC, R 10 about the origin, 0 -> 90 degrees --------------------------
(cg-curve "arc-0-90"
  "(entmakex (list '(0 . \"ARC\") '(100 . \"AcDbEntity\") '(100 . \"AcDbCircle\") '(10 0.0 0.0 0.0) '(40 . 10.0) '(100 . \"AcDbArc\") (cons 50 0.0) (cons 51 cg-pi/2)))"
  (list
    "(vlax-curve-getPointAtParam e cg-pi/4)"
    "(vlax-curve-getDistAtParam e cg-pi/4)"
    "(vlax-curve-getParamAtDist e 5.0)"
    "(vlax-curve-getParamAtPoint e '(0.0 10.0 0.0))"
    "(vlax-curve-getDistAtPoint e '(0.0 10.0 0.0))"
    "(vlax-curve-getDistAtPoint e (list (* 10 (cos cg-pi/4)) (* 10 (sin cg-pi/4)) 0.0))"
    "(vlax-curve-getClosestPointTo e '(0.0 20.0 0.0))"
    "(vlax-curve-getClosestPointTo e '(-10.0 -1.0 0.0))"
    "(vlax-curve-getClosestPointTo e '(-10.0 -1.0 0.0) T)"
    "(vlax-get o 'ArcLength)"
    "(vlax-get o 'TotalAngle)"
    "(vlax-get o 'StartAngle)"
    "(vlax-get o 'EndAngle)"
    "(vlax-get o 'StartPoint)"
    "(vlax-get o 'EndPoint)"
    "(vlax-get o 'Center)"
    "(vlax-get o 'Radius)"
    "(vla-get-ArcLength o)"
    "(vla-get-TotalAngle o)"
    "(vla-get-StartAngle o)"))

;; --- ARC crossing 0 degrees: 315 -> 45 ------------------------------------
(cg-curve "arc-315-45"
  "(entmakex (list '(0 . \"ARC\") '(100 . \"AcDbEntity\") '(100 . \"AcDbCircle\") '(10 0.0 0.0 0.0) '(40 . 10.0) '(100 . \"AcDbArc\") (cons 50 cg-7pi/4) (cons 51 cg-pi/4)))"
  (list
    "(vlax-curve-getParamAtPoint e '(10.0 0.0 0.0))"
    "(vlax-curve-getDistAtPoint e '(10.0 0.0 0.0))"
    "(vlax-curve-getPointAtParam e 0.1)"
    "(vlax-curve-getPointAtParam e (+ 0.1 (* 2 pi)))"
    "(vlax-curve-getDistAtParam e 0.1)"
    "(vlax-curve-getDistAtParam e (* 2 pi))"
    "(vlax-get o 'ArcLength)"
    "(vlax-get o 'TotalAngle)"
    "(vlax-get o 'StartAngle)"
    "(vlax-get o 'EndAngle)"))

;; --- ARC entmade with angles outside [0, 2pi): are they normalised? -------
(cg-curve "arc-entmake-unnormalised"
  "(entmakex (list '(0 . \"ARC\") '(100 . \"AcDbEntity\") '(100 . \"AcDbCircle\") '(10 0.0 0.0 0.0) '(40 . 10.0) '(100 . \"AcDbArc\") (cons 50 (- cg-pi/4)) (cons 51 7.0)))"
  (list "(vlax-get o 'StartAngle)" "(vlax-get o 'EndAngle)"))

;; --- ARC by command, Center form, and by vla-AddArc --------------------------
(cg-curve "arc-command-center"
  "(progn (command \"_.ARC\" \"_C\" '(0.0 0.0) '(10.0 0.0) '(0.0 10.0)) (entlast))"
  (list "(vlax-get o 'ArcLength)"))
(cg-curve "arc-command-center-angle"
  "(progn (command \"_.ARC\" \"_C\" '(0.0 0.0) (list (* 10 (cos cg-7pi/4)) (* 10 (sin cg-7pi/4))) \"_A\" 90) (entlast))"
  (list "(vlax-get o 'ArcLength)"))
(cg-curve "arc-command-3p-negative-angles"
  "(progn (command \"_.ARC\" '(0.0 -10.0) '(10.0 0.0) '(0.0 10.0)) (entlast))"
  nil)
(cg-curve "arc-vla-addarc"
  "(vlax-vla-object->ename (vla-AddArc (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))) (vlax-3d-point '(0.0 0.0 0.0)) 10.0 (- cg-pi/4) cg-pi/4))"
  (list "(vlax-get o 'StartAngle)" "(vlax-get o 'ArcLength)"))

;; --- CIRCLE R 5 ------------------------------------------------------------------
(cg-curve "circle-r5"
  "(entmakex '((0 . \"CIRCLE\") (100 . \"AcDbEntity\") (100 . \"AcDbCircle\") (10 0.0 0.0 0.0) (40 . 5.0)))"
  (list
    "(vlax-curve-getPointAtParam e cg-pi/2)"
    "(vlax-curve-getDistAtParam e pi)"
    "(vlax-curve-getParamAtDist e (* 5 pi))"
    "(vlax-curve-getParamAtPoint e '(0.0 5.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(5.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(5.0 -1.0e-12 0.0))"
    "(vlax-get o 'Circumference)"
    "(vlax-get o 'Diameter)"))

;; --- LINE (0,0) -> (10,0) ---------------------------------------------------------
(cg-curve "line-10"
  "(entmakex '((0 . \"LINE\") (100 . \"AcDbEntity\") (100 . \"AcDbLine\") (10 0.0 0.0 0.0) (11 10.0 0.0 0.0)))"
  (list
    "(vlax-curve-getPointAtParam e 5.0)"
    "(vlax-curve-getParamAtPoint e '(4.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(4.0 0.0))"
    "(vlax-curve-getFirstDeriv e 5.0)"
    "(vlax-get o 'Angle)"
    "(vlax-get o 'Delta)"))

;; --- LWPOLYLINE (0,0) bulge 1 (10,0) then (10,10) ----------------------------------
(cg-curve "lwpoly-bulge"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 3) (70 . 0) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0) (10 10.0 10.0)))"
  (list
    "(vlax-curve-getDistAtParam e 1.0)"
    "(vlax-curve-getDistAtParam e 0.5)"
    "(vlax-curve-getDistAtParam e 1.5)"
    "(vlax-curve-getPointAtParam e 0.5)"
    "(vlax-curve-getPointAtParam e 0.25)"
    "(vlax-curve-getPointAtParam e 1.0)"
    "(vlax-curve-getParamAtPoint e '(0.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(10.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(10.0 10.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(5.0 -5.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(10.0 0.0))"
    "(vlax-curve-getDistAtPoint e '(10.0 0.0 0.0))"
    "(vlax-curve-getDistAtPoint e '(5.0 -5.0 0.0))"
    "(vlax-curve-getPointAtDist e (* 2.5 pi))"
    "(vlax-curve-getParamAtDist e (* 5 pi))"
    "(vlax-curve-getFirstDeriv e 0.5)"
    "(vlax-curve-getFirstDeriv e 1.5)"
    "(vlax-curve-getSecondDeriv e 0.5)"
    "(vlax-curve-getClosestPointTo e '(5.0 -9.0 0.0))"
    "(vlax-get o 'Coordinates)"
    "(vla-GetBulge o 0)"
    "(vlax-get o 'Closed)"))

;; --- LWPOLYLINE closed 10x10 square, and a closed one with a bulge -------------------
(cg-curve "lwpoly-closed-square"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 4) (70 . 1) (10 0.0 0.0) (10 10.0 0.0) (10 10.0 10.0) (10 0.0 10.0)))"
  (list
    "(vlax-curve-getPointAtParam e 3.5)"
    "(vlax-curve-getParamAtPoint e '(0.0 10.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(0.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(0.0 5.0 0.0))"
    "(vlax-curve-getDistAtPoint e '(0.0 5.0 0.0))"
    "(vlax-get o 'Closed)"))
(cg-curve "lwpoly-closed-bulge"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 1) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0) (42 . 1.0)))"
  (list "(vlax-curve-getPointAtParam e 1.5)"))
(cg-curve "lwpoly-open-negative-bulge"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 0) (10 0.0 0.0) (42 . -1.0) (10 10.0 0.0)))"
  (list "(vlax-curve-getPointAtParam e 0.5)"))

;; --- LWPOLYLINE at elevation 5: 2D vs 3D query points ---------------------------------
(cg-curve "lwpoly-elevation-5"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 0) (38 . 5.0) (10 0.0 0.0) (10 10.0 0.0)))"
  (list
    "(vlax-curve-getParamAtPoint e '(4.0 0.0 5.0))"
    "(vlax-curve-getParamAtPoint e '(4.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(4.0 0.0 0.0))"
    "(vlax-curve-getClosestPointTo e '(4.0 3.0))"))

;; --- 2D (heavy) POLYLINE, the same bulge path ------------------------------------------
(cg-curve "poly2d-bulge"
  "(progn (entmake '((0 . \"POLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDb2dPolyline\") (66 . 1) (70 . 0) (10 0.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 0.0 0.0 0.0) (42 . 1.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 10.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 10.0 10.0 0.0))) (entmake '((0 . \"SEQEND\") (100 . \"AcDbEntity\"))) (entlast))"
  (list
    "(vlax-curve-getDistAtParam e 1.0)"
    "(vlax-curve-getPointAtParam e 0.5)"
    "(vlax-curve-getParamAtPoint e '(10.0 0.0 0.0))"
    "(vlax-curve-getParamAtPoint e '(5.0 -5.0 0.0))"))

;;; --- second round (2026-10-08): the thresholds the first run bracketed ----

;; Reading long real literals: on AutoCAD the first run saw the constants
;; above (17 significant digits) arrive as 1.5708 / 0.785398 / 5.49779.
(setq cg-long 1.5707963267948966 cg-mid 1.570796326794897 cg-short 1.5707963267949)
(cg-case "reader" "(rtos cg-long 2 16)")
(cg-case "reader" "(rtos cg-mid 2 16)")
(cg-case "reader" "(rtos cg-short 2 16)")
(cg-case "reader" "(rtos (atof \"1.5707963267948966\") 2 16)")
(cg-case "reader" "(rtos (read \"1.5707963267948966\") 2 16)")
(cg-case "reader" "(rtos (/ pi 2) 2 16)")
;; Decisive between the CAD's reader and alfe's transport
;; (alfe-cad-transport-rounds-reals): a TOP-LEVEL form travels through alfe's
;; autolisp-eval-request-form, which re-prints it; the text inside a string
;; is only READ on the CAD. Same literal, both ways.
(setq cg-x 1.2345678901234)
(cg-case "reader" "(rtos cg-x 2 16)")
(cg-case "reader" "(rtos (eval (read \"(setq cg-y 1.2345678901234)\")) 2 16)")
(cg-case "reader" "(rtos 1.2345678901234 2 16)")

;; Point tolerance: offsets off the end of an ARC, a LINE, LWPOLYLINEs at
;; elevation 0 and 5 and a 2D POLYLINE, along Z and in the plane.
(setq cg-offsets '(1.0e-11 1.0e-10 1.0e-9 1.0e-8 1.0e-6 1.0e-5))
(defun cg-tolerance-cases (label maker / e p)
  (setq e (vl-catch-all-apply 'eval (list (read maker))))
  (if (or (null e) (vl-catch-all-error-p e))
      (princ (strcat "CURVE\t" label "\t" maker "\tNOENTITY\tnil\n"))
      (progn
        (setq p (vlax-curve-getEndPoint e))
        (foreach d cg-offsets
          (setq cg-tol-e e cg-tol-p p cg-tol-d d)
          (cg-case label (strcat "(vlax-curve-getParamAtPoint cg-tol-e (mapcar '+ cg-tol-p (list 0.0 0.0 cg-tol-d))) ; z " (rtos d 1 0)))
          (cg-case label (strcat "(vlax-curve-getParamAtPoint cg-tol-e (mapcar '+ cg-tol-p (list cg-tol-d cg-tol-d 0.0))) ; xy " (rtos d 1 0)))))))
(cg-tolerance-cases "tol-arc"
  "(entmakex (list '(0 . \"ARC\") '(100 . \"AcDbEntity\") '(100 . \"AcDbCircle\") '(10 0.0 0.0 0.0) '(40 . 10.0) '(100 . \"AcDbArc\") (cons 50 0.0) (cons 51 (/ pi 2))))")
(cg-tolerance-cases "tol-line"
  "(entmakex '((0 . \"LINE\") (100 . \"AcDbEntity\") (100 . \"AcDbLine\") (10 0.0 0.0 0.0) (11 10.0 0.0 0.0)))")
(cg-tolerance-cases "tol-line-z5"
  "(entmakex '((0 . \"LINE\") (100 . \"AcDbEntity\") (100 . \"AcDbLine\") (10 0.0 0.0 5.0) (11 10.0 0.0 5.0)))")
(cg-tolerance-cases "tol-lwpoly"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 3) (70 . 0) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0) (10 10.0 10.0)))")
(cg-tolerance-cases "tol-lwpoly-z5"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 0) (38 . 5.0) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0)))")

;; BricsCAD answers getParamAtDist far past the end with the LENGTH, a hair
;; past it like at the end: where is the threshold? (and AutoCAD's polylines)
(setq cg-overshoots '(1.0e-8 1.0e-7 1.0e-6 1.0e-5 1.0e-4 1.0e-2))
(defun cg-overshoot-cases (label maker / e len)
  (setq e (vl-catch-all-apply 'eval (list (read maker))))
  (if (or (null e) (vl-catch-all-error-p e))
      (princ (strcat "CURVE\t" label "\t" maker "\tNOENTITY\tnil\n"))
      (progn
        (setq cg-ov-e e cg-ov-len (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)))
        (foreach d cg-overshoots
          (setq cg-ov-d d)
          (cg-case label (strcat "(vlax-curve-getParamAtDist cg-ov-e (+ cg-ov-len cg-ov-d)) ; +" (rtos d 1 0)))
          (cg-case label (strcat "(vlax-curve-getParamAtDist cg-ov-e (- cg-ov-d)) ; -" (rtos d 1 0)))
          (cg-case label (strcat "(vlax-curve-getDistAtParam cg-ov-e (+ (vlax-curve-getEndParam cg-ov-e) cg-ov-d)) ; +" (rtos d 1 0)))))))
(cg-overshoot-cases "over-arc"
  "(entmakex (list '(0 . \"ARC\") '(100 . \"AcDbEntity\") '(100 . \"AcDbCircle\") '(10 0.0 0.0 0.0) '(40 . 10.0) '(100 . \"AcDbArc\") (cons 50 0.0) (cons 51 (/ pi 2))))")
(cg-overshoot-cases "over-lwpoly"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 3) (70 . 0) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0) (10 10.0 10.0)))")
(cg-overshoot-cases "over-poly2d"
  "(progn (entmake '((0 . \"POLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDb2dPolyline\") (66 . 1) (70 . 0) (10 0.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 0.0 0.0 0.0) (42 . 1.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 10.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 10.0 10.0 0.0))) (entmake '((0 . \"SEQEND\") (100 . \"AcDbEntity\"))) (entlast))")

;; AutoCAD's LWPOLYLINE second derivative carried the elevation as Z on a
;; straight segment: on a bulge segment too? And a 2D POLYLINE's Coordinates.
(cg-curve "lwpoly-bulge-elevation-5"
  "(entmakex '((0 . \"LWPOLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDbPolyline\") (90 . 2) (70 . 0) (38 . 5.0) (10 0.0 0.0) (42 . 1.0) (10 10.0 0.0)))"
  (list "(vlax-curve-getSecondDeriv e 0.5)" "(vlax-curve-getFirstDeriv e 0.5)"))
(cg-curve "poly2d-coordinates"
  "(progn (entmake '((0 . \"POLYLINE\") (100 . \"AcDbEntity\") (100 . \"AcDb2dPolyline\") (66 . 1) (70 . 0) (10 0.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 0.0 0.0 0.0))) (entmake '((0 . \"VERTEX\") (100 . \"AcDbEntity\") (100 . \"AcDbVertex\") (100 . \"AcDb2dVertex\") (10 10.0 0.0 0.0))) (entmake '((0 . \"SEQEND\") (100 . \"AcDbEntity\"))) (entlast))"
  (list "(vlax-get o 'Coordinates)" "(vlax-get o 'Closed)"))

(princ "CURVE-DONE\n")
(princ)
