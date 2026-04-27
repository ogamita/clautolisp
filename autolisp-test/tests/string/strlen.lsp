;;;; tests/string/strlen.lsp -- STRLEN

(deftest "strlen-empty"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen "") 0)

(deftest "strlen-one"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen "x") 1)

(deftest "strlen-five"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen "abcde") 5)

(deftest "strlen-with-space"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen "a b c") 5)

(deftest "strlen-zero-arg-is-zero"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen) 0)

(deftest "strlen-multi-arg-sums"
  '((operator . "STRLEN") (area . "string") (profile . strict))
  '(strlen "ab" "cd") 4)
