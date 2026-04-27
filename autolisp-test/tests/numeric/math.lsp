;;;; tests/numeric/math.lsp -- SQRT EXP LOG LOG10 SIN COS TAN ASIN ACOS ATAN EXPT MOD

(deftest "sqrt-of-four"
  '((operator . "SQRT") (area . "numeric") (profile . strict)) '(sqrt 4) 2.0)

(deftest "sqrt-of-zero"
  '((operator . "SQRT") (area . "numeric") (profile . strict)) '(sqrt 0) 0.0)

(deftest "exp-zero-is-one"
  '((operator . "EXP") (area . "numeric") (profile . strict)) '(exp 0) 1.0)

(deftest-pred "exp-one-near-e"
  '((operator . "EXP") (area . "numeric") (profile . strict))
  '(exp 1)
  '(< (abs (- *result* 2.71828)) 0.001))

(deftest-pred "log-of-e-near-one"
  '((operator . "LOG") (area . "numeric") (profile . strict))
  '(log (exp 1.0))
  '(< (abs (- *result* 1.0)) 0.0001))

(deftest "log10-of-100"
  '((operator . "LOG10") (area . "numeric") (profile . strict)) '(log10 100.0) 2.0)

(deftest "sin-of-zero"
  '((operator . "SIN") (area . "numeric") (profile . strict)) '(sin 0) 0.0)

(deftest "cos-of-zero"
  '((operator . "COS") (area . "numeric") (profile . strict)) '(cos 0) 1.0)

(deftest "tan-of-zero"
  '((operator . "TAN") (area . "numeric") (profile . strict)) '(tan 0) 0.0)

(deftest "asin-of-zero"
  '((operator . "ASIN") (area . "numeric") (profile . strict)) '(asin 0) 0.0)

(deftest "acos-of-one"
  '((operator . "ACOS") (area . "numeric") (profile . strict)) '(acos 1) 0.0)

(deftest "atan-of-zero"
  '((operator . "ATAN") (area . "numeric") (profile . strict)) '(atan 0) 0.0)

(deftest "expt-square"
  '((operator . "EXPT") (area . "numeric") (profile . strict)) '(expt 2 8) 256)

(deftest "expt-real-base"
  '((operator . "EXPT") (area . "numeric") (profile . strict)) '(expt 2.0 3) 8.0)

(deftest "mod-positive"
  '((operator . "MOD") (area . "numeric") (profile . strict)) '(mod 10 3) 1)

(deftest "mod-zero-result"
  '((operator . "MOD") (area . "numeric") (profile . strict)) '(mod 12 4) 0)
