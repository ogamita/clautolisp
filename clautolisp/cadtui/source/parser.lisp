(in-package #:clautolisp.cadtui)

;;;; Meta-command parser (Phase 2 slice 2).
;;;;
;;;; Turns the meta-command text produced by CLASSIFY-LINE (the line minus its
;;;; leading escape) into a structured META-COMMAND (spec grammar §5.2, verb
;;;; table §5.3). Grammar:
;;;;   meta-command ::= verb [ "(" [ arg ("," arg)* ] ")" ]
;;;;   arg          ::= option | positional
;;;;   option       ::= option-name ":" value        ; name in the fixed set
;;;;   value        ::= "..." string | "(" number* ")" tuple | :keyword
;;;;                  | number | target-expression
;;;; A bare verb (no parens) is a zero-argument command (=next, =previous,
;;;; =help). Verbs and option names are canonical ENGLISH tokens; a Phase-7
;;;; lexical pre-pass maps localised surface forms to them before this parser
;;;; runs, so the parser never localises.
;;;;
;;;; TARGET expressions (paths, role:cle, role[i], D<n>.cle, keywords) are
;;;; captured RAW as (:target . "string"); the address layer resolves them. This
;;;; keeps the parser decoupled from the tree and testable on its own.

(defstruct meta-command
  "A parsed meta-command: VERB is a keyword; POSITIONALS an ordered list of
tagged argument values; OPTIONS an alist of (option-keyword . tagged-value)."
  verb
  (positionals '())
  (options '()))

(define-condition meta-command-parse-error (cadtui-error)
  ((text   :initarg :text   :reader meta-command-parse-error-text)
   (reason :initarg :reason :reader meta-command-parse-error-reason))
  (:report (lambda (condition stream)
             (format stream "Cannot parse meta-command ~S: ~A."
                     (meta-command-parse-error-text condition)
                     (meta-command-parse-error-reason condition))))
  (:documentation "Signalled by PARSE-META-COMMAND on a malformed meta-command."))

(defparameter *meta-option-names*
  '("depth" "page" "size" "window" "factor")
  "The fixed set of option names (canonical English). An arg 'name: value' whose
NAME is in this set is an OPTION; a colon in any other arg (e.g. entity:2A,
menu:Draw) is part of a target expression, not an option separator. NOTE 'page'
is also a verb — different contexts, no conflict.")

;;; --- Small string helpers -----------------------------------------

(defun %trim (s)
  (string-trim '(#\Space #\Tab #\Return #\Newline) s))

(defun %blank-p (s)
  (zerop (length (%trim s))))

(defun %parse-number-or-nil (s)
  "The number S denotes in full (integer or real, incl. negative), or NIL when S
is not exactly one numeric token."
  (let ((trimmed (%trim s)))
    (when (plusp (length trimmed))
      (let ((value (ignore-errors
                    (let ((*read-default-float-format* 'double-float))
                      (with-input-from-string (in trimmed)
                        (let ((x (read in nil nil)))
                          (and (null (read in nil nil)) x)))))))
        (and (numberp value) value)))))

;;; --- Argument value classification --------------------------------

(defun %parse-tuple (s text)
  "Parse a parenthesized whitespace-separated number list \"(n n ...)\" into
(:tuple n ...). Signal on a non-number element."
  (let* ((inside (%trim (subseq s 1 (1- (length s)))))
         (tokens (%split-on-whitespace inside)))
    (cons :tuple
          (mapcar (lambda (tok)
                    (or (%parse-number-or-nil tok)
                        (%parse-error text "tuple element ~S is not a number" tok)))
                  tokens))))

(defun %split-on-whitespace (s)
  (let ((tokens '()) (start 0) (len (length s)))
    (loop
      (loop while (and (< start len)
                       (member (char s start) '(#\Space #\Tab)))
            do (incf start))
      (when (>= start len) (return))
      (let ((end start))
        (loop while (and (< end len)
                         (not (member (char s end) '(#\Space #\Tab))))
              do (incf end))
        (push (subseq s start end) tokens)
        (setf start end)))
    (nreverse tokens)))

(defun %parse-error (text format &rest args)
  (error 'meta-command-parse-error :text text
                                   :reason (apply #'format nil format args)))

(defun %classify-value (chunk text)
  "Classify one argument value string CHUNK into a tagged value."
  (let ((s (%trim chunk)))
    (cond
      ((zerop (length s)) (%parse-error text "empty argument"))
      ;; "..." string literal — quotes stripped, never translated.
      ((char= (char s 0) #\")
       (if (and (> (length s) 1) (char= (char s (1- (length s))) #\"))
           (subseq s 1 (1- (length s)))
           (%parse-error text "unterminated string ~S" s)))
      ;; (n n ...) tuple.
      ((char= (char s 0) #\()
       (if (char= (char s (1- (length s))) #\))
           (%parse-tuple s text)
           (%parse-error text "unbalanced tuple ~S" s)))
      ;; :keyword.
      ((char= (char s 0) #\:)
       (intern (string-upcase (subseq s 1)) :keyword))
      ;; a bare number.
      ((%parse-number-or-nil s))
      ;; otherwise a raw target expression.
      (t (cons :target s)))))

;;; --- Top-level comma splitting ------------------------------------

(defun %split-args (inside text)
  "Split the INSIDE of the argument list on top-level commas, respecting paren
depth and \"...\" quotes. Returns a list of chunk strings (each still to be
value-classified). Signals on a trailing empty chunk (e.g. \"x,\")."
  (when (%blank-p inside) (return-from %split-args '()))
  (let ((chunks '()) (start 0) (depth 0) (in-string nil) (len (length inside)))
    (dotimes (i len)
      (let ((c (char inside i)))
        (cond
          (in-string (when (char= c #\") (setf in-string nil)))
          ((char= c #\") (setf in-string t))
          ((char= c #\() (incf depth))
          ((char= c #\)) (decf depth))
          ((and (char= c #\,) (zerop depth))
           (push (subseq inside start i) chunks)
           (setf start (1+ i))))))
    (push (subseq inside start len) chunks)
    (let ((result (nreverse chunks)))
      (dolist (chunk result)
        (when (%blank-p chunk)
          (%parse-error text "empty argument (a stray comma?)")))
      result)))

;;; --- The parser ---------------------------------------------------

(defun %option-name-p (name)
  (member name *meta-option-names* :test #'string-equal))

(defun %parse-arg (chunk text)
  "Parse one argument CHUNK into either (:option keyword . tagged-value) or
(:positional . tagged-value)."
  (let* ((s (%trim chunk))
         (colon (position #\: s)))
    (if (and colon (%option-name-p (%trim (subseq s 0 colon))))
        (list* :option
               (intern (string-upcase (%trim (subseq s 0 colon))) :keyword)
               (%classify-value (subseq s (1+ colon)) text))
        (cons :positional (%classify-value s text)))))

(defun parse-meta-command (text)
  "Parse TEXT (a meta-command with its leading escape already stripped) into a
META-COMMAND, or signal META-COMMAND-PARSE-ERROR. TEXT is either a bare verb
or verb(args)."
  (let* ((s (%trim text))
         (open (position #\( s)))
    (when (zerop (length s))
      (%parse-error text "empty meta-command"))
    (cond
      ;; bare verb, no argument list.
      ((null open)
       (make-meta-command :verb (%verb-keyword s text)))
      (t
       (let ((verb (%trim (subseq s 0 open))))
         (when (zerop (length verb))
           (%parse-error text "missing verb"))
         (unless (char= (char s (1- (length s))) #\))
           (%parse-error text "expected a closing paren at the end"))
         (let* ((inside (subseq s (1+ open) (1- (length s))))
                (args (%split-args inside text))
                (positionals '())
                (options '()))
           (dolist (chunk args)
             (let ((parsed (%parse-arg chunk text)))
               (ecase (first parsed)
                 (:option (push (cons (second parsed) (cddr parsed)) options))
                 (:positional (push (cdr parsed) positionals)))))
           (make-meta-command :verb (%verb-keyword verb text)
                              :positionals (nreverse positionals)
                              :options (nreverse options))))))))

(defun %verb-keyword (verb text)
  "Intern VERB (a canonical English identifier) as a keyword, or signal."
  (let ((v (%trim verb)))
    (when (or (zerop (length v)) (position #\Space v))
      (%parse-error text "malformed verb ~S" v))
    (intern (string-upcase v) :keyword)))
