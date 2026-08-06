(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; End-to-end AutoLISP tests for the drawing-data + selection layer
;;;; (REGAPP, XData round-trip, the named-object-dictionary tree,
;;;; XRECORD lifecycle, symbol tables, and the ssget filter grammar)
;;;; driven through the reader + evaluator against a fresh MockHost.
;;;;
;;;; Each program returns an integer (a count, or 1/0 for a boolean)
;;;; so the CL-side assertion is a simple EQL — no wrapper unwrapping.

(defun %dd-run (source)
  "Evaluate SOURCE through the evaluator on a fresh mock host; return
the raw result value."
  (reset-autolisp-symbol-table)
  (run-autolisp-string source :setup-fn #'%install-cador-and-core))

;;; --- REGAPP ------------------------------------------------------

(test dd-regapp-registers-then-rejects-duplicate
  ;; first regapp returns the name; second returns nil.
  (is (eql 1 (%dd-run "(if (and (regapp \"SCHMS\") (not (regapp \"SCHMS\"))) 1 0)")))
  ;; an invalid name (reserved char) fails via SNVALID -> nil
  (is (eql 1 (%dd-run "(if (regapp \"BAD/NAME\") 0 1)"))))

;;; --- Divergence D1: R13+ subclass-marker enforcement (dialect) ---

(defun %d1-run (source dialect-keyword)
  "Evaluate SOURCE under DIALECT-KEYWORD on a fresh mock host, capturing
*error-output*; return (values RESULT WARNING-STRING). FiveAM's progress
dots go to *standard-output*, so rebinding *error-output* is clean."
  (reset-autolisp-symbol-table)
  (let ((warn (make-string-output-stream))
        (dialect (or (clautolisp.autolisp-reader:find-autolisp-dialect dialect-keyword)
                     (error "unknown dialect ~S" dialect-keyword))))
    (let ((result (let ((*error-output* warn))
                    (run-autolisp-string source
                                         :dialect dialect
                                         :setup-fn #'%install-cador-and-core))))
      (values result (get-output-stream-string warn)))))

;; A marker-less ELLIPSE (R13+): AutoCAD rejects it, BricsCAD accepts it.
(defparameter *d1-markerless-ellipse*
  "(if (= (type (entmakex (list (cons 0 \"ELLIPSE\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 0.0 0.0))
                                (cons 40 0.5) (cons 41 0.0) (cons 42 6.28))))
         'ENAME) 1 0)")

;; The same ELLIPSE WITH the AutoCAD subclass markers supplied.
(defparameter *d1-marked-ellipse*
  "(if (= (type (entmakex (list (cons 0 \"ELLIPSE\")
                                (cons 100 \"AcDbEntity\") (cons 100 \"AcDbEllipse\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 0.0 0.0))
                                (cons 40 0.5) (cons 41 0.0) (cons 42 6.28))))
         'ENAME) 1 0)")

;; A marker-less LINE (pre-R13): accepted by every vendor, marker or not.
(defparameter *d1-markerless-line*
  "(if (= (type (entmakex (list (cons 0 \"LINE\")
                                (cons 10 (list 0.0 0.0 0.0))
                                (cons 11 (list 1.0 1.0 0.0)))))
         'ENAME) 1 0)")

;; The autolisp-spec resolves D1 in AutoCAD's favour (markers required),
;; so the NORMATIVE dialects (autocad, clautolisp, strict) reject
;; marker-less input; the DEVIANT dialects (bricscad, lax) accept it.
;; strict (any divergence) and bricscad (the non-condoned deviant) warn.

(test dd-d1-normative-dialects-reject-markerless-r13-entity
  (dolist (d '(:autocad-2026 :clautolisp :strict))
    (is (eql 0 (nth-value 0 (%d1-run *d1-markerless-ellipse* d)))
        "marker-less ELLIPSE should be rejected under ~S" d)))

(test dd-d1-deviant-dialects-accept-markerless-r13-entity
  (dolist (d '(:bricscad-v26 :lax))
    (is (eql 1 (nth-value 0 (%d1-run *d1-markerless-ellipse* d)))
        "marker-less ELLIPSE should be accepted under ~S" d)))

(test dd-d1-warns-under-bricscad-and-strict-only
  (dolist (d '(:bricscad-v26 :strict))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-ellipse* d)
      (declare (ignore r))
      (is (search "entmake-subclass-marker" w)
          "expected the [entmake-subclass-marker] warning under ~S; got: ~S" d w)))
  (dolist (d '(:autocad-2026 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-ellipse* d)
      (declare (ignore r))
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d1-explicit-markers-portable-across-all-dialects
  ;; With the markers supplied, the create succeeds everywhere — including
  ;; the strict dialects — with no warning.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-marked-ellipse* d)
      (is (eql 1 r) "marked ELLIPSE should create under ~S" d)
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d1-pre-r13-entity-unaffected-by-marker-contract
  ;; A LINE is pre-R13: no marker requirement under any dialect.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w) (%d1-run *d1-markerless-line* d)
      (is (eql 1 r) "markerless LINE should create under ~S" d)
      (is (string= "" w) "no warning expected for LINE under ~S; got: ~S" d w))))

;;; --- Divergence D3: entmod on a non-graphical XRECORD (dialect) --

;; Create an XRECORD under a dict key, entmod its group-1 value, read it
;; back; return the readback string. On AutoCAD entmod no-ops (old value),
;; on BricsCAD it updates.
(defparameter *d3-xrecord-entmod*
  "(setq nod (namedobjdict))
   (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v1\"))))
   (dictadd nod \"K\" xr)
   (entmod (list (cons -1 xr) (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v2\")))
   (cdr (assoc 1 (dictsearch nod \"K\")))")

(defun %d3-readback (dialect-keyword)
  "Run the xrecord-entmod probe under DIALECT-KEYWORD; return
(values READBACK-STRING WARNING)."
  (multiple-value-bind (r w) (%d1-run *d3-xrecord-entmod* dialect-keyword)
    (values (and (typep r 'autolisp-string) (autolisp-string-value r)) w)))

;; The autolisp-spec resolves D3 in AutoCAD's favour (entmod does not
;; modify a non-graphical object -> no-op), so the NORMATIVE dialects
;; (autocad, clautolisp, strict) keep the old value; the DEVIANT dialects
;; (bricscad, lax) apply. strict and bricscad warn.

(test dd-d3-normative-dialects-noop-entmod-on-xrecord
  (dolist (d '(:autocad-2026 :clautolisp :strict))
    (is (string= "v1" (%d3-readback d))
        "entmod on xrecord should be a no-op under ~S" d)))

(test dd-d3-deviant-dialects-apply-entmod-on-xrecord
  (dolist (d '(:bricscad-v26 :lax))
    (is (string= "v2" (%d3-readback d))
        "entmod on xrecord should apply under ~S" d)))

(test dd-d3-warns-under-bricscad-and-strict-only
  (dolist (d '(:bricscad-v26 :strict))
    (multiple-value-bind (r w) (%d3-readback d)
      (declare (ignore r))
      (is (search "entmod-nongraphical" w)
          "expected the [entmod-nongraphical] warning under ~S; got: ~S" d w)))
  (dolist (d '(:autocad-2026 :clautolisp :lax))
    (multiple-value-bind (r w) (%d3-readback d)
      (declare (ignore r))
      (is (string= "" w) "no warning expected under ~S; got: ~S" d w))))

(test dd-d3-graphical-entmod-unaffected-by-object-gate
  ;; entmod on a graphical entity (CIRCLE) always applies, every dialect,
  ;; no warning -- the D3 gate is non-graphical-objects only.
  (dolist (d '(:autocad-2026 :strict :bricscad-v26 :clautolisp :lax))
    (multiple-value-bind (r w)
        (%d1-run "
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (list (cons -1 e) (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 2.0)))
  (cdr (assoc 40 (entget e)))" d)
      (is (and (numberp r) (= r 2.0)) "CIRCLE entmod should apply under ~S (got ~S)" d r)
      (is (string= "" w) "no warning expected for a graphical entmod under ~S; got: ~S" d w))))

;;; --- XData round-trip with the full group-code set ---------------

(test dd-xdata-full-codeset-round-trips-through-entmod
  ;; Attach xdata using every SCHMS group code plus points and the
  ;; brace controls, then read them back verbatim and count the pairs
  ;; recovered under the application list.
  (is (eql 8
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"APP\"
                                       (cons 1000 \"str\")
                                       (cons 1002 \"{\")
                                       (cons 1003 \"LAYER0\")
                                       (cons 1005 \"2A\")
                                       (cons 1040 1.5)
                                       (cons 1070 42)
                                       (cons 1071 100000)
                                       (cons 1002 \"}\"))))))
  (setq xd (cdr (assoc -3 (entget e (list \"APP\")))))
  ;; xd = ((\"APP\" (1000 . str) (1002 . {) ...)); count the xdata pairs
  (length (cdr (car xd)))"))))

(test dd-xdata-preserves-order-and-multiplicity
  ;; Two 1000 strings in a set order must come back in the same order.
  (is (eql 1
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"APP\" (cons 1000 \"first\") (cons 1000 \"second\"))))))
  (setq xd (cdr (car (cdr (assoc -3 (entget e (list \"APP\")))))))
  ;; xd = ((1000 . first) (1000 . second)) -> check both order and count
  (if (and (= (length xd) 2)
           (= (strcase (cdr (nth 0 xd))) \"FIRST\")
           (= (strcase (cdr (nth 1 xd))) \"SECOND\"))
      1 0)"))))

(test dd-entget-without-applist-suppresses-xdata
  (is (eql 1
           (%dd-run "
  (regapp \"APP\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e) (list (list -3 (list \"APP\" (cons 1000 \"x\"))))))
  (if (and (null (assoc -3 (entget e)))
           (assoc -3 (entget e (list \"APP\"))))
      1 0)"))))

(test dd-xdata-multi-application-filter
  ;; Two applications' xdata on one entity; entget with one app name
  ;; surfaces only that app; the wildcard surfaces both.
  (is (eql 1
           (%dd-run "
  (regapp \"A1\") (regapp \"A2\")
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list \"A1\" (cons 1000 \"one\"))
                                  (list \"A2\" (cons 1000 \"two\"))))))
  (if (and (= (length (cdr (assoc -3 (entget e (list \"A1\"))))) 1)
           (= (length (cdr (assoc -3 (entget e (list \"A2\"))))) 1)
           (= (length (cdr (assoc -3 (entget e (list \"*\"))))) 2))
      1 0)"))))

;;; --- Named-object dictionary + XRECORD lifecycle ----------------

(test dd-dictionary-xrecord-lifecycle
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\")
                           (cons 1 \"payload\") (cons 70 5))))
  (dictadd nod \"MYDICT_ENTRY\" xr)
  (setq found (dictsearch nod \"MYDICT_ENTRY\"))
  (if (and (= (type nod) 'ENAME)
           found
           (= (strcase (cdr (assoc 0 found))) \"XRECORD\")
           (= (cdr (assoc 1 found)) \"payload\")
           (= (cdr (assoc 70 found)) 5))
      1 0)"))))

(test dd-dictionary-duplicate-and-absent-return-nil
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"K\" xr)
  (if (and (null (dictadd nod \"K\" xr))       ; duplicate key
           (null (dictsearch nod \"ABSENT\")))  ; absent key
      1 0)"))))

(test dd-xrecord-mutate-via-entmod-through-dict
  ;; entmod that UPDATES an xrecord is the lenient (BricsCAD) behaviour;
  ;; under the strict default it is a no-op (AutoCAD parity, divergence
  ;; D3), so exercise it under --dialect bricscad-v26. The D3-specific
  ;; per-dialect behaviour is asserted in dd-d3-* below.
  (is (eql 1
           (nth-value 0 (%d1-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v1\"))))
  (dictadd nod \"K\" xr)
  (entmod (list (cons -1 xr) (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"v2\")))
  (if (= (cdr (assoc 1 (dictsearch nod \"K\"))) \"v2\") 1 0)"
                                  :bricscad-v26)))))

(test dd-dictremove-detaches-entry
  (is (eql 1
           (%dd-run "
  (setq nod (namedobjdict))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"K\" xr)
  (dictremove nod \"K\")
  (if (null (dictsearch nod \"K\")) 1 0)"))))

(test dd-dictnext-enumerates-entries
  (is (eql 3
           (%dd-run "
  (setq nod (namedobjdict))
  (dictadd nod \"A\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"a\"))))
  (dictadd nod \"B\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"b\"))))
  (dictadd nod \"C\" (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\") (cons 1 \"c\"))))
  (setq n 0)
  (setq d (dictnext nod T))
  (while d (setq n (1+ n)) (setq d (dictnext nod)))
  n"))))

;;; --- Symbol tables ----------------------------------------------

(test dd-tblsearch-standard-tables
  (is (eql 1
           (%dd-run "
  (if (and (tblsearch \"LAYER\" \"0\")
           (tblsearch \"LTYPE\" \"Continuous\")
           (tblsearch \"STYLE\" \"Standard\")
           (tblsearch \"APPID\" \"ACAD\")
           (null (tblsearch \"LAYER\" \"NOSUCH\")))
      1 0)"))))

(test dd-tblnext-walks-layers
  ;; add two layers via a block-agnostic table op is not exposed to
  ;; AutoLISP; instead walk the default LAYER table which has "0".
  (is (eql 1
           (%dd-run "
  (setq r (tblnext \"LAYER\" T))
  (if (and r (= (cdr (assoc 2 r)) \"0\")) 1 0)"))))

;;; --- ssget filter grammar (whole-database scan) -----------------

(defun %seed-ss ()
  "AutoLISP source that seeds three LINEs (colours 1/2/3, layers
WALL/WALL/DOOR) and one CIRCLE bearing MYAPP xdata."
  "
  (entmake (list (cons 0 \"LINE\") (cons 8 \"WALL\") (cons 62 1)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (entmake (list (cons 0 \"LINE\") (cons 8 \"WALL\") (cons 62 2)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))))
  (entmake (list (cons 0 \"LINE\") (cons 8 \"DOOR\") (cons 62 3)
                 (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 3.0 0.0 0.0))))
  (regapp \"MYAPP\")
  (setq c (entmakex (list (cons 0 \"CIRCLE\") (cons 8 \"DOOR\")
                          (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget c) (list (list -3 (list \"MYAPP\" (cons 1000 \"t\"))))))")

(defun %ss-count (filter-source)
  "Run the seed then (ssget \"X\" FILTER) and return the member count."
  (%dd-run (format nil "~A~%(setq ss (ssget \"X\" ~A))~%(if ss (sslength ss) 0)"
                   (%seed-ss) filter-source)))

(test dd-ssget-type-filter
  (is (eql 3 (%ss-count "(list (cons 0 \"LINE\"))")))
  (is (eql 4 (%ss-count "nil"))))

(test dd-ssget-comma-layer-and-wildcard
  (is (eql 2 (%ss-count "(list (cons 0 \"LINE\") (cons 8 \"WALL,SLAB\"))")))
  (is (eql 4 (%ss-count "(list (cons 8 \"*\"))"))))

(test dd-ssget-or-filter
  (is (eql 2 (%ss-count
              "(list (cons 0 \"LINE\") (cons -4 \"<OR\") (cons 62 1) (cons 62 3) (cons -4 \"OR>\"))"))))

(test dd-ssget-and-not-filters
  (is (eql 1 (%ss-count
              "(list (cons 0 \"LINE\") (cons -4 \"<NOT\") (cons 8 \"WALL\") (cons -4 \"NOT>\"))")))
  (is (eql 2 (%ss-count
              "(list (cons -4 \"<AND\") (cons 0 \"LINE\") (cons 8 \"WALL\") (cons -4 \"AND>\"))"))))

(test dd-ssget-relational-filter
  (is (eql 2 (%ss-count "(list (cons 0 \"LINE\") (cons -4 \">\") (cons 62 1))")))
  (is (eql 1 (%ss-count "(list (cons 0 \"LINE\") (cons -4 \"<\") (cons 62 2))"))))

(test dd-ssget-xdata-filter
  (is (eql 1 (%ss-count "(list (cons 0 \"CIRCLE\") (list -3 (list \"MYAPP\")))")))
  (is (eql 0 (%ss-count "(list (list -3 (list \"OTHERAPP\")))"))))

(test dd-ssget-never-returns-dictionaries
  ;; create a dictionary object; ssget "X" with no filter still sees
  ;; only the graphical entities.
  (is (eql 4 (%dd-run (format nil "~A~%(namedobjdict)~%(setq ss (ssget \"X\"))~%(if ss (sslength ss) 0)"
                              (%seed-ss))))))

;;; --- ssname / ssadd / ssdel / ssmemb ----------------------------

(test dd-selection-set-membership-ops
  (is (eql 1
           (%dd-run (format nil "~A
  (setq ss (ssget \"X\" (list (cons 0 \"LINE\"))))
  (setq e0 (ssname ss 0))
  (setq empty (ssadd))
  (setq one (ssadd e0))
  (if (and (= (sslength ss) 3)
           (= (sslength empty) 0)
           (= (sslength one) 1)
           (ssmemb e0 one)
           (progn (ssdel e0 one) (= (sslength one) 0)))
      1 0)" (%seed-ss))))))

;;; --- out-of-scope interactive modes fail cleanly ----------------

(test dd-ssget-interactive-modes-do-not-crash
  ;; Out-of-scope interactive/graphical selection modes fail *cleanly*:
  ;; they signal a catchable AutoLISP error (caught by vl-catch-all-apply
  ;; / *error*) rather than crashing the engine. Headless code guards
  ;; them; nothing here escapes to the process.
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget nil))
                          1 0)")))          ; (ssget) interactive pick
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget (list \"_W\")))
                          1 0)")))          ; window mode
  (is (eql 1 (%dd-run "(if (vl-catch-all-error-p
                            (vl-catch-all-apply 'ssget (list \"_CP\")))
                          1 0)"))))         ; crossing-polygon mode
