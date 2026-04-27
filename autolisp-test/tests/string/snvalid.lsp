;;;; tests/string/snvalid.lsp -- SNVALID

(deftest "snvalid-simple-name-is-T"
  '((operator . "SNVALID") (area . "string") (profile . strict))
  '(snvalid "ALPHA") T)

(deftest "snvalid-name-with-underscore"
  '((operator . "SNVALID") (area . "string") (profile . strict))
  '(snvalid "MY_NAME") T)

(deftest "snvalid-name-with-leading-digit-rejected"
  '((operator . "SNVALID") (area . "string") (profile . strict))
  '(snvalid "1foo") nil)

(deftest "snvalid-empty-rejected"
  '((operator . "SNVALID") (area . "string") (profile . strict))
  '(snvalid "") nil)
