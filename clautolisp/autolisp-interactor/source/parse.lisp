;;;; The command-line parser.
;;;;
;;;; A command line is a list of whitespace-separated tokens:
;;;;
;;;;   command ::= name { ident | integer | float | string | token } .
;;;;
;;;;   ident   ::= /[A-Za-z][-A-Za-z0-9]*/ .
;;;;   integer ::= /[-+]?[0-9]+/ .
;;;;   float   ::= /[-+]?[0-9]+(\.[0-9]*)?(e[-+]?[0-9]+)?/ .
;;;;   string  ::= /"([^\"]|\[\"])*"/ .
;;;;   token   ::= /[^ ]+/ .
;;;;
;;;; Case is preserved. A string lets us include spaces in a token; any other
;;;; non-whitespace run not matching ident/integer/float is a token. The
;;;; command NAME is usually an ident, but a punctuation token (`.', `>>',
;;;; `?') or a signed integer (the navigators' ±N motion) is accepted too —
;;;; only a string cannot name a command.

(in-package #:clautolisp.interactor)

(define-condition command-syntax-error (error)
  ((command :initarg :command :reader command-syntax-error-command)
   (position :initarg :position :reader command-syntax-error-position))
  (:report (lambda (condition stream)
             (format stream "Command syntax error at position ~D in ~S"
                     (command-syntax-error-position condition)
                     (command-syntax-error-command condition)))))

(define-condition simple-command-syntax-error (command-syntax-error simple-error)
  ())

(defun parse-command (command &key (start 0) (end nil) lenient)
  "Parse COMMAND (between START and END) into a list of (TYPE . TEXT) conses,
TYPE one of IDENT, INTEGER, FLOAT, STRING or TOKEN; TEXT the token's
characters (a STRING's content is decoded: quotes stripped, \\\\ and \\\"
unescaped). Signals COMMAND-SYNTAX-ERROR on a malformed string, or when the
first token is a string. With LENIENT true, a malformed string degrades to a
plain TOKEN instead of signaling — the readers use this so a command whose
raw argument embeds a Lisp form (`condition 3 (equal s \"a  b\")`) still
reads; such tokens are approximate, but a raw (&WHOLE) command takes its
argument from the raw line anyway.

Examples:
    break 42          --> ((ident . \"break\") (integer . \"42\"))
    list source       --> ((ident . \"list\") (ident . \"source\"))
    b source.lsp:33   --> ((ident . \"b\") (token . \"source.lsp:33\"))
    b \"/path with spaces/f.lsp:143\"
                      --> ((ident . \"b\") (string . \"/path with spaces/f.lsp:143\"))"
  (check-type command string)
  (check-type start (integer 0))
  (check-type end (or null (integer 0)))
  (let ((end (or end (length command)))
        (index start)
        (tokens '()))
    (labels ((whitespacep (ch)
               (or (char= ch #\space) (char= ch #\tab)))
             (ascii-letter-p (ch)
               (or (char<= #\A ch #\Z) (char<= #\a ch #\z)))
             (ascii-digit-p (ch)
               (char<= #\0 ch #\9))
             (syntax-error (position)
               (error 'command-syntax-error
                      :command command
                      :position position))
             (integerp* (text)
               ;; /[-+]?[0-9]+/
               (let ((n (length text)) (i 0))
                 (when (and (< i n) (member (char text i) '(#\+ #\-)))
                   (incf i))
                 (let ((start-digits i))
                   (loop :while (and (< i n) (ascii-digit-p (char text i)))
                         :do (incf i))
                   ;; at least one digit, and the whole text consumed.
                   (and (> i start-digits) (= i n)))))
             (floatp* (text)
               ;; /[-+]?[0-9]+(\.[0-9]*)?(e[-+]?[0-9]+)?/
               (let ((n (length text)) (i 0))
                 (when (and (< i n) (member (char text i) '(#\+ #\-)))
                   (incf i))
                 ;; mantissa: at least one digit is required
                 (let ((start-digits i))
                   (loop :while (and (< i n) (ascii-digit-p (char text i)))
                         :do (incf i))
                   (when (= i start-digits)
                     (return-from floatp* nil)))
                 ;; optional fractional part
                 (when (and (< i n) (char= (char text i) #\.))
                   (incf i)
                   (loop :while (and (< i n) (ascii-digit-p (char text i)))
                         :do (incf i)))
                 ;; optional exponent
                 (when (and (< i n) (char-equal (char text i) #\e))
                   (incf i)
                   (when (and (< i n) (member (char text i) '(#\+ #\-)))
                     (incf i))
                   (let ((start-exp i))
                     (loop :while (and (< i n) (ascii-digit-p (char text i)))
                           :do (incf i))
                     (when (= i start-exp)
                       (return-from floatp* nil))))
                 (= i n)))
             (classify (text)
               ;; The order matters: integer before float, because "42"
               ;; matches both the integer and the (looser) float regexp.
               ;; The ident rule /[A-Za-z][-A-Za-z0-9]*/ is IDENT-TEXT-P
               ;; (command.lisp), shared with the IDENT argument conversion.
               (cond ((ident-text-p text) 'ident)
                     ((integerp* text) 'integer)
                     ((floatp* text)   'float)
                     (t                'token)))
             (parse-string ()
               ;; INDEX points at the opening double-quote.  Consume up to
               ;; and including the closing (unescaped) double-quote, and
               ;; return the decoded content (quotes stripped, \\ and \"
               ;; unescaped).
               (let ((open index)
                     (out (make-string-output-stream)))
                 (incf index)           ; skip opening quote
                 (loop
                   (when (>= index end)
                     ;; end-of-command while still inside a string.
                     (syntax-error open))
                   (let ((ch (char command index)))
                     (cond
                       ((char= ch #\")
                        (incf index)    ; skip closing quote
                        (return))
                       ((char= ch #\\)
                        (incf index)
                        (when (>= index end)
                          (syntax-error open))
                        (let ((escaped (char command index)))
                          (unless (or (char= escaped #\\) (char= escaped #\"))
                            ;; only \\ and \" are valid escapes.
                            (syntax-error (1- index)))
                          (write-char escaped out)
                          (incf index)))
                       (t
                        (write-char ch out)
                        (incf index)))))
                 ;; A string is a whole token: it must be followed by
                 ;; whitespace or end-of-command.
                 (when (and (< index end) (not (whitespacep (char command index))))
                   (syntax-error index))
                 (get-output-stream-string out)))
             (parse-token ()
               ;; A maximal run of non-whitespace characters.
               (let ((first index))
                 (loop :while (and (< index end)
                                   (not (whitespacep (char command index))))
                       :do (incf index))
                 (subseq command first index))))
      ;; skip leading whitespace
      (loop :while (and (< index end) (whitespacep (char command index)))
            :do (incf index))
      (loop
        (when (>= index end)
          (return))
        (if (char= (char command index) #\")
            (let* ((position index)
                   (content (if lenient
                                (handler-case (parse-string)
                                  (command-syntax-error ()
                                    (setf index position)
                                    nil))
                                (parse-string))))
              (if content
                  (progn
                    (push (cons 'string content) tokens)
                    ;; a string can never name a command, so it cannot be
                    ;; the first token.
                    (when (null (rest tokens))
                      (syntax-error position)))
                  ;; lenient: the malformed string is a plain token
                  (let ((text (parse-token)))
                    (push (cons 'token text) tokens))))
            (let ((text (parse-token)))
              (push (cons (classify text) text) tokens)))
        ;; skip whitespace separating tokens
        (loop :while (and (< index end) (whitespacep (char command index)))
              :do (incf index)))
      (nreverse tokens))))
