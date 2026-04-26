(in-package #:clautolisp.autolisp-dcl)

;;;; Phase 15b — sexp-based wire protocol for DCL renderers.
;;;;
;;;; The protocol is a stream of s-expressions, one per line.
;;;; This is not full CL: only a small grammar, hand-rolled, so
;;;; the GUI driver can implement it without dragging in a CL
;;;; reader. Readability is the priority — humans should be able
;;;; to read a wire trace and understand what is happening.
;;;;
;;;; Token grammar:
;;;;   - `(` and `)` group lists
;;;;   - `"..."` is a string with `\\`, `\"`, `\n`, `\t`, `\r`
;;;;     escapes
;;;;   - `:keyword` is a keyword (no package, always uppercased
;;;;     internally)
;;;;   - `nil` is the empty list, `t` is the true symbol
;;;;   - integers like `42` and floats like `3.14` are numbers
;;;;   - bare identifiers `[A-Za-z_-][A-Za-z0-9_-]*` become
;;;;     uppercased symbols in the keyword package
;;;;
;;;; Message grammar (downstream — runtime to GUI):
;;;;   (:open-dialog DID NAME TILE-FORM)
;;;;   (:close-dialog DID STATUS)
;;;;   (:set-tile DID KEY VALUE)
;;;;   (:focus DID KEY)
;;;;   (:mode-tile DID KEY MODE)
;;;;   (:populate-list DID KEY OPERATION INDEX (ITEM1 ITEM2 ...))
;;;;   (:image-paint DID KEY (PRIM1 PRIM2 ...))
;;;;       where PRIM is one of:
;;;;         (:fill X Y W H COLOUR)
;;;;         (:vector X1 Y1 X2 Y2 COLOUR)
;;;;         (:slide X Y W H "/path/to/sld")
;;;;   (:bye)
;;;;
;;;; Message grammar (upstream — GUI to runtime):
;;;;   (:action DID KEY VALUE REASON)
;;;;   (:done DID STATUS)
;;;;   (:hello PROTOCOL-VERSION)
;;;;   (:error MESSAGE)
;;;;
;;;; TILE-FORM is a tagged tree:
;;;;   (:tile TYPE KEY (:attr (NAME VALUE) ...) (:children TILE-FORM ...))

(defparameter *sexp-protocol-version* 1)

(define-condition sexp-wire-error (error)
  ((message :initarg :message :reader sexp-wire-error-message))
  (:report (lambda (c s)
             (format s "DCL wire-protocol error: ~A"
                     (sexp-wire-error-message c)))))

(defun signal-sexp-wire-error (fmt &rest args)
  (error 'sexp-wire-error :message (apply #'format nil fmt args)))

;;; --- Reader ----------------------------------------------------

(defstruct sexp-reader-state
  (stream nil)
  (peeked nil :type (or null character)))

(defun sr-peek (state)
  (or (sexp-reader-state-peeked state)
      (setf (sexp-reader-state-peeked state)
            (read-char (sexp-reader-state-stream state) nil nil))))

(defun sr-advance (state)
  (let ((c (sr-peek state)))
    (setf (sexp-reader-state-peeked state) nil)
    c))

(defun sr-skip-whitespace (state)
  (loop for c = (sr-peek state)
        while (and c (member c '(#\Space #\Tab #\Newline #\Return)))
        do (sr-advance state)))

(defun sr-read-string-literal (state)
  ;; Caller has already consumed the opening `"`.
  (with-output-to-string (out)
    (loop
      (let ((c (sr-advance state)))
        (cond
          ((null c) (signal-sexp-wire-error "unterminated string"))
          ((char= c #\") (return))
          ((char= c #\\)
           (let ((next (sr-advance state)))
             (case next
               (#\n (write-char #\Newline out))
               (#\t (write-char #\Tab out))
               (#\r (write-char #\Return out))
               (#\\ (write-char #\\ out))
               (#\" (write-char #\" out))
               (otherwise
                (when next (write-char next out))))))
          (t (write-char c out)))))))

(defun sr-read-token (state)
  ;; Reads a non-string, non-paren token starting at the current char.
  (with-output-to-string (out)
    (loop for c = (sr-peek state)
          while (and c
                     (not (member c '(#\Space #\Tab #\Newline #\Return
                                      #\( #\) #\"))))
          do (write-char (sr-advance state) out))))

(defun sr-classify-token (text)
  (cond
    ((zerop (length text))
     (signal-sexp-wire-error "empty token"))
    ((char= (char text 0) #\:)
     ;; Keyword: drop the colon, upcase, intern in :keyword.
     (intern (string-upcase (subseq text 1)) :keyword))
    ((string-equal text "nil") nil)
    ((string-equal text "t") t)
    (t
     (let ((number (sr-maybe-number text)))
       (cond
         (number number)
         (t (intern (string-upcase text) :keyword)))))))

(defun sr-maybe-number (text)
  ;; Hand-rolled numeric recogniser: integer or float; refuse
  ;; ratios, complex, #-syntax, scientific notation is OK.
  (and (sr-numeric-shape-p text)
       (with-input-from-string (s text)
         (let* ((*read-default-float-format* 'double-float)
                (value (handler-case (read s nil nil)
                         (error () nil))))
           (and (numberp value) value)))))

(defun sr-numeric-shape-p (text)
  (let ((len (length text)))
    (and (plusp len)
         (let ((start (if (member (char text 0) '(#\- #\+)) 1 0)))
           (and (< start len)
                (loop for i from start below len
                      for c = (char text i)
                      always (or (digit-char-p c)
                                 (member c '(#\. #\e #\E #\- #\+)))))))))

(defun read-sexp-message (stream)
  "Read one sexp from STREAM. Returns the parsed object, or :eof."
  (let ((state (make-sexp-reader-state :stream stream)))
    (sr-skip-whitespace state)
    (cond
      ((null (sr-peek state)) :eof)
      (t (sr-read-form state)))))

(defun sr-read-form (state)
  (sr-skip-whitespace state)
  (let ((c (sr-peek state)))
    (cond
      ((null c) (signal-sexp-wire-error "unexpected EOF"))
      ((char= c #\() (sr-advance state) (sr-read-list state))
      ((char= c #\)) (signal-sexp-wire-error "unexpected )"))
      ((char= c #\") (sr-advance state) (sr-read-string-literal state))
      (t (sr-classify-token (sr-read-token state))))))

(defun sr-read-list (state)
  (let ((acc '()))
    (loop
      (sr-skip-whitespace state)
      (let ((c (sr-peek state)))
        (cond
          ((null c) (signal-sexp-wire-error "unterminated list"))
          ((char= c #\)) (sr-advance state) (return (nreverse acc)))
          (t (push (sr-read-form state) acc)))))))

;;; --- Writer ----------------------------------------------------

(defun write-sexp-message (form stream)
  "Serialise FORM to STREAM as one line followed by #\\Newline."
  (write-sexp-form form stream)
  (write-char #\Newline stream)
  (force-output stream))

(defun write-sexp-form (form stream)
  (cond
    ((null form) (write-string "nil" stream))
    ((eq form t) (write-string "t" stream))
    ((stringp form) (write-sexp-string form stream))
    ((keywordp form)
     (write-char #\: stream)
     (write-string (string-downcase (symbol-name form)) stream))
    ((symbolp form)
     ;; Non-keyword symbols are written as their downcased name.
     (write-string (string-downcase (symbol-name form)) stream))
    ((integerp form) (format stream "~D" form))
    ((numberp form)
     (let ((*read-default-float-format* 'double-float))
       (format stream "~F" form)))
    ((consp form)
     (write-char #\( stream)
     (loop for cell on form
           for first = t then nil
           do (unless first (write-char #\Space stream))
              (write-sexp-form (car cell) stream)
              (when (and (cdr cell) (not (consp (cdr cell))))
                (signal-sexp-wire-error
                 "improper list in sexp wire protocol")))
     (write-char #\) stream))
    (t (signal-sexp-wire-error "unsupported value type: ~S" form))))

(defun write-sexp-string (s stream)
  (write-char #\" stream)
  (loop for c across s do
    (case c
      (#\\ (write-string "\\\\" stream))
      (#\" (write-string "\\\"" stream))
      (#\Newline (write-string "\\n" stream))
      (#\Tab (write-string "\\t" stream))
      (#\Return (write-string "\\r" stream))
      (otherwise (write-char c stream))))
  (write-char #\" stream))

;;; --- Tile-form encoding ----------------------------------------

(defun tile->sexp (tile)
  "Convert a dcl-tile to its on-the-wire sexp shape. The key slot
prefers the top-level dcl-tile-key (set by `name : class { ... }`
syntax) but falls back to the `key` attribute (set by anonymous
`: class { key = ... }` syntax). Real AutoLISP treats both as
the tile identifier addressed by set_tile / get_tile / action_tile."
  (list :tile
        (dcl-tile-type tile)
        (or (dcl-tile-key tile)
            (tile-attribute tile "key")
            :nokey)
        (cons :attr
              (mapcar (lambda (a) (list (car a) (attribute-value->sexp (cdr a))))
                      (dcl-tile-attributes tile)))
        (cons :children
              (mapcar #'tile->sexp (dcl-tile-children tile)))))

(defun attribute-value->sexp (value)
  ;; DCL attribute values are strings, numbers, t/nil, or keywords.
  ;; Pass them through; the writer handles the formatting.
  value)
