(in-package #:clautolisp.autolisp-reader.tests)

(deftest integer-overflow-warning ()
  (let* ((result (tokenize-string "2147483648"
                                  :warn-on-integer-overflow-p t))
         (token (first (read-result-objects result)))
         (diagnostics (read-result-diagnostics result)))
    (is-equal :real (token-kind token))
    (is (typep token 'token))
    (is-equal 1 (length diagnostics))
    (is-equal :warning (diagnostic-severity (first diagnostics)))
    (is-equal :integer-overflow-read-as-real
              (diagnostic-code (first diagnostics)))))
