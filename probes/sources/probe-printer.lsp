;;;; probes/sources/probe-printer.lsp
;;;;
;;;; What PRINC / PRIN1 / PRINT return when called with NO argument. The
;;;; spec says the VOID (null) symbol -- the reason a command function ends
;;;; in (princ). clautolisp returned nil until 2026-10-03
;;;; (princ-without-argument-returns-nil); this asks the vendors directly.

(defun cad-probe-run-printer-probes ()
  (foreach f '(princ prin1 print)
    (cad-probe-capture "printer" (strcat "type of (" (vl-symbol-name f) ")")
      (function (lambda () (vl-princ-to-string (type (apply f '()))))))
    (cad-probe-capture "printer" (strcat "symbol name of (" (vl-symbol-name f) ")")
      (function (lambda ( / v)
        (setq v (apply f '()))
        (if (= (type v) 'SYM) (strcat "[" (vl-symbol-name v) "]") "not a symbol"))))
    (cad-probe-capture "printer" (strcat "(null (" (vl-symbol-name f) "))")
      (function (lambda () (if (null (apply f '())) "T" "nil"))))
    ;; 2026-10-04: BricsCAD's (prin1) returned a STR -- which one?
    (cad-probe-capture "printer" (strcat "value of (" (vl-symbol-name f) ")")
      (function (lambda () (vl-prin1-to-string (apply f '()))))))
  (princ))
