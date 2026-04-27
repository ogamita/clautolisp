;;;; tests/control/eval.lsp -- EVAL

(deftest "eval-of-quoted-arithmetic"
  '((operator . "EVAL") (area . "control") (profile . strict))
  '(eval '(+ 1 2 3)) 6)

(deftest "eval-of-symbol"
  '((operator . "EVAL") (area . "control") (profile . strict))
  '(progn (setq eval-x 17) (eval 'eval-x)) 17)

(deftest "eval-of-literal"
  '((operator . "EVAL") (area . "control") (profile . strict))
  '(eval 42) 42)

(deftest "eval-of-string"
  '((operator . "EVAL") (area . "control") (profile . strict))
  '(eval "hello") "hello")

(deftest "eval-builds-and-applies-form"
  '((operator . "EVAL") (area . "control") (profile . strict))
  '(eval (list '+ 1 2 3)) 6)
