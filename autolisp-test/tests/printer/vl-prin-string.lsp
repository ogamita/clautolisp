;;;; tests/printer/vl-prin-string.lsp -- VL-PRIN1-TO-STRING / VL-PRINC-TO-STRING

(deftest "vl-prin1-to-string-int"
  '((operator . "VL-PRIN1-TO-STRING") (area . "printer") (profile . strict))
  '(vl-prin1-to-string 17) "17")

(deftest "vl-prin1-to-string-string-quoted"
  '((operator . "VL-PRIN1-TO-STRING") (area . "printer") (profile . strict))
  '(vl-prin1-to-string "hi") "\"hi\"")

(deftest "vl-prin1-to-string-symbol"
  '((operator . "VL-PRIN1-TO-STRING") (area . "printer") (profile . strict))
  '(vl-prin1-to-string 'foo) "FOO")

(deftest "vl-princ-to-string-int"
  '((operator . "VL-PRINC-TO-STRING") (area . "printer") (profile . strict))
  '(vl-princ-to-string 17) "17")

(deftest "vl-princ-to-string-string-unquoted"
  '((operator . "VL-PRINC-TO-STRING") (area . "printer") (profile . strict))
  '(vl-princ-to-string "hi") "hi")

(deftest "vl-princ-to-string-symbol"
  '((operator . "VL-PRINC-TO-STRING") (area . "printer") (profile . strict))
  '(vl-princ-to-string 'bar) "BAR")
