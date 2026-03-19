(in-package #:clautolisp.autolisp-reader.tests)

(in-suite autolisp-reader-suite)

(test integer-overflow-warning
  (let* ((result (tokenize-string "2147483648"
                                  :warn-on-integer-overflow-p t))
         (token (first (read-result-objects result)))
         (diagnostics (read-result-diagnostics result)))
    (is (eq :real (token-kind token)))
    (is (typep token 'token))
    (is (= 1 (length diagnostics)))
    (is (eq :warning (diagnostic-severity (first diagnostics))))
    (is (eq :integer-overflow-read-as-real
            (diagnostic-code (first diagnostics))))))
