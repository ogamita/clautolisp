;;;; tests/symbol/boundp.lsp -- BOUNDP

(deftest "boundp-after-setq-true"
  '((operator . "BOUNDP") (area . "symbol") (profile . strict))
  '(progn (setq bp-existing 1) (boundp 'bp-existing))
  T)

(deftest "boundp-of-undefined-symbol"
  '((operator . "BOUNDP") (area . "symbol") (profile . strict))
  '(boundp 'bp-completely-undefined-symbol-xyz)
  nil)

(deftest "boundp-of-nil-symbol-T"
  '((operator . "BOUNDP") (area . "symbol") (profile . strict))
  '(boundp 'nil)
  T)

(deftest "boundp-of-T"
  '((operator . "BOUNDP") (area . "symbol") (profile . strict))
  '(boundp 'T)
  T)
