(:name "drawing-data-autocad"
 :description "The SAME portable drawing-data-structures probe (drawing-data-probe.lsp), run UNCHANGED on AutoCAD via alfe. Classified autocad-only: the conformance runner SKIPS it unless AutoCAD is detected on the host — the vendor-verification tail for the drawing-data-structures-parity work (BLOCKED on real CAD access). When an AutoCAD install is present it must exhibit the same observations (any per-vendor divergence is recorded in the scenario's expected-observations)."
 :classification :autocad-only
 :argv ("--autocad" "-l" "drawing-data-probe.lsp")
 :setup-files (("drawing-data-probe.lsp" ";;;; drawing-data-probe.lsp — drawing-data-structures PROBE
;;;;
;;;; A probe EXERCISES a feature and reports the EXHIBITED behaviour to be
;;;; compared against the specification (autolisp-spec ch.25 probe model) —
;;;; it does not itself judge pass/fail. This one drives the drawing-
;;;; resident data structures — registered applications and XData, the
;;;; named-object dictionary tree, XRECORD objects, and the symbol tables —
;;;; through the low-level functions AutoCAD, BricsCAD and clautolisp all
;;;; provide, so it runs UNCHANGED on every target.
;;;;
;;;; Run it:
;;;;   clautolisp:            clautolisp --clautolisp --host mock -l drawing-data-probe.lsp
;;;;   via alfe on BricsCAD:  alfe --bricscad -l drawing-data-probe.lsp
;;;;   via alfe on AutoCAD:   alfe --autocad  -l drawing-data-probe.lsp
;;;;
;;;; Output: for each observation a machine-readable line
;;;;   OBSERVE <name> <token>
;;;; recording the exhibited behaviour, interleaved with human context; the
;;;; last line is \"OBSERVATIONS <n>\". The conformance runner (and the vendor
;;;; harness) compare each token against the per-target expectation derived
;;;; from the spec and report CONFORMS / KNOWN-DIVERGENCE / UNEXPECTED.
;;;; Divergences are EXPECTED here, not hidden: e.g. entmod on an XRECORD's
;;;; entry contents (divergence D3) is a no-op on AutoCAD and applies on
;;;; BricsCAD, and the probe reports whichever the running target exhibits.

(setq *obs-count* 0)

;; Emit one observation: NAME is a stable dotted key, TOKEN a single
;; whitespace-free word encoding the exhibited outcome. Returns TOKEN.
(defun obs (name token / )
  (setq *obs-count* (1+ *obs-count*))
  (princ (strcat \"OBSERVE \" name \" \" token \"\\n\"))
  token)

;; Boolean property -> yes/no observation (for behaviour all vendors share).
(defun obf (name flag / ) (obs name (if flag \"yes\" \"no\")))

;; A per-run-unique suffix, so REGAPP genuinely sees a fresh application
;; (regapp of an ALREADY-registered app returns nil on both vendors — the
;; spec, not a divergence — and there is no unregapp).
(defun uniq ( / d)
  (setq d (getvar \"DATE\"))
  (if d (itoa (fix (* 864000000.0 (- d (fix d))))) \"X\"))

;; Portable value -> whitespace-free token.
(defun tok (x)
  (cond ((null x) \"nil\")
        ((= (type x) 'STR) (if (= x \"\") \"empty\" x))
        ((= (type x) 'INT) (itoa x))
        ((= (type x) 'REAL) (rtos x 2 6))
        ((= (type x) 'SYM) (vl-symbol-name x))
        ((= (type x) 'ENAME) \"ename\")
        ((listp x) \"list\")
        (T \"other\")))

(defun a2 (code lst) (cdr (assoc code lst)))

;;; --- REGAPP -----------------------------------------------------

(defun run-regapp-probe (/ app r)
  (princ \"regapp:\\n\")
  (setq app (strcat \"CLAUTOLISP_DDP\" (uniq)))
  (setq r (regapp app))
  ;; Exhibited: does regapp of a fresh application return its name?
  (obs \"regapp.fresh\" (if (= r app) \"name\" (tok r))))

;;; --- XData: the full SCHMS group-code set -----------------------

(defun run-xdata-probe (/ app e d dx xd)
  (princ \"xdata:\\n\")
  (setq app \"CLAUTOLISP_XD\")
  (regapp app)
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 5.0 5.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list app
                                       (cons 1000 \"tag-string\")
                                       (cons 1002 \"{\")
                                       (cons 1003 \"0\")
                                       (cons 1005 \"2A\")
                                       (cons 1040 1.5)
                                       (cons 1070 42)
                                       (cons 1071 100000)
                                       (cons 1002 \"}\"))))))
  (setq d (entget e))
  (obf \"xdata.hidden-without-applist\" (null (assoc -3 d)))
  (setq dx (entget e (list app)))
  (obf \"xdata.surfaced-with-applist\" (not (null (assoc -3 dx))))
  (setq xd (cdr (car (cdr (assoc -3 dx)))))   ; the app's xdata pairs
  (obs \"xdata.pair-count\" (itoa (length xd)))
  (obf \"xdata.1000-string\" (equal (a2 1000 xd) \"tag-string\"))
  (obf \"xdata.1040-real\"   (equal (a2 1040 xd) 1.5))
  (obf \"xdata.1070-int16\"  (equal (a2 1070 xd) 42))
  (obf \"xdata.1071-int32\"  (equal (a2 1071 xd) 100000))
  (obf \"xdata.1005-handle\" (equal (a2 1005 xd) \"2A\"))
  (entdel e))

(defun run-xdata-multi-app-probe (/ a1 a2app e)
  (princ \"xdata multi-app:\\n\")
  (setq a1 \"CLAUTOLISP_A1\")
  (setq a2app \"CLAUTOLISP_A2\")
  (regapp a1) (regapp a2app)
  (setq e (entmakex (list (cons 0 \"CIRCLE\") (cons 10 (list 7.0 7.0 0.0)) (cons 40 1.0))))
  (entmod (append (entget e)
                  (list (list -3 (list a1 (cons 1000 \"one\"))
                                  (list a2app (cons 1000 \"two\"))))))
  (obs \"xdata.single-app-count\"
       (itoa (length (cdr (assoc -3 (entget e (list a1)))))))
  (obs \"xdata.wildcard-count\"
       (itoa (length (cdr (assoc -3 (entget e (list \"*\")))))))
  (entdel e))

;;; --- Named-object dictionary + XRECORD --------------------------

(defun run-dictionary-probe (/ nod xr found)
  (princ \"dictionary + xrecord:\\n\")
  (setq nod (namedobjdict))
  (obf \"dict.namedobjdict-ename\" (= (type nod) 'ENAME))
  (setq xr (entmakex (list (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\")
                           (cons 1 \"payload\") (cons 70 5))))
  (obf \"dict.entmakex-xrecord-ename\" (= (type xr) 'ENAME))
  (obf \"dict.dictadd-ename\" (= (type (dictadd nod \"CLAUTOLISP_REC\" xr)) 'ENAME))
  (setq found (dictsearch nod \"CLAUTOLISP_REC\"))
  (obf \"dict.dictsearch-found\" (not (null found)))
  (obs \"dict.dictsearch-type\" (if found (strcase (tok (a2 0 found))) \"nil\"))
  (obs \"dict.dictsearch-payload\" (tok (a2 1 found)))
  ;; Divergence D3: entmod on an XRECORD's ENTRY CONTENTS. AutoCAD
  ;; documents this as a NO-OP (\"their entries cannot be altered with
  ;; entmod\"); BricsCAD applies it. The autolisp-spec adopts AutoCAD's
  ;; no-op as normative. The probe EXERCISES it and reports whichever the
  ;; target exhibits: token \"payload2\" = mutated (BricsCAD/lax), \"payload\"
  ;; = unchanged/no-op (AutoCAD/clautolisp/strict).
  (entmod (list (cons -1 xr) (cons 0 \"XRECORD\") (cons 100 \"AcDbXrecord\")
                (cons 1 \"payload2\") (cons 70 5)))
  (setq found (dictsearch nod \"CLAUTOLISP_REC\"))
  (obs \"dict.entmod-xrecord-entry\" (tok (a2 1 found)))
  (obs \"dict.duplicate-key\" (tok (dictadd nod \"CLAUTOLISP_REC\" xr)))
  (dictremove nod \"CLAUTOLISP_REC\")
  (obf \"dict.dictremove-gone\" (null (dictsearch nod \"CLAUTOLISP_REC\"))))

;;; --- Symbol tables ----------------------------------------------

(defun run-table-probe (/ r)
  (princ \"symbol tables:\\n\")
  (obf \"table.layer-0\"          (not (null (tblsearch \"LAYER\" \"0\"))))
  (obf \"table.ltype-continuous\" (not (null (tblsearch \"LTYPE\" \"Continuous\"))))
  (obf \"table.style-standard\"   (not (null (tblsearch \"STYLE\" \"Standard\"))))
  (obf \"table.appid-acad\"       (not (null (tblsearch \"APPID\" \"ACAD\"))))
  (obf \"table.absent-nil\"       (null (tblsearch \"LAYER\" \"NO_SUCH_LAYER_XYZ\")))
  (setq r (tblnext \"LAYER\" T))
  (obf \"table.tblnext-record\"   (not (null r)))
  (obf \"table.tblnext-group2-str\" (= (type (a2 2 r)) 'STR)))

;;; --- Driver -----------------------------------------------------

(defun run-drawing-data-probes (/ )
  (princ \"=== drawing-data structure probes ===\\n\")
  (run-regapp-probe)
  (run-xdata-probe)
  (run-xdata-multi-app-probe)
  (run-dictionary-probe)
  (run-table-probe)
  (princ (strcat \"OBSERVATIONS \" (itoa *obs-count*) \"\\n\"))
  (princ))

(run-drawing-data-probes)
"))
 :expected-exit 0
 :expected-observations (
   ("regapp.fresh" "name")
   ("xdata.hidden-without-applist" "yes")
   ("xdata.surfaced-with-applist" "yes")
   ("xdata.pair-count" "8")
   ("xdata.1000-string" "yes")
   ("xdata.1040-real" "yes")
   ("xdata.1070-int16" "yes")
   ("xdata.1071-int32" "yes")
   ("xdata.1005-handle" "yes")
   ("xdata.single-app-count" "1")
   ("xdata.wildcard-count" "2")
   ("dict.namedobjdict-ename" "yes")
   ("dict.entmakex-xrecord-ename" "yes")
   ("dict.dictadd-ename" "yes")
   ("dict.dictsearch-found" "yes")
   ("dict.dictsearch-type" "XRECORD")
   ("dict.dictsearch-payload" "payload")
   ("dict.duplicate-key" "nil")
   ("dict.dictremove-gone" "yes")
   ("table.layer-0" "yes")
   ("table.ltype-continuous" "yes")
   ("table.style-standard" "yes")
   ("table.appid-acad" "yes")
   ("table.absent-nil" "yes")
   ("table.tblnext-record" "yes")
   ("table.tblnext-group2-str" "yes")
   ("dict.entmod-xrecord-entry" "payload")
  )
 :covers-options ("--autocad" "-l"))
