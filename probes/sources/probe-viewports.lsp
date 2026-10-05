;;;; probes/sources/probe-viewports.lsp
;;;;
;;;; VPORTS and SETVIEW (system-variables.issue, "Still open: vports/setview").
;;;; clautolisp answers (vports) with ((1 (0.0 0.0) (1.0 1.0))) -- the
;;;; documentation's example -- and (setview ...) with nil; neither was ever
;;;; measured. One suite, vports:
;;;;   - a fresh drawing: TILEMODE, CVPORT, (vports);
;;;;   - after -VPORTS 2 (vertical): (vports), CVPORT; back to SIngle;
;;;;   - TILEMODE 0 (paper space): TILEMODE, CVPORT, (vports); back to 1;
;;;;   - SETVIEW with a saved view's TBLSEARCH list: without a viewport id,
;;;;     with CVPORT, with a viewport that does not exist; and with nil.
;;;; Every step under VL-CATCH-ALL-APPLY; COMMAND only from a lambda.

(defun cad-probe--vp-show (cad-probe--vp-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--vp-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--vp (name cad-probe--vp-fn)
  (cad-probe-capture "vports" name
    (function (lambda () (cad-probe--vp-show cad-probe--vp-fn)))))

(defun cad-probe--vp-state ()
  (list (getvar "TILEMODE") (getvar "CVPORT") (vports)))

(defun cad-probe-run-viewport-probes ( / cad-probe--vp-view)
  (cad-probe--vp "fresh drawing: (TILEMODE CVPORT (vports))"
    (function cad-probe--vp-state))
  (cad-probe--vp "after -VPORTS 2 vertical: (TILEMODE CVPORT (vports))"
    (function (lambda ()
                (command "_.-VPORTS" "2" "_V")
                (cad-probe--vp-state))))
  (cad-probe--vp "after -VPORTS SIngle: (TILEMODE CVPORT (vports))"
    (function (lambda ()
                (command "_.-VPORTS" "_SI")
                (cad-probe--vp-state))))
  (cad-probe--vp "TILEMODE 0: (TILEMODE CVPORT (vports))"
    (function (lambda ()
                (setvar "TILEMODE" 0)
                (cad-probe--vp-state))))
  (cad-probe--vp "TILEMODE back to 1: (TILEMODE CVPORT (vports))"
    (function (lambda ()
                (setvar "TILEMODE" 1)
                (cad-probe--vp-state))))
  (cad-probe--vp "-VIEW Save PRBVIEW, then (tblsearch \"VIEW\" \"PRBVIEW\") keys"
    (function (lambda ()
                (command "_.-VIEW" "_S" "PRBVIEW")
                (setq cad-probe--vp-view (tblsearch "VIEW" "PRBVIEW"))
                (mapcar 'car cad-probe--vp-view))))
  (cad-probe--vp "(setview view)"
    (function (lambda () (setview cad-probe--vp-view))))
  (cad-probe--vp "(setview view (getvar \"CVPORT\"))"
    (function (lambda () (setview cad-probe--vp-view (getvar "CVPORT")))))
  (cad-probe--vp "(setview view 99) -- no such viewport"
    (function (lambda () (setview cad-probe--vp-view 99))))
  (cad-probe--vp "(setview nil)"
    (function (lambda () (setview nil))))
  (princ))
