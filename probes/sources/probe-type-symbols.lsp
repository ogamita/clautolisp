;;;; probes/sources/probe-type-symbols.lsp
;;;;
;;;; How the symbols returned by TYPE print, per type
;;;; (issues/open/type-symbols-print-lowercase-on-autocad.issue).
;;;;
;;;; intersectwith-probe.lsp measured on AutoCAD 2022 (job 17029587295)
;;;; that (vl-princ-to-string (type v)) is "variant" for a VARIANT and
;;;; "safearray" for a SAFEARRAY, where BricsCAD V25 / V26 and clautolisp
;;;; print "VARIANT" / "SAFEARRAY"; VLA-OBJECT and ENAME print in upper
;;;; case on AutoCAD. Only VL-PRINC-TO-STRING was measured. Before the
;;;; divergence can be implemented we need, for every TYPE result:
;;;;   - vl-princ-to-string, vl-prin1-to-string, vl-symbol-name of it
;;;;     (is the symbol's NAME lower case, or only its printed form?);
;;;;   - whether it is EQ to the upper-case literal read from source;
;;;;   - how the literal symbol ('VARIANT, 'variant) and (read "VARIANT")
;;;;     print, independently of TYPE (is it the symbol that is interned
;;;;     with a lower-case name, so that every reference prints that way?).
;;;; Every value is built under VL-CATCH-ALL-APPLY; an engine without a
;;;; type (no COM, no EXRXSUBR) records an error for that row only.
;;;; Parameter names are unique: AutoLISP binds dynamically.

(defun cad-probe--ts-row (cad-probe--ts-label cad-probe--ts-thunk / cad-probe--ts-v)
  ;; Records the printed forms of (TYPE value) for the value built by THUNK.
  (setq cad-probe--ts-v (vl-catch-all-apply cad-probe--ts-thunk '()))
  (if (vl-catch-all-error-p cad-probe--ts-v)
      (cad-probe-capture "type-symbols" (strcat cad-probe--ts-label " build")
        (function (lambda () (strcat "ERROR " (vl-catch-all-error-message cad-probe--ts-v)))))
      (progn
        (cad-probe-capture "type-symbols" (strcat cad-probe--ts-label " vl-princ-to-string")
          (function (lambda () (vl-princ-to-string (type cad-probe--ts-v)))))
        (cad-probe-capture "type-symbols" (strcat cad-probe--ts-label " vl-prin1-to-string")
          (function (lambda () (vl-prin1-to-string (type cad-probe--ts-v)))))
        (cad-probe-capture "type-symbols" (strcat cad-probe--ts-label " vl-symbol-name")
          (function (lambda () (vl-symbol-name (type cad-probe--ts-v)))))
        (cad-probe-capture "type-symbols" (strcat cad-probe--ts-label " eq read upcase")
          (function (lambda ()
            (if (eq (type cad-probe--ts-v)
                    (read (strcase (vl-symbol-name (type cad-probe--ts-v)))))
                "T" "nil")))))))

(defun cad-probe-run-type-symbols-probes ( / cad-probe--ts-en cad-probe--ts-file)
  (vl-catch-all-apply 'vl-load-com '())
  ;; --- the literal symbols, independently of TYPE ------------------------
  (foreach cad-probe--ts-name '("VARIANT" "SAFEARRAY" "VLA-OBJECT" "ENAME" "PICKSET"
                                "FILE" "SUBR" "USUBR" "EXRXSUBR" "INT" "REAL"
                                "STR" "SYM" "LIST")
    (cad-probe-capture "type-symbols" (strcat "literal " cad-probe--ts-name " vl-princ-to-string")
      (function (lambda () (vl-princ-to-string (read cad-probe--ts-name)))))
    (cad-probe-capture "type-symbols" (strcat "literal " cad-probe--ts-name " vl-symbol-name")
      (function (lambda () (vl-symbol-name (read cad-probe--ts-name)))))
    (cad-probe-capture "type-symbols" (strcat "literal " (strcase cad-probe--ts-name t) " vl-princ-to-string")
      (function (lambda () (vl-princ-to-string (read (strcase cad-probe--ts-name t)))))))
  (cad-probe-capture "type-symbols" "(vl-princ-to-string 'VARIANT) quoted in source"
    (function (lambda () (vl-princ-to-string 'VARIANT))))
  (cad-probe-capture "type-symbols" "(vl-princ-to-string 'safearray) quoted in source"
    (function (lambda () (vl-princ-to-string 'safearray))))
  (cad-probe-capture "type-symbols" "(atoms-family 1 '(\"VARIANT\" \"SAFEARRAY\"))"
    (function (lambda () (vl-prin1-to-string (atoms-family 1 '("VARIANT" "SAFEARRAY"))))))
  ;; --- (type value) for every kind of value ------------------------------
  (cad-probe--ts-row "variant"
    (function (lambda () (vlax-make-variant 1))))
  (cad-probe--ts-row "variant of a safearray"
    (function (lambda ()
      (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray 5 '(0 . 1)) '(1.0 2.0))))))
  (cad-probe--ts-row "safearray"
    (function (lambda () (vlax-make-safearray 5 '(0 . 1)))))
  (cad-probe--ts-row "vla-object"
    (function (lambda () (vlax-get-acad-object))))
  (setq cad-probe--ts-en
        (vl-catch-all-apply 'entmakex
          (list '((0 . "LINE") (10 0.0 0.0 0.0) (11 1.0 0.0 0.0)))))
  (if (vl-catch-all-error-p cad-probe--ts-en) (setq cad-probe--ts-en nil))
  (if cad-probe--ts-en
      (cad-probe--ts-row "ename" (function (lambda () cad-probe--ts-en))))
  (cad-probe--ts-row "pickset"
    (function (lambda () (ssadd))))
  (setq cad-probe--ts-file
        (vl-catch-all-apply
          (function (lambda () (open (vl-filename-mktemp "tsprobe.txt") "w")))
          '()))
  (if (vl-catch-all-error-p cad-probe--ts-file) (setq cad-probe--ts-file nil))
  (if cad-probe--ts-file
      (cad-probe--ts-row "file" (function (lambda () cad-probe--ts-file))))
  (if cad-probe--ts-file (vl-catch-all-apply 'close (list cad-probe--ts-file)))
  (cad-probe--ts-row "subr car"
    (function (lambda () car)))
  (cad-probe--ts-row "usubr"
    (function (lambda () cad-probe--ts-row)))
  (cad-probe--ts-row "exrxsubr acad_strlsort"
    (function (lambda () acad_strlsort)))
  (cad-probe--ts-row "int" (function (lambda () 1)))
  (cad-probe--ts-row "real" (function (lambda () 1.5)))
  (cad-probe--ts-row "str" (function (lambda () "s")))
  (cad-probe--ts-row "sym" (function (lambda () 'foo)))
  (cad-probe--ts-row "list" (function (lambda () '(1 2))))
  (if cad-probe--ts-en (vl-catch-all-apply 'entdel (list cad-probe--ts-en)))
  (princ))
