;;;; tests/reader/list.lsp
;;;;
;;;; Reader-level conformance for the List syntax. The harness calls
;;;; (eval form), so a literal data list must be wrapped in QUOTE
;;;; before it reaches the harness; otherwise eval would treat it as
;;;; a function application. The double-tick `''(1 2 3)` reads as
;;;; `(quote (quote (1 2 3)))', evaluates once at deftest call time
;;;; (yielding the form `(quote (1 2 3))'), and finally evaluates
;;;; inside the harness to the list `(1 2 3)'.

(deftest "list-empty"
  '((operator . "List") (area . "reader") (profile . strict))
  ''() nil)

(deftest "list-single"
  '((operator . "List") (area . "reader") (profile . strict))
  ''(1) '(1))

(deftest "list-three-elements"
  '((operator . "List") (area . "reader") (profile . strict))
  ''(1 2 3) '(1 2 3))

(deftest "list-mixed-types"
  '((operator . "List") (area . "reader") (profile . strict))
  ''(1 "two" three nil) '(1 "two" three nil))

(deftest "list-nested"
  '((operator . "List") (area . "reader") (profile . strict))
  ''((a) (b c) (d (e f))) '((a) (b c) (d (e f))))
