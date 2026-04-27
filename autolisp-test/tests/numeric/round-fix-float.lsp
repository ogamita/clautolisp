;;;; tests/numeric/round-fix-float.lsp -- ROUND FLOOR CEILING FIX FLOAT

(deftest "fix-of-real"
  '((operator . "FIX") (area . "numeric") (profile . strict)) '(fix 3.7) 3)

(deftest "fix-of-negative-real"
  '((operator . "FIX") (area . "numeric") (profile . strict)) '(fix -3.7) -3)

(deftest "fix-of-integer"
  '((operator . "FIX") (area . "numeric") (profile . strict)) '(fix 7) 7)

(deftest "float-of-integer"
  '((operator . "FLOAT") (area . "numeric") (profile . strict)) '(float 5) 5.0)

(deftest "float-of-real"
  '((operator . "FLOAT") (area . "numeric") (profile . strict)) '(float 3.5) 3.5)

(deftest "floor-of-positive"
  '((operator . "FLOOR") (area . "numeric") (profile . strict)) '(floor 3.7) 3)

(deftest "floor-of-negative"
  '((operator . "FLOOR") (area . "numeric") (profile . strict)) '(floor -3.2) -4)

(deftest "ceiling-of-positive"
  '((operator . "CEILING") (area . "numeric") (profile . strict)) '(ceiling 3.2) 4)

(deftest "ceiling-of-integer"
  '((operator . "CEILING") (area . "numeric") (profile . strict)) '(ceiling 7) 7)

(deftest "round-half-up"
  '((operator . "ROUND") (area . "numeric") (profile . strict)) '(round 3.7) 4)

(deftest "round-half-down"
  '((operator . "ROUND") (area . "numeric") (profile . strict)) '(round 3.2) 3)
