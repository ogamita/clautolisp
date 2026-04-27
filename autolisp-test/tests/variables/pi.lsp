;;;; tests/variables/pi.lsp -- PI

(deftest-pred "pi-is-real"
  '((operator . "PI") (area . "variable") (profile . strict))
  'pi
  '(eq (type *result*) 'real))

(deftest-pred "pi-near-3.14159"
  '((operator . "PI") (area . "variable") (profile . strict))
  'pi
  '(< (abs (- *result* 3.14159265)) 0.0001))

(deftest-pred "pi-greater-than-3"
  '((operator . "PI") (area . "variable") (profile . strict))
  'pi
  '(> *result* 3.0))
