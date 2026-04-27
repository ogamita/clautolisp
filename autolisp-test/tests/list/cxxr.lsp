;;;; tests/list/cxxr.lsp -- Cxxr / Cxxxr / Cxxxxr family

;; Two-level
(deftest "caar-of-nested-list"
  '((operator . "CAAR") (area . "list") (profile . strict))
  '(caar '((1 2) 3))
  1)

(deftest "cadr-second-element"
  '((operator . "CADR") (area . "list") (profile . strict))
  '(cadr '(1 2 3))
  2)

(deftest "cdar-rest-of-first"
  '((operator . "CDAR") (area . "list") (profile . strict))
  '(cdar '((1 2 3) x))
  '(2 3))

(deftest "cddr-tail-after-two"
  '((operator . "CDDR") (area . "list") (profile . strict))
  '(cddr '(1 2 3 4))
  '(3 4))

;; Three-level
(deftest "caaar-deeply-nested"
  '((operator . "CAAAR") (area . "list") (profile . strict))
  '(caaar '(((1))))
  1)

(deftest "caadr-second-then-first"
  '((operator . "CAADR") (area . "list") (profile . strict))
  '(caadr '(x (1 2) y))
  1)

(deftest "cadar-first-tail-second"
  '((operator . "CADAR") (area . "list") (profile . strict))
  '(cadar '((1 2)))
  2)

(deftest "caddr-third-element"
  '((operator . "CADDR") (area . "list") (profile . strict))
  '(caddr '(a b c d))
  'c)

(deftest "cdaar-tail-of-first-of-first"
  '((operator . "CDAAR") (area . "list") (profile . strict))
  '(cdaar '(((1 2 3))))
  '(2 3))

(deftest "cdadr-tail-of-first-of-second"
  '((operator . "CDADR") (area . "list") (profile . strict))
  '(cdadr '(x (1 2 3) y))
  '(2 3))

(deftest "cddar-tail-of-tail-of-first"
  '((operator . "CDDAR") (area . "list") (profile . strict))
  '(cddar '((1 2 3 4)))
  '(3 4))

(deftest "cdddr-tail-after-three"
  '((operator . "CDDDR") (area . "list") (profile . strict))
  '(cdddr '(a b c d e))
  '(d e))

;; Four-level
(deftest "cadddr-fourth-element"
  '((operator . "CADDDR") (area . "list") (profile . strict))
  '(cadddr '(a b c d e))
  'd)

(deftest "caaaar-deeply-nested-4"
  '((operator . "CAAAAR") (area . "list") (profile . strict))
  '(caaaar '((((1)))))
  1)
