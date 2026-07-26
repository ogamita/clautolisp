;;;; entity-lifecycle-probe.lsp — entity CRUD lifecycle PROBE
;;;;
;;;; A probe EXERCISES a feature and reports the EXHIBITED behaviour to be
;;;; compared against the specification (autolisp-spec ch.25 probe model) —
;;;; it does not itself judge pass/fail. This one drives the create -> read
;;;; -> modify -> read -> delete -> restore lifecycle of the core drawing-
;;;; entity families through the low-level entity functions (entmakex /
;;;; entget / entmod / entdel / entlast / entnext / handent), plus the
;;;; ENTMAKE R13+ subclass-marker policy (divergence D1). It uses ONLY
;;;; functions AutoCAD, BricsCAD and clautolisp all provide, so it runs
;;;; UNCHANGED on every target.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --host mock -l entity-lifecycle-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l entity-lifecycle-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l entity-lifecycle-probe.lsp
;;;;
;;;; Output: one "OBSERVE <name> <token>" line per observation recording
;;;; the exhibited behaviour, then "OBSERVATIONS <n>". The conformance
;;;; runner compares each token against the per-target expectation from the
;;;; spec (CONFORMS / KNOWN-DIVERGENCE / UNEXPECTED). Most checks are
;;;; portable boolean properties (token yes/no); the D1 marker policy is
;;;; divergent (token created/rejected) and is EXERCISED, not hidden.

(setq *obs-count* 0)

(defun obs (name token / )
  (setq *obs-count* (1+ *obs-count*))
  (princ (strcat "OBSERVE " name " " token "\n"))
  token)

(defun obf (name flag / ) (obs name (if flag "yes" "no")))

;;; --- Core graphical family lifecycle ----------------------------
;;
;; Colour (group 62) is an optional ACI integer valid on every graphical
;; entity, so it is the portable modify target: fresh entities default to
;; BYLAYER (no 62 pair); we set it to 3 and read it back.
(defun probe-graphical (fam data / e d)
  (princ (strcat "family " fam ":\n"))
  (setq e (entmakex data))
  (if (/= (type e) 'ENAME)
      (obf (strcat fam ".entmakex-ename") nil)   ; created? no -> the rest can't run
      (progn
        (obf (strcat fam ".entmakex-ename") t)
        (setq d (entget e))
        (obf (strcat fam ".entget-list") (= (type d) 'LIST))
        (obf (strcat fam ".group0-type")
             (= (strcase (cdr (assoc 0 d))) (strcase fam)))
        (obf (strcat fam ".handle") (= (type (cdr (assoc 5 d))) 'STR))
        (obf (strcat fam ".handent-roundtrip")
             (= (type (handent (cdr (assoc 5 d)))) 'ENAME))
        (entmod (append (entget e) (list (cons 62 3))))
        (obf (strcat fam ".entmod-colour") (= (cdr (assoc 62 (entget e))) 3))
        (entdel e)
        (obf (strcat fam ".entget-nil-after-entdel") (null (entget e)))
        (entdel e)                                ; entdel is a within-session toggle
        (obf (strcat fam ".live-after-re-entdel") (not (null (entget e))))
        e)))

(defun run-graphical-probes ()
  ;; Pre-R13 families accept data without subclass markers on every vendor.
  (probe-graphical "LINE"
    (list (cons 0 "LINE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 1.0 0.0))))
  (probe-graphical "POINT"
    (list (cons 0 "POINT") (cons 10 (list 2.0 2.0 0.0))))
  (probe-graphical "CIRCLE"
    (list (cons 0 "CIRCLE") (cons 10 (list 4.0 3.0 0.0)) (cons 40 1.0)))
  (probe-graphical "ARC"
    (list (cons 0 "ARC") (cons 10 (list 4.0 3.0 0.0)) (cons 40 2.0)
          (cons 50 0.0) (cons 51 1.5708)))
  (probe-graphical "TEXT"
    (list (cons 0 "TEXT") (cons 10 (list 1.0 1.0 0.0)) (cons 40 0.2) (cons 1 "hi")))
  (probe-graphical "SOLID"
    (list (cons 0 "SOLID") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))
          (cons 12 (list 0.0 1.0 0.0)) (cons 13 (list 1.0 1.0 0.0))))
  (probe-graphical "3DFACE"
    (list (cons 0 "3DFACE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))
          (cons 12 (list 1.0 1.0 0.0)) (cons 13 (list 0.0 1.0 0.0))))
  ;; R13+ families WITH their subclass markers create on every target
  ;; (portable) — the marker-less policy is probed separately below.
  (probe-graphical "ELLIPSE"
    (list (cons 0 "ELLIPSE") (cons 100 "AcDbEntity") (cons 100 "AcDbEllipse")
          (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))
          (cons 40 0.5) (cons 41 0.0) (cons 42 6.283185)))
  (probe-graphical "LWPOLYLINE"
    (list (cons 0 "LWPOLYLINE") (cons 100 "AcDbEntity") (cons 100 "AcDbPolyline")
          (cons 90 2) (cons 70 0)
          (cons 10 (list 0.0 0.0)) (cons 10 (list 1.0 0.0))))
  (probe-graphical "RAY"
    (list (cons 0 "RAY") (cons 100 "AcDbEntity") (cons 100 "AcDbRay")
          (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (probe-graphical "XLINE"
    (list (cons 0 "XLINE") (cons 100 "AcDbEntity") (cons 100 "AcDbXline")
          (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 0.0 1.0 0.0)))))

;;; --- Divergence D1: R13+ subclass-marker policy -----------------
;;
;; entmakex of an R13+ entity WITHOUT the (100 . "AcDb...") markers.
;; AutoCAD documents them as required and REJECTS marker-less data (the
;; autolisp-spec's normative behaviour); BricsCAD synthesises them and
;; CREATES. Token: "created" (bricscad/lax) or "rejected"
;; (autocad/clautolisp/strict).
(defun probe-marker-policy (name data / e)
  (setq e (entmakex data))
  (obs name (if (= (type e) 'ENAME) "created" "rejected")))

(defun run-marker-policy-probes ()
  (princ "marker policy (D1):\n")
  (probe-marker-policy "d1.markerless-ellipse"
    (list (cons 0 "ELLIPSE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))
          (cons 40 0.5) (cons 41 0.0) (cons 42 6.283185)))
  (probe-marker-policy "d1.markerless-lwpolyline"
    (list (cons 0 "LWPOLYLINE") (cons 90 2) (cons 70 0)
          (cons 10 (list 0.0 0.0)) (cons 10 (list 1.0 0.0))))
  (probe-marker-policy "d1.markerless-ray"
    (list (cons 0 "RAY") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (probe-marker-policy "d1.markerless-xline"
    (list (cons 0 "XLINE") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 0.0 1.0 0.0)))))

;;; --- entmakex vs entmake return contract ------------------------

(defun run-return-contract-probe (/ e d)
  (princ "return contract:\n")
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 9.0 9.0 0.0)) (cons 40 1.0))))
  (obf "return.entmakex-ename" (= (type e) 'ENAME))
  (obf "return.entmakex-feeds-entget" (= (type (entget e)) 'LIST))
  (setq d (entmake (list (cons 0 "CIRCLE") (cons 10 (list 8.0 8.0 0.0)) (cons 40 1.0))))
  (obf "return.entmake-non-nil" (not (null d)))
  (obf "return.entlast-ename" (= (type (entlast)) 'ENAME))
  ;; A missing required code fails softly (nil), never an error — portable.
  (obf "return.code-short-line-nil" (null (entmake (list (cons 0 "LINE"))))))

;;; --- XData (extended data) lifecycle ----------------------------

(defun run-xdata-probe (/ app e d dx)
  (princ "xdata:\n")
  (setq app "CLAUTOLISP_PROBE")
  (regapp app)
  (setq e (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list app (cons 1000 "probe-tag") (cons 1070 42))))))
  (setq d (entget e))
  (obf "xdata.hidden-without-applist" (null (assoc -3 d)))
  (setq dx (entget e (list app)))
  (obf "xdata.surfaced-with-applist" (not (null (assoc -3 dx))))
  (entdel e))

;;; --- Traversal (entnext) ----------------------------------------

(defun run-traversal-probe (/ first-e next-e)
  (princ "traversal:\n")
  (entmakex (list (cons 0 "CIRCLE") (cons 10 (list 0.0 0.0 0.0)) (cons 40 1.0)))
  (setq first-e (entnext))
  (obf "traversal.entnext-first-ename-or-nil"
       (or (null first-e) (= (type first-e) 'ENAME)))
  (setq next-e (if first-e (entnext first-e) nil))
  (obf "traversal.entnext-next-ename-or-nil"
       (or (null next-e) (= (type next-e) 'ENAME))))

;;; --- Driver -----------------------------------------------------

(defun run-entity-probes (/ )
  (princ "=== entity lifecycle probes ===\n")
  (run-return-contract-probe)
  (run-graphical-probes)
  (run-marker-policy-probes)
  (run-xdata-probe)
  (run-traversal-probe)
  (princ (strcat "OBSERVATIONS " (itoa *obs-count*) "\n"))
  (princ))

(run-entity-probes)
