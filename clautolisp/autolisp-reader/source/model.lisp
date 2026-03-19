(in-package #:clautolisp.autolisp-reader.internal)

(defstruct source-span
  (source-name nil :type (or null string))
  (start-line 1 :type fixnum)
  (start-column 1 :type fixnum)
  (end-line 1 :type fixnum)
  (end-column 1 :type fixnum))

(defstruct diagnostic
  (severity :error :type keyword)
  (code :unknown :type keyword)
  (message "" :type string)
  (span nil :type (or null source-span)))

(defstruct (reader-options
            (:constructor make-reader-options
                (&key
                 (token-mode :strict)
                 (retain-comments-p nil)
                 (recover-malformed-p nil)
                 (warn-on-integer-overflow-p nil)
                 (extended-string-escapes-p nil)
                 (canonical-case :upcase)
                 source-name)))
  (token-mode :strict :type keyword)
  (retain-comments-p nil :type boolean)
  (recover-malformed-p nil :type boolean)
  (warn-on-integer-overflow-p nil :type boolean)
  (extended-string-escapes-p nil :type boolean)
  (canonical-case :upcase :type keyword)
  (source-name nil :type (or null string)))

(defstruct token
  (kind :eof :type keyword)
  (lexeme "" :type string)
  (value nil)
  (span nil :type (or null source-span))
  (acceptance-mode :strict :type keyword)
  (overflowed-integer-p nil :type boolean))

(defstruct comment-object
  (text "" :type string)
  (span nil :type (or null source-span))
  (kind :line-comment :type keyword))

(defstruct dot-object
  (lexeme "." :type string)
  (span nil :type (or null source-span)))

(defstruct symbol-object
  (original-name "" :type string)
  (canonical-name "" :type string)
  (span nil :type (or null source-span))
  (acceptance-mode :strict :type keyword))

(defstruct string-object
  (value "" :type string)
  (lexeme "" :type string)
  (span nil :type (or null source-span))
  (acceptance-mode :strict :type keyword))

(defstruct integer-object
  (value 0 :type integer)
  (lexeme "" :type string)
  (span nil :type (or null source-span))
  (acceptance-mode :strict :type keyword))

(defstruct real-object
  (value 0d0 :type double-float)
  (lexeme "" :type string)
  (span nil :type (or null source-span))
  (acceptance-mode :strict :type keyword)
  (overflowed-integer-p nil :type boolean))

(defstruct cons-object
  (elements '() :type list)
  (tail nil)
  (dotted-p nil :type boolean)
  (span nil :type (or null source-span)))

(defstruct quote-object
  object
  (span nil :type (or null source-span)))

(defstruct concrete-list-object
  (items '() :type list)
  (span nil :type (or null source-span)))

(defstruct read-result
  (objects '() :type list)
  (diagnostics '() :type list))

(defun clone-reader-options (options &rest initargs)
  (apply #'make-reader-options
         :token-mode (reader-options-token-mode options)
         :retain-comments-p (reader-options-retain-comments-p options)
         :recover-malformed-p (reader-options-recover-malformed-p options)
         :warn-on-integer-overflow-p
         (reader-options-warn-on-integer-overflow-p options)
         :extended-string-escapes-p
         (reader-options-extended-string-escapes-p options)
         :canonical-case (reader-options-canonical-case options)
         :source-name (reader-options-source-name options)
         initargs))

(defun combine-spans (start-span end-span)
  (make-source-span
   :source-name (or (and start-span (source-span-source-name start-span))
                    (and end-span (source-span-source-name end-span)))
   :start-line (if start-span (source-span-start-line start-span) 1)
   :start-column (if start-span (source-span-start-column start-span) 1)
   :end-line (if end-span (source-span-end-line end-span) 1)
   :end-column (if end-span (source-span-end-column end-span) 1)))
