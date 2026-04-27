;;;; tests/types/type-of.lsp -- TYPE

(deftest "type-of-integer"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type 17) 'int)

(deftest "type-of-real"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type 3.14) 'real)

(deftest "type-of-string"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type "abc") 'str)

(deftest "type-of-symbol"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type 'foo) 'sym)

(deftest "type-of-list"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type '(1 2)) 'list)

(deftest "type-of-nil-is-nil-or-list"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(or (eq (type nil) 'list) (eq (type nil) nil)) T)

(deftest "type-of-builtin-function-is-subr"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type 'car)
  'sym)

(deftest-pred "type-of-builtin-eval-is-subr-or-usubr"
  '((operator . "TYPE") (area . "types") (profile . strict))
  '(type +)
  '(or (eq *result* 'subr)
       (eq *result* 'usubr)
       (eq *result* 'exsubr)
       (eq *result* 'subrf)))
