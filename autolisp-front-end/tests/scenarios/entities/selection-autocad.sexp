(:name "selection-autocad"
 :description "The SAME portable selection + snapshot probe (selection-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — the vendor-verification tail for the selection-and-snapshot-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must exhibit the same observations (any per-vendor divergence is recorded in the scenario's expected-observations)."
 :classification :autocad-only
 :argv ("--autocad" "-l" "selection-probe.lsp")
 :setup-files (("selection-probe.lsp" ";;;; selection-probe.lsp — selection-set + snapshot PROBE
;;;;
;;;; A probe EXERCISES a feature and reports the EXHIBITED behaviour to be
;;;; compared against the specification (autolisp-spec ch.25 probe model) —
;;;; it does not itself judge pass/fail. This one drives the non-interactive
;;;; whole-database selection scan (ssget \"X\") and the selection-set
;;;; functions (sslength / ssname / ssadd / ssdel / ssmemb), plus ENTNEXT /
;;;; ENTLAST traversal, through functions AutoCAD, BricsCAD and clautolisp
;;;; all provide, so it runs UNCHANGED on every target. These are portable
;;;; behaviours (no vendor divergence), so every observation is a yes/no
;;;; property expected to be \"yes\" on all targets.
;;;;
;;;; The probe isolates its own entities from anything already in the
;;;; drawing by tagging every seeded entity with XData under a private
;;;; application name and AND-ing that (-3 ...) filter into every scan, so
;;;; the observations hold whether or not the CAD drawing started empty —
;;;; they test semantic set MEMBERSHIP, never raw enumeration order.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --clautolisp --host mock -l selection-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l selection-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l selection-probe.lsp
;;;;
;;;; Output: \"OBSERVE <name> <token>\" per observation, then
;;;; \"OBSERVATIONS <n>\".

(setq *obs-count* 0)

(defun obs (name token / )
  (setq *obs-count* (1+ *obs-count*))
  (princ (strcat \"OBSERVE \" name \" \" token \"\\n\"))
  token)

(defun obf (name flag / ) (obs name (if flag \"yes\" \"no\")))

(defun p2s (x)
  (cond ((null x) \"nil\")
        ((= (type x) 'STR) x)
        ((= (type x) 'INT) (itoa x))
        ((= (type x) 'ENAME) \"<ename>\")
        ((listp x) \"<list>\")
        (T \"<other>\")))

(setq *app* \"CLAUTOLISP_SEL\")

;; Count the members of a pickset (0 when nil).
(defun sscount (ss) (if ss (sslength ss) 0))

;; entmakex an entity, then tag it with our private XData so ssget -3 can
;; isolate exactly the probe's entities.
(defun mk (data / e)
  (setq e (entmakex data))
  (entmod (append (entget e) (list (list -3 (list *app* (cons 1000 \"sel\"))))))
  e)

;; The (-3 (*app*)) sublist used to fence the probe's own entities.
(defun mine () (list -3 (list *app*)))

;; Diagnostic dump (human context only, never an OBSERVE line): when the
;; (mine) filter can't see the seeded entities, print the values that pin
;; the root cause. Silent when the seed is visible.
(defun diag-seed (/ e d cnt)
  (setq cnt (sscount (ssget \"X\" (list (mine)))))
  (if (/= cnt 4)
      (progn
        (setq e (entlast))
        (setq d (entget e (list *app*)))
        (princ (strcat \"  DIAG regapp(app) -> \" (p2s (regapp *app*)) \"\\n\"))
        (princ (strcat \"  DIAG last-seed -3 xdata attached? \"
                       (if (assoc -3 d) \"YES\" \"NO\") \"\\n\"))
        (princ (strcat \"  DIAG mine-filter count -> \" (p2s cnt) \" (want 4)\\n\")))))

;;; --- Seed (from a clean slate) ----------------------------------

;; Delete every existing entity first so the absolute counts hold even on a
;; drawing left non-empty by a prior run; silent no-op on an empty drawing.
(defun clean-slate (/ ss i)
  (setq ss (ssget \"X\"))
  (if ss
      (progn (setq i 0)
             (while (< i (sslength ss))
               (entdel (ssname ss i))
               (setq i (1+ i))))))

(defun seed (/ )
  (clean-slate)
  (regapp *app*)
  (mk (list (cons 0 \"LINE\") (cons 62 1) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 0.0 0.0))))
  (mk (list (cons 0 \"LINE\") (cons 62 2) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 2.0 0.0 0.0))))
  (mk (list (cons 0 \"LINE\") (cons 62 3) (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 3.0 0.0 0.0))))
  (mk (list (cons 0 \"CIRCLE\") (cons 62 1) (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))

;;; --- ssget filter grammar ---------------------------------------

(defun run-filter-probes (/ )
  (princ \"ssget filters:\\n\")
  (obf \"filter.mine-selects-4\" (= (sscount (ssget \"X\" (list (mine)))) 4))
  (obf \"filter.type-line-3\"
       (= (sscount (ssget \"X\" (list (cons 0 \"LINE\") (mine)))) 3))
  (obf \"filter.type-line-circle-4\"
       (= (sscount (ssget \"X\" (list (cons 0 \"LINE,CIRCLE\") (mine)))) 4))
  (obf \"filter.or-colour-2\"
       (= (sscount (ssget \"X\" (list (cons 0 \"LINE\")
                                    (cons -4 \"<OR\") (cons 62 1) (cons 62 3) (cons -4 \"OR>\")
                                    (mine)))) 2))
  (obf \"filter.and-line-colour2-1\"
       (= (sscount (ssget \"X\" (list (cons -4 \"<AND\") (cons 0 \"LINE\") (cons 62 2) (cons -4 \"AND>\")
                                    (mine)))) 1))
  (obf \"filter.not-colour1-2\"
       (= (sscount (ssget \"X\" (list (cons 0 \"LINE\")
                                    (cons -4 \"<NOT\") (cons 62 1) (cons -4 \"NOT>\")
                                    (mine)))) 2))
  (obf \"filter.colour-gt1-2\"
       (= (sscount (ssget \"X\" (list (cons 0 \"LINE\") (cons -4 \">\") (cons 62 1) (mine)))) 2))
  (obf \"filter.otherapp-0\"
       (= (sscount (ssget \"X\" (list (list -3 (list \"CLAUTOLISP_NOBODY\"))))) 0)))

;;; --- selection-set membership functions -------------------------

(defun run-set-op-probes (/ ss e0 e1 empty one)
  (princ \"selection-set ops:\\n\")
  (setq ss (ssget \"X\" (list (cons 0 \"LINE\") (mine))))
  (obf \"setop.line-length-3\" (= (sslength ss) 3))
  (setq e0 (ssname ss 0))
  (setq e1 (ssname ss 1))
  (obf \"setop.ssname0-ename\" (= (type e0) 'ENAME))
  (obf \"setop.ssname-past-end-nil\" (null (ssname ss 99)))
  (setq empty (ssadd))
  (obf \"setop.ssadd-empty-0\" (= (sslength empty) 0))
  (setq one (ssadd e0))
  (obf \"setop.ssadd-singleton-1\" (= (sslength one) 1))
  (ssadd e1 one)
  (obf \"setop.ssadd-extends-2\" (= (sslength one) 2))
  (ssadd e0 one)
  (obf \"setop.readd-no-grow-2\" (= (sslength one) 2))
  (obf \"setop.ssmemb-finds\" (not (null (ssmemb e0 one))))
  (ssdel e0 one)
  (obf \"setop.ssdel-removes-1\" (= (sslength one) 1))
  (obf \"setop.ssmemb-after-ssdel-nil\" (null (ssmemb e0 one))))

;;; --- ENTNEXT / ENTLAST traversal --------------------------------

(defun run-traversal-probe (/ last first nxt)
  (princ \"entnext / entlast:\\n\")
  (setq last (entlast))
  (obf \"traversal.entlast-ename\" (= (type last) 'ENAME))
  (setq first (entnext))
  (obf \"traversal.entnext-first-ename-or-nil\"
       (or (null first) (= (type first) 'ENAME)))
  (setq nxt (if first (entnext first) nil))
  (obf \"traversal.entnext-next-ename-or-nil\"
       (or (null nxt) (= (type nxt) 'ENAME))))

;;; --- Driver -----------------------------------------------------

(defun run-selection-probes (/ )
  (princ \"=== selection + snapshot probes ===\\n\")
  (seed)
  (diag-seed)
  (run-filter-probes)
  (run-set-op-probes)
  (run-traversal-probe)
  (princ (strcat \"OBSERVATIONS \" (itoa *obs-count*) \"\\n\"))
  (princ))

(run-selection-probes)
"))
 :expected-exit 0
 :expected-observations-default "yes"
 :covers-options ("--autocad" "-l"))
