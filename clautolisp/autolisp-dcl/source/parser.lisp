(in-package #:clautolisp.autolisp-dcl)

;;;; DCL (Dialog Control Language) parser.
;;;;
;;;; Implements the DCL syntax documented in Autodesk's "DCL Editor"
;;;; reference and reproduced in autolisp-spec ch.18. DCL is a small
;;;; C-like language:
;;;;
;;;;   name : tile-class { attributes-and-subtiles }
;;;;   : tile-class { attributes-and-subtiles }       (anonymous)
;;;;   tile-class ;                                   (instantiate
;;;;                                                   predefined)
;;;;
;;;; Comments are `// line` and `/* block */`. Strings are
;;;; double-quoted with backslash escapes. Numbers are integer or
;;;; real. Identifiers contain letters, digits, underscores, and
;;;; dots.

(define-condition dcl-parse-error (clautolisp.autolisp-runtime:autolisp-runtime-error)
  ((line   :initarg :line   :reader dcl-parse-error-line)
   (column :initarg :column :reader dcl-parse-error-column)))

(defun signal-dcl-parse-error (state message &rest args)
  (error 'dcl-parse-error
         :code :dcl-parse-error
         :message (apply #'format nil message args)
         :line (parser-state-line state)
         :column (parser-state-column state)))

(defstruct parser-state
  (text "" :type string)
  (index 0 :type fixnum)
  (line 1 :type fixnum)
  (column 1 :type fixnum))

(defun ps-eof-p (state)
  (>= (parser-state-index state) (length (parser-state-text state))))

(defun ps-peek (state &optional (offset 0))
  (let ((i (+ (parser-state-index state) offset)))
    (and (< i (length (parser-state-text state)))
         (char (parser-state-text state) i))))

(defun ps-advance (state)
  (let ((c (ps-peek state)))
    (when c
      (incf (parser-state-index state))
      (cond
        ((char= c #\Newline)
         (incf (parser-state-line state))
         (setf (parser-state-column state) 1))
        (t (incf (parser-state-column state))))
      c)))

(defun skip-whitespace (state)
  (loop
    (let ((c (ps-peek state)))
      (cond
        ((null c) (return))
        ((member c '(#\Space #\Tab #\Newline #\Return #\Page))
         (ps-advance state))
        ;; Line comment: //...
        ((and (char= c #\/) (eql (ps-peek state 1) #\/))
         (loop until (or (ps-eof-p state) (char= (ps-peek state) #\Newline))
               do (ps-advance state)))
        ;; Block comment: /* ... */
        ((and (char= c #\/) (eql (ps-peek state 1) #\*))
         (ps-advance state) (ps-advance state)
         (loop until (or (ps-eof-p state)
                         (and (eql (ps-peek state) #\*)
                              (eql (ps-peek state 1) #\/)))
               do (ps-advance state))
         (when (not (ps-eof-p state))
           (ps-advance state) (ps-advance state)))
        (t (return))))))

(defun identifier-start-char-p (c)
  (or (and c (alpha-char-p c)) (eql c #\_)))

(defun identifier-char-p (c)
  (or (and c (alphanumericp c)) (member c '(#\_ #\. #\$))))

(defun parse-identifier (state)
  (skip-whitespace state)
  (unless (identifier-start-char-p (ps-peek state))
    (signal-dcl-parse-error state "Expected an identifier."))
  (with-output-to-string (out)
    (loop while (identifier-char-p (ps-peek state))
          do (write-char (ps-advance state) out))))

(defun parse-string-literal (state)
  (skip-whitespace state)
  (unless (eql (ps-peek state) #\")
    (signal-dcl-parse-error state "Expected a string literal."))
  (ps-advance state)
  (with-output-to-string (out)
    (loop
      (let ((c (ps-peek state)))
        (cond
          ((null c) (signal-dcl-parse-error state "Unterminated string."))
          ((char= c #\") (ps-advance state) (return))
          ((char= c #\\)
           (ps-advance state)
           (let ((next (ps-advance state)))
             (case next
               (#\n (write-char #\Newline out))
               (#\t (write-char #\Tab out))
               (#\r (write-char #\Return out))
               (#\" (write-char #\" out))
               (#\\ (write-char #\\ out))
               (otherwise (when next (write-char next out))))))
          (t (ps-advance state) (write-char c out)))))))

(defun parse-number-literal (state)
  (skip-whitespace state)
  (let ((sign 1) (start (parser-state-index state)))
    (when (eql (ps-peek state) #\-)
      (setf sign -1)
      (ps-advance state))
    (loop while (let ((c (ps-peek state)))
                  (or (and c (digit-char-p c))
                      (eql c #\.) (eql c #\e) (eql c #\E)
                      (eql c #\+) (eql c #\-)))
          do (ps-advance state))
    (let* ((text (subseq (parser-state-text state)
                         start (parser-state-index state)))
           (value (with-input-from-string (s text)
                    (read s nil nil))))
      (cond
        ((integerp value) (* sign value))
        ((numberp value) (coerce (* sign value) 'double-float))
        (t (signal-dcl-parse-error state "Invalid numeric literal: ~S" text))))))

(defun parse-attribute-value (state)
  (skip-whitespace state)
  (let ((c (ps-peek state)))
    (cond
      ((null c) (signal-dcl-parse-error state "Expected an attribute value."))
      ((char= c #\") (parse-string-literal state))
      ((or (digit-char-p c) (char= c #\-) (char= c #\.))
       (parse-number-literal state))
      ((identifier-start-char-p c)
       (let ((id (parse-identifier state)))
         (cond
           ((string-equal id "true") t)
           ((string-equal id "false") nil)
           (t (intern (string-upcase id) "KEYWORD")))))
      (t (signal-dcl-parse-error state "Unexpected character in attribute value: ~A" c)))))

(defun expect-char (state expected)
  (skip-whitespace state)
  (unless (eql (ps-peek state) expected)
    (signal-dcl-parse-error state "Expected ~A." expected))
  (ps-advance state))

(defun maybe-eat-char (state c)
  (skip-whitespace state)
  (when (eql (ps-peek state) c)
    (ps-advance state) t))

(defun parse-tile-body (state tile)
  (expect-char state #\{)
  (loop
    (skip-whitespace state)
    (cond
      ((ps-eof-p state)
       (signal-dcl-parse-error state "Unterminated tile body."))
      ((eql (ps-peek state) #\})
       (ps-advance state)
       (return tile))
      ((eql (ps-peek state) #\:)
       ;; Anonymous nested tile.
       (push (parse-tile-form state nil) (dcl-tile-children tile)))
      (t
       ;; Either an attribute, a named child class, or a predefined
       ;; tile instantiation.
       (let ((id (parse-identifier state)))
         (skip-whitespace state)
         (cond
           ((eql (ps-peek state) #\=)
            (ps-advance state)
            (let ((val (parse-attribute-value state)))
              (expect-char state #\;)
              (set-tile-attribute tile id val)))
           ((eql (ps-peek state) #\;)
            (ps-advance state)
            ;; Reference to a predefined tile (e.g. ok_cancel ;).
            (push (make-dcl-tile :type (dcl-keyword id)
                                  :attributes nil
                                  :children nil)
                  (dcl-tile-children tile)))
           ((eql (ps-peek state) #\:)
            ;; Named child: id : tile-class { ... }
            (push (parse-tile-form state id) (dcl-tile-children tile)))
           (t
            (signal-dcl-parse-error state
             "After identifier ~A: expected `=` (attribute), `:` (named child), or `;` (instantiation)."
             id))))))))

(defun parse-tile-form (state name)
  ;; Either:
  ;;   : tile-class { ... }
  ;;   name : tile-class { ... }
  ;; (NAME passed in from the caller when it was already consumed.)
  (skip-whitespace state)
  (when (eql (ps-peek state) #\:)
    (ps-advance state))
  (let* ((class (parse-identifier state))
         (tile (make-dcl-tile :type (dcl-keyword class)
                               :key (or name nil))))
    (when name
      (set-tile-attribute tile "_name_" name))
    (skip-whitespace state)
    (cond
      ((eql (ps-peek state) #\{)
       (parse-tile-body state tile)
       ;; Reverse children to source order.
       (setf (dcl-tile-children tile) (nreverse (dcl-tile-children tile)))
       tile)
      ((eql (ps-peek state) #\;)
       (ps-advance state)
       tile)
      (t (signal-dcl-parse-error state
          "After tile class ~A: expected `{` or `;`." class)))))

(defun dcl-keyword (name)
  (intern (string-upcase
           (with-output-to-string (out)
             (loop for c across name
                   do (write-char (if (char= c #\_) #\- c) out))))
          "KEYWORD"))

(defun parse-dcl (text)
  "Parse TEXT as a DCL source; return an alist of tile-class
NAME-STRING -> dcl-tile."
  (let ((state (make-parser-state :text text))
        (tiles '()))
    (loop
      (skip-whitespace state)
      (when (ps-eof-p state) (return))
      (let* ((name (parse-identifier state))
             (tile (parse-tile-form state name)))
        (push (cons name tile) tiles)
        (skip-whitespace state)))
    (nreverse tiles)))

(defun parse-dcl-from-file (path)
  (with-open-file (s path :direction :input :external-format :iso-8859-1)
    (let ((buf (make-string (file-length s))))
      (read-sequence buf s)
      (parse-dcl buf))))
