;;;; tests/namespace/vl-bb.lsp -- VL-BB-REF / VL-BB-SET / VL-PROPAGATE

(deftest "vl-bb-set-then-ref"
  '((operator . "VL-BB-SET") (area . "namespace") (profile . strict))
  '(progn (vl-bb-set 'bb-test-key 123)
          (vl-bb-ref 'bb-test-key))
  123)

(deftest "vl-bb-ref-of-unset-returns-nil"
  '((operator . "VL-BB-REF") (area . "namespace") (profile . strict))
  '(vl-bb-ref 'bb-test-utterly-unbound)
  nil)

(deftest "vl-bb-set-overwrites"
  '((operator . "VL-BB-SET") (area . "namespace") (profile . strict))
  '(progn (vl-bb-set 'bb-test-overw 1)
          (vl-bb-set 'bb-test-overw 2)
          (vl-bb-ref 'bb-test-overw))
  2)
