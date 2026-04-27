;;;; tests/symbol/vl-symbol.lsp -- VL-SYMBOLP / VL-SYMBOL-NAME / VL-SYMBOL-VALUE

(deftest "vl-symbolp-of-symbol"
  '((operator . "VL-SYMBOLP") (area . "symbol") (profile . strict))
  '(vl-symbolp 'foo) T)

(deftest "vl-symbolp-of-string"
  '((operator . "VL-SYMBOLP") (area . "symbol") (profile . strict))
  '(vl-symbolp "foo") nil)

(deftest "vl-symbolp-of-integer"
  '((operator . "VL-SYMBOLP") (area . "symbol") (profile . strict))
  '(vl-symbolp 42) nil)

(deftest "vl-symbol-name-of-symbol"
  '((operator . "VL-SYMBOL-NAME") (area . "symbol") (profile . strict))
  '(vl-symbol-name 'hello) "HELLO")

(deftest "vl-symbol-value-of-bound"
  '((operator . "VL-SYMBOL-VALUE") (area . "symbol") (profile . strict))
  '(progn (setq vlsv-x 99) (vl-symbol-value 'vlsv-x))
  99)
