;;;; probes/sources/probe-triage3.lsp
;;;;
;;;; Triage round 3 (2026-10-05, pjb: "proceed with points 1-5"):
;;;;   bool       -- what COM boolean properties return and accept
;;;;                 (vlax-boolean-properties-return-t): the type and value
;;;;                 of Application.Visible, Document.Saved / ReadOnly,
;;;;                 Block.IsLayout / IsXRef, Layer.LayerOn / Freeze / Lock /
;;;;                 Plottable, Entity.Visible -- through vla-get-*, through
;;;;                 vlax-get-property, through vlax-get; and the put side:
;;;;                 does vla-put-layeron take T / nil as well as :vlax-false?
;;;;                 (BricsCAD only: AutoCAD's accoreconsole has no COM.)
;;;;   layoutlist -- (layoutlist) on a fresh drawing, after LAYOUT New, after
;;;;                 LAYOUT Delete (layoutlist-returns-model), and CTAB.
;;;; Every step runs under VL-CATCH-ALL-APPLY; COMMAND is only ever called
;;;; from a lambda (AutoCAD aborts the run on (vl-catch-all-apply 'command
;;;; ...)). Parameter names are unique: AutoLISP binds dynamically.

(defun cad-probe--t3-show (cad-probe--t3-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--t3-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--t3 (suite name cad-probe--t3-fn)
  (cad-probe-capture suite name
    (function (lambda () (cad-probe--t3-show cad-probe--t3-fn)))))

(defun cad-probe--t3-typed (cad-probe--t3-v)
  ;; (TYPE VALUE) of a value, so :vlax-true, T and -1 are told apart.
  (list (type cad-probe--t3-v) cad-probe--t3-v))

(defun cad-probe-run-triage3-probes ( / acad doc layer ms ent before)
  (vl-catch-all-apply 'vl-load-com '())
  ;; --- bool ---------------------------------------------------------------
  (setq acad (vl-catch-all-apply 'vlax-get-acad-object '()))
  (if (vl-catch-all-error-p acad) (setq acad nil))
  (setq doc (if acad (vl-catch-all-apply 'vla-get-activedocument (list acad))))
  (if (vl-catch-all-error-p doc) (setq doc nil))
  (setq layer (if doc (vl-catch-all-apply (function (lambda () (vla-item (vla-get-layers doc) "0"))) '())))
  (if (vl-catch-all-error-p layer) (setq layer nil))
  (setq ms (if doc (vl-catch-all-apply 'vla-get-modelspace (list doc))))
  (if (vl-catch-all-error-p ms) (setq ms nil))
  (vl-catch-all-apply (function (lambda () (command "_.LINE" "0,0" "5,0" ""))) '())
  (setq ent (if acad (vl-catch-all-apply 'vlax-ename->vla-object (list (entlast)))))
  (if (vl-catch-all-error-p ent) (setq ent nil))
  (cad-probe--t3 "bool" "(vla-get-visible app)"
    (function (lambda () (cad-probe--t3-typed (vla-get-visible acad)))))
  (cad-probe--t3 "bool" "(vla-get-saved doc)"
    (function (lambda () (cad-probe--t3-typed (vla-get-saved doc)))))
  (cad-probe--t3 "bool" "(vla-get-readonly doc)"
    (function (lambda () (cad-probe--t3-typed (vla-get-readonly doc)))))
  (cad-probe--t3 "bool" "(vla-get-islayout modelspace)"
    (function (lambda () (cad-probe--t3-typed (vla-get-islayout ms)))))
  (cad-probe--t3 "bool" "(vla-get-isxref modelspace)"
    (function (lambda () (cad-probe--t3-typed (vla-get-isxref ms)))))
  (cad-probe--t3 "bool" "(vla-get-layeron layer0)"
    (function (lambda () (cad-probe--t3-typed (vla-get-layeron layer)))))
  (cad-probe--t3 "bool" "(vla-get-freeze layer0)"
    (function (lambda () (cad-probe--t3-typed (vla-get-freeze layer)))))
  (cad-probe--t3 "bool" "(vla-get-lock layer0)"
    (function (lambda () (cad-probe--t3-typed (vla-get-lock layer)))))
  (cad-probe--t3 "bool" "(vla-get-plottable layer0)"
    (function (lambda () (cad-probe--t3-typed (vla-get-plottable layer)))))
  (cad-probe--t3 "bool" "(vla-get-visible line)"
    (function (lambda () (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vlax-get-property layer0 'LayerOn)"
    (function (lambda () (cad-probe--t3-typed (vlax-get-property layer 'LayerOn)))))
  (cad-probe--t3 "bool" "(vlax-get layer0 'LayerOn)"
    (function (lambda () (cad-probe--t3-typed (vlax-get layer 'LayerOn)))))
  ;; The put side, on the line (never on layer 0's state the rest relies on).
  (cad-probe--t3 "bool" "(vla-put-visible line :vlax-false) then get"
    (function (lambda ()
                (vla-put-visible ent :vlax-false)
                (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vla-put-visible line T) then get"
    (function (lambda ()
                (vla-put-visible ent T)
                (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vla-put-visible line nil) then get"
    (function (lambda ()
                (vla-put-visible ent nil)
                (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vla-put-visible line 0) then get"
    (function (lambda ()
                (vla-put-visible ent 0)
                (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vla-put-visible line -1) then get"
    (function (lambda ()
                (vla-put-visible ent -1)
                (cad-probe--t3-typed (vla-get-visible ent)))))
  (cad-probe--t3 "bool" "(vlax-put line 'Visible 0) then vlax-get"
    (function (lambda ()
                (vlax-put ent 'Visible 0)
                (cad-probe--t3-typed (vlax-get ent 'Visible)))))
  (vl-catch-all-apply 'vla-put-visible (list ent :vlax-true))
  (cad-probe--t3 "bool" "(type :vlax-true) / (eval :vlax-true)"
    (function (lambda () (list (type :vlax-true) :vlax-true :vlax-false))))
  ;; --- layoutlist -------------------------------------------------------------
  (cad-probe--t3 "layoutlist" "(layoutlist) fresh"
    (function (lambda () (layoutlist))))
  (cad-probe--t3 "layoutlist" "(getvar \"CTAB\")"
    (function (lambda () (getvar "CTAB"))))
  (setq before (vl-catch-all-apply 'layoutlist '()))
  (cad-probe--t3 "layoutlist" "(layoutlist) after LAYOUT New ProbeLayout"
    (function (lambda ()
                (command "_.LAYOUT" "_N" "ProbeLayout")
                (layoutlist))))
  (cad-probe--t3 "layoutlist" "(layoutlist) after LAYOUT Delete ProbeLayout"
    (function (lambda ()
                (command "_.LAYOUT" "_D" "ProbeLayout")
                (layoutlist))))
  (princ))
