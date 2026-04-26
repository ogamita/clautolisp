(in-package #:clautolisp.autolisp-reader.internal)

(defconstant +int32-min+ -2147483648)
(defconstant +int32-max+ 2147483647)

(defun whitespace-char-p (ch)
  (or (char= ch #\Space)
      (char= ch #\Tab)
      (char= ch #\Page)
      (char= ch #\Newline)))

(defun delimiter-char-p (ch)
  (or (whitespace-char-p ch)
      (member ch '(#\( #\) #\' #\" #\;))))

(defun canonicalize-symbol-name (name options)
  (ecase (reader-options-canonical-case options)
    (:upcase (string-upcase name))
    (:downcase (string-downcase name))
    (:preserve name)))

(defun digit-char-10-p (ch)
  (and ch (digit-char-p ch 10)))

(defun strict-integer-lexeme-p (lexeme)
  (let* ((length (length lexeme))
         (start (if (and (> length 0)
                         (member (char lexeme 0) '(#\+ #\-)))
                    1
                    0)))
    (and (> length start)
         (loop for index from start below length
               always (digit-char-10-p (char lexeme index))))))

(defun exponent-part-valid-p (lexeme exp-pos)
  (let* ((length (length lexeme))
         (exp-start (1+ exp-pos)))
    (when (and (< exp-start length)
               (member (char lexeme exp-start) '(#\+ #\-)))
      (incf exp-start))
    (and (< exp-start length)
         (loop for index from exp-start below length
               always (digit-char-10-p (char lexeme index))))))

(defun strict-real-lexeme-p (lexeme)
  (let* ((length (length lexeme))
         (start (if (and (> length 0)
                         (member (char lexeme 0) '(#\+ #\-)))
                    1
                    0))
         (dot-pos (position #\. lexeme))
         (exp-pos (or (position #\e lexeme) (position #\E lexeme)))
         (fraction-end (or exp-pos length)))
    (and dot-pos
         (> dot-pos start)
         (> fraction-end (1+ dot-pos))
         (or (null exp-pos) (< dot-pos exp-pos))
         (loop for index from start below dot-pos
               always (digit-char-10-p (char lexeme index)))
         (loop for index from (1+ dot-pos) below fraction-end
               always (digit-char-10-p (char lexeme index)))
         (if exp-pos
             (exponent-part-valid-p lexeme exp-pos)
             t))))

(defun lax-real-lexeme-p (lexeme)
  (let* ((length (length lexeme))
         (start (if (and (> length 0)
                         (member (char lexeme 0) '(#\+ #\-)))
                    1
                    0))
         (dot-pos (position #\. lexeme))
         (exp-pos (or (position #\e lexeme) (position #\E lexeme))))
    (cond
      ((strict-real-lexeme-p lexeme) t)
      ((and dot-pos
            (or (null exp-pos) (< dot-pos exp-pos)))
       (let ((fraction-end (or exp-pos length)))
         (and (or (> dot-pos start)
                  (> fraction-end (1+ dot-pos)))
              (loop for index from start below dot-pos
                    always (digit-char-10-p (char lexeme index)))
              (loop for index from (1+ dot-pos) below fraction-end
                    always (digit-char-10-p (char lexeme index)))
              (if exp-pos
                  (exponent-part-valid-p lexeme exp-pos)
                  t))))
      ((and exp-pos
            (> exp-pos start)
            (loop for index from start below exp-pos
                  always (digit-char-10-p (char lexeme index))))
       (exponent-part-valid-p lexeme exp-pos))
      (t nil))))

(defun parse-real-lexeme (lexeme)
  (with-safe-io-syntax ()
    (let ((value (read-from-string lexeme)))
      (coerce value 'double-float))))

(defun make-span (options start-line start-column end-line end-column)
  (make-source-span
   :source-name (reader-options-source-name options)
   :start-line start-line
   :start-column start-column
   :end-line end-line
   :end-column end-column))

(defun hex-digit-p (ch)
  (and ch (digit-char-p ch 16)))

(defun recover-after-string-error (text index line column)
  (let ((length (length text)))
    (loop while (< index length)
          for ch = (char text index)
          do (cond
               ((char= ch #\Newline)
                (incf index)
                (incf line)
                (setf column 1))
               ((char= ch #\")
                (return (values (1+ index) line (1+ column))))
               (t
                (incf index)
                (incf column))))
    (values index line column)))

(defun scan-unicode-escape (text backslash-index line column options)
  (let* ((length (length text))
         (u-index (1+ backslash-index))
         (plus-index (1+ u-index))
         (digit-start (1+ plus-index)))
    (unless (and (< plus-index length)
                 (char-equal (char text u-index) #\u)
                 (char= (char text plus-index) #\+))
      (return-from scan-unicode-escape
        (values nil backslash-index line column nil)))
    (let ((digit-end (+ digit-start 4)))
      (unless (and (<= digit-end length)
                   (loop for index from digit-start below digit-end
                         always (hex-digit-p (char text index))))
        (let ((end-column (+ column (- digit-end backslash-index))))
          (return-from scan-unicode-escape
            (values nil
                    digit-end
                    line
                    end-column
                    (list
                     (make-diagnostic
                      :severity :error
                      :code :invalid-unicode-escape
                      :message "Unicode escape must use \\u+ followed by at least four hexadecimal digits."
                      :span (make-span options line column line end-column)))))))
      (let* ((digits (subseq text digit-start digit-end))
             (code (parse-integer digits :radix 16))
             (character (code-char code))
             (next-column (+ column (- digit-end backslash-index))))
        (unless character
          (return-from scan-unicode-escape
            (values nil
                    digit-end
                    line
                    next-column
                    (list
                     (make-diagnostic
                      :severity :error
                      :code :invalid-unicode-codepoint
                      :message "Unicode escape does not designate a valid character."
                      :span (make-span options line column line next-column))))))
        (values character digit-end line next-column '())))))

(defun scan-string-literal (text start-index line column options)
  (let ((length (length text))
        (index (1+ start-index))
        (value-out (make-string-output-stream))
        (line0 line)
        (col0 column))
    (loop
      (when (>= index length)
        (return (values nil
                        index
                        line
                        column
                        (list
                         (make-diagnostic
                          :severity :error
                          :code :unterminated-string
                          :message "Unterminated string literal."
                          :span (make-span
                                 options line0 col0 line column))))))
      (let ((ch (char text index)))
        (cond
          ((char= ch #\")
           (if (and (< (1+ index) length)
                    (char= (char text (1+ index)) #\"))
               (progn
                 (write-char #\" value-out)
                 (incf index 2)
                 (incf column 2))
               (let* ((end-index (1+ index))
                      (end-column (1+ column))
                      (lexeme (subseq text start-index end-index)))
                 (return
                   (values
                    (make-token
                     :kind :string
                     :lexeme lexeme
                     :value (get-output-stream-string value-out)
                     :span (make-span options line0 col0 line end-column)
                    :acceptance-mode :strict)
                    end-index
                    line
                    end-column
                    '())))))
          ;; Universal AutoLISP / Visual LISP single-character string
          ;; escapes. These are recognised in every dialect, not only
          ;; under extended-string-escapes-p; vendor reference pages
          ;; for PRINC, PRIN1, and string syntax document them as the
          ;; baseline.
          ((and (char= ch #\\)
                (< (1+ index) length)
                (member (char text (1+ index))
                        '(#\\ #\" #\n #\t #\r #\e #\0)))
           (let ((escape (char text (1+ index))))
             (write-char (case escape
                           (#\n #\Newline)
                           (#\t #\Tab)
                           (#\r #\Return)
                           (#\e (code-char 27))
                           (#\0 (code-char 0))
                           (otherwise escape))
                         value-out))
           (incf index 2)
           (incf column 2))
          ((and (char= ch #\\)
                (reader-options-extended-string-escapes-p options))
           (when (>= (1+ index) length)
             (return
               (values nil
                       (1+ index)
                       line
                       (1+ column)
                       (list
                        (make-diagnostic
                         :severity :error
                         :code :dangling-string-escape
                         :message "Dangling escape at end of string literal."
                         :span (make-span options line column line (1+ column)))))))
           (multiple-value-bind (unicode-char next-index next-line next-column diags)
               (scan-unicode-escape text index line column options)
             (cond
               (diags
                (multiple-value-bind (recovered-index recovered-line recovered-column)
                    (recover-after-string-error text next-index next-line next-column)
                  (return (values nil
                                  recovered-index
                                  recovered-line
                                  recovered-column
                                  diags))))
               (unicode-char
                (write-char unicode-char value-out)
                (setf index next-index
                      line next-line
                      column next-column))
               (t
                (write-char (char text (1+ index)) value-out)
                (incf index 2)
                (incf column 2)))))
          (t
           (write-char ch value-out)
           (incf index)
           (incf column)))))))

(defun scan-comment (text start-index line column options)
  (let ((length (length text)))
    (if (and (< (1+ start-index) length)
             (char= (char text (1+ start-index)) #\|))
        (scan-block-comment text start-index line column options)
        (scan-line-comment text start-index line column options))))

(defun scan-line-comment (text start-index line column options)
  (let ((length (length text))
        (index start-index)
        (column0 column))
    (loop while (and (< index length)
                     (not (char= (char text index) #\Newline)))
          do (incf index)
             (incf column))
    (values
     (make-token
      :kind :comment
      :lexeme (subseq text start-index index)
      :value (subseq text start-index index)
      :span (make-span options line column0 line column)
      :acceptance-mode :strict)
     index
     line
     column
     '())))

(defun scan-block-comment (text start-index line column options)
  (let ((length (length text))
        (index (+ start-index 2))
        (line0 line)
        (column0 column))
    (incf column 2)
    (loop
      (when (>= index length)
        (return
          (values nil
                  index
                  line
                  column
                  (list
                   (make-diagnostic
                    :severity :error
                    :code :unterminated-block-comment
                    :message "Unterminated block comment."
                    :span (make-span options line0 column0 line column))))))
      (let ((ch (char text index)))
        (cond
          ((and (char= ch #\|)
                (< (1+ index) length)
                (char= (char text (1+ index)) #\;))
           (let ((end-index (+ index 2))
                 (end-column (+ column 2)))
             (return
               (values
                (make-token
                 :kind :comment
                 :lexeme (subseq text start-index end-index)
                 :value (subseq text start-index end-index)
                 :span (make-span options line0 column0 line end-column)
                 :acceptance-mode :strict)
                end-index
                line
                end-column
                '()))))
          ((char= ch #\Newline)
           (incf index)
           (incf line)
           (setf column 1))
          (t
           (incf index)
           (incf column)))))))

(defun classify-lexeme-token (lexeme span options)
  (let* ((strictp (eq (reader-options-token-mode options) :strict))
         (acceptance-mode (if strictp :strict :lax)))
    (cond
      ((strict-integer-lexeme-p lexeme)
       (let ((integer-value (parse-integer lexeme)))
         (if (<= +int32-min+ integer-value +int32-max+)
             (values
              (make-token
               :kind :integer
               :lexeme lexeme
               :value integer-value
               :span span
               :acceptance-mode :strict)
              '())
             (values
              (make-token
               :kind :real
               :lexeme lexeme
               :value (coerce integer-value 'double-float)
               :span span
               :acceptance-mode :strict
               :overflowed-integer-p t)
              (if (reader-options-warn-on-integer-overflow-p options)
                  (list
                   (make-diagnostic
                    :severity :warning
                    :code :integer-overflow-read-as-real
                    :message
                    "Integer-shaped token is outside signed 32-bit range and was read as a real."
                    :span span))
                  '())))))
      ((strict-real-lexeme-p lexeme)
       (values
        (make-token
         :kind :real
         :lexeme lexeme
         :value (parse-real-lexeme lexeme)
         :span span
         :acceptance-mode :strict)
        '()))
      ((and (not strictp)
            (lax-real-lexeme-p lexeme))
       (values
        (make-token
         :kind :real
         :lexeme lexeme
         :value (parse-real-lexeme lexeme)
         :span span
         :acceptance-mode :lax)
        '()))
      (t
       (values
        (make-token
         :kind :symbol
         :lexeme lexeme
         :value (canonicalize-symbol-name lexeme options)
         :span span
         :acceptance-mode acceptance-mode)
        '())))))

(defun scan-bare-token (text start-index line column options)
  (let ((length (length text))
        (index start-index)
        (line0 line)
        (col0 column))
    (loop while (and (< index length)
                     (not (delimiter-char-p (char text index)))
                     (not (member (char text index) '(#\( #\) #\'))))
          do (incf index)
             (incf column))
    (let* ((lexeme (subseq text start-index index))
           (span (make-span options line0 col0 line column)))
      (if (string= lexeme ".")
          (values
           (make-token
            :kind :dot
            :lexeme lexeme
            :value lexeme
            :span span
            :acceptance-mode :strict)
           index
           line
           column
           '())
          (multiple-value-bind (token diagnostics)
              (classify-lexeme-token lexeme span options)
            (values token index line column diagnostics))))))

(defun scan-tokens (text options)
  (let ((tokens '())
        (diagnostics '())
        (length (length text))
        (index 0)
        (line 1)
        (column 1))
    (labels ((emit (token)
               (push token tokens))
             (emit-diagnostics (items)
               (setf diagnostics (nconc diagnostics items))))
      (loop while (< index length)
            do (let ((ch (char text index)))
                 (cond
                   ((whitespace-char-p ch)
                    (if (char= ch #\Newline)
                        (progn
                          (incf index)
                          (incf line)
                          (setf column 1))
                        (progn
                          (incf index)
                          (incf column))))
                   ((char= ch #\;)
                    (multiple-value-bind (token next-index next-line next-column diags)
                        (scan-comment text index line column options)
                      (when (reader-options-retain-comments-p options)
                        (emit token))
                      (emit-diagnostics diags)
                      (setf index next-index
                            line next-line
                            column next-column)))
                   ((char= ch #\()
                    (emit (make-token :kind :left-paren
                                      :lexeme "("
                                      :value "("
                                      :span (make-span options line column line (1+ column))
                                      :acceptance-mode :strict))
                    (incf index)
                    (incf column))
                   ((char= ch #\))
                    (emit (make-token :kind :right-paren
                                      :lexeme ")"
                                      :value ")"
                                      :span (make-span options line column line (1+ column))
                                      :acceptance-mode :strict))
                    (incf index)
                    (incf column))
                   ((char= ch #\')
                    (emit (make-token :kind :quote
                                      :lexeme "'"
                                      :value "'"
                                      :span (make-span options line column line (1+ column))
                                      :acceptance-mode :strict))
                    (incf index)
                    (incf column))
                   ((char= ch #\")
                    (multiple-value-bind (token next-index next-line next-column diags)
                        (scan-string-literal text index line column options)
                      (when token
                        (emit token))
                      (emit-diagnostics diags)
                      (setf index next-index
                            line next-line
                            column next-column)))
                   (t
                    (multiple-value-bind (token next-index next-line next-column diags)
                        (scan-bare-token text index line column options)
                      (emit token)
                      (emit-diagnostics diags)
                      (setf index next-index
                            line next-line
                            column next-column))))))
      (emit (make-token :kind :eof
                        :lexeme ""
                        :value nil
                        :span (make-span options line column line column)
                        :acceptance-mode :strict)))
    (values (nreverse tokens) diagnostics)))
