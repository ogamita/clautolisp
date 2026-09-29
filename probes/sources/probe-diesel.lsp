;;;; probes/sources/probe-diesel.lsp
;;;;
;;;; Ground truth for DIESEL through (menucmd "M=..."). clautolisp's
;;;; evaluator (autolisp-builtins-core/source/diesel.lisp,
;;;; system-variables.issue) follows Autodesk's DIESEL reference; these
;;;; cases pin what the reference leaves open -- how a non-integral result
;;;; prints, the error strings, EDTIME's codes -- and record what BricsCAD
;;;; does with the M= form it does not document.
;;;;
;;;; EDTIME cases use a FIXED Julian date, 2461313.75 = 2026-09-29 18:00
;;;; local (DATE-sysvar convention: Julian Day Number + day fraction), so
;;;; the answers do not depend on when the probe runs.

(defun cad-probe--diesel (expr)
  (cad-probe-capture "diesel"
    expr
    (function (lambda () (menucmd (strcat "M=" expr))))))

(defun cad-probe-run-diesel-probes ()
  (foreach e (list
              ;; arithmetic, and how a non-integral result prints
              "$(+,1,2)" "$(*,1,2,3)" "$(-,1,2)" "$(/,1,4)" "$(/,1,3)"
              "$(/,2,3)" "$(+,0.1,0.2)" "$(*,1.5,2)" "$(/,10,4)"
              "$(+,1e3,1)" "$(fix,3.7)" "$(fix,-3.7)"
              ;; comparisons and bitwise
              "$(=,2,2.0)" "$(>,1,2)" "$(!=,1,2)" "$(<=,2,2)"
              "$(and,6,3)" "$(or,6,3)" "$(xor,6,3)"
              ;; strings and control
              "$(if,$(=,1,1),yes,no)" "$(if,0,yes,no)" "$(if,0,yes)"
              "$(eq,abc,abc)" "$(eq,abc,ABC)" "$(strlen,hello)"
              "$(substr,hello,2,3)" "$(substr,hello,2)" "$(substr,hello,9)"
              "$(upper,abc)" "$(index,1,\"a,b,c\")" "$(index,5,\"a,b,c\")"
              "$(nth,2,a,b,c)" "$(nth,7,a,b,c)" "$(eval,$(+,1,2))"
              "x=$(+,1,1)!"
              ;; errors
              "$(nosuch,1)" "$(/,1,0)" "$(+,a)" "$(+,1" "$(substr)"
              ;; units and variables
              "$(rtos,17.5,4,2)" "$(angtos,1.5707963268,0,2)"
              "$(getvar,lunits)" "$(getvar,dimzin)"
              ;; edtime on the fixed date
              "$(edtime,2461313.75,DDDD\",\" D MONTH YYYY)"
              "$(edtime,2461313.75,DDD MON)" "$(edtime,2461313.75,YY-MO-DD)"
              "$(edtime,2461313.75,M/D/YYYY)" "$(edtime,2461313.75,HH:MM:SS AM/PM)"
              "$(edtime,2461313.75,H:MM am/pm)" "$(edtime,2461313.75,Ha/p)"
              "$(edtime,2461313.75,HH:MM:SS.MSEC)" "$(edtime,2461313.5,H A/P)")
    (cad-probe--diesel e))
  (princ))
