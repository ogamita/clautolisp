;;;; tests/equality/listp.lsp -- LISTP

(deftest "listp-of-list"
  '((operator . "LISTP") (area . "equality") (profile . strict))
  '(listp '(1 2))
  T)

(deftest "listp-of-nil"
  '((operator . "LISTP") (area . "equality") (profile . strict))
  '(listp nil)
  T)

(deftest "listp-of-symbol-nil"
  '((operator . "LISTP") (area . "equality") (profile . strict))
  '(listp 'foo)
  nil)

(deftest "listp-of-integer-nil"
  '((operator . "LISTP") (area . "equality") (profile . strict))
  '(listp 42)
  nil)

(deftest "listp-of-dotted-pair-is-T"
  '((operator . "LISTP") (area . "equality") (profile . strict))
  '(listp (cons 1 2))
  T)
