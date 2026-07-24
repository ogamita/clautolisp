;;;; drawing-data-probe.lsp — portable drawing-data-structures probe
;;;;
;;;; A single, self-contained AutoLISP program that exercises the
;;;; drawing-resident data structures — registered applications and
;;;; XData, the named-object dictionary tree, XRECORD objects, and the
;;;; symbol tables — through the low-level functions that AutoCAD,
;;;; BricsCAD and clautolisp all provide, so it runs UNCHANGED on every
;;;; target.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --clautolisp --host mock -l drawing-data-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l drawing-data-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l drawing-data-probe.lsp
;;;;   inside a CAD:          (load "drawing-data-probe.lsp")
;;;;
;;;; Output: one line per assertion (ok / FAIL) plus a final summary.
;;;; The last line is exactly "ALL DRAWING-DATA PROBES PASSED" when every
;;;; assertion held, or "DRAWING-DATA PROBES FAILED: <n>" otherwise — the
;;;; alfe conformance scenarios key on those strings.

(setq *probe-pass* 0)
(setq *probe-fail* 0)

(defun chk (label ok)
  (if ok
      (progn (setq *probe-pass* (1+ *probe-pass*))
             (princ (strcat "  ok   " label "\n")))
      (progn (setq *probe-fail* (1+ *probe-fail*))
             (princ (strcat "  FAIL " label "\n"))))
  ok)

(defun a2 (code lst) (cdr (assoc code lst)))

;;; --- REGAPP -----------------------------------------------------

(defun run-regapp-probe (/ app)
  (princ "regapp:\n")
  (setq app "CLAUTOLISP_DDP")
  ;; A fresh application registers and returns its name.
  (chk "regapp of a fresh app returns the name"
       (= (regapp app) app)))

;;; --- XData: the full SCHMS group-code set -----------------------

(defun run-xdata-probe (/ app e d dx xd)
  (princ "xdata:\n")
  (setq app "CLAUTOLISP_XD")
  (regapp app)
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  ;; Attach xdata using every group code the SCHMS codec round-trips,
  ;; wrapped in a 1002 { } control-string pair.
  (entmod (append (entget e)
                  (list (list -3 (list app
                                       (cons 1000 "tag-string")
                                       (cons 1002 "{")
                                       (cons 1003 "0")
                                       (cons 1005 "2A")
                                       (cons 1040 1.5)
                                       (cons 1070 42)
                                       (cons 1071 100000)
                                       (cons 1002 "}"))))))
  ;; entget WITHOUT an application list suppresses xdata.
  (setq d (entget e))
  (chk "entget without applist hides xdata" (null (assoc -3 d)))
  ;; entget WITH the application list surfaces it.
  (setq dx (entget e (list app)))
  (chk "entget with applist surfaces the (-3 ...) group" (not (null (assoc -3 dx))))
  ;; The recovered xdata preserves count, order and value fidelity.
  (setq xd (cdr (car (cdr (assoc -3 dx)))))   ; the app's xdata pairs
  (chk "xdata pair count preserved (8 codes)" (= (length xd) 8))
  (chk "xdata 1000 string round-trips" (= (a2 1000 xd) "tag-string"))
  (chk "xdata 1040 real round-trips" (equal (a2 1040 xd) 1.5))
  (chk "xdata 1070 int16 round-trips" (= (a2 1070 xd) 42))
  (chk "xdata 1071 int32 round-trips" (= (a2 1071 xd) 100000))
  (chk "xdata 1005 handle round-trips" (= (a2 1005 xd) "2A"))
  (entdel e))

(defun run-xdata-multi-app-probe (/ a1 a2app e)
  (princ "xdata multi-app:\n")
  (setq a1 "CLAUTOLISP_A1")
  (setq a2app "CLAUTOLISP_A2")
  (regapp a1) (regapp a2app)
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 7.0 7.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list a1 (cons 1000 "one"))
                                  (list a2app (cons 1000 "two"))))))
  ;; One application requested surfaces only that application's group.
  (chk "single-app filter surfaces one application"
       (= (length (cdr (assoc -3 (entget e (list a1))))) 1))
  ;; The wildcard surfaces both.
  (chk "wildcard applist surfaces both applications"
       (= (length (cdr (assoc -3 (entget e (list "*"))))) 2))
  (entdel e))

;;; --- Named-object dictionary + XRECORD --------------------------

(defun run-dictionary-probe (/ nod xr found)
  (princ "dictionary + xrecord:\n")
  (setq nod (namedobjdict))
  (chk "namedobjdict returns an ENAME" (= (type nod) 'ENAME))
  ;; Create an XRECORD and add it under a key.
  (setq xr (entmakex (list (cons 0 "XRECORD") (cons 100 "AcDbXrecord")
                           (cons 1 "payload") (cons 70 5))))
  (chk "entmakex XRECORD returns an ENAME" (= (type xr) 'ENAME))
  (chk "dictadd returns the object ENAME" (= (type (dictadd nod "CLAUTOLISP_REC" xr)) 'ENAME))
  ;; Read it back.
  (setq found (dictsearch nod "CLAUTOLISP_REC"))
  (chk "dictsearch returns the xrecord data" (not (null found)))
  (chk "dictsearch data has (0 . XRECORD)" (= (strcase (a2 0 found)) "XRECORD"))
  (chk "dictsearch data carries the payload (group 1)" (= (a2 1 found) "payload"))
  ;; Mutate it through entmod.
  (entmod (list (cons -1 xr) (cons 0 "XRECORD") (cons 100 "AcDbXrecord")
                (cons 1 "payload2") (cons 70 5)))
  (chk "entmod on the xrecord reads back the new value"
       (= (a2 1 (dictsearch nod "CLAUTOLISP_REC")) "payload2"))
  ;; A duplicate key fails soft (nil).
  (chk "duplicate dictadd key returns nil"
       (null (dictadd nod "CLAUTOLISP_REC" xr)))
  ;; Remove it.
  (dictremove nod "CLAUTOLISP_REC")
  (chk "dictsearch after dictremove returns nil"
       (null (dictsearch nod "CLAUTOLISP_REC"))))

;;; --- Symbol tables ----------------------------------------------

(defun run-table-probe (/ r)
  (princ "symbol tables:\n")
  (chk "tblsearch LAYER 0 found" (not (null (tblsearch "LAYER" "0"))))
  (chk "tblsearch LTYPE Continuous found" (not (null (tblsearch "LTYPE" "Continuous"))))
  (chk "tblsearch STYLE Standard found" (not (null (tblsearch "STYLE" "Standard"))))
  (chk "tblsearch APPID ACAD found" (not (null (tblsearch "APPID" "ACAD"))))
  (chk "tblsearch of an absent record returns nil"
       (null (tblsearch "LAYER" "NO_SUCH_LAYER_XYZ")))
  ;; tblnext walks the LAYER table; the "0" layer is always present.
  (setq r (tblnext "LAYER" T))
  (chk "tblnext LAYER (rewound) returns a record" (not (null r)))
  (chk "tblnext record group 2 is a string" (= (type (a2 2 r)) 'STR)))

;;; --- Driver -----------------------------------------------------

(defun run-drawing-data-probes (/ )
  (princ "=== drawing-data structure probes ===\n")
  (run-regapp-probe)
  (run-xdata-probe)
  (run-xdata-multi-app-probe)
  (run-dictionary-probe)
  (run-table-probe)
  (princ (strcat "\nsummary: " (itoa *probe-pass*) " passed, "
                 (itoa *probe-fail*) " failed\n"))
  (if (= *probe-fail* 0)
      (princ "ALL DRAWING-DATA PROBES PASSED\n")
      (princ (strcat "DRAWING-DATA PROBES FAILED: " (itoa *probe-fail*) "\n")))
  (princ))

(run-drawing-data-probes)
