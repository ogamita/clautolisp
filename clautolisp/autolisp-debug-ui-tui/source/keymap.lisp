(in-package #:tui-core)

;;;; Keymaps (TUI module spec §6 / ncurses-key-bindings.issue). A KEYMAP is a
;;;; prefix tree from key TOKENS to either a bound COMMAND (a leaf) or a nested
;;;; KEYMAP (a prefix). This layer is clautolisp-independent: it parses
;;;; Emacs-style key-sequence strings into tokens, stores/looks up bindings, and
;;;; iterates them. The COMMAND value is opaque here — a UI decides how to fire
;;;; it (a command name/line string, a function, or a form).
;;;;
;;;; A TOKEN is one keystroke, in the same alphabet a screen's READ-KEY yields:
;;;;   * a CHARACTER — a printable key, or a control key as its control code
;;;;     character (C-w = (code-char 23)); so C-<c> needs no special token.
;;;;   * a KEYWORD — a named non-printable key: :up :down :left :right :enter
;;;;     :escape :backspace :tab :space :home :end …
;;;;   * (:meta . TOKEN) — a Meta/Alt chord (Esc prefix): M-x = (:meta . #\x).
;;;;   * (:shift . TOKEN) — Shift on a named key: S-UP = (:shift . :up).

(defparameter +named-keys+
  '(("RET" . :enter) ("SPC" . #\Space) ("TAB" . #\Tab) ("DEL" . :backspace)
    ("ESC" . :escape) ("UP" . :up) ("DOWN" . :down) ("LEFT" . :left)
    ("RIGHT" . :right) ("HOME" . :home) ("END" . :end))
  "Named-key words <-> tokens (Emacs-style key-sequence syntax).")

(defun %parse-token (str)
  "Parse ONE key-sequence word (e.g. \"C-x\", \"M-RET\", \"UP\", \">\") to a token."
  (cond
    ((zerop (length str)) (error "empty key token"))
    ((and (> (length str) 2) (char-equal #\C (char str 0)) (char= #\- (char str 1)))
     ;; C-<c>: the control code character.
     (let ((base (%parse-token (subseq str 2))))
       (if (characterp base)
           (code-char (logand (char-code (char-upcase base)) #x1f))
           (error "C- must prefix a character key, got ~S" str))))
    ((and (> (length str) 2) (char-equal #\M (char str 0)) (char= #\- (char str 1)))
     (cons :meta (%parse-token (subseq str 2))))
    ((and (> (length str) 2) (char-equal #\S (char str 0)) (char= #\- (char str 1)))
     (cons :shift (%parse-token (subseq str 2))))
    ((cdr (assoc str +named-keys+ :test #'string-equal)))
    ((= (length str) 1) (char str 0))
    (t (error "unknown key token ~S" str))))

(defun parse-key-sequence (string)
  "Parse an Emacs-style key sequence (\"C-x C-f\", \"M-x\", \"C-w >\") into a
list of TOKENS. Words are separated by spaces; the space key itself is \"SPC\"."
  (let ((words (remove "" (uiop-split string #\Space) :test #'string=)))
    (mapcar #'%parse-token words)))

(defun %unparse-token (token)
  (cond
    ((and (consp token) (eq (car token) :meta)) (format nil "M-~A" (%unparse-token (cdr token))))
    ((and (consp token) (eq (car token) :shift)) (format nil "S-~A" (%unparse-token (cdr token))))
    ((keywordp token)
     (or (car (rassoc token +named-keys+)) (string-capitalize (symbol-name token))))
    ((characterp token)
     (let ((code (char-code token)))
       (cond
         ((rassoc token +named-keys+) (car (rassoc token +named-keys+)))
         ((< code 32) (format nil "C-~A" (char-downcase (code-char (+ code 64)))))
         (t (string token)))))
    (t (princ-to-string token))))

(defun unparse-key-sequence (tokens)
  "The canonical key-sequence string for a list of TOKENS (round-trips with
PARSE-KEY-SEQUENCE for the tokens it produces)."
  (format nil "~{~A~^ ~}" (mapcar #'%unparse-token tokens)))

(defun uiop-split (string separator)
  "Split STRING on SEPARATOR (a character) into a list of substrings."
  (loop with start = 0
        for pos = (position separator string :start start)
        collect (subseq string start (or pos (length string)))
        while pos do (setf start (1+ pos))))

;;;; --- the keymap prefix tree ----------------------------------------

(defstruct (keymap (:constructor %make-keymap))
  ;; TOKEN -> (or KEYMAP <command>); a KEYMAP value is a prefix, anything else a
  ;; bound command leaf. EQUAL test so cons tokens ((:meta . #\x)) key correctly.
  (entries (make-hash-table :test 'equal)))

(defun make-keymap () (%make-keymap))

(defun keymap-bind (map tokens command)
  "Bind the key sequence TOKENS to COMMAND in MAP, creating prefix nodes as
needed. Binding through an existing leaf replaces it with a prefix; binding a
prefix of an existing binding replaces that subtree with the leaf."
  (if (null (rest tokens))
      (setf (gethash (first tokens) (keymap-entries map)) command)
      (let ((next (gethash (first tokens) (keymap-entries map))))
        (unless (keymap-p next)
          (setf next (make-keymap)
                (gethash (first tokens) (keymap-entries map)) next))
        (keymap-bind next (rest tokens) command)))
  command)

(defun keymap-unbind (map tokens)
  "Remove the binding at TOKENS from MAP (pruning now-empty prefix nodes).
Returns T if something was removed."
  (let ((entries (keymap-entries map)))
    (cond
      ((null tokens) nil)
      ((null (rest tokens))
       (when (nth-value 1 (gethash (first tokens) entries))
         (remhash (first tokens) entries) t))
      (t (let ((next (gethash (first tokens) entries)))
           (when (keymap-p next)
             (prog1 (keymap-unbind next (rest tokens))
               (when (zerop (hash-table-count (keymap-entries next)))
                 (remhash (first tokens) entries)))))))))

(defun keymap-step (map token)
  "One step: (values KIND VALUE) — :prefix + sub-keymap, :leaf + command, or
:none when TOKEN is unbound in MAP."
  (multiple-value-bind (value present) (gethash token (keymap-entries map))
    (cond ((not present) (values :none nil))
          ((keymap-p value) (values :prefix value))
          (t (values :leaf value)))))

(defun keymap-lookup (map tokens)
  "The command bound to the whole sequence TOKENS in MAP, or NIL (a bare prefix,
or a path that runs through a leaf before TOKENS end, returns NIL)."
  (loop with node = map
        for rest on tokens
        for tok = (first rest)
        do (multiple-value-bind (kind value) (keymap-step node tok)
             (ecase kind
               (:none (return nil))
               (:leaf (return (if (rest rest) nil value)))  ; leaf only if last token
               (:prefix (setf node value))))
        finally (return nil)))

(defun keymap-leaves (map)
  "All bindings in MAP as a list of (TOKENS . COMMAND), depth-first."
  (let ((out '()))
    (labels ((walk (node prefix)
               (maphash (lambda (tok value)
                          (if (keymap-p value)
                              (walk value (append prefix (list tok)))
                              (push (cons (append prefix (list tok)) value) out)))
                        (keymap-entries node))))
      (walk map '()))
    (nreverse out)))

(defun keymap-map (map function)
  "Call FUNCTION with (KEY-STRING COMMAND) for every binding in MAP."
  (dolist (leaf (keymap-leaves map))
    (funcall function (unparse-key-sequence (car leaf)) (cdr leaf))))
