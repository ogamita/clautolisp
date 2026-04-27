;;;; tests/string/wcmatch.lsp -- WCMATCH

(deftest "wcmatch-exact"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "abc" "abc") T)

(deftest "wcmatch-star-prefix"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "hello.lsp" "*.lsp") T)

(deftest "wcmatch-star-suffix"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "hello.lsp" "hello.*") T)

(deftest "wcmatch-question-single"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "ab" "?b") T)

(deftest "wcmatch-no-match"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "abc" "xyz") nil)

(deftest "wcmatch-at-alpha"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "A" "@") T)

(deftest "wcmatch-hash-digit"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "5" "#") T)

(deftest "wcmatch-comma-alternation"
  '((operator . "WCMATCH") (area . "string") (profile . strict))
  '(wcmatch "abc" "abc,xyz") T)
