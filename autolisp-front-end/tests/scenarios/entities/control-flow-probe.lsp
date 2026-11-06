;;;; control-flow-probe.lsp -- MEASURE the control-flow answers the 2026-10-21
;;;; tickets need, on the real CADs:
;;;;   while-repeat-return-nil.issue          what WHILE and REPEAT return;
;;;;   vl-exit-with-error-leaks-host-condition.issue
;;;;                                          what vl-exit-with-error /
;;;;                                          vl-exit-with-value do outside a
;;;;                                          separate-namespace VLX.
;;;; It measures, it does not judge. Each case is a string READ and EVAL'd at
;;;; run time inside vl-catch-all-apply, so a form a CAD refuses is reported,
;;;; not fatal. (A LOCAL *error* -- local-error-handler-not-called -- cannot be
;;;; measured from here: alfe evaluates every request inside
;;;; vl-catch-all-apply, so the CAD's top-level *error* call never happens.)
;;;;
;;;; Output, one line per case:
;;;;   CTRLF <case> VALUE <(vl-prin1-to-string value)>
;;;;   CTRLF <case> ERROR <(vl-catch-all-error-message e)>
;;;;   CTRLF-INFO <name> <value>
;;;;   CTRLF-DONE
;;;; Keep this file ASCII.

(defun ctrlf-run (name text / r)
  (setq r (vl-catch-all-apply
            (function (lambda () (eval (read text))))
            nil))
  (princ (strcat "CTRLF " name
                 (if (vl-catch-all-error-p r)
                   (strcat " ERROR " (vl-prin1-to-string (vl-catch-all-error-message r)))
                   (strcat " VALUE " (vl-prin1-to-string r)))
                 "\n")))

(princ (strcat "CTRLF-INFO PRODUCT " (vl-prin1-to-string (getvar "PRODUCT")) "\n"))
(princ (strcat "CTRLF-INFO ACADVER " (vl-prin1-to-string (getvar "ACADVER")) "\n"))

(foreach c
  '(("repeat-last"        "(repeat 3 (setq ctrlf-i 6))")
    ("repeat-counter"     "(progn (setq ctrlf-n 0) (repeat 3 (setq ctrlf-n (1+ ctrlf-n))))")
    ("repeat-zero"        "(repeat 0 (quote never))")
    ("repeat-empty-body"  "(repeat 2)")
    ("repeat-nil-last"    "(repeat 2 7 nil)")
    ("while-last"         "(progn (setq ctrlf-k 0) (while (< ctrlf-k 3) (setq ctrlf-k (1+ ctrlf-k)) (* ctrlf-k 100)))")
    ("while-never"        "(while nil (quote never))")
    ("while-test-only"    "(progn (setq ctrlf-k 0) (while (< (setq ctrlf-k (1+ ctrlf-k)) 3)))")
    ("while-string"       "(progn (setq ctrlf-k 0) (while (< ctrlf-k 2) (setq ctrlf-k (1+ ctrlf-k)) \"s\"))")
    ("exit-with-error"    "(vl-exit-with-error \"boom\")")
    ("exit-with-value"    "(vl-exit-with-value 42)")
    ("exit-with-error-in-defun"
     "(progn (defun ctrlf-f () (vl-exit-with-error \"inner\") (quote after)) (ctrlf-f))")
    ("exit-with-value-in-defun"
     "(progn (defun ctrlf-g () (vl-exit-with-value 7) (quote after)) (ctrlf-g))"))
  (ctrlf-run (car c) (cadr c)))

(princ "CTRLF-DONE\n")
(princ)
