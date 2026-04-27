;;;; tests/numeric/comparison.lsp -- = /= < <= > >= ABS

(deftest "eq-numeric-equal"
  '((operator . "=") (area . "numeric") (profile . strict)) '(= 3 3) T)

(deftest "eq-numeric-not-equal"
  '((operator . "=") (area . "numeric") (profile . strict)) '(= 3 4) nil)

(deftest "eq-numeric-int-real-equal"
  '((operator . "=") (area . "numeric") (profile . strict)) '(= 3 3.0) T)

(deftest "eq-numeric-three-args"
  '((operator . "=") (area . "numeric") (profile . strict)) '(= 5 5 5) T)

(deftest "neq-numeric"
  '((operator . "/=") (area . "numeric") (profile . strict)) '(/= 3 4) T)

(deftest "neq-numeric-equal-args"
  '((operator . "/=") (area . "numeric") (profile . strict)) '(/= 3 3) nil)

(deftest "lt-true"
  '((operator . "<") (area . "numeric") (profile . strict)) '(< 1 2) T)

(deftest "lt-false"
  '((operator . "<") (area . "numeric") (profile . strict)) '(< 2 1) nil)

(deftest "lt-chain"
  '((operator . "<") (area . "numeric") (profile . strict)) '(< 1 2 3 4) T)

(deftest "lt-chain-broken"
  '((operator . "<") (area . "numeric") (profile . strict)) '(< 1 2 1) nil)

(deftest "lte-true"
  '((operator . "<=") (area . "numeric") (profile . strict)) '(<= 3 3) T)

(deftest "lte-chain"
  '((operator . "<=") (area . "numeric") (profile . strict)) '(<= 1 2 2 3) T)

(deftest "gt-true"
  '((operator . ">") (area . "numeric") (profile . strict)) '(> 5 3) T)

(deftest "gt-false"
  '((operator . ">") (area . "numeric") (profile . strict)) '(> 3 5) nil)

(deftest "gt-chain"
  '((operator . ">") (area . "numeric") (profile . strict)) '(> 5 4 3) T)

(deftest "gte-true"
  '((operator . ">=") (area . "numeric") (profile . strict)) '(>= 3 3) T)

(deftest "gte-chain"
  '((operator . ">=") (area . "numeric") (profile . strict)) '(>= 5 4 4 3) T)

(deftest "abs-positive"
  '((operator . "ABS") (area . "numeric") (profile . strict)) '(abs 7) 7)

(deftest "abs-negative"
  '((operator . "ABS") (area . "numeric") (profile . strict)) '(abs -7) 7)

(deftest "abs-zero"
  '((operator . "ABS") (area . "numeric") (profile . strict)) '(abs 0) 0)

(deftest "abs-negative-real"
  '((operator . "ABS") (area . "numeric") (profile . strict)) '(abs -1.5) 1.5)
