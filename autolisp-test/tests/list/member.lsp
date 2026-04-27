;;;; tests/list/member.lsp -- MEMBER

(deftest "member-found-symbol"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member 'b '(a b c))
  '(b c))

(deftest "member-found-integer"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member 2 '(1 2 3 4))
  '(2 3 4))

(deftest "member-not-found"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member 'z '(a b c))
  nil)

(deftest "member-empty-list"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member 'a nil)
  nil)

(deftest "member-string-uses-equal"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member "b" '("a" "b" "c"))
  '("b" "c"))

(deftest "member-list-element-uses-equal"
  '((operator . "MEMBER") (area . "list") (profile . strict))
  '(member '(2) '((1) (2) (3)))
  '((2) (3)))
