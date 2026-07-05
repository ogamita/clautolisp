;;;; clautolisp/autolisp-sedit/source/format.lisp
;;;;
;;;; Formatting (sedit spec §5.2–§5.3, §6.7 formatting fidelity): comment objects
;;;; and the pretty-printer. UNPARSE reproduces a node's source: byte-for-byte
;;;; when the node carries verbatim text (clean, loaded source), otherwise laid
;;;; out from the indentation rules — AutoLISP's finite special-operator set
;;;; makes a form's indentation fully determined (§5.2).

(in-package #:clautolisp.sedit)

;;; --- configuration (the `set' options of §5.2–§5.3) -----------------------

(defvar *comment-column* 40
  "The column a margin comment (;-) sits at (spec §5.2; `set comment-column').")

(defvar *text-editor* :editor
  "Where sedit defers multi-line comment-body editing (spec §5.3; `set
text-editor'): :editor ($EDITOR), :visual ($VISUAL), or a path string.")

(defvar *print-width* 72
  "The target line width the structural pretty-printer wraps at.")

;;; --- comment objects (§5.3) -----------------------------------------------

(defun comment-line-level (text)
  "The level of a line comment TEXT: the count of leading semicolons capped at 4
— 1 =;-= (margin), 2 =;;-= (sub-form), 3/4 =;;;-=/=;;;;-= (flush-left). NIL when
TEXT is not a line comment."
  (when (and (plusp (length text)) (char= #\; (char text 0)))
    (min 4 (or (position #\; text :test-not #'char=) (length text)))))

(defun comment-block-p (text)
  "True when TEXT is a block comment =;| … |;=."
  (and (>= (length text) 2) (char= #\; (char text 0)) (char= #\| (char text 1))))

(defun comment-level (comment)
  "The level of a COMMENT node: :block for a =;| |;= block, else its line level
(1–4), or NIL."
  (let ((text (comment-node-text comment)))
    (if (comment-block-p text) :block (comment-line-level text))))

(defun merge-comments (comments)
  "Merge a list of contiguous COMMENTS: a run of same-level line comments
coalesces into one multi-line comment node (spec §5.2/§5.3), their texts joined
with newlines; a block comment or a level change starts a new unit. Returns the
list of merged comment nodes."
  (let ((result '()) (run '()) (run-level nil))
    (flet ((flush ()
             (when run
               (push (if (rest run)
                         (make-comment-node
                          (format nil "~{~A~^~%~}" (mapcar #'comment-node-text (reverse run))))
                         (first run))
                     result)
               (setf run '() run-level nil))))
      (dolist (c comments)
        (let ((level (comment-level c)))
          (if (and run-level (eql level run-level) (not (eq level :block)))
              (push c run)
              (progn (flush) (setf run (list c) run-level level)))))
      (flush))
    (nreverse result)))

;;; --- the AutoLISP indentation table (§5.2) --------------------------------

(defparameter *special-indent*
  ;; operator name (upper-case) -> the number of DISTINGUISHED leading arguments
  ;; that stay on the header line; the rest are the body, indented two spaces.
  ;; AutoLISP's special-operator set is finite, so this fully determines layout.
  '(("DEFUN" . 2) ("DEFUN-Q" . 2) ("LAMBDA" . 1)
    ("IF" . 1) ("WHILE" . 1) ("REPEAT" . 1) ("FOREACH" . 2)
    ("COND" . 0) ("PROGN" . 0) ("AND" . 0) ("OR" . 0) ("SETQ" . 0))
  "Distinguished-argument counts for AutoLISP special operators (spec §5.2).")

(defun %operator-name (node)
  "The upper-case operator name if NODE is a symbol atom, else NIL."
  (and (atom-node-p node) (symbolp (atom-node-value node)) (atom-node-value node)
       (string-upcase (symbol-name (atom-node-value node)))))

(defun %distinguished-count (op-name)
  (or (cdr (assoc op-name *special-indent* :test #'equal)) 0))

;;; --- the pretty-printer ---------------------------------------------------

(defun unparse (node)
  "NODE's source text (spec §5, §6.7). Byte-preserving when NODE carries verbatim
text (clean, loaded source); otherwise laid out from the indentation rules."
  (%emit node 0))

(defun %emit (node col)
  "NODE rendered starting at column COL: its verbatim text if any, else a
structural layout."
  (or (node-text node) (%format-node node col)))

(defun %format-node (node col)
  (typecase node
    (atom-node (%format-atom node))
    (comment-node (comment-node-text node))
    (list-node (%format-list node col))
    (file-node (%format-file node))
    (dir-node (or (dir-node-name node) ""))
    (t (princ-to-string node))))

(defun %format-atom (node)
  (let ((v (atom-node-value node)))
    (cond ((null v) "nil")
          ((stringp v) (prin1-to-string v))
          ((symbolp v) (string-downcase (symbol-name v)))
          (t (princ-to-string v)))))

(defun %format-list (node col)
  (let ((children (list-node-children node)))
    (if (null children)
        "()"
        (let ((one (and (notany #'comment-node-p children) (%oneline-list children))))
          (if (and one (<= (+ col (length one)) *print-width*))
              one
              (%multiline-list children col))))))

(defun %oneline-list (children)
  "The children rendered on one line, or NIL if any spans multiple lines."
  (let ((parts (mapcar (lambda (c) (%emit c 0)) children)))
    (unless (some (lambda (p) (find #\Newline p)) parts)
      (format nil "(~{~A~^ ~})" parts))))

(defun %multiline-list (children col)
  "The children laid out over lines: the operator and its distinguished
arguments on the header line, the rest as a body indented two spaces (§5.2)."
  (let* ((dist (%distinguished-count (%operator-name (first children))))
         (head-count (min (1+ dist) (length children)))
         (head (subseq children 0 head-count))
         (rest (nthcdr head-count children))
         (open-col (1+ col))
         (body-indent (+ col 2))
         (out (make-string-output-stream)))
    (write-char #\( out)
    (loop for c in head for first = t then nil
          do (unless first (write-char #\Space out))
             (write-string (%emit c open-col) out))
    (dolist (c rest)
      (write-char #\Newline out)
      (dotimes (i body-indent) (write-char #\Space out))
      (write-string (%emit c body-indent) out))
    (write-char #\) out)
    (get-output-stream-string out)))

(defun %format-file (node)
  "A file's children laid out, one form per paragraph (blank line between)."
  (format nil "~{~A~^~2%~}"
          (mapcar (lambda (c) (%emit c 0)) (file-node-children node))))
