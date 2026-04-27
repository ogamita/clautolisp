;;;; tests/numeric/bitwise.lsp -- LOGAND LOGIOR LOGXOR LSH ~ BOOLE

(deftest "logand-basic"
  '((operator . "LOGAND") (area . "numeric") (profile . strict)) '(logand 12 10) 8)

(deftest "logand-three"
  '((operator . "LOGAND") (area . "numeric") (profile . strict)) '(logand 15 7 3) 3)

(deftest "logior-basic"
  '((operator . "LOGIOR") (area . "numeric") (profile . strict)) '(logior 12 10) 14)

(deftest "logior-three"
  '((operator . "LOGIOR") (area . "numeric") (profile . strict)) '(logior 1 2 4) 7)

(deftest "logxor-basic"
  '((operator . "LOGXOR") (area . "numeric") (profile . strict)) '(logxor 12 10) 6)

(deftest "lsh-shift-left"
  '((operator . "LSH") (area . "numeric") (profile . strict)) '(lsh 1 3) 8)

(deftest "lsh-shift-right"
  '((operator . "LSH") (area . "numeric") (profile . strict)) '(lsh 16 -2) 4)

(deftest "lsh-zero-shift"
  '((operator . "LSH") (area . "numeric") (profile . strict)) '(lsh 5 0) 5)

(deftest "bitwise-not-of-zero"
  '((operator . "~") (area . "numeric") (profile . strict)) '(~ 0) -1)

(deftest "bitwise-not-of-minus-one"
  '((operator . "~") (area . "numeric") (profile . strict)) '(~ -1) 0)
