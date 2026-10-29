;;;; probes/sources/probe-pending-divergences.lsp
;;;;
;;;; One batched suite feeding the three data-blocked divergence issues, so a
;;;; single runner session on AutoCAD + BricsCAD captures all of it:
;;;;
;;;;   A. entmake-subclass-group-order -- which subclass-marker ORDERINGS each
;;;;      product accepts vs rejects (entmake-subclass-group-order.issue, "To do
;;;;      #1: probe more"). Measured so far: ARC with all-markers-first is
;;;;      created by AutoCAD, rejected by BricsCAD; ATTDEF all-markers-first is
;;;;      rejected by both. This varies the ordering per multi-subclass family.
;;;;   B. type-of-defun-subr-or-usubr -- (type f) of a user function across
;;;;      definition paths, and (type car) / (type (lambda ...)) baselines
;;;;      (type-of-defun-subr-or-usubr.issue). Vendors answered SUBR where
;;;;      clautolisp says USUBR; the open question is whether the load path
;;;;      (interpreted vs compiled) decides it.
;;;;   C. autocad-symbol-case-preserved -- the predefined symbols whose print
;;;;      name is NOT all-upper-case, swept from atoms-family
;;;;      (autocad-symbol-case-preserved.issue). clautolisp overrides only
;;;;      variant / safearray / vlax-vbEmpty today; this finds the whole set.
;;;;
;;;; Every step runs under VL-CATCH-ALL-APPLY via the cad-probe-* helpers.
;;;; Parameter names are unique (AutoLISP binds dynamically). entmake needs a
;;;; drawing, so this runs inside the CAD (probe:suite:*), not standalone.

;; ---- A. entmake subclass-marker ordering -----------------------------------

(defun cad-probe--pd-make (cad-probe--pd-data / e)
  ;; entmakex the data; "created" when it yields an ENAME, else
  ;; "rejected ERRNO=<n>" (the code the product left behind), or the error.
  (setq e (vl-catch-all-apply 'entmakex (list cad-probe--pd-data)))
  (cond ((vl-catch-all-error-p e) (strcat "ERROR " (vl-catch-all-error-message e)))
        ((= (type e) 'ENAME) "created")
        (t (strcat "rejected ERRNO="
                   (vl-prin1-to-string (vl-catch-all-apply 'getvar '("ERRNO")))))))

(defun cad-probe--pd-order (cad-probe--pd-name cad-probe--pd-data2)
  (cad-probe-capture "entmake-order" cad-probe--pd-name
    (function (lambda () (cad-probe--pd-make cad-probe--pd-data2)))))

(defun cad-probe-run-pending-divergences-probes ( / cad-probe--pd-names)
  (cad-probe-note "entmake-order"
    "legend"
    "created / rejected per subclass-marker ORDERING; control = each group after its own marker")

  ;; ARC: AcDbCircle owns 10/40, AcDbArc owns 50/51. Four orderings.
  (cad-probe--pd-order "ARC ordered (10 40 under AcDbCircle, 50 51 under AcDbArc)"
    '((0 . "ARC") (100 . "AcDbEntity")
      (100 . "AcDbCircle") (10 4.0 3.0 0.0) (40 . 2.0)
      (100 . "AcDbArc") (50 . 0.0) (51 . 1.5)))
  (cad-probe--pd-order "ARC all-markers-first (then 10 40 50 51)"
    '((0 . "ARC") (100 . "AcDbEntity") (100 . "AcDbCircle") (100 . "AcDbArc")
      (10 4.0 3.0 0.0) (40 . 2.0) (50 . 0.0) (51 . 1.5)))
  (cad-probe--pd-order "ARC groups-before-any-marker"
    '((0 . "ARC") (10 4.0 3.0 0.0) (40 . 2.0) (50 . 0.0) (51 . 1.5)
      (100 . "AcDbEntity") (100 . "AcDbCircle") (100 . "AcDbArc")))
  (cad-probe--pd-order "ARC 50 51 under AcDbCircle (AcDbArc marker empty, last)"
    '((0 . "ARC") (100 . "AcDbEntity")
      (100 . "AcDbCircle") (10 4.0 3.0 0.0) (40 . 2.0) (50 . 0.0) (51 . 1.5)
      (100 . "AcDbArc")))

  ;; ATTDEF: AcDbText owns 10/40/1, AcDbAttributeDefinition owns 3/2/70.
  (cad-probe--pd-order "ATTDEF ordered (10 40 1 under AcDbText, 3 2 70 under AcDbAttributeDefinition)"
    '((0 . "ATTDEF") (100 . "AcDbEntity")
      (100 . "AcDbText") (10 1.0 1.0 0.0) (40 . 0.2) (1 . "V")
      (100 . "AcDbAttributeDefinition") (3 . "prompt") (2 . "TAG") (70 . 0)))
  (cad-probe--pd-order "ATTDEF all-markers-first (then 10 40 1 3 2 70)"
    '((0 . "ATTDEF") (100 . "AcDbEntity") (100 . "AcDbText") (100 . "AcDbAttributeDefinition")
      (10 1.0 1.0 0.0) (40 . 0.2) (1 . "V") (3 . "prompt") (2 . "TAG") (70 . 0)))

  ;; LWPOLYLINE: single subclass (AcDbPolyline) -- a control that ordering
  ;; cannot break, to confirm single-subclass families are order-insensitive.
  (cad-probe--pd-order "LWPOLYLINE single-subclass (90 70 10 10 after AcDbPolyline)"
    '((0 . "LWPOLYLINE") (100 . "AcDbEntity") (100 . "AcDbPolyline")
      (90 . 2) (70 . 0) (10 0.0 0.0) (10 1.0 0.0)))

  ;; ---- B. (type ...) of a user function across definition paths -----------
  (cad-probe-note "type-of-fn" "legend"
    "TYPE of a function by how it was defined (SUBR vs USUBR); car = builtin baseline")
  ;; Defined by evaluating a DEFUN form read at run time (interpreted source).
  (cad-probe-capture "type-of-fn" "(type f) where f from (eval (read defun))"
    (function (lambda ( / )
      (eval (read "(defun cad-probe--pd-f () 1)"))
      (vl-princ-to-string (type cad-probe--pd-f)))))
  (cad-probe-capture "type-of-fn" "(type (function f))"
    (function (lambda () (vl-princ-to-string (type (function cad-probe--pd-f))))))
  ;; Defined in a plain .lsp loaded with LOAD (the issue's second path).
  (cad-probe-capture "type-of-fn" "(type g) where g from a LOAD'd .lsp"
    (function (lambda ( / dir path handle)
      (setq dir (getvar "TEMPPREFIX"))
      (if (or (null dir) (= dir "")) (setq dir "./"))
      (setq path (strcat dir "cad-probe-typefn.lsp"))
      (setq handle (open path "w"))
      (if handle (progn (write-line "(defun cad-probe--pd-g () 2)" handle) (close handle)))
      (load path)
      (vl-string-subst "" "" "")   ; no-op to keep the thunk a progn
      (vl-princ-to-string (type cad-probe--pd-g)))))
  (cad-probe-capture "type-of-fn" "(type car) builtin baseline"
    (function (lambda () (vl-princ-to-string (type car)))))
  (cad-probe-capture "type-of-fn" "(type (lambda () 1)) anonymous"
    (function (lambda () (vl-princ-to-string (type (lambda () 1))))))

  ;; ---- C. predefined symbols whose print name is not all-upper-case -------
  (cad-probe-note "symbol-case" "legend"
    "predefined symbol names (atoms-family) that are NOT all-upper-case")
  (cad-probe-capture "symbol-case" "count of all predefined symbols"
    (function (lambda () (length (atoms-family 1)))))
  (cad-probe-capture "symbol-case" "names where name /= (strcase name)"
    (function (lambda ( / cad-probe--pd-names cad-probe--pd-lower)
      (setq cad-probe--pd-names
            (mapcar (function vl-princ-to-string) (atoms-family 1)))
      (setq cad-probe--pd-lower
            (vl-remove-if
              (function (lambda (cad-probe--pd-n) (= cad-probe--pd-n (strcase cad-probe--pd-n))))
              cad-probe--pd-names))
      (vl-prin1-to-string cad-probe--pd-lower))))
  (princ))
