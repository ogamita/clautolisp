;;;; tests/namespace/vl-doc.lsp -- VL-DOC-REF / VL-DOC-SET / VL-DOC-EXPORT / VL-DOC-IMPORT

(deftest "vl-doc-set-then-ref"
  '((operator . "VL-DOC-SET") (area . "namespace") (profile . strict))
  '(progn (vl-doc-set 'doc-test-key "value")
          (vl-doc-ref 'doc-test-key))
  "value")

(deftest "vl-doc-ref-of-unset-returns-nil"
  '((operator . "VL-DOC-REF") (area . "namespace") (profile . strict))
  '(vl-doc-ref 'doc-test-completely-unbound)
  nil)
