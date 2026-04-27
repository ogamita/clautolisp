;;;; tests/string/vl-string.lsp -- VL-STRING-* family

(deftest "vl-string-trim-default"
  '((operator . "VL-STRING-TRIM") (area . "string") (profile . strict))
  '(vl-string-trim " " "  abc  ") "abc")

(deftest "vl-string-trim-explicit-chars"
  '((operator . "VL-STRING-TRIM") (area . "string") (profile . strict))
  '(vl-string-trim "x" "xxabcxx") "abc")

(deftest "vl-string-left-trim"
  '((operator . "VL-STRING-LEFT-TRIM") (area . "string") (profile . strict))
  '(vl-string-left-trim " " "  abc  ") "abc  ")

(deftest "vl-string-right-trim"
  '((operator . "VL-STRING-RIGHT-TRIM") (area . "string") (profile . strict))
  '(vl-string-right-trim " " "  abc  ") "  abc")

(deftest "vl-string-search-found"
  '((operator . "VL-STRING-SEARCH") (area . "string") (profile . strict))
  '(vl-string-search "bc" "abcd") 1)

(deftest "vl-string-search-not-found"
  '((operator . "VL-STRING-SEARCH") (area . "string") (profile . strict))
  '(vl-string-search "z" "abc") nil)

(deftest "vl-string-position-found"
  '((operator . "VL-STRING-POSITION") (area . "string") (profile . strict))
  '(vl-string-position 99 "abc") 2)

(deftest "vl-string-position-not-found"
  '((operator . "VL-STRING-POSITION") (area . "string") (profile . strict))
  '(vl-string-position 122 "abc") nil)

(deftest "vl-string-translate-replace-set"
  '((operator . "VL-STRING-TRANSLATE") (area . "string") (profile . strict))
  '(vl-string-translate "abc" "XYZ" "abcdef") "XYZdef")

(deftest "vl-string-subst-once"
  '((operator . "VL-STRING-SUBST") (area . "string") (profile . strict))
  '(vl-string-subst "X" "b" "abcb") "aXcb")

(deftest "vl-string-mismatch-prefix"
  '((operator . "VL-STRING-MISMATCH") (area . "string") (profile . strict))
  '(vl-string-mismatch "abcdef" "abcXyz") 3)

(deftest "vl-string-elt"
  '((operator . "VL-STRING-ELT") (area . "string") (profile . strict))
  '(vl-string-elt "abc" 1) 98)

(deftest "vl-string-to-list"
  '((operator . "VL-STRING->LIST") (area . "string") (profile . strict))
  '(vl-string->list "abc") '(97 98 99))

(deftest "vl-list-to-string"
  '((operator . "VL-LIST->STRING") (area . "string") (profile . strict))
  '(vl-list->string '(97 98 99)) "abc")
