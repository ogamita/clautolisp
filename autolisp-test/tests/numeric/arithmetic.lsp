;;;; tests/numeric/arithmetic.lsp -- + - * / 1+ 1- MAX MIN REM GCD LCM

;; +
(deftest "plus-zero-args"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+) 0)

(deftest "plus-one-arg"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+ 7) 7)

(deftest "plus-two-ints"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+ 3 4) 7)

(deftest "plus-many-ints"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+ 1 2 3 4) 10)

(deftest "plus-int-real-yields-real"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+ 1 2.5) 3.5)

(deftest "plus-negatives"
  '((operator . "+") (area . "numeric") (profile . strict)) '(+ -1 -2 -3) -6)

;; -
(deftest "minus-one-arg-negates"
  '((operator . "-") (area . "numeric") (profile . strict)) '(- 5) -5)

(deftest "minus-two-args"
  '((operator . "-") (area . "numeric") (profile . strict)) '(- 10 3) 7)

(deftest "minus-many-args"
  '((operator . "-") (area . "numeric") (profile . strict)) '(- 100 10 20 30) 40)

;; *
(deftest "times-zero-args-is-1"
  '((operator . "*") (area . "numeric") (profile . strict)) '(*) 1)

(deftest "times-one-arg"
  '((operator . "*") (area . "numeric") (profile . strict)) '(* 7) 7)

(deftest "times-many-ints"
  '((operator . "*") (area . "numeric") (profile . strict)) '(* 2 3 4) 24)

(deftest "times-with-real"
  '((operator . "*") (area . "numeric") (profile . strict)) '(* 2 0.5) 1.0)

;; /
(deftest "div-integers-truncates"
  '((operator . "/") (area . "numeric") (profile . strict)) '(/ 7 2) 3)

(deftest "div-real-keeps-fraction"
  '((operator . "/") (area . "numeric") (profile . strict)) '(/ 7.0 2) 3.5)

(deftest "div-many"
  '((operator . "/") (area . "numeric") (profile . strict)) '(/ 100 5 2) 10)

;; 1+ / 1-
(deftest "one-plus"
  '((operator . "1+") (area . "numeric") (profile . strict)) '(1+ 9) 10)

(deftest "one-minus"
  '((operator . "1-") (area . "numeric") (profile . strict)) '(1- 9) 8)

;; MAX / MIN
(deftest "max-three"
  '((operator . "MAX") (area . "numeric") (profile . strict)) '(max 1 5 3) 5)

(deftest "max-mixed-types"
  '((operator . "MAX") (area . "numeric") (profile . strict)) '(max 1 2.5 2) 2.5)

(deftest "min-three"
  '((operator . "MIN") (area . "numeric") (profile . strict)) '(min 4 1 3) 1)

;; REM / GCD / LCM
(deftest "rem-positive"
  '((operator . "REM") (area . "numeric") (profile . strict)) '(rem 10 3) 1)

(deftest "gcd-two"
  '((operator . "GCD") (area . "numeric") (profile . strict)) '(gcd 12 8) 4)

(deftest "gcd-three"
  '((operator . "GCD") (area . "numeric") (profile . strict)) '(gcd 24 36 60) 12)

(deftest "lcm-two"
  '((operator . "LCM") (area . "numeric") (profile . strict)) '(lcm 4 6) 12)
