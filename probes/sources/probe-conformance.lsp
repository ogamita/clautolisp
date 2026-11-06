;;;; probes/sources/probe-conformance.lsp
;;;;
;;;; cador-4 slice 5: the multi-document conformance experiments of
;;;; clautolisp-multidocument-analysis.org (E1-E10) that ONE routine in a
;;;; batch run can measure. Suite conformance:
;;;;   E1  -- symbol identity through the blackboard (a namespace of its
;;;;          own): (eq (vl-bb-ref 'probe) 'my-symbol), and its type;
;;;;   E2  -- copy or share: (eq l (vl-bb-ref 'probe)) after (vl-bb-set
;;;;          'probe l), and (equal ...);
;;;;   E8  -- SDI: its value, and what (setvar "SDI" 1) does (restored);
;;;;   E10 -- MTFLAGS: its value, and whether 4095 is accepted (restored).
;;;; E3 / E6 need LISP to run in a SECOND document's namespace, E4 / E5 a
;;;; live UI: neither is reachable from a batch routine (the cador-4 ticket
;;;; records them). Every step under VL-CATCH-ALL-APPLY.

(defun cad-probe--cf-show (cad-probe--cf-thunk / r)
  (setq r (vl-catch-all-apply cad-probe--cf-thunk '()))
  (if (vl-catch-all-error-p r)
      (strcat "ERROR " (vl-catch-all-error-message r))
      (vl-prin1-to-string r)))

(defun cad-probe--cf (name cad-probe--cf-fn)
  (cad-probe-capture "conformance" name
    (function (lambda () (cad-probe--cf-show cad-probe--cf-fn)))))

(defun cad-probe-run-conformance-probes ( / l saved)
  ;; --- E1 ---------------------------------------------------------------------
  (cad-probe--cf "E1 (vl-bb-set 'cfprobe 'my-symbol) then (eq (vl-bb-ref 'cfprobe) 'my-symbol)"
    (function (lambda ()
                (vl-bb-set 'cfprobe 'my-symbol)
                (eq (vl-bb-ref 'cfprobe) 'my-symbol))))
  (cad-probe--cf "E1 (type (vl-bb-ref 'cfprobe))"
    (function (lambda () (type (vl-bb-ref 'cfprobe)))))
  ;; --- E2 ---------------------------------------------------------------------
  (cad-probe--cf "E2 (setq l (list 1 2 3)) (vl-bb-set 'cfprobe l): (eq l (vl-bb-ref 'cfprobe)) / equal"
    (function (lambda ()
                (setq l (list 1 2 3))
                (vl-bb-set 'cfprobe l)
                (list (eq l (vl-bb-ref 'cfprobe)) (equal l (vl-bb-ref 'cfprobe))))))
  (cad-probe--cf "E2 a string: (eq s (vl-bb-ref 'cfprobe)) / equal"
    (function (lambda ( / s)
                (setq s "abc")
                (vl-bb-set 'cfprobe s)
                (list (eq s (vl-bb-ref 'cfprobe)) (equal s (vl-bb-ref 'cfprobe))))))
  (vl-catch-all-apply 'vl-bb-set '(cfprobe nil))
  ;; --- E8 ---------------------------------------------------------------------
  (cad-probe--cf "E8 (getvar \"SDI\")"
    (function (lambda () (getvar "SDI"))))
  (cad-probe--cf "E8 (setvar \"SDI\" 1) then (getvar \"SDI\") (restored)"
    (function (lambda ( / r)
                (setq saved (getvar "SDI"))
                (setq r (vl-catch-all-apply 'setvar '("SDI" 1)))
                (list (if (vl-catch-all-error-p r) (strcat "ERROR " (vl-catch-all-error-message r)) r)
                      (getvar "SDI")
                      (progn (vl-catch-all-apply 'setvar (list "SDI" saved)) (getvar "SDI"))))))
  ;; --- E10 --------------------------------------------------------------------
  (cad-probe--cf "E10 (getvar \"MTFLAGS\")"
    (function (lambda () (getvar "MTFLAGS"))))
  (cad-probe--cf "E10 (setvar \"MTFLAGS\" 4095) then (getvar \"MTFLAGS\") (restored)"
    (function (lambda ( / r)
                (setq saved (getvar "MTFLAGS"))
                (setq r (vl-catch-all-apply 'setvar '("MTFLAGS" 4095)))
                (list (if (vl-catch-all-error-p r) (strcat "ERROR " (vl-catch-all-error-message r)) r)
                      (getvar "MTFLAGS")
                      (progn (vl-catch-all-apply 'setvar (list "MTFLAGS" saved)) (getvar "MTFLAGS"))))))
  (princ))
