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
      (function (lambda () (vl-prin1-to-string (apply f '())))))
    ;; 2026-11-04 (autocad-output-explicit-nil-file-rejected): an EXPLICIT
    ;; nil file. Both references document it (output to the command line);
    ;; AutoCAD 2022 at LISPSYS 0 rejects it, BricsCAD V26 accepts it. Still
    ;; open: AutoCAD 2026, and LISPSYS 1 / 2. Under alfe on BricsCAD the
    ;; printers are alfe's variadic shadows, so run this suite natively there.
    (cad-probe-capture "printer" (strcat "(" (vl-symbol-name f) " \"x\" nil)")
      (function (lambda () (vl-prin1-to-string (apply f (list "x" nil)))))))
  (cad-probe-capture "printer" "(write-line \"x\" nil)"
    (function (lambda () (vl-prin1-to-string (write-line "x" nil)))))
  (cad-probe-capture "printer" "(write-char 65 nil)"
    (function (lambda () (vl-prin1-to-string (write-char 65 nil)))))
  (cad-probe-capture "printer" "LISPSYS"
    (function (lambda () (vl-prin1-to-string (getvar "LISPSYS")))))
  (princ))
