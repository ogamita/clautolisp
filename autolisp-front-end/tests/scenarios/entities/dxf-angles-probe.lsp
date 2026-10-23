;;;; dxf-angles-probe.lsp -- MEASURE the unit of the angle groups in a DXF
;;;; file written by the CAD, against what entget reports for the same
;;;; entity (issues/open/dxf-file-angle-units.issue,
;;;; issues/open/dxf-angle-units-hatch-viewport-tables.issue).
;;;;
;;;; The claim under test (clautolisp/drawing/source/dxf.lisp,
;;;; *dxf-degree-groups* / *dxf-repeated-degree-groups*): the FILE stores
;;;; these groups in DEGREES while entget / tblsearch report RADIANS --
;;;; ARC 50/51; TEXT / ATTRIB / ATTDEF 50/51; MTEXT 50; INSERT 50;
;;;; DIMENSION 50-53; VERTEX 50; HATCH 52, every 53 and the 50/51 of the
;;;; circular-arc (72 = 2) and elliptic-arc (72 = 3) boundary edges; table
;;;; records VPORT 50/51, VIEW 50, STYLE 50.
;;;;
;;;; Steps:
;;;;   1. build entities with KNOWN angles (entmakex where reliable, COMMAND
;;;;      for DIMENSION and HATCH, with an entmakex fallback for HATCH), all
;;;;      on layer DXFANG; set SNAPANG (lands in the VPORT *Active record);
;;;;   2. print entget's angle groups (radians);
;;;;   3. export the drawing as an ASCII DXF: vla-SaveAs (COM, guarded),
;;;;      else (command "_.SAVEAS" "_DXF" "16" path) on AutoCAD /
;;;;      AcCoreConsole, (command "_.DXFOUT" path "16") on BricsCAD, then the
;;;;      other one -- FILEDIA 0 meanwhile;
;;;;   4. read the produced .dxf as text, find each entity / record by its
;;;;      handle (the 5 / 105 group following the 0 group) and print the same
;;;;      groups as written in the file.
;;;;
;;;; Output, one line per observation, space-separated:
;;;;   DXFANG INFO <name> <value>
;;;;   DXFANG CASE <case> <entmake|command|...|FAILED> [<message>]
;;;;   DXFANG HANDLE <case> <type> <handle>
;;;;   DXFANG ENTGET <case> <code> <value>   ; every occurrence, entget order
;;;;   DXFANG ENTGET <case> <code> ABSENT
;;;;   DXFANG SYSVAR <name> <value>
;;;;   DXFANG EXPORT <method> <ok|missing|error> [<message>]
;;;;   DXFANG EXPORT-PATH <path>              ; the rest of the line
;;;;   DXFANG FILE-HANDLE <case> <type> <handle>
;;;;   DXFANG FILE <case> <code> <value>     ; every occurrence, file order,
;;;;                                         ; up to a 1001 (XDATA) group
;;;;   DXFANG FILE <case> NOTFOUND
;;;;   DXFANG-DONE
;;;; Reals are printed with (rtos x 2 15), points as x,y,z; file values as
;;;; the text the file holds. A report without DXFANG-DONE died mid-way.
;;;;
;;;; CAD-probe pitfalls honoured here:
;;;;   - COMMAND is never called through (vl-catch-all-apply 'command ...)
;;;;     nor inside any vl-catch-all-apply: AutoCAD aborts the whole run on
;;;;     it (probes/sources/probe-triage2.lsp, console-flood-probe.lsp). The
;;;;     command steps are plain top-level calls, each followed by a capped
;;;;     drain of CMDACTIVE; everything else is guarded, so a refused case
;;;;     is a DXFANG CASE ... FAILED line, never the end of the run.
;;;;   - OSMODE 0 while points are passed to commands; FILEDIA 0 around the
;;;;     export; both restored at the end.
;;;; The output DXF path is $DXFANG_DXF when the CAD sees that variable,
;;;; else TEMPPREFIX + dxf-angles-probe.dxf; the run scripts
;;;; (scripts/run-dxf-angles-probe.{sh,ps1}) copy it from the EXPORT-PATH
;;;; line. Keep this file ASCII.

(defun dxfang-say (text) (princ (strcat "DXFANG " text "\n")))

(defun dxfang-getvar (name / v)
  (setq v (vl-catch-all-apply 'getvar (list name)))
  (if (vl-catch-all-error-p v) nil v))

(defun dxfang-setvar (name value / r)
  (setq r (vl-catch-all-apply 'setvar (list name value)))
  (if (vl-catch-all-error-p r)
    (dxfang-say (strcat "SYSVAR-SET " name " ERROR "
                        (vl-catch-all-error-message r))))
  r)

(defun dxfang-join (strings / out)
  (setq out "")
  (foreach s strings
    (setq out (if (= out "") s (strcat out "," s))))
  out)

(defun dxfang-fmt (v)
  (cond
    ((null v) "nil")
    ((= (type v) 'REAL) (rtos v 2 15))
    ((= (type v) 'INT) (itoa v))
    ((= (type v) 'STR) v)
    ((and (= (type v) 'LIST) (vl-consp v)) (dxfang-join (mapcar 'dxfang-fmt v)))
    (t (vl-prin1-to-string v))))

(defun dxfang-deg (d) (* pi (/ d 180.0)))

;; --- the registry: (HANDLE CASE CODES) -------------------------------------
(setq *dxfang-registry* nil)

(defun dxfang-print-entget (case data codes / seen)
  (foreach pair data
    (if (and (vl-consp pair) (member (car pair) codes))
      (progn
        (setq seen (cons (car pair) seen))
        (dxfang-say (strcat "ENTGET " case " " (itoa (car pair)) " "
                            (dxfang-fmt (cdr pair)))))))
  (foreach code codes
    (if (not (member code seen))
      (dxfang-say (strcat "ENTGET " case " " (itoa code) " ABSENT")))))

;; Record ENAME under CASE: its handle, and entget's CODES.
(defun dxfang-register (case ename codes / data handle)
  (setq data (entget ename))
  (setq handle (cdr (assoc 5 data)))
  (if (null handle) (setq handle (cdr (assoc 105 data))))
  (dxfang-say (strcat "HANDLE " case " " (dxfang-fmt (cdr (assoc 0 data)))
                      " " (dxfang-fmt handle)))
  (if handle
    (setq *dxfang-registry*
          (cons (list (strcase handle) case codes) *dxfang-registry*)))
  (dxfang-print-entget case data codes)
  ename)

;; Run the guarded step FN (a symbol naming a function of no argument that
;; returns an ename or nil) for CASE, then register its result.
(defun dxfang-guarded (case fn how codes / e r)
  (setq e (vl-catch-all-apply fn nil))
  (cond
    ((vl-catch-all-error-p e)
     (dxfang-say (strcat "CASE " case " FAILED " (vl-catch-all-error-message e)))
     nil)
    ((null e)
     (dxfang-say (strcat "CASE " case " FAILED nil"))
     nil)
    (t
     (dxfang-say (strcat "CASE " case " " how))
     (setq r (vl-catch-all-apply 'dxfang-register (list case e codes)))
     (if (vl-catch-all-error-p r)
       (dxfang-say (strcat "CASE " case " REPORT-ERROR "
                           (vl-catch-all-error-message r))))
     e)))

;; End whatever command a COMMAND call left active (bad input, a prompt we
;; did not foresee): a few ENTERs, then a cancel. Never guarded.
(defun dxfang-drain ( / n)
  (setq n 0)
  (while (and (< n 6) (numberp (dxfang-getvar "CMDACTIVE"))
              (> (logand (dxfang-getvar "CMDACTIVE") 1) 0))
    (command "")
    (setq n (1+ n)))
  (if (and (numberp (dxfang-getvar "CMDACTIVE"))
           (> (logand (dxfang-getvar "CMDACTIVE") 1) 0))
    (command))
  n)

;; The entity a command step produced: (entlast) when it changed and is of
;; TYPE.
(defun dxfang-new-entity (before etype / e)   ; ETYPE: see dxfang-scan-file
  (setq e (entlast))
  (if (and e (not (equal e before))
           (= (strcase (cdr (assoc 0 (entget e)))) etype))
    e))

;; --- context ------------------------------------------------------------------
(foreach name '("PRODUCT" "PROGRAM" "ACADVER" "LUNITS" "AUNITS" "ANGBASE"
                "ANGDIR" "DWGNAME" "TEMPPREFIX")
  (dxfang-say (strcat "INFO " name " " (dxfang-fmt (dxfang-getvar name)))))

(setq *dxfang-old-cmdecho* (dxfang-getvar "CMDECHO"))
(setq *dxfang-old-osmode* (dxfang-getvar "OSMODE"))
(setq *dxfang-old-filedia* (dxfang-getvar "FILEDIA"))
(setq *dxfang-old-clayer* (dxfang-getvar "CLAYER"))
(setq *dxfang-old-snapang* (dxfang-getvar "SNAPANG"))
(dxfang-setvar "CMDECHO" 0)
(dxfang-setvar "OSMODE" 0)

;; Layer DXFANG: every probe entity lands on it (the clautolisp-side fixture
;; test, clautolisp/drawing/tests/dxf-tests.lisp, keys on it too).
(defun dxfang-make-layer ()
  (if (not (tblsearch "LAYER" "DXFANG"))
    (entmake '((0 . "LAYER") (100 . "AcDbSymbolTableRecord")
               (100 . "AcDbLayerTableRecord") (2 . "DXFANG") (70 . 0)
               (62 . 3) (6 . "Continuous"))))
  (tblsearch "LAYER" "DXFANG"))
(if (vl-catch-all-error-p (setq *dxfang-r* (vl-catch-all-apply 'dxfang-make-layer nil)))
  (dxfang-say (strcat "CASE layer FAILED " (vl-catch-all-error-message *dxfang-r*)))
  (dxfang-say (strcat "CASE layer " (if *dxfang-r* "entmake" "FAILED nil"))))
(if *dxfang-r* (dxfang-setvar "CLAYER" "DXFANG"))

;; --- ARC 30 .. 120 degrees -------------------------------------------------
(defun dxfang-make-arc ()
  (entmakex (list '(0 . "ARC") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbCircle") '(10 0.0 0.0 0.0) '(40 . 10.0)
                  '(100 . "AcDbArc")
                  (cons 50 (dxfang-deg 30.0)) (cons 51 (dxfang-deg 120.0)))))
(dxfang-guarded "arc" 'dxfang-make-arc "entmake" '(50 51))

;; --- TEXT rotation 45, oblique 15 ----------------------------------------------
(defun dxfang-make-text ()
  (entmakex (list '(0 . "TEXT") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbText") '(10 20.0 0.0 0.0) '(40 . 2.5)
                  '(1 . "DXFANG")
                  (cons 50 (dxfang-deg 45.0)) (cons 51 (dxfang-deg 15.0))
                  '(100 . "AcDbText"))))
(dxfang-guarded "text" 'dxfang-make-text "entmake" '(50 51))

;; --- ATTDEF (in model space) rotation 30, oblique 10 ---------------------------
(defun dxfang-make-attdef ()
  (entmakex (list '(0 . "ATTDEF") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbText") '(10 20.0 20.0 0.0) '(40 . 2.5)
                  '(1 . "DEF")
                  (cons 50 (dxfang-deg 30.0)) (cons 51 (dxfang-deg 10.0))
                  '(100 . "AcDbAttributeDefinition") '(3 . "PROMPT")
                  '(2 . "DXFANGTAG") '(70 . 0))))
(dxfang-guarded "attdef" 'dxfang-make-attdef "entmake" '(50 51))

;; --- MTEXT rotation 60: once by 50, once by the 11 direction vector ----------
(defun dxfang-make-mtext-50 ()
  (entmakex (list '(0 . "MTEXT") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbMText") '(10 40.0 0.0 0.0) '(40 . 2.5)
                  '(41 . 30.0) '(71 . 1) '(1 . "DXFANG")
                  (cons 50 (dxfang-deg 60.0)))))
(dxfang-guarded "mtext-50" 'dxfang-make-mtext-50 "entmake-50" '(50 11 21))

(defun dxfang-make-mtext-11 ()
  (entmakex (list '(0 . "MTEXT") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbMText") '(10 40.0 20.0 0.0) '(40 . 2.5)
                  '(41 . 30.0) '(71 . 1) '(1 . "DXFANG")
                  (list 11 (cos (dxfang-deg 60.0)) (sin (dxfang-deg 60.0)) 0.0))))
(dxfang-guarded "mtext-11" 'dxfang-make-mtext-11 "entmake-11" '(50 11 21))

;; --- a small block, an INSERT rotation 30, an attributed INSERT ------------
(defun dxfang-make-block ()
  (if (not (tblsearch "BLOCK" "DXFANGBLK"))
    (progn
      (entmake '((0 . "BLOCK") (2 . "DXFANGBLK") (70 . 0) (10 0.0 0.0 0.0)))
      (entmake '((0 . "LINE") (8 . "0") (10 0.0 0.0 0.0) (11 5.0 0.0 0.0)))
      (entmake '((0 . "ENDBLK")))))
  (tblsearch "BLOCK" "DXFANGBLK"))
(if (vl-catch-all-error-p (setq *dxfang-r* (vl-catch-all-apply 'dxfang-make-block nil)))
  (dxfang-say (strcat "CASE block FAILED " (vl-catch-all-error-message *dxfang-r*)))
  (dxfang-say (strcat "CASE block " (if *dxfang-r* "entmake" "FAILED nil"))))

(defun dxfang-make-insert ()
  (entmakex (list '(0 . "INSERT") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbBlockReference") '(2 . "DXFANGBLK")
                  '(10 60.0 0.0 0.0) (cons 50 (dxfang-deg 30.0)))))
(dxfang-guarded "insert" 'dxfang-make-insert "entmake" '(50))

;; An INSERT rotated 45 carrying one ATTRIB (rotation 45, oblique 15): a
;; complex entmake (INSERT 66=1, ATTRIB, SEQEND); the ATTRIB is entnext of
;; the INSERT.
(defun dxfang-make-insert-attr ()
  (entmake (list '(0 . "INSERT") '(8 . "DXFANG") '(66 . 1) '(2 . "DXFANGBLK")
                 '(10 60.0 20.0 0.0) (cons 50 (dxfang-deg 45.0))))
  (entmake (list '(0 . "ATTRIB") '(100 . "AcDbEntity") '(8 . "DXFANG")
                 '(100 . "AcDbText") '(10 60.0 20.0 0.0) '(40 . 2.5)
                 '(1 . "VAL") (cons 50 (dxfang-deg 45.0))
                 (cons 51 (dxfang-deg 15.0))
                 '(100 . "AcDbAttribute") '(2 . "DXFANGTAG") '(70 . 0)))
  (entmake '((0 . "SEQEND") (8 . "DXFANG")))
  (dxfang-new-entity nil "INSERT"))
(setq *dxfang-insert-attr*
      (dxfang-guarded "insert-attr" 'dxfang-make-insert-attr "entmake" '(50)))
(defun dxfang-attrib-of-insert ( / e)
  (setq e (entnext *dxfang-insert-attr*))
  (if (and e (= (cdr (assoc 0 (entget e))) "ATTRIB")) e))
(if *dxfang-insert-attr*
  (dxfang-guarded "attrib" 'dxfang-attrib-of-insert "entmake" '(50 51)))

;; --- a 2D POLYLINE whose VERTEX has a curve-fit tangent of 30 degrees ------
(defun dxfang-make-polyline ()
  (entmake '((0 . "POLYLINE") (100 . "AcDbEntity") (8 . "DXFANG")
             (100 . "AcDb2dPolyline") (66 . 1) (10 0.0 0.0 0.0) (70 . 0)))
  (entmake (list '(0 . "VERTEX") '(100 . "AcDbEntity") '(8 . "DXFANG")
                 '(100 . "AcDbVertex") '(100 . "AcDb2dVertex")
                 '(10 80.0 0.0 0.0) '(70 . 2) (cons 50 (dxfang-deg 30.0))))
  (entmake (list '(0 . "VERTEX") '(100 . "AcDbEntity") '(8 . "DXFANG")
                 '(100 . "AcDbVertex") '(100 . "AcDb2dVertex")
                 '(10 90.0 5.0 0.0) '(70 . 2) (cons 50 (dxfang-deg 30.0))))
  (entmake '((0 . "SEQEND") (8 . "DXFANG")))
  (dxfang-new-entity nil "POLYLINE"))
(setq *dxfang-polyline* (vl-catch-all-apply 'dxfang-make-polyline nil))
(if (vl-catch-all-error-p *dxfang-polyline*)
  (progn
    (dxfang-say (strcat "CASE polyline FAILED "
                        (vl-catch-all-error-message *dxfang-polyline*)))
    (setq *dxfang-polyline* nil)))
(defun dxfang-first-vertex ( / e)
  (setq e (entnext *dxfang-polyline*))
  (if (and e (= (cdr (assoc 0 (entget e))) "VERTEX")) e))
(if *dxfang-polyline*
  (dxfang-guarded "vertex" 'dxfang-first-vertex "entmake" '(50 70))
  (dxfang-say "CASE vertex FAILED no POLYLINE"))

;; --- table records: STYLE oblique 10, VIEW twist 45 ------------------------
(defun dxfang-table-ename (table name / e)
  (setq e (tblobjname table name))
  e)

(defun dxfang-make-style ()
  (if (not (tblsearch "STYLE" "DXFANG"))
    (entmake (list '(0 . "STYLE") '(100 . "AcDbSymbolTableRecord")
                   '(100 . "AcDbTextStyleTableRecord") '(2 . "DXFANG")
                   '(70 . 0) '(40 . 0.0) '(41 . 1.0)
                   (cons 50 (dxfang-deg 10.0)) '(71 . 0) '(42 . 2.5)
                   '(3 . "txt") '(4 . ""))))
  (dxfang-table-ename "STYLE" "DXFANG"))
(dxfang-guarded "style" 'dxfang-make-style "entmake" '(50))
(if (vl-catch-all-error-p (setq *dxfang-r* (vl-catch-all-apply 'tblsearch (list "STYLE" "DXFANG"))))
  (dxfang-say (strcat "TBLSEARCH style ERROR " (vl-catch-all-error-message *dxfang-r*)))
  (dxfang-say (strcat "TBLSEARCH style 50 " (dxfang-fmt (cdr (assoc 50 *dxfang-r*))))))

(defun dxfang-make-view ()
  (if (not (tblsearch "VIEW" "DXFANG"))
    (entmake (list '(0 . "VIEW") '(100 . "AcDbSymbolTableRecord")
                   '(100 . "AcDbViewTableRecord") '(2 . "DXFANG") '(70 . 0)
                   '(40 . 50.0) '(10 0.0 0.0) '(41 . 80.0) '(11 0.0 0.0 1.0)
                   '(12 0.0 0.0 0.0) '(42 . 50.0) '(43 . 0.0) '(44 . 0.0)
                   (cons 50 (dxfang-deg 45.0)) '(71 . 0))))
  (dxfang-table-ename "VIEW" "DXFANG"))
(dxfang-guarded "view" 'dxfang-make-view "entmake" '(50))

;; --- SNAPANG 20 degrees: the VPORT *Active record's 50 ---------------------
(dxfang-setvar "SNAPANG" (dxfang-deg 20.0))
(dxfang-say (strcat "SYSVAR SNAPANG " (dxfang-fmt (dxfang-getvar "SNAPANG"))))
(defun dxfang-active-vport () (dxfang-table-ename "VPORT" "*ACTIVE"))
(dxfang-guarded "vport" 'dxfang-active-vport "setvar-SNAPANG" '(50 51))

;; --- DIMENSION by command: DIMLINEAR, text angle 20, rotated 30; then
;; DIMEDIT Oblique 15. COMMAND unguarded on purpose (see the header).
(setq *dxfang-before* (entlast))
(command "_.DIMLINEAR" '(0.0 60.0 0.0) '(10.0 65.0 0.0)
         "_A" 20 "_R" 30 '(5.0 75.0 0.0))
(setq *dxfang-drained* (dxfang-drain))
(dxfang-say (strcat "INFO dimlinear-drain " (itoa *dxfang-drained*)))
(setq *dxfang-dim* (dxfang-new-entity *dxfang-before* "DIMENSION"))
(if *dxfang-dim*
  (progn
    (command "_.DIMEDIT" "_O" *dxfang-dim* "" 15)
    (setq *dxfang-drained* (dxfang-drain))
    (dxfang-say (strcat "INFO dimedit-drain " (itoa *dxfang-drained*)))))
(defun dxfang-dim () *dxfang-dim*)
(dxfang-guarded "dimension" 'dxfang-dim "command-DIMLINEAR+DIMEDIT" '(50 51 52 53))

;; --- HATCH ANSI31 angle 30 by command (-HATCH Properties / Select objects),
;; else by entmakex. Three boundaries: a CIRCLE (an arc edge 0..360), an
;; ELLIPSE (an elliptic-arc edge), an ARC 30..150 closed by a LINE.
(defun dxfang-make-circle ()
  (entmakex '((0 . "CIRCLE") (100 . "AcDbEntity") (8 . "DXFANG")
              (100 . "AcDbCircle") (10 0.0 -40.0 0.0) (40 . 10.0))))
(defun dxfang-make-ellipse ()
  (entmakex (list '(0 . "ELLIPSE") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbEllipse") '(10 40.0 -40.0 0.0)
                  (list 11 (* 10.0 (cos (dxfang-deg 30.0)))
                        (* 10.0 (sin (dxfang-deg 30.0))) 0.0)
                  '(210 0.0 0.0 1.0) '(40 . 0.5) '(41 . 0.0) (cons 42 (* 2 pi)))))
(setq *dxfang-arc-c* '(80.0 -40.0 0.0))
(defun dxfang-make-bound-arc ()
  (entmakex (list '(0 . "ARC") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbCircle") (cons 10 *dxfang-arc-c*) '(40 . 10.0)
                  '(100 . "AcDbArc")
                  (cons 50 (dxfang-deg 30.0)) (cons 51 (dxfang-deg 150.0)))))
(defun dxfang-make-bound-line ()
  (entmakex (list '(0 . "LINE") '(100 . "AcDbEntity") '(8 . "DXFANG")
                  '(100 . "AcDbLine")
                  (cons 10 (polar *dxfang-arc-c* (dxfang-deg 150.0) 10.0))
                  (cons 11 (polar *dxfang-arc-c* (dxfang-deg 30.0) 10.0)))))

(defun dxfang-try (fn / r)
  (setq r (vl-catch-all-apply fn nil))
  (if (vl-catch-all-error-p r) nil r))

(setq *dxfang-circle* (dxfang-try 'dxfang-make-circle))
(setq *dxfang-ellipse* (dxfang-try 'dxfang-make-ellipse))
(setq *dxfang-bound-arc* (dxfang-try 'dxfang-make-bound-arc))
(setq *dxfang-bound-line* (dxfang-try 'dxfang-make-bound-line))
(dxfang-say (strcat "INFO hatch-boundaries "
                    (if *dxfang-circle* "circle " "no-circle ")
                    (if *dxfang-ellipse* "ellipse " "no-ellipse ")
                    (if (and *dxfang-bound-arc* *dxfang-bound-line*)
                      "arc+line" "no-arc+line")))

;; One -HATCH run over BOUNDARY (a list of one or two enames). Unguarded.
;; One COMMAND call per run (no (apply 'command ...): AutoCAD refuses it),
;; so an engine that ends a command with its COMMAND call still sees it all.
(defun dxfang-hatch-command (boundary / before)
  (setq before (entlast))
  (if (cdr boundary)
    (command "_.-HATCH" "_P" "ANSI31" 1.0 30 "_S"
             (car boundary) (cadr boundary) "" "")
    (command "_.-HATCH" "_P" "ANSI31" 1.0 30 "_S" (car boundary) "" ""))
  (dxfang-drain)
  (dxfang-new-entity before "HATCH"))

;; The entmakex fallback: ANSI31 (one 45-degree line family, spacing 3.175)
;; at pattern angle 30, the EDGES (already DXF-shaped) as one external path.
(defun dxfang-hatch-entmake (edges / a)
  (setq a (dxfang-deg 75.0))
  (entmakex
    (append
      (list '(0 . "HATCH") '(100 . "AcDbEntity") '(8 . "DXFANG")
            '(100 . "AcDbHatch") '(10 0.0 0.0 0.0) '(210 0.0 0.0 1.0)
            '(2 . "ANSI31") '(70 . 0) '(71 . 0) '(91 . 1) '(92 . 1)
            (cons 93 (length edges)))
      (apply 'append edges)
      (list '(97 . 0) '(75 . 1) '(76 . 1) (cons 52 (dxfang-deg 30.0))
            '(41 . 1.0) '(77 . 0) '(78 . 1) (cons 53 a)
            '(43 . 0.0) '(44 . 0.0)
            (cons 45 (* -3.175 (sin a))) (cons 46 (* 3.175 (cos a)))
            '(79 . 0) '(98 . 0)))))

(setq *dxfang-hatch-codes* '(52 53 72 50 51))

(defun dxfang-hatch-case (case boundary edges / h)
  (if boundary
    (setq h (dxfang-hatch-command boundary)))
  (if h
    (progn
      (setq *dxfang-h* h)
      (dxfang-guarded case 'dxfang-current-h "command--HATCH" *dxfang-hatch-codes*))
    (progn
      (dxfang-say (strcat "CASE " case " command--HATCH gave no HATCH"))
      (setq *dxfang-edges* edges)
      (dxfang-guarded case 'dxfang-current-edges-hatch "entmake"
                      *dxfang-hatch-codes*))))
(defun dxfang-current-h () *dxfang-h*)
(defun dxfang-current-edges-hatch () (dxfang-hatch-entmake *dxfang-edges*))

(dxfang-hatch-case "hatch-circle"
  (if *dxfang-circle* (list *dxfang-circle*))
  (list (list '(72 . 2) '(10 0.0 -40.0) '(40 . 10.0) '(50 . 0.0)
              (cons 51 (* 2 pi)) '(73 . 1))))
(dxfang-hatch-case "hatch-ellipse"
  (if *dxfang-ellipse* (list *dxfang-ellipse*))
  (list (list '(72 . 3) '(10 40.0 -40.0)
              (list 11 (* 10.0 (cos (dxfang-deg 30.0)))
                    (* 10.0 (sin (dxfang-deg 30.0))))
              '(40 . 0.5) '(50 . 0.0) (cons 51 (* 2 pi)) '(73 . 1))))
(dxfang-hatch-case "hatch-arcline"
  (if (and *dxfang-bound-arc* *dxfang-bound-line*)
    (list *dxfang-bound-arc* *dxfang-bound-line*))
  (list (list '(72 . 2) (list 10 (car *dxfang-arc-c*) (cadr *dxfang-arc-c*))
              '(40 . 10.0) (cons 50 (dxfang-deg 30.0))
              (cons 51 (dxfang-deg 150.0)) '(73 . 1))
        (list '(72 . 1)
              (cons 10 (reverse (cdr (reverse (polar *dxfang-arc-c* (dxfang-deg 150.0) 10.0)))))
              (cons 11 (reverse (cdr (reverse (polar *dxfang-arc-c* (dxfang-deg 30.0) 10.0))))))))

;; --- export ---------------------------------------------------------------
(setq *dxfang-path*
      (cond
        ((and (= (type (setq *dxfang-r* (vl-catch-all-apply 'getenv (list "DXFANG_DXF")))) 'STR)
              (/= *dxfang-r* ""))
         *dxfang-r*)
        ((= (type (dxfang-getvar "TEMPPREFIX")) 'STR)
         (strcat (dxfang-getvar "TEMPPREFIX") "dxf-angles-probe.dxf"))
        (t "dxf-angles-probe.dxf")))
(if (findfile *dxfang-path*) (vl-catch-all-apply 'vl-file-delete (list *dxfang-path*)))
(dxfang-setvar "FILEDIA" 0)

(defun dxfang-exported-p ( / s)
  (and (findfile *dxfang-path*)
       (numberp (setq s (vl-catch-all-apply 'vl-file-size (list *dxfang-path*))))
       (> s 0)))

(defun dxfang-export-report (method / ok)
  (setq ok (dxfang-exported-p))
  (dxfang-say (strcat "EXPORT " method (if ok " ok" " missing")))
  ok)

;; 1. COM (AutoCAD GUI, BricsCAD, clautolisp; AcCoreConsole has none).
(defun dxfang-saveas-type ( / v)
  (setq v (vl-catch-all-apply 'eval (list 'ac2018_dxf)))
  (if (numberp v) v 65))   ; AcSaveAsType ac2018_dxf
(defun dxfang-export-com ()
  (vl-load-com)
  (vla-SaveAs (vla-get-ActiveDocument (vlax-get-acad-object))
              *dxfang-path* (dxfang-saveas-type)))
;; AcCoreConsole has no COM, and there (vlax-get-acad-object) ends the run
;; even inside vl-catch-all-apply (jobs 17409369692, 17411108963: every
;; case, then nothing). Its PROGRAM is "acad" like the GUI's, so the run
;; script says which backend it is (DXFANG_BACKEND).
(setq *dxfang-no-com*
      (= (vl-catch-all-apply 'getenv (list "DXFANG_BACKEND")) "accoreconsole"))
(if *dxfang-no-com*
  (dxfang-say "EXPORT vla-SaveAs skipped (accoreconsole: no COM)")
  (progn
    (setq *dxfang-r* (vl-catch-all-apply 'dxfang-export-com nil))
    (if (vl-catch-all-error-p *dxfang-r*)
      (dxfang-say (strcat "EXPORT vla-SaveAs error " (vl-catch-all-error-message *dxfang-r*)))
      (dxfang-export-report "vla-SaveAs"))))

;; 2. commands, unguarded; the product's own form first.
(setq *dxfang-bricscad*
      (wcmatch (strcase (dxfang-fmt (dxfang-getvar "PRODUCT"))) "*BRICSCAD*"))
(defun dxfang-export-saveas ()
  (command "_.SAVEAS" "_DXF" "16" *dxfang-path*)
  (dxfang-drain)
  (dxfang-export-report "command-SAVEAS-DXF"))
(defun dxfang-export-dxfout ()
  (command "_.DXFOUT" *dxfang-path* "16")
  (dxfang-drain)
  (dxfang-export-report "command-DXFOUT"))
(if (not (dxfang-exported-p))
  (if *dxfang-bricscad*
    (if (not (dxfang-export-dxfout)) (dxfang-export-saveas))
    (if (not (dxfang-export-saveas)) (dxfang-export-dxfout))))
;; The measured file is a COPY taken now: the document IS the exported file
;; after a SaveAs, and the probe saves it once more at the very end (below,
;; so that no quit ever finds it modified) -- with the sysvars restored by
;; then, which would lose SNAPANG's 20 degrees from the artefact.
(setq *dxfang-measured* (strcat (vl-filename-directory *dxfang-path*) "\\"
                                (vl-filename-base *dxfang-path*) "-measured.dxf"))
(if (not (wcmatch *dxfang-path* "*\\*"))
  (setq *dxfang-measured* (strcat (vl-filename-directory *dxfang-path*) "/"
                                  (vl-filename-base *dxfang-path*) "-measured.dxf")))
(if (findfile *dxfang-measured*) (vl-catch-all-apply 'vl-file-delete (list *dxfang-measured*)))
(if (and (dxfang-exported-p)
         (not (vl-catch-all-error-p
                (vl-catch-all-apply 'vl-file-copy (list *dxfang-path* *dxfang-measured*))))
         (findfile *dxfang-measured*))
  (dxfang-say (strcat "EXPORT-PATH " *dxfang-measured*))
  (dxfang-say (strcat "EXPORT-PATH " *dxfang-path*)))

;; --- read the file back -------------------------------------------------------
(defun dxfang-trim (s) (vl-string-trim " \t\r\n" s))

;; OTYPE, never TYPE: AutoLISP has ONE value cell per symbol, so a local
;; named TYPE shadows the TYPE function for everything called meanwhile
;; -- AutoCAD then failed with "bad function: "VPORT"" (job 17409369691).
(defun dxfang-scan-file (path encoding / f line1 line2 code val otype cur await stopped
                                           found)
  (setq f (if encoding (open path "r" encoding) (open path "r")))
  (if (null f)
    (dxfang-say "FILE-OPEN FAILED")
    (progn
      (while (setq line1 (read-line f))
        (setq line2 (read-line f))
        (if (null line2) (setq line2 ""))
        (setq code (atoi (dxfang-trim line1))
              val (dxfang-trim line2))
        (cond
          ((= code 0)
           (setq otype val cur nil await T stopped nil))
          ((and await (or (= code 5) (= code 105)))
           (setq await nil)
           (setq cur (assoc (strcase val) *dxfang-registry*))
           (if cur
             (progn
               (setq found (cons (cadr cur) found))
               (dxfang-say (strcat "FILE-HANDLE " (cadr cur) " " otype " " val)))))
          ((and cur (not stopped) (= code 1001))
           (setq stopped T))
          ((and cur (not stopped) (member code (caddr cur)))
           (dxfang-say (strcat "FILE " (cadr cur) " " (itoa code) " " val)))))
      (close f)
      (foreach entry (reverse *dxfang-registry*)
        (if (not (member (cadr entry) found))
          (dxfang-say (strcat "FILE " (cadr entry) " NOTFOUND")))))))

;; The default OPEN first. When it fails (clautolisp 2.3.42 writes its AC1027
;; DXF header strings in ISO-8859-1, which its UTF-8 READ-LINE refuses),
;; once more as ISO-8859-1 -- an engine without that OPEN argument just
;; records the error. FILE lines printed before a failure may repeat.
(defun dxfang-scan (encoding / r)
  (setq r (vl-catch-all-apply 'dxfang-scan-file (list *dxfang-path* encoding)))
  (if (vl-catch-all-error-p r)
    (progn
      (dxfang-say (strcat "FILE-SCAN ERROR " (if encoding encoding "default") " "
                          (vl-catch-all-error-message r)))
      nil)
    T))
(if (dxfang-exported-p)
  (if (not (dxfang-scan nil))
    (dxfang-scan "ISO-8859-1"))
  (dxfang-say "FILE-SCAN SKIPPED no exported file"))

;; --- restore ------------------------------------------------------------------
(if *dxfang-old-filedia* (dxfang-setvar "FILEDIA" *dxfang-old-filedia*))
(if *dxfang-old-osmode* (dxfang-setvar "OSMODE" *dxfang-old-osmode*))
(if *dxfang-old-snapang* (dxfang-setvar "SNAPANG" *dxfang-old-snapang*))
(if *dxfang-old-clayer* (dxfang-setvar "CLAYER" *dxfang-old-clayer*))
(if *dxfang-old-cmdecho* (dxfang-setvar "CMDECHO" *dxfang-old-cmdecho*))

;; --- leave the document UNMODIFIED -------------------------------------------
;; The export renamed the document (SaveAs) and the restores above changed
;; it again: a document left modified makes whatever quits the CAD ask
;; "Save changes?" -- AutoCAD sat on that prompt with dxf-angles-probe.dxf
;; (2026-10-23). Save it (COM, its own format, no dialog) when DBMOD says it
;; is modified, and report DBMOD before and after.
(dxfang-say (strcat "INFO DBMOD-before-final-save " (dxfang-fmt (dxfang-getvar "DBMOD"))))
;; (AcCoreConsole: no COM; its run script ends with QSAVE then QUIT.)
(if (and (not *dxfang-no-com*)
         (numberp (dxfang-getvar "DBMOD")) (/= 0 (dxfang-getvar "DBMOD")))
  (progn
    (setq *dxfang-r* (vl-catch-all-apply
                       (function (lambda ()
                         (vl-load-com)
                         (vla-Save (vla-get-ActiveDocument (vlax-get-acad-object)))))
                       nil))
    (if (vl-catch-all-error-p *dxfang-r*)
      (dxfang-say (strcat "INFO final-save error " (vl-catch-all-error-message *dxfang-r*))))))
(dxfang-say (strcat "INFO DBMOD-at-end " (dxfang-fmt (dxfang-getvar "DBMOD"))))

(princ "DXFANG-DONE\n")
(princ)
