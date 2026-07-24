;;;; selection-probe.lsp — portable selection-set + snapshot probe
;;;;
;;;; A single, self-contained AutoLISP program that exercises the
;;;; non-interactive whole-database selection scan (ssget "X") and the
;;;; selection-set functions (sslength / ssname / ssadd / ssdel /
;;;; ssmemb), plus ENTNEXT / ENTLAST traversal, through functions that
;;;; AutoCAD, BricsCAD and clautolisp all provide, so it runs UNCHANGED
;;;; on every target.
;;;;
;;;; The probe isolates its own entities from anything already in the
;;;; drawing by tagging every seeded entity with XData under a private
;;;; application name and AND-ing that (-3 ...) filter into every scan.
;;;; The assertions therefore hold whether or not the CAD drawing was
;;;; empty at start — they test semantic set MEMBERSHIP, never raw
;;;; enumeration order or a global entity count.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --clautolisp --host mock -l selection-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l selection-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l selection-probe.lsp
;;;;   inside a CAD:          (load "selection-probe.lsp")
;;;;
;;;; Output: last line is exactly "ALL SELECTION PROBES PASSED" on
;;;; success, or "SELECTION PROBES FAILED: <n>" otherwise.

(setq *probe-pass* 0)
(setq *probe-fail* 0)

(defun chk (label ok)
  (if ok
      (progn (setq *probe-pass* (1+ *probe-pass*))
             (princ (strcat "  ok   " label "\n")))
      (progn (setq *probe-fail* (1+ *probe-fail*))
             (princ (strcat "  FAIL " label "\n"))))
  ok)

(setq *app* "CLAUTOLISP_SEL")

;; Count the members of a pickset (0 when nil).
(defun sscount (ss) (if ss (sslength ss) 0))

;; entmakex an entity, then tag it with our private XData so ssget -3
;; can isolate exactly the probe's entities.
(defun mk (data / e)
  (setq e (entmakex data))
  (entmod (append (entget e) (list (list -3 (list *app* (cons 1000 "sel"))))))
  e)

;; The (-3 (*app*)) sublist used to fence the probe's own entities.
(defun mine () (list -3 (list *app*)))

;;; --- Seed -------------------------------------------------------

(defun seed (/ )
  (regapp *app*)
  ;; Three LINEs, colours 1 / 2 / 3.
  (mk (list (cons 0 "LINE") (cons 62 1) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (mk (list (cons 0 "LINE") (cons 62 2) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))))
  (mk (list (cons 0 "LINE") (cons 62 3) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 3.0 0.0 0.0))))
  ;; One CIRCLE.
  (mk (list (cons 0 "CIRCLE") (cons 62 1) (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))

;;; --- ssget filter grammar ---------------------------------------

(defun run-filter-probes (/ )
  (princ "ssget filters:\n")
  ;; All four probe entities.
  (chk "ssget X (-3 app) selects the four seeded entities"
       (= (sscount (ssget "X" (list (mine)))) 4))
  ;; Entity-type filter (group 0).
  (chk "ssget X type=LINE selects the three lines"
       (= (sscount (ssget "X" (list (cons 0 "LINE") (mine)))) 3))
  ;; Comma-joined alternation on the type code.
  (chk "ssget X type=LINE,CIRCLE selects all four"
       (= (sscount (ssget "X" (list (cons 0 "LINE,CIRCLE") (mine)))) 4))
  ;; -4 <OR: colour 1 OR colour 3.
  (chk "ssget X OR(colour 1, colour 3) selects two"
       (= (sscount (ssget "X" (list (cons 0 "LINE")
                                    (cons -4 "<OR") (cons 62 1) (cons 62 3) (cons -4 "OR>")
                                    (mine)))) 2))
  ;; -4 <AND: explicit conjunction.
  (chk "ssget X AND(LINE, colour 2) selects one"
       (= (sscount (ssget "X" (list (cons -4 "<AND") (cons 0 "LINE") (cons 62 2) (cons -4 "AND>")
                                    (mine)))) 1))
  ;; -4 <NOT: lines whose colour is NOT 1.
  (chk "ssget X NOT(colour 1) over lines selects two"
       (= (sscount (ssget "X" (list (cons 0 "LINE")
                                    (cons -4 "<NOT") (cons 62 1) (cons -4 "NOT>")
                                    (mine)))) 2))
  ;; -4 relational comparison.
  (chk "ssget X colour > 1 over lines selects two"
       (= (sscount (ssget "X" (list (cons 0 "LINE") (cons -4 ">") (cons 62 1) (mine)))) 2))
  ;; -3 for an application nobody used -> empty.
  (chk "ssget X (-3 OTHERAPP) selects none"
       (= (sscount (ssget "X" (list (list -3 (list "CLAUTOLISP_NOBODY"))))) 0)))

;;; --- selection-set membership functions -------------------------

(defun run-set-op-probes (/ ss e0 e1 empty one)
  (princ "selection-set ops:\n")
  (setq ss (ssget "X" (list (cons 0 "LINE") (mine))))
  (chk "sslength of the LINE set is 3" (= (sslength ss) 3))
  (setq e0 (ssname ss 0))
  (setq e1 (ssname ss 1))
  (chk "ssname 0 is an ENAME" (= (type e0) 'ENAME))
  (chk "ssname past the end is nil" (null (ssname ss 99)))
  ;; ssadd: empty, then one.
  (setq empty (ssadd))
  (chk "(ssadd) makes an empty set" (= (sslength empty) 0))
  (setq one (ssadd e0))
  (chk "(ssadd ename) makes a singleton" (= (sslength one) 1))
  ;; ssadd into an existing set; duplicates do not grow it.
  (ssadd e1 one)
  (chk "(ssadd ename set) extends the set" (= (sslength one) 2))
  (ssadd e0 one)
  (chk "re-adding a member does not grow the set" (= (sslength one) 2))
  ;; ssmemb.
  (chk "ssmemb finds a member" (not (null (ssmemb e0 one))))
  ;; ssdel.
  (ssdel e0 one)
  (chk "ssdel removes a member" (= (sslength one) 1))
  (chk "ssmemb after ssdel is nil" (null (ssmemb e0 one))))

;;; --- ENTNEXT / ENTLAST traversal --------------------------------

(defun run-traversal-probe (/ last first nxt)
  (princ "entnext / entlast:\n")
  (setq last (entlast))
  (chk "entlast returns an ENAME after seeding" (= (type last) 'ENAME))
  (setq first (entnext))
  (chk "entnext with no arg returns the first ENAME"
       (or (null first) (= (type first) 'ENAME)))
  (if first
      (progn
        (setq nxt (entnext first))
        (chk "entnext ename returns an ENAME or nil at the tail"
             (or (null nxt) (= (type nxt) 'ENAME))))))

;;; --- Driver -----------------------------------------------------

(defun run-selection-probes (/ )
  (princ "=== selection + snapshot probes ===\n")
  (seed)
  (run-filter-probes)
  (run-set-op-probes)
  (run-traversal-probe)
  (princ (strcat "\nsummary: " (itoa *probe-pass*) " passed, "
                 (itoa *probe-fail*) " failed\n"))
  (if (= *probe-fail* 0)
      (princ "ALL SELECTION PROBES PASSED\n")
      (princ (strcat "SELECTION PROBES FAILED: " (itoa *probe-fail*) "\n")))
  (princ))

(run-selection-probes)
