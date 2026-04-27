;;;; tests/list/subst.lsp -- SUBST

(deftest "subst-replaces-occurrence"
  '((operator . "SUBST") (area . "list") (profile . strict))
  '(subst 'X 'b '(a b c))
  '(a X c))

(deftest "subst-no-match-returns-input"
  '((operator . "SUBST") (area . "list") (profile . strict))
  '(subst 'X 'z '(a b c))
  '(a b c))

(deftest "subst-replaces-all-equal-occurrences"
  '((operator . "SUBST") (area . "list") (profile . strict))
  '(subst 'X 'b '(a b c b d))
  '(a X c X d))

(deftest "subst-empty-list"
  '((operator . "SUBST") (area . "list") (profile . strict))
  '(subst 'X 'a nil)
  nil)

(deftest "subst-substitutes-deeply"
  '((operator . "SUBST") (area . "list") (profile . strict))
  '(subst 'X 'b '(a (b) c))
  '(a (X) c))
