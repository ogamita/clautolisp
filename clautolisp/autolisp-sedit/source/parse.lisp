;;;; clautolisp/autolisp-sedit/source/parse.lisp
;;;;
;;;; A lossless reader: AutoLISP source text -> an adorned tree (sedit spec §5,
;;;; §6.7). Every node keeps its verbatim source slice, and the file node keeps
;;;; the whole source, so PARSE-SOURCE then UNPARSE reproduces the text
;;;; byte-for-byte. Comments become comment nodes (kept in the tree, dropped by
;;;; TREE->SEXP); quote sugar 'x `x ,x ,@x becomes a (quote/… x) list whose
;;;; verbatim text is the sugar. Self-contained — no reader dependency — so
;;;; sedit stays reusable. Symbols read as keywords (predictable; the sexp value
;;;; only matters for structure, printing uses the verbatim text).

(in-package #:clautolisp.sedit)

(defstruct (preader (:constructor make-preader (src)))
  (src "" :type simple-string)
  (pos 0 :type fixnum))

(declaim (inline %pk %pk2 %eofp))
(defun %pk (r)
  (let ((p (preader-pos r))) (when (< p (length (preader-src r))) (char (preader-src r) p))))
(defun %pk2 (r)
  (let ((p (1+ (preader-pos r)))) (when (< p (length (preader-src r))) (char (preader-src r) p))))
(defun %eofp (r) (>= (preader-pos r) (length (preader-src r))))
(defun %adv (r) (incf (preader-pos r)))

(defun %ws-char-p (c) (and c (member c '(#\Space #\Tab #\Newline #\Return #\Page) :test #'char=)))
(defun %skip-ws (r) (loop while (%ws-char-p (%pk r)) do (%adv r)))

(defun %slice (r start)
  (subseq (preader-src r) start (preader-pos r)))

(defun %atom-terminator-p (c)
  (or (null c) (%ws-char-p c) (member c '(#\( #\) #\" #\; #\') :test #'char=)))

;;; --- token value parsing (structure only; printing uses verbatim text) ----

(defun %numeric-token-p (text)
  (and (plusp (length text))
       (let ((c (char text 0))) (or (digit-char-p c) (member c '(#\+ #\- #\.) :test #'char=)))
       (every (lambda (c) (or (digit-char-p c) (member c '(#\+ #\- #\. #\e #\E) :test #'char=)))
              text)))

(defun %token-value (text)
  "The Lisp value a bare token TEXT denotes: a number when it parses as one, else
a keyword (a predictable, pollution-free symbol; case-folded to upper)."
  (or (and (%numeric-token-p text)
           (let ((v (ignore-errors (let ((*read-eval* nil)) (read-from-string text nil nil)))))
             (and (numberp v) v)))
      (intern (string-upcase text) :keyword)))

(defun %string-value (text)
  "The string a \"…\" literal TEXT denotes (quotes stripped, escapes resolved)."
  (or (ignore-errors (let ((*read-eval* nil)) (read-from-string text nil nil))) text))

;;; --- readers (each returns a node carrying its verbatim text) --------------

(defun %read-comment (r)
  (let ((start (preader-pos r)))
    (if (and (eql (%pk r) #\;) (eql (%pk2 r) #\|))
        (progn (%adv r) (%adv r)               ; ;|
               (loop until (or (%eofp r) (and (eql (%pk r) #\|) (eql (%pk2 r) #\;)))
                     do (%adv r))
               (unless (%eofp r) (%adv r) (%adv r)))   ; |;
        (loop until (or (%eofp r) (eql (%pk r) #\Newline)) do (%adv r)))
    (make-comment-node (%slice r start))))

(defun %read-string (r)
  (let ((start (preader-pos r)))
    (%adv r)                                    ; opening "
    (loop until (or (%eofp r) (eql (%pk r) #\"))
          do (when (eql (%pk r) #\\) (%adv r))  ; escape: skip the next char
             (unless (%eofp r) (%adv r)))
    (unless (%eofp r) (%adv r))                 ; closing "
    (let ((text (%slice r start)))
      (make-atom-node (%string-value text) :adornment (make-adornment :text text)))))

(defun %read-atom (r)
  (let ((start (preader-pos r)))
    (loop until (%atom-terminator-p (%pk r)) do (%adv r))
    (let ((text (%slice r start)))
      (make-atom-node (%token-value text) :adornment (make-adornment :text text)))))

(defun %read-quote (r)
  (let ((start (preader-pos r))
        (head (ecase (%pk r)
                (#\' (%adv r) :quote)
                (#\` (%adv r) :quasiquote)
                (#\, (%adv r) (if (eql (%pk r) #\@) (progn (%adv r) :unquote-splicing) :unquote)))))
    (let ((sub (%read-item r)))
      (make-list-node (list (make-atom-node head) sub)
                      :adornment (make-adornment :text (%slice r start))))))

(defun %read-list (r)
  (let ((start (preader-pos r)) (children '()))
    (%adv r)                                    ; consume (
    (loop
      (%skip-ws r)
      (when (%eofp r) (error "sedit parse: unterminated list"))
      (when (eql (%pk r) #\)) (%adv r) (return))
      (push (%read-item r) children))
    (make-list-node (nreverse children) :adornment (make-adornment :text (%slice r start)))))

(defun %read-item (r)
  "Read one comment or form (skipping leading whitespace); NIL at end of input."
  (%skip-ws r)
  (let ((c (%pk r)))
    (cond
      ((null c) nil)
      ((char= c #\;) (%read-comment r))
      ((char= c #\() (%read-list r))
      ((char= c #\)) (error "sedit parse: unexpected )"))
      ((char= c #\") (%read-string r))
      ((member c '(#\' #\` #\,) :test #'char=) (%read-quote r))
      (t (%read-atom r)))))

;;; --- entry points ----------------------------------------------------------

(defun parse-source (string &key file)
  "Parse AutoLISP source STRING into an adorned file-node whose children are its
top-level forms and comments (each with verbatim text). The file keeps the whole
source, so PARSE-SOURCE then UNPARSE is byte-preserving (§6.7). FILE names it."
  (let ((r (make-preader (coerce string 'simple-string))) (items '()))
    (loop for item = (%read-item r) while item do (push item items))
    (make-file-node file (nreverse items) :adornment (make-adornment :text string))))

(defun parse-form (string)
  "Parse STRING as a single form/comment, returning its adorned node (or NIL)."
  (%read-item (make-preader (coerce string 'simple-string))))
