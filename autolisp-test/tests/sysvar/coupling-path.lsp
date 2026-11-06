;;;; tests/sysvar/coupling-path.lsp
;;;;
;;;; DWGNAME / DWGPREFIX seed default path resolution for the file
;;;; builtins; SRCHPATH (BricsCAD) is the support-path setting read by
;;;; findfile / load. DWGNAME / DWGPREFIX are read-only session values
;;;; headlessly, so we assert their shape rather than a vendor-exact
;;;; string; SRCHPATH round-trips through getvar / setvar.

(deftest-pred "sysvar-dwgname-is-a-dwg-filename"
  '((operator . "DWGNAME") (area . "sysvar") (profile . strict))
  '(getvar "DWGNAME")
  '(and (eq (type *result*) 'str)
        (> (strlen *result*) 0)
        (wcmatch (strcase *result*) "*.DWG")))

(deftest-pred "sysvar-dwgprefix-is-a-string"
  '((operator . "DWGPREFIX") (area . "sysvar") (profile . strict))
  '(getvar "DWGPREFIX")
  '(eq (type *result*) 'str))

(deftest "sysvar-srchpath-round-trips"
  '((operator . "SRCHPATH") (area . "sysvar") (profile . strict))
  '(progn (setvar "SRCHPATH" "/tmp/support-a;/tmp/support-b")
          (let ((result (getvar "SRCHPATH")))
            (setvar "SRCHPATH" "")         ;; restore empty default
            result))
  "/tmp/support-a;/tmp/support-b")
