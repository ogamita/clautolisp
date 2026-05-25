(in-package #:clautolisp.autolisp-reader.internal)

(defun token-to-atom-object (token)
  (ecase (token-kind token)
    (:symbol
     (make-symbol-object
      :original-name (token-lexeme token)
      :canonical-name (token-value token)
      :span (token-span token)
      :acceptance-mode (token-acceptance-mode token)))
    (:string
     (make-string-object
      :value (token-value token)
      :lexeme (token-lexeme token)
      :span (token-span token)
      :acceptance-mode (token-acceptance-mode token)))
    (:integer
     (make-integer-object
      :value (token-value token)
      :lexeme (token-lexeme token)
      :span (token-span token)
      :acceptance-mode (token-acceptance-mode token)))
    (:real
     (make-real-object
      :value (token-value token)
      :lexeme (token-lexeme token)
      :span (token-span token)
      :acceptance-mode (token-acceptance-mode token)
      :overflowed-integer-p (token-overflowed-integer-p token)))))

(defun token-to-comment-object (token)
  (make-comment-object
   :text (token-value token)
   :span (token-span token)
   :kind (if (and (>= (length (token-lexeme token)) 2)
                  (string= ";|" (subseq (token-lexeme token) 0 2)))
             :block-comment
             :line-comment)))

(defun token-to-dot-object (token)
  (make-dot-object
   :lexeme (token-lexeme token)
   :span (token-span token)))

(defun parser-error (token code message)
  (error 'simple-error
         :format-control "~A"
         :format-arguments
         (list (make-diagnostic
                :severity :error
                :code code
                :message message
                :span (and token (token-span token))))))

(defun block-comment-lexeme-p (lexeme)
  "T iff LEXEME starts with ;| and ends with |; — the AutoLISP
block-comment delimiters. Used by the parser's pending-doc track
to distinguish doc-carrying block comments from plain ; line
comments (which never carry documentation)."
  (and (>= (length lexeme) 4)
       (string= ";|" lexeme :end2 2)
       (string= "|;" lexeme :start2 (- (length lexeme) 2))))

(defun strip-block-comment-delimiters (lexeme)
  "Return the doc-string carried by a block-comment token's
LEXEME — the text between ;| and |;, with internal whitespace
and newlines preserved verbatim. Assumes LEXEME is a valid
block-comment lexeme per BLOCK-COMMENT-LEXEME-P."
  (subseq lexeme 2 (- (length lexeme) 2)))

(defun parse-form-tokens (tokens options)
  (declare (ignore options))
  ;; The pending-doc slot threads the text of the most recent
  ;; ;| ... |; block comment past intervening whitespace and ;
  ;; line comments to the next non-comment form. When the form is
  ;; a cons (the only kind that can be (defun NAME ...) or
  ;; (setq NAME ...)) the doc text is attached as the cons-object's
  ;; preceding-doc slot; the runtime side reads that slot when
  ;; evaluating the form and tags the binding cell's doc accordingly.
  ;; A second block comment before any consuming form overwrites the
  ;; pending text — only the immediately-preceding block wins.
  ;; The runtime side of the design lives in
  ;; autolisp-runtime/source/api.lisp (see *preceding-docs* and the
  ;; defun / setq handlers).
  (let ((items tokens)
        (pending-doc nil))
    (labels ((peek () (first items))
             (advance () (prog1 (first items) (setf items (rest items))))
             (consume-comments-tracking-doc ()
               (loop while (eq (token-kind (peek)) :comment)
                     for tok = (advance)
                     do (let ((lex (token-lexeme tok)))
                          (when (block-comment-lexeme-p lex)
                            (setf pending-doc
                                  (strip-block-comment-delimiters lex))))))
             (take-pending-doc ()
               (let ((d pending-doc))
                 (setf pending-doc nil)
                 d))
             (parse-form ()
               (consume-comments-tracking-doc)
               (let ((token (peek)))
                 (case (token-kind token)
                   ((:symbol :string :integer :real)
                    ;; Atom — drop any pending doc; only cons forms
                    ;; carry documentation under this design.
                    (take-pending-doc)
                    (advance)
                    (token-to-atom-object token))
                   (:quote
                    (take-pending-doc)
                    (let ((quote-token (advance))
                          (payload (parse-form)))
                      (make-quote-object
                       :object payload
                       :span (combine-spans (token-span quote-token)
                                            (object-span payload)))))
                   (:left-paren
                    (let ((doc (take-pending-doc))
                          (cons (parse-list)))
                      (when doc
                        (setf (cons-object-preceding-doc cons) doc))
                      cons))
                   (:dot
                    (parser-error token :misplaced-dot
                                  "Dot token is only valid in dotted-pair position."))
                   (:right-paren
                    (parser-error token :unexpected-right-paren
                                  "Unexpected right parenthesis."))
                   (:eof
                    (parser-error token :unexpected-eof
                                  "Unexpected end of input."))
                   (otherwise
                    (parser-error token :unexpected-token
                                  "Unexpected token.")))))
             (parse-list ()
               (let ((open-token (advance))
                     (elements '())
                     (tail nil)
                     (dotted-p nil))
                 (loop
                   (consume-comments-tracking-doc)
                   (let ((token (peek)))
                     (case (token-kind token)
                       (:right-paren
                        ;; A trailing block comment between the last
                        ;; element and the close-paren has no form to
                        ;; attach to — drop it.
                        (take-pending-doc)
                        (advance)
                        (return
                          (make-cons-object
                           :elements (nreverse elements)
                           :tail tail
                           :dotted-p dotted-p
                           :span (combine-spans (token-span open-token)
                                                (token-span token)))))
                       (:dot
                        (when (or dotted-p (null elements))
                          (parser-error token :misplaced-dot
                                        "Misplaced dot in list syntax."))
                        (take-pending-doc)
                        (advance)
                        (setf dotted-p t)
                        (setf tail (parse-form))
                        (consume-comments-tracking-doc)
                        (take-pending-doc)
                        (unless (eq (token-kind (peek)) :right-paren)
                          (parser-error (peek) :dotted-tail-extra
                                        "Dotted pair must have exactly one tail object."))
                        nil)
                       (:eof
                        (parser-error token :unexpected-eof
                                      "Unexpected end of input inside list."))
                       (otherwise
                        (when dotted-p
                          (parser-error token :dotted-tail-extra
                                        "Dotted pair must have exactly one tail object."))
                        (push (parse-form) elements)))))))
             (object-span (object)
               (typecase object
                 (symbol-object (symbol-object-span object))
                 (string-object (string-object-span object))
                 (integer-object (integer-object-span object))
                 (real-object (real-object-span object))
                 (comment-object (comment-object-span object))
                 (dot-object (dot-object-span object))
                 (cons-object (cons-object-span object))
                 (quote-object (quote-object-span object))
                 (concrete-list-object (concrete-list-object-span object))
                 (t nil))))
      (let ((objects '()))
        (consume-comments-tracking-doc)
        (loop until (eq (token-kind (peek)) :eof)
              do (push (parse-form) objects)
                 (consume-comments-tracking-doc))
        ;; Trailing block comments at end of file with no following
        ;; form are dropped.
        (take-pending-doc)
        (nreverse objects)))))

(defun parse-concrete-tokens (tokens options)
  (declare (ignore options))
  (let ((items tokens))
    (labels ((peek () (first items))
             (advance () (prog1 (first items) (setf items (rest items))))
             (parse-object ()
               (let ((token (peek)))
                 (case (token-kind token)
                   (:comment
                    (advance)
                    (token-to-comment-object token))
                   (:dot
                    (advance)
                    (token-to-dot-object token))
                   ((:symbol :string :integer :real)
                    (advance)
                    (token-to-atom-object token))
                   (:quote
                    (let ((quote-token (advance))
                          (payload (parse-object)))
                      (make-quote-object
                       :object payload
                       :span (combine-spans (token-span quote-token)
                                            (object-span payload)))))
                   (:left-paren
                    (parse-list))
                   (:right-paren
                    (parser-error token :unexpected-right-paren
                                  "Unexpected right parenthesis in concrete syntax stream."))
                   (:eof nil)
                   (otherwise
                    (parser-error token :unexpected-token
                                  "Unexpected token in concrete syntax stream.")))))
             (parse-list ()
               (let ((open-token (advance))
                     (children '()))
                 (loop
                   (let ((token (peek)))
                     (case (token-kind token)
                       (:right-paren
                        (advance)
                        (return
                          (make-concrete-list-object
                           :items (nreverse children)
                           :span (combine-spans (token-span open-token)
                                                (token-span token)))))
                       (:eof
                        (parser-error token :unexpected-eof
                                      "Unexpected end of input inside concrete list."))
                       (otherwise
                        (push (parse-object) children)))))))
             (object-span (object)
               (typecase object
                 (symbol-object (symbol-object-span object))
                 (string-object (string-object-span object))
                 (integer-object (integer-object-span object))
                 (real-object (real-object-span object))
                 (comment-object (comment-object-span object))
                 (dot-object (dot-object-span object))
                 (cons-object (cons-object-span object))
                 (quote-object (quote-object-span object))
                 (concrete-list-object (concrete-list-object-span object))
                 (t nil))))
      (let ((objects '()))
        (loop for object = (parse-object)
              while object
              do (push object objects))
        (nreverse objects)))))
