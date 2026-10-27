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

(test tokenize-retained-block-comments
  (let* ((result (tokenize-string "a ;| block
comment |; b"
                                  :retain-comments-p t))
         (tokens (read-result-objects result))
         (kinds (mapcar #'token-kind tokens)))
    (is (equal '(:symbol :comment :symbol :eof) kinds))
    (is (string= ";| block
comment |;"
                 (token-lexeme (second tokens))))))

(test tokenize-string-with-invalid-unicode-escape
  (let* ((result (tokenize-string "\"x\\u+12\""
                                  :extended-string-escapes-p t))
         (diagnostics (read-result-diagnostics result)))
    (is (= 1 (length diagnostics)))
    (is (eq :invalid-unicode-escape
            (diagnostic-code (first diagnostics))))))

(test strict-vs-lax-real-tokenization
  (let* ((strict-result (tokenize-string "1e3"))
         (lax-result (tokenize-string "1e3" :token-mode :lax))
         (strict-token (first (read-result-objects strict-result)))
         (lax-token (first (read-result-objects lax-result))))
    (is (eq :symbol (token-kind strict-token)))
    (is (eq :real (token-kind lax-token)))))

(test strict-real-accepts-dot-with-digits-on-either-side
  ;; Regression for issues/closed/strict-dialect-autolisp-divergences
  ;; § 4: vendor AutoCAD / BricsCAD read "42.", "5.", and ".5" as
  ;; reals (42.0, 5.0, 0.5) even under the strict acceptor. The
  ;; previous strict-real-lexeme-p required digits on BOTH sides of
  ;; the dot, which contradicted vendor behaviour and broke a SCHMS+
  ;; literal `(PARMI 42.)' that read as a symbol.
  (dolist (case '(("42."  42.0d0)
                  ("5."   5.0d0)
                  (".5"   0.5d0)
                  ("-42." -42.0d0)
                  ("+.5"  0.5d0)
                  ("-5."  -5.0d0)
                  ("1.e3" 1000.0d0)
                  (".5e2" 50.0d0)))
    (destructuring-bind (lexeme expected) case
      (let* ((result (tokenize-string lexeme))
             (token (first (read-result-objects result))))
        (is (eq :real (token-kind token))
            "~S should tokenize as :real, got ~S"
            lexeme (token-kind token))
        (is (eql expected
                 (clautolisp.autolisp-reader:token-value token))
            "~S parses to ~S (got ~S)"
            lexeme expected
            (clautolisp.autolisp-reader:token-value token))))))

(test integer-overflow-tokenization
  (let* ((result (tokenize-string "2147483648"
                                  :warn-on-integer-overflow-p t))
         (token (first (read-result-objects result)))
         (diagnostics (read-result-diagnostics result)))
    (is (eq :real (token-kind token)))
    (is (= 1 (length diagnostics)))))

;;;; A line break written literally inside a string literal
;;;; (issues/open/lone-cr-in-string-literal.issue, probe
;;;; probes/sources/probe-multiline-string.lsp). LF and CR LF become one
;;;; LF in every engine; a LONE CR is kept by READ in every vendor and by
;;;; AutoCAD's LOAD, turned into LF by BricsCAD's LOAD. The reader keeps
;;;; it by default and turns it into LF under :lone-cr-in-string :newline.

(defun %string-token-value (text &rest options)
  (token-value (first (read-result-objects (apply #'tokenize-string text options)))))

(test string-literal-line-feed-is-kept
  (is (string= (format nil "ab~Ccd" #\Newline)
               (%string-token-value (format nil "\"ab~Ccd\"" #\Newline)))))

(test string-literal-crlf-becomes-line-feed
  (is (string= (format nil "ab~Ccd" #\Newline)
               (%string-token-value (format nil "\"ab~C~Ccd\"" #\Return #\Newline))))
  (is (string= (format nil "ab~Ccd" #\Newline)
               (%string-token-value (format nil "\"ab~C~Ccd\"" #\Return #\Newline)
                                    :lone-cr-in-string :keep))))

(test string-literal-lone-cr-is-kept-by-default
  (is (string= (format nil "ab~Ccd" #\Return)
               (%string-token-value (format nil "\"ab~Ccd\"" #\Return))))
  (is (string= (format nil "ab~C~Ccd" #\Return #\Return)
               (%string-token-value (format nil "\"ab~C~Ccd\"" #\Return #\Return)))))

(test string-literal-lone-cr-becomes-line-feed-on-request
  (is (string= (format nil "ab~Ccd" #\Newline)
               (%string-token-value (format nil "\"ab~Ccd\"" #\Return)
                                    :lone-cr-in-string :newline))))

(test string-literal-lone-cr-is-signalled-with-its-line
  (let ((lines '()))
    (handler-bind ((clautolisp.autolisp-reader:lone-cr-in-string-literal
                     (lambda (condition)
                       (push (clautolisp.autolisp-reader:lone-cr-in-string-literal-line
                              condition)
                             lines))))
      (tokenize-string (format nil "a~C\"x~Cy\" \"p~C~Cq\"" #\Newline #\Return #\Return #\Newline)))
    ;; Only the lone CR is reported; the CR LF in the second string is not.
    (is (equal '(2) lines))))

(test lone-cr-outside-strings-is-a-line-break
  (let ((tokens (read-result-objects
                 (tokenize-string (format nil "a~Cb ; c~Cd" #\Return #\Return)))))
    (is (equal '(:symbol :symbol :symbol :eof) (mapcar #'token-kind tokens)))
    (is (equal '(1 2 3)
               (mapcar (lambda (token) (source-span-start-line (token-span token)))
                       (butlast tokens))))))

(test line-numbers-advance-across-a-multiline-string
  (let ((tokens (read-result-objects
                 (tokenize-string (format nil "\"x~Cy~C~Cz\" w" #\Newline #\Return #\Newline)))))
    (is (eql 3 (source-span-start-line (token-span (second tokens)))))))
