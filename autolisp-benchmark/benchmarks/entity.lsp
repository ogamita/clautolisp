;;;; autolisp-benchmark/benchmarks/entity.lsp
;;;;
;;;; CAD class: entity creation and mutation. One iteration runs a full
;;;; create -> read -> modify -> delete cycle on a LINE entity:
;;;;
;;;;   entmake   build the entity in the current space,
;;;;   entlast   get its entity name,
;;;;   entget    fetch its DXF data,
;;;;   subst     edit the end-point group,
;;;;   entmod    write the change back,
;;;;   entdel    remove the entity.
;;;;
;;;; The name comes from (entlast) rather than the (entmake) return
;;;; value, which is the one portable path across all three targets:
;;;; on AutoCAD / BricsCAD (entmake) returns the DXF list while
;;;; (entmakex) returns the ename, but clautolisp currently returns the
;;;; DXF list from both (see issues/open/entmakex-returns-list.issue).
;;;; (entlast) returns an ename on every target, so the workload is
;;;; independent of that divergence.
;;;;
;;;; Deleting each entity keeps the drawing database at steady state so
;;;; the per-iteration cost stays comparable over the whole run. This
;;;; runs identically on clautolisp's in-memory drawing database and on
;;;; a real AutoCAD / BricsCAD drawing. It uses only entity primitives,
;;;; never (command ...), so no interactive command loop is required.

(defun bench-entity (reps / i en ed)
  (setq i 0)
  (while (< i reps)
    (entmake (list (cons 0 "LINE")
                   (cons 8 "0")
                   (cons 10 (list (float i) 0.0 0.0))
                   (cons 11 (list (float i) (float i) 0.0))))
    (setq en (entlast))                         ; portable ename
    (if en
        (progn
          (setq ed (entget en))                 ; read
          (setq ed (subst (cons 11 (list (float i) (* 2.0 (float i)) 0.0))
                          (assoc 11 ed)
                          ed))                  ; edit end-point
          (entmod ed)                           ; write back
          (entdel en)))                         ; remove (steady state)
    (setq i (1+ i)))
  en)

(defbench "entity" "entity" 'bench-entity)

(princ)
