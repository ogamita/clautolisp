(in-package #:clautolisp.autolisp-reader.tests)

(in-suite autolisp-reader-suite)

(test tokenize-basic-forms
  (let* ((result (tokenize-string "(foo 17 3.5 \"x\")"))
         (kinds (mapcar #'token-kind (read-result-objects result))))
    (is (equal '(:left-paren :symbol :integer :real :string :right-paren :eof)
               kinds))))

(test tokenize-retained-comments
  (let* ((result (tokenize-string (format nil "a ; c~%b")
                                  :retain-comments-p t))
         (kinds (mapcar #'token-kind (read-result-objects result))))
    (is (equal '(:symbol :comment :symbol :eof) kinds))))

(test strict-vs-lax-real-tokenization
  (let* ((strict-result (tokenize-string "1e3"))
         (lax-result (tokenize-string "1e3" :token-mode :lax))
         (strict-token (first (read-result-objects strict-result)))
         (lax-token (first (read-result-objects lax-result))))
    (is (eq :symbol (token-kind strict-token)))
    (is (eq :real (token-kind lax-token)))))

(test integer-overflow-tokenization
  (let* ((result (tokenize-string "2147483648"
                                  :warn-on-integer-overflow-p t))
         (token (first (read-result-objects result)))
         (diagnostics (read-result-diagnostics result)))
    (is (eq :real (token-kind token)))
    (is (= 1 (length diagnostics)))))
