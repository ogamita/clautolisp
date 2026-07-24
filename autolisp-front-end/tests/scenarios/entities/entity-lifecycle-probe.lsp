;;;; entity-lifecycle-probe.lsp — portable entity CRUD conformance probe
;;;;
;;;; A single, self-contained AutoLISP program that exercises the
;;;; create -> read -> modify -> read -> delete -> restore lifecycle of
;;;; the core drawing-entity families through the low-level entity
;;;; functions (entmakex / entget / entmod / entdel / entlast / entnext
;;;; / handent). It uses ONLY functions that AutoCAD, BricsCAD and
;;;; clautolisp all provide, so it runs UNCHANGED on every target.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --host mock -l entity-lifecycle-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l entity-lifecycle-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l entity-lifecycle-probe.lsp
;;;;   inside a CAD:          (load "entity-lifecycle-probe.lsp")
;;;;
;;;; Output: one line per assertion (ok / FAIL) plus a final summary.
;;;; The last line is exactly "ALL ENTITY PROBES PASSED" when every
;;;; assertion held, or "ENTITY PROBES FAILED: <n>" otherwise — the
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

;; Colour (group 62) is an optional ACI integer valid on every
;; graphical entity, so it is the portable modify target: fresh
;; entities default to BYLAYER (no 62 pair), we set it to 3 and read
;; it back.
(defun probe-graphical (fam data / e d)
  (princ (strcat "family " fam ":\n"))
  ;; CREATE
  (setq e (entmakex data))
  (chk (strcat fam " entmakex returns an ENAME") (= (type e) 'ENAME))
  (if (/= (type e) 'ENAME)
      (progn (princ (strcat "  (skipping rest of " fam ")\n")) nil)
      (progn
        ;; READ
        (setq d (entget e))
        (chk (strcat fam " entget returns a list") (= (type d) 'LIST))
        (chk (strcat fam " group 0 is the entity type")
             (= (strcase (cdr (assoc 0 d))) (strcase fam)))
        (chk (strcat fam " carries a handle (group 5)")
             (= (type (cdr (assoc 5 d))) 'STR))
        (chk (strcat fam " handent round-trips the handle")
             (= (type (handent (cdr (assoc 5 d)))) 'ENAME))
        ;; MODIFY: set colour to 3 and read it back.
        (entmod (append (entget e) (list (cons 62 3))))
        (chk (strcat fam " entmod set colour 62 = 3")
             (= (cdr (assoc 62 (entget e))) 3))
        ;; DELETE
        (entdel e)
        (chk (strcat fam " entget is nil after entdel") (null (entget e)))
        ;; RESTORE (entdel is a within-session toggle)
        (entdel e)
        (chk (strcat fam " entget is live again after re-entdel")
             (not (null (entget e))))
        e)))

;;; --- Core graphical families ------------------------------------

(defun run-graphical-probes ()
  (probe-graphical "LINE"
    (list (cons 0 "LINE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 1.0 0.0))))
  (probe-graphical "POINT"
    (list (cons 0 "POINT") (cons 10 (list 2.0 2.0 0.0))))
  (probe-graphical "CIRCLE"
    (list (cons 0 "CIRCLE") (cons 10 (list 4.0 3.0 0.0)) (cons 40 1.0)))
  (probe-graphical "ARC"
    (list (cons 0 "ARC") (cons 10 (list 4.0 3.0 0.0)) (cons 40 2.0)
          (cons 50 0.0) (cons 51 1.5708)))
  (probe-graphical "ELLIPSE"
    (list (cons 0 "ELLIPSE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))
          (cons 40 0.5) (cons 41 0.0) (cons 42 6.283185)))
  (probe-graphical "TEXT"
    (list (cons 0 "TEXT") (cons 10 (list 1.0 1.0 0.0)) (cons 40 0.2) (cons 1 "hi")))
  (probe-graphical "LWPOLYLINE"
    (list (cons 0 "LWPOLYLINE") (cons 90 2) (cons 70 0)
          (cons 10 (list 0.0 0.0)) (cons 10 (list 1.0 0.0))))
  (probe-graphical "SOLID"
    (list (cons 0 "SOLID") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))
          (cons 12 (list 0.0 1.0 0.0)) (cons 13 (list 1.0 1.0 0.0))))
  (probe-graphical "3DFACE"
    (list (cons 0 "3DFACE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))
          (cons 12 (list 1.0 1.0 0.0)) (cons 13 (list 0.0 1.0 0.0))))
  (probe-graphical "RAY"
    (list (cons 0 "RAY") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (probe-graphical "XLINE"
    (list (cons 0 "XLINE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 0.0 1.0 0.0)))))

;;; --- entmakex vs entmake return contract ------------------------

(defun run-return-contract-probe (/ e d)
  (princ "return contract:\n")
  ;; entmakex hands back the ENAME (feedable straight into entget).
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 9.0 9.0 0.0)) (cons 40 1.0))))
  (chk "entmakex returns ENAME (not a list)" (= (type e) 'ENAME))
  (chk "entmakex ename feeds straight into entget" (= (type (entget e)) 'LIST))
  ;; entmake returns a non-nil result on success (the vendors echo the
  ;; supplied list; we only assert truthiness so the probe is portable).
  (setq d (entmake (list (cons 0 "CIRCLE") (cons 10 (list 8.0 8.0 0.0)) (cons 40 1.0))))
  (chk "entmake returns non-nil on success" (not (null d)))
  (chk "entlast after entmake is an ENAME" (= (type (entlast)) 'ENAME))
  ;; A missing required code fails softly (nil), never an error.
  (chk "entmake of a code-short LINE returns nil"
       (null (entmake (list (cons 0 "LINE"))))))

;;; --- XData (extended data) lifecycle ----------------------------

(defun run-xdata-probe (/ app e d dx)
  (princ "xdata:\n")
  (setq app "CLAUTOLISP_PROBE")
  (regapp app)
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  ;; Attach xdata for our application.
  (entmod (append (entget e)
                  (list (list -3 (list app (cons 1000 "probe-tag") (cons 1070 42))))))
  ;; entget WITHOUT an application list suppresses xdata.
  (setq d (entget e))
  (chk "entget without applist hides xdata" (null (assoc -3 d)))
  ;; entget WITH the application list surfaces it.
  (setq dx (entget e (list app)))
  (chk "entget with applist surfaces the (-3 ...) group" (not (null (assoc -3 dx))))
  (entdel e))

;;; --- Subentity traversal (entnext walks past main entities) -----

(defun run-traversal-probe (/ first-e next-e)
  (princ "traversal:\n")
  (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0)))
  (setq first-e (entnext))
  (chk "entnext with no arg returns the first ENAME (or nil in empty dwg)"
       (or (null first-e) (= (type first-e) 'ENAME)))
  (if first-e
      (progn
        (setq next-e (entnext first-e))
        (chk "entnext ename returns an ENAME or nil at the tail"
             (or (null next-e) (= (type next-e) 'ENAME))))))

;;; --- Driver -----------------------------------------------------

(defun run-entity-probes (/ )
  (princ "=== entity lifecycle probes ===\n")
  (run-return-contract-probe)
  (run-graphical-probes)
  (run-xdata-probe)
  (run-traversal-probe)
  (princ (strcat "\nsummary: " (itoa *probe-pass*) " passed, "
                 (itoa *probe-fail*) " failed\n"))
  (if (= *probe-fail* 0)
      (princ "ALL ENTITY PROBES PASSED\n")
      (princ (strcat "ENTITY PROBES FAILED: " (itoa *probe-fail*) "\n")))
  (princ))

(run-entity-probes)
