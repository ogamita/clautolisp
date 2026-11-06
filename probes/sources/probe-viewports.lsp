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
;;;; and suite vports-options: the other -VPORTS options (below).
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
  (cad-probe-run-viewport-option-probes)
  (princ))

;;; --- suite vports-options: the -VPORTS options not measured above ------------
;;; (pjb 2026-10-05: "probe and implement"). Each case starts from SIngle,
;;; runs its options, and records (CVPORT (vports)). JOIN is left out: it
;;; picks viewports, which a batch run cannot answer.

(defun cad-probe--vpo (name cad-probe--vpo-options)
  (cad-probe-capture "vports-options" name
    (function (lambda ()
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_SI")
                              (apply 'command (cons "_.-VPORTS" cad-probe--vpo-options))
                              (list (getvar "CVPORT") (vports)))))))))

(defun cad-probe-run-viewport-option-probes ()
  (cad-probe--vpo "2 H" '("2" "_H"))
  (cad-probe--vpo "2 <default>" '("2" ""))
  (cad-probe--vpo "3 V" '("3" "_V"))
  (cad-probe--vpo "3 H" '("3" "_H"))
  (cad-probe--vpo "3 Above" '("3" "_A"))
  (cad-probe--vpo "3 Below" '("3" "_B"))
  (cad-probe--vpo "3 Left" '("3" "_L"))
  (cad-probe--vpo "3 Right" '("3" "_R"))
  (cad-probe--vpo "3 <default>" '("3" ""))
  (cad-probe--vpo "4" '("4"))
  (cad-probe-capture "vports-options" "2 V, then 2 V again: (CVPORT (vports))"
    (function (lambda ()
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_SI")
                              (command "_.-VPORTS" "2" "_V")
                              (command "_.-VPORTS" "2" "_V")
                              (list (getvar "CVPORT") (vports))))))))
  (cad-probe-capture "vports-options" "2 V, (setvar \"CVPORT\" 3): (CVPORT (vports))"
    (function (lambda ()
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_SI")
                              (command "_.-VPORTS" "2" "_V")
                              (setvar "CVPORT" 3)
                              (list (getvar "CVPORT") (vports))))))))
  (cad-probe-capture "vports-options" "2 V, Toggle, Toggle: ((CVPORT (vports)) (CVPORT (vports)))"
    (function (lambda ( / a)
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_SI")
                              (command "_.-VPORTS" "2" "_V")
                              (command "_.-VPORTS" "_T")
                              (setq a (list (getvar "CVPORT") (vports)))
                              (command "_.-VPORTS" "_T")
                              (list a (list (getvar "CVPORT") (vports)))))))))
  (cad-probe-capture "vports-options" "4, Save PRBCFG, SIngle, Restore PRBCFG: (CVPORT (vports) VPORT-records)"
    (function (lambda ()
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_SI")
                              (command "_.-VPORTS" "4")
                              (command "_.-VPORTS" "_S" "PRBCFG")
                              (command "_.-VPORTS" "_SI")
                              (command "_.-VPORTS" "_R" "PRBCFG")
                              (list (getvar "CVPORT") (vports)
                                    (if (tblsearch "VPORT" "PRBCFG") "PRBCFG-RECORD" "NO-RECORD"))))))))
  (cad-probe-capture "vports-options" "Delete PRBCFG: (tblsearch \"VPORT\" \"PRBCFG\")"
    (function (lambda ()
                (cad-probe--vp-show
                  (function (lambda ()
                              (command "_.-VPORTS" "_D" "PRBCFG")
                              (tblsearch "VPORT" "PRBCFG")))))))
  (command "_.-VPORTS" "_SI"))
