;;;; probes/sources/probe-entity-access.lsp
;;;;
;;;; windows-runner-sunset-probe-campaign, batch B9 (AC-crit). The ch.17
;;;; entity-access details still open after the 2026-11-16 pending-divergences
;;;; capture (entmake marker ORDER is measured there), whose AutoCAD answer is
;;;; lost with the Windows runner:
;;;;
;;;;   - ENTGET's group-code SET and ORDER right after ENTMAKEX (flagged "not
;;;;     normative" in the spec): LINE, CIRCLE, TEXT;
;;;;   - ENTNEXT / ENTLAST confinement: does a non-graphical object (an
;;;;     XRECORD made by ENTMAKEX) become ENTLAST, and does an ENTNEXT walk from
;;;;     nil ever meet one? (clautolisp enumerates them -- the divergence);
;;;;   - ENTMOD on a non-graphical object (an XRECORD in the named-object
;;;;     dictionary): applied, ignored, or refused?
;;;;   - SSGET "X" with a malformed -4 operator list: error, ERRNO, or a
;;;;     silent partial match?
;;;;   - the ERRNO a failed ENTMAKE / ENTMOD / ENTNEXT-past-the-end leaves.
;;;;
;;;; Each case runs through CAD-PROBE--EA-RUN: ERRNO cleared, the case text
;;;; EVAL'd under VL-CATCH-ALL-APPLY, record (RESULT ERRNO-AFTER) -- RESULT is
;;;; (error MESSAGE) on an error. Entity names are never recorded (they differ
;;;; per run): cases return types, group codes, counts, T / nil. Every entity
;;;; or dictionary entry a case makes is deleted again.
;;;;
;;;; Portability (probes/README.org): each case is a STRING (eval (read ...))'d;
;;;; the case name is the exact expression. Parameter names are unique
;;;; (AutoLISP binds dynamically).

(defun cad-probe--ea-run (cad-probe--ea-text / r errno)
  (vl-catch-all-apply 'setvar (list "ERRNO" 0))
  (setq r (vl-catch-all-apply (function (lambda () (eval (read cad-probe--ea-text)))) nil))
  (setq errno (getvar "ERRNO"))
  (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) r)
        errno))

(defun cad-probe--ea (cad-probe--ea-case)
  (cad-probe-capture "entity-access" cad-probe--ea-case
    (function (lambda () (vl-prin1-to-string (cad-probe--ea-run cad-probe--ea-case))))))

(defun cad-probe--ea-codes (cad-probe--ea-ename / data)
  ;; The group codes of ENAME's ENTGET, in order (-1 / 5 / 330 included: the
  ;; ORDER is the question), then the entity deleted.
  (setq data (entget cad-probe--ea-ename))
  (entdel cad-probe--ea-ename)
  (mapcar 'car data))

(defun cad-probe--ea-xrec ( / x)
  ;; An XRECORD made by ENTMAKEX, not yet owned by any dictionary.
  (entmakex '((0 . "XRECORD") (100 . "AcDbXrecord") (1 . "b9-probe"))))

(defun cad-probe--ea-last-type-after-xrec ( / before x after r)
  ;; Does ENTLAST move to a fresh (ownerless) XRECORD?
  (setq before (entlast))
  (setq x (cad-probe--ea-xrec))
  (setq after (entlast))
  (setq r (list (if x (cdr (assoc 0 (entget x))) 'no-xrecord)
                (if after (cdr (assoc 0 (entget after))) nil)
                (equal before after)))
  (if x (vl-catch-all-apply 'entdel (list x)))
  r)

(defun cad-probe--ea-walk-types ( / x e types n)
  ;; The distinct entity types an ENTNEXT walk from nil meets, with an
  ;; ownerless XRECORD in the drawing meanwhile.
  (setq x (cad-probe--ea-xrec))
  (setq e (entnext) n 0)
  (while (and e (< n 10000))
    (setq types (cons (cdr (assoc 0 (entget e))) types))
    (setq e (entnext e) n (1+ n)))
  (if x (vl-catch-all-apply 'entdel (list x)))
  (list n (vl-sort (cad-probe--ea-uniq types) '<)))

(defun cad-probe--ea-uniq (cad-probe--ea-l / out)
  (foreach i cad-probe--ea-l (if (not (member i out)) (setq out (cons i out))))
  out)

(defun cad-probe--ea-xrec-entmod ( / x d r after)
  ;; ENTMOD of an XRECORD owned by the named-object dictionary: is the new
  ;; group 1 there afterwards? Removed from the dictionary at the end.
  (setq x (cad-probe--ea-xrec))
  (if (null x)
      'no-xrecord
      (progn
        (vl-catch-all-apply 'dictadd (list (namedobjdict) "CLAUTOLISP-B9-PROBE" x))
        (setq d (entget x))
        (setq r (vl-catch-all-apply 'entmod
                  (list (subst (cons 1 "b9-modified") (assoc 1 d) d))))
        (setq after (cdr (assoc 1 (entget x))))
        (vl-catch-all-apply 'dictremove (list (namedobjdict) "CLAUTOLISP-B9-PROBE"))
        (vl-catch-all-apply 'entdel (list x))
        (list (if (vl-catch-all-error-p r) (list 'error (vl-catch-all-error-message r)) (not (null r)))
              after))))

(defun cad-probe--ea-past-end ( / e)
  ;; ENTNEXT of the last entity (made fresh, so there IS one), then deleted.
  (setq e (entmakex '((0 . "POINT") (10 0.0 0.0 0.0))))
  (list (entnext e) (progn (entdel e) 'deleted)))

(defun cad-probe--ea-entdel-twice ( / e a b)
  ;; ENTDEL toggles: the second call undeletes. What does each return?
  (setq e (entmakex '((0 . "POINT") (10 1.0 1.0 0.0))))
  (setq a (not (null (entdel e))))
  (setq b (not (null (entdel e))))
  (entdel e)
  (list a b))

(defun cad-probe-run-entity-access-probes ()
  ;; --- ENTGET group codes and order after ENTMAKEX -------------------------
  (cad-probe-note "entity-access" "entget-order"
    "(GROUP-CODES ERRNO): ENTGET's group codes, in order, of an entity just made by ENTMAKEX")
  (cad-probe--ea "(cad-probe--ea-codes (entmakex '((0 . \"LINE\") (10 0.0 0.0 0.0) (11 1.0 1.0 0.0))))")
  (cad-probe--ea "(cad-probe--ea-codes (entmakex '((0 . \"CIRCLE\") (10 0.0 0.0 0.0) (40 . 1.0))))")
  (cad-probe--ea "(cad-probe--ea-codes (entmakex '((0 . \"TEXT\") (10 0.0 0.0 0.0) (40 . 1.0) (1 . \"b9\"))))")
  (cad-probe--ea "(cad-probe--ea-codes (entmakex '((0 . \"POINT\") (10 0.0 0.0 0.0))))")

  ;; --- ENTNEXT / ENTLAST and non-graphical objects --------------------------
  (cad-probe-note "entity-access" "confinement"
    "an ownerless XRECORD made by ENTMAKEX: its type, ENTLAST's type after it, ENTLAST unchanged?; an ENTNEXT walk's types")
  (cad-probe--ea "(cad-probe--ea-last-type-after-xrec)")
  (cad-probe--ea "(cad-probe--ea-walk-types)")

  ;; --- ENTMOD on a non-graphical object -------------------------------------
  (cad-probe-note "entity-access" "entmod-nongraphical"
    "ENTMOD of an XRECORD in the named-object dictionary: (ENTMOD-RESULT GROUP-1-AFTER)")
  (cad-probe--ea "(cad-probe--ea-xrec-entmod)")

  ;; --- SSGET \"X\" with a malformed -4 list ----------------------------------
  (cad-probe-note "entity-access" "ssget-malformed"
    "SSGET \"X\" with an unbalanced or empty -4 operator list: error / ERRNO / a selection (its length)")
  (cad-probe--ea "(cad-probe--ea-sslen (ssget \"X\" '((-4 . \"<AND\") (0 . \"LINE\"))))")
  (cad-probe--ea "(cad-probe--ea-sslen (ssget \"X\" '((-4 . \"<OR\"))))")
  (cad-probe--ea "(cad-probe--ea-sslen (ssget \"X\" '((-4 . \"AND>\"))))")
  (cad-probe--ea "(cad-probe--ea-sslen (ssget \"X\" '((-4 . \"<NOSUCHOP\") (0 . \"LINE\") (-4 . \"NOSUCHOP>\"))))")
  (cad-probe--ea "(cad-probe--ea-sslen (ssget \"X\" '((-4 . \"<NOT\") (0 . \"LINE\") (0 . \"CIRCLE\") (-4 . \"NOT>\"))))")

  ;; --- ERRNO after a failed ENTMAKE / ENTMOD / ENTNEXT ------------------------
  (cad-probe-note "entity-access" "errno"
    "(RESULT ERRNO) of failing entity calls")
  (cad-probe--ea "(entmake '((0 . \"NOSUCHTYPE\")))")
  (cad-probe--ea "(entmake '((0 . \"LINE\")))")
  (cad-probe--ea "(entmake '((10 0.0 0.0 0.0)))")
  (cad-probe--ea "(entmake nil)")
  (cad-probe--ea "(entmod '((0 . \"LINE\") (10 0.0 0.0 0.0)))")
  (cad-probe--ea "(entmod nil)")
  (cad-probe--ea "(cad-probe--ea-past-end)")
  (cad-probe--ea "(cad-probe--ea-entdel-twice)")
  (cad-probe--ea "(entget nil)")
  (cad-probe--ea "(entupd nil)")
  (princ))

(defun cad-probe--ea-sslen (cad-probe--ea-ss)
  ;; A selection set's length (nil stays nil): its names differ per run.
  (if (= (type cad-probe--ea-ss) 'PICKSET) (sslength cad-probe--ea-ss) cad-probe--ea-ss))
