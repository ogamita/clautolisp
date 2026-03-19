(in-package #:clautolisp.autolisp-reader.internal)

(defun ensure-reader-options (options &rest initargs)
  (if options
      (apply #'clone-reader-options options initargs)
      (apply #'make-reader-options initargs)))

(defun tokenize-normalized-text (text options)
  (multiple-value-bind (tokens diagnostics)
      (scan-tokens text options)
    (make-read-result :objects tokens :diagnostics diagnostics)))

(defun parse-normalized-text (text options parser)
  (multiple-value-bind (tokens diagnostics)
      (scan-tokens text options)
    (make-read-result
     :objects (funcall parser tokens options)
     :diagnostics diagnostics)))

(in-package #:clautolisp.autolisp-reader)

(deftype reader-options ()
  'clautolisp.autolisp-reader.internal::reader-options)

(deftype source-span ()
  'clautolisp.autolisp-reader.internal::source-span)

(deftype diagnostic ()
  'clautolisp.autolisp-reader.internal::diagnostic)

(deftype token ()
  'clautolisp.autolisp-reader.internal::token)

(deftype comment-object ()
  'clautolisp.autolisp-reader.internal::comment-object)

(deftype dot-object ()
  'clautolisp.autolisp-reader.internal::dot-object)

(deftype symbol-object ()
  'clautolisp.autolisp-reader.internal::symbol-object)

(deftype string-object ()
  'clautolisp.autolisp-reader.internal::string-object)

(deftype integer-object ()
  'clautolisp.autolisp-reader.internal::integer-object)

(deftype real-object ()
  'clautolisp.autolisp-reader.internal::real-object)

(deftype cons-object ()
  'clautolisp.autolisp-reader.internal::cons-object)

(deftype quote-object ()
  'clautolisp.autolisp-reader.internal::quote-object)

(deftype concrete-list-object ()
  'clautolisp.autolisp-reader.internal::concrete-list-object)

(deftype read-result ()
  'clautolisp.autolisp-reader.internal::read-result)

(defun make-reader-options (&rest args)
  (apply #'clautolisp.autolisp-reader.internal:make-reader-options args))

(defun reader-options-token-mode (options)
  (clautolisp.autolisp-reader.internal::reader-options-token-mode options))

(defun reader-options-retain-comments-p (options)
  (clautolisp.autolisp-reader.internal::reader-options-retain-comments-p options))

(defun reader-options-recover-malformed-p (options)
  (clautolisp.autolisp-reader.internal::reader-options-recover-malformed-p options))

(defun reader-options-warn-on-integer-overflow-p (options)
  (clautolisp.autolisp-reader.internal::reader-options-warn-on-integer-overflow-p options))

(defun reader-options-extended-string-escapes-p (options)
  (clautolisp.autolisp-reader.internal::reader-options-extended-string-escapes-p options))

(defun reader-options-canonical-case (options)
  (clautolisp.autolisp-reader.internal::reader-options-canonical-case options))

(defun reader-options-source-name (options)
  (clautolisp.autolisp-reader.internal::reader-options-source-name options))

(defun source-span-source-name (span)
  (clautolisp.autolisp-reader.internal::source-span-source-name span))

(defun source-span-start-line (span)
  (clautolisp.autolisp-reader.internal::source-span-start-line span))

(defun source-span-start-column (span)
  (clautolisp.autolisp-reader.internal::source-span-start-column span))

(defun source-span-end-line (span)
  (clautolisp.autolisp-reader.internal::source-span-end-line span))

(defun source-span-end-column (span)
  (clautolisp.autolisp-reader.internal::source-span-end-column span))

(defun diagnostic-severity (diagnostic)
  (clautolisp.autolisp-reader.internal::diagnostic-severity diagnostic))

(defun diagnostic-code (diagnostic)
  (clautolisp.autolisp-reader.internal::diagnostic-code diagnostic))

(defun diagnostic-message (diagnostic)
  (clautolisp.autolisp-reader.internal::diagnostic-message diagnostic))

(defun diagnostic-span (diagnostic)
  (clautolisp.autolisp-reader.internal::diagnostic-span diagnostic))

(defun token-kind (token)
  (clautolisp.autolisp-reader.internal::token-kind token))

(defun token-lexeme (token)
  (clautolisp.autolisp-reader.internal::token-lexeme token))

(defun token-value (token)
  (clautolisp.autolisp-reader.internal::token-value token))

(defun token-span (token)
  (clautolisp.autolisp-reader.internal::token-span token))

(defun token-acceptance-mode (token)
  (clautolisp.autolisp-reader.internal::token-acceptance-mode token))

(defun token-overflowed-integer-p (token)
  (clautolisp.autolisp-reader.internal::token-overflowed-integer-p token))

(defun comment-object-text (object)
  (clautolisp.autolisp-reader.internal::comment-object-text object))

(defun comment-object-span (object)
  (clautolisp.autolisp-reader.internal::comment-object-span object))

(defun comment-object-kind (object)
  (clautolisp.autolisp-reader.internal::comment-object-kind object))

(defun dot-object-lexeme (object)
  (clautolisp.autolisp-reader.internal::dot-object-lexeme object))

(defun dot-object-span (object)
  (clautolisp.autolisp-reader.internal::dot-object-span object))

(defun symbol-object-original-name (object)
  (clautolisp.autolisp-reader.internal::symbol-object-original-name object))

(defun symbol-object-canonical-name (object)
  (clautolisp.autolisp-reader.internal::symbol-object-canonical-name object))

(defun symbol-object-span (object)
  (clautolisp.autolisp-reader.internal::symbol-object-span object))

(defun symbol-object-acceptance-mode (object)
  (clautolisp.autolisp-reader.internal::symbol-object-acceptance-mode object))

(defun string-object-value (object)
  (clautolisp.autolisp-reader.internal::string-object-value object))

(defun string-object-lexeme (object)
  (clautolisp.autolisp-reader.internal::string-object-lexeme object))

(defun string-object-span (object)
  (clautolisp.autolisp-reader.internal::string-object-span object))

(defun string-object-acceptance-mode (object)
  (clautolisp.autolisp-reader.internal::string-object-acceptance-mode object))

(defun integer-object-value (object)
  (clautolisp.autolisp-reader.internal::integer-object-value object))

(defun integer-object-lexeme (object)
  (clautolisp.autolisp-reader.internal::integer-object-lexeme object))

(defun integer-object-span (object)
  (clautolisp.autolisp-reader.internal::integer-object-span object))

(defun integer-object-acceptance-mode (object)
  (clautolisp.autolisp-reader.internal::integer-object-acceptance-mode object))

(defun real-object-value (object)
  (clautolisp.autolisp-reader.internal::real-object-value object))

(defun real-object-lexeme (object)
  (clautolisp.autolisp-reader.internal::real-object-lexeme object))

(defun real-object-span (object)
  (clautolisp.autolisp-reader.internal::real-object-span object))

(defun real-object-acceptance-mode (object)
  (clautolisp.autolisp-reader.internal::real-object-acceptance-mode object))

(defun real-object-overflowed-integer-p (object)
  (clautolisp.autolisp-reader.internal::real-object-overflowed-integer-p object))

(defun cons-object-elements (object)
  (clautolisp.autolisp-reader.internal::cons-object-elements object))

(defun cons-object-tail (object)
  (clautolisp.autolisp-reader.internal::cons-object-tail object))

(defun cons-object-dotted-p (object)
  (clautolisp.autolisp-reader.internal::cons-object-dotted-p object))

(defun cons-object-span (object)
  (clautolisp.autolisp-reader.internal::cons-object-span object))

(defun quote-object-object (object)
  (clautolisp.autolisp-reader.internal::quote-object-object object))

(defun quote-object-span (object)
  (clautolisp.autolisp-reader.internal::quote-object-span object))

(defun concrete-list-object-items (object)
  (clautolisp.autolisp-reader.internal::concrete-list-object-items object))

(defun concrete-list-object-span (object)
  (clautolisp.autolisp-reader.internal::concrete-list-object-span object))

(defun read-result-objects (result)
  (clautolisp.autolisp-reader.internal::read-result-objects result))

(defun read-result-diagnostics (result)
  (clautolisp.autolisp-reader.internal::read-result-diagnostics result))

(defun tokenize-string (text &key options (token-mode :strict) retain-comments-p
                               warn-on-integer-overflow-p
                               extended-string-escapes-p
                               source-name)
  (let* ((effective-options
           (clautolisp.autolisp-reader.internal::ensure-reader-options
            options
            :token-mode token-mode
            :retain-comments-p retain-comments-p
            :warn-on-integer-overflow-p warn-on-integer-overflow-p
            :extended-string-escapes-p extended-string-escapes-p
            :source-name source-name))
         (normalized
           (clautolisp.autolisp-reader.internal:normalize-line-endings text)))
    (clautolisp.autolisp-reader.internal::tokenize-normalized-text
     normalized effective-options)))

(defun tokenize-stream (stream &key options (token-mode :strict) retain-comments-p
                                 warn-on-integer-overflow-p
                                 extended-string-escapes-p
                                 source-name)
  (tokenize-string
   (clautolisp.autolisp-reader.internal:decode-and-normalize-stream stream)
   :options options
   :token-mode token-mode
   :retain-comments-p retain-comments-p
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name source-name))

(defun tokenize-file (path &key options (token-mode :strict) retain-comments-p
                               warn-on-integer-overflow-p source-name
                               extended-string-escapes-p
                               external-format)
  (tokenize-string
   (if external-format
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file
        path :external-format external-format)
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file path))
   :options options
   :token-mode token-mode
   :retain-comments-p retain-comments-p
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name (or source-name (namestring path))))

(defun read-forms-from-string (text &key options (token-mode :strict)
                                    warn-on-integer-overflow-p
                                    extended-string-escapes-p
                                    source-name)
  (let ((effective-options
          (clautolisp.autolisp-reader.internal::ensure-reader-options
           options
           :token-mode token-mode
           :retain-comments-p nil
           :warn-on-integer-overflow-p warn-on-integer-overflow-p
           :extended-string-escapes-p extended-string-escapes-p
           :source-name source-name)))
    (clautolisp.autolisp-reader.internal::parse-normalized-text
     (clautolisp.autolisp-reader.internal:normalize-line-endings text)
     effective-options
     #'clautolisp.autolisp-reader.internal:parse-form-tokens)))

(defun read-forms-from-stream (stream &key options (token-mode :strict)
                                      warn-on-integer-overflow-p
                                      extended-string-escapes-p
                                      source-name)
  (read-forms-from-string
   (clautolisp.autolisp-reader.internal:decode-and-normalize-stream stream)
   :options options
   :token-mode token-mode
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name source-name))

(defun read-forms-from-file (path &key options (token-mode :strict)
                                       warn-on-integer-overflow-p source-name
                                       extended-string-escapes-p
                                       external-format)
  (read-forms-from-string
   (if external-format
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file
        path :external-format external-format)
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file path))
   :options options
   :token-mode token-mode
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name (or source-name (namestring path))))

(defun read-concrete-from-string (text &key options (token-mode :strict)
                                       warn-on-integer-overflow-p
                                       extended-string-escapes-p
                                       source-name)
  (let ((effective-options
          (clautolisp.autolisp-reader.internal::ensure-reader-options
           options
           :token-mode token-mode
           :retain-comments-p t
           :warn-on-integer-overflow-p warn-on-integer-overflow-p
           :extended-string-escapes-p extended-string-escapes-p
           :source-name source-name)))
    (clautolisp.autolisp-reader.internal::parse-normalized-text
     (clautolisp.autolisp-reader.internal:normalize-line-endings text)
     effective-options
     #'clautolisp.autolisp-reader.internal:parse-concrete-tokens)))

(defun read-concrete-from-stream (stream &key options (token-mode :strict)
                                         warn-on-integer-overflow-p
                                         extended-string-escapes-p
                                         source-name)
  (read-concrete-from-string
   (clautolisp.autolisp-reader.internal:decode-and-normalize-stream stream)
   :options options
   :token-mode token-mode
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name source-name))

(defun read-concrete-from-file (path &key options (token-mode :strict)
                                          warn-on-integer-overflow-p source-name
                                          extended-string-escapes-p
                                          external-format)
  (read-concrete-from-string
   (if external-format
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file
        path :external-format external-format)
       (clautolisp.autolisp-reader.internal:decode-and-normalize-file path))
   :options options
   :token-mode token-mode
   :warn-on-integer-overflow-p warn-on-integer-overflow-p
   :extended-string-escapes-p extended-string-escapes-p
   :source-name (or source-name (namestring path))))
