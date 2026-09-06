;;;; autolisp-builtins-core/source/source-file.lisp
;;;;
;;;; The source-file editing module (sedit-bugs-and-design.issue): read and
;;;; edit a source file at the granularity of top-level items (comments,
;;;; atoms, forms), keeping CLAUTOLISP.SOURCE:*SOURCE-POSITION-TABLE* consistent
;;;; as lines are inserted, replaced, or deleted — so a sedit save no longer
;;;; invalidates the positions of the forms below the first edit, and the
;;;; debugger's breakpoints / file navigation on those forms stay correct.
;;;;
;;;; Reading uses the sedit lossless parser (comments kept, atoms and forms
;;;; separated); a form is read to a runtime cons whose position is recorded.
;;;; Every mutating operation shifts the table by the number of lines it added
;;;; or removed (CLAUTOLISP.SOURCE:SHIFT-SOURCE-POSITIONS).

(defpackage #:clautolisp.source-file
  (:use #:cl)
  (:documentation
   "Line-level source-file editing that maintains the source-position map
(sedit-bugs-and-design.issue). See SOURCE-FILE-OPEN.")
  (:export #:source-file #:source-file-p #:source-file-path #:source-file-dirty-p
           #:source-file-open #:source-file-read #:source-file-close
           #:source-file-save-and-close
           #:source-file-insert-toplevel-form #:source-file-replace-toplevel-form
           #:source-file-delete-toplevel-form
           #:source-file-insert-comment #:source-file-replace-comment
           #:source-file-delete-comment
           ;; the item structures SOURCE-FILE-READ yields
           #:sf-comment #:sf-comment-p #:sf-comment-position #:sf-comment-kind
           #:sf-comment-lines
           #:sf-atom #:sf-atom-p #:sf-atom-position #:sf-atom-value))

(in-package #:clautolisp.source-file)

;;; --- items --------------------------------------------------------------

;; The internal, positioned view of one top-level item. KIND is
;; :comment-line / :comment-block / :atom / :form; START-LINE and END-LINE are
;; 1-based inclusive; TEXT is the item's verbatim source; VALUE is the runtime
;; cons (form), the atom value, or the list of comment-line strings.
(defstruct sf-item kind start-line end-line text value)

;; What SOURCE-FILE-READ hands back for a comment or a bare atom (a form is
;; returned as its cons directly, per the issue).
(defstruct sf-comment position kind lines)
(defstruct sf-atom position value)

(defstruct (source-file (:constructor %make-source-file))
  path                 ; namestring of the file
  mode                 ; :read | :update
  (lines '())          ; the file's lines, content only (no newline)
  (items '())          ; the parsed SF-ITEMs, in file order
  (cursor 0)           ; SOURCE-FILE-READ position into ITEMS
  (dirty nil))

(defun source-file-dirty-p (sf) (source-file-dirty sf))

;;; --- text <-> lines -----------------------------------------------------

(defun %split-lines (text)
  "TEXT split into content lines (no newlines). A trailing newline does not
add an empty final line."
  (let ((lines (uiop:split-string text :separator '(#\Newline))))
    (if (and (cdr lines) (string= "" (car (last lines))))
        (butlast lines)
        lines)))

(defun %join-lines (lines)
  "LINES joined into text, one newline after each (files end with a newline)."
  (with-output-to-string (out)
    (dolist (line lines) (write-line line out))))

;;; --- parsing top-level items -------------------------------------------

(defun %block-comment-p (text)
  "True when comment TEXT is a =;| … |;= block comment."
  (let ((s (string-left-trim '(#\Space #\Tab) text)))
    (and (>= (length s) 2) (char= (char s 0) #\;) (char= (char s 1) #\|))))

(defun %parse-items (path text)
  "Parse TEXT (the whole file) into SF-ITEMs with 1-based line spans, via the
sedit lossless parser. Line spans are found by locating each item's verbatim
text in TEXT (so inter-item whitespace is accounted for). Forms are NOT
recorded here — SOURCE-FILE-READ records the form it returns."
  (let* ((root (clautolisp.sedit:parse-source text :file (namestring path)))
         (children (clautolisp.sedit:file-node-children root)))
    (loop with pos = 0
          for node in children
          for ntext = (clautolisp.sedit:node-text node)
          for at = (or (and (plusp (length ntext)) (search ntext text :start2 pos)) pos)
          for start = (1+ (count #\Newline text :end at))
          for end = (+ start (count #\Newline ntext))
          do (setf pos (+ at (length ntext)))
          collect (%item-of node ntext start end))))

(defun %item-of (node text start end)
  (cond
    ((clautolisp.sedit:comment-node-p node)
     (make-sf-item :kind (if (%block-comment-p text) :comment-block :comment-line)
                   :start-line start :end-line end :text text
                   :value (%split-lines text)))
    ((clautolisp.sedit:atom-node-p node)
     (make-sf-item :kind :atom :start-line start :end-line end :text text
                   :value (clautolisp.sedit:atom-node-value node)))
    (t
     (make-sf-item :kind :form :start-line start :end-line end :text text
                   :value (ignore-errors
                           (clautolisp.autolisp-runtime:autolisp-read-from-string text))))))

(defun %reparse (sf)
  "Recompute SF's items from its current lines."
  (setf (source-file-items sf)
        (%parse-items (source-file-path sf) (%join-lines (source-file-lines sf))))
  sf)

;;; --- opening / closing --------------------------------------------------

(defun source-file-open (path mode)
  "Open the source file at PATH for MODE, 'READ (or :READ) to read its items,
'UPDATE (or :UPDATE) to edit them. A non-existent file opens empty (it is
created by SOURCE-FILE-SAVE-AND-CLOSE). Returns a SOURCE-FILE."
  (let* ((mode (intern (string-upcase (string mode)) :keyword))
         (text (if (probe-file path)
                   (uiop:read-file-string path)
                   ""))
         (sf (%make-source-file :path (namestring (if (probe-file path)
                                                      (truename path)
                                                      (merge-pathnames path)))
                                :mode mode
                                :lines (%split-lines text))))
    (%reparse sf)
    sf))

(defun source-file-close (sf)
  "Close SF, discarding any unsaved edits. Returns NIL."
  (setf (source-file-items sf) '() (source-file-lines sf) '())
  nil)

(defun source-file-save-and-close (sf)
  "Write SF's current text to its file and close it. Returns the namestring."
  (with-open-file (out (source-file-path sf) :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create
                                             :external-format :utf-8)
    (write-string (%join-lines (source-file-lines sf)) out))
  (let ((path (source-file-path sf)))
    (source-file-close sf)
    path))

;;; --- reading ------------------------------------------------------------

(defun %record-form (sf item)
  "Record ITEM's form cons at its span in the source-position table, and return
the cons."
  (let ((cons (sf-item-value item)))
    (when (consp cons)
      (setf (gethash cons clautolisp.source:*source-position-table*)
            (clautolisp.source:make-source-position
             :file (source-file-path sf)
             :start-line (sf-item-start-line item) :start-column 1
             :end-line (sf-item-end-line item) :end-column 1)))
    cons))

(defun %item-position (sf item)
  (clautolisp.source:make-source-position
   :file (source-file-path sf)
   :start-line (sf-item-start-line item) :start-column 1
   :end-line (sf-item-end-line item) :end-column 1))

(defun source-file-read (sf &optional eof-indicator)
  "Return SF's next top-level item and advance: a cons for a form (its position
recorded/updated in the table), an SF-ATOM for a bare atom, an SF-COMMENT for a
comment, or EOF-INDICATOR at end."
  (let ((items (source-file-items sf))
        (i (source-file-cursor sf)))
    (if (>= i (length items))
        eof-indicator
        (let ((item (nth i items)))
          (incf (source-file-cursor sf))
          (ecase (sf-item-kind item)
            (:form (%record-form sf item))
            (:atom (make-sf-atom :position (%item-position sf item)
                                 :value (sf-item-value item)))
            ((:comment-line :comment-block)
             (make-sf-comment :position (%item-position sf item)
                              :kind (sf-item-kind item)
                              :lines (sf-item-value item))))))))

;;; --- editing: shared machinery -----------------------------------------

(defun %item-at-line (sf line)
  "The SF-ITEM whose span contains LINE, or NIL."
  (find-if (lambda (it) (<= (sf-item-start-line it) line (sf-item-end-line it)))
           (source-file-items sf)))

(defun %item-starting-at (sf line)
  "The SF-ITEM whose START-LINE is LINE, or NIL."
  (find line (source-file-items sf) :key #'sf-item-start-line))

(defun %check-boundary (sf line what)
  "Signal an error when LINE falls strictly inside a top-level item — an
insertion/edit point must be at an item boundary or in blank space."
  (let ((item (%item-at-line sf line)))
    (when (and item (> line (sf-item-start-line item)))
      (error "source-file ~A: line ~D falls inside the ~(~A~) at lines ~D-~D."
             what line (sf-item-kind item)
             (sf-item-start-line item) (sf-item-end-line item)))))

(defun %splice-lines (lines at count new)
  "Return LINES with COUNT lines removed at 1-based AT and NEW (a list) spliced
in there. COUNT 0 inserts; NEW '() deletes."
  (let ((head (subseq lines 0 (min (1- at) (length lines))))
        (tail (nthcdr (+ (1- at) count) lines)))
    (append head new tail)))

(defun %apply-edit (sf at old-count new-lines)
  "Replace OLD-COUNT lines at 1-based AT with NEW-LINES, shift the position
table for the forms below the edit by the line delta, re-parse, and mark SF
dirty. Returns the delta (new minus old line count)."
  (let ((delta (- (length new-lines) old-count)))
    (setf (source-file-lines sf)
          (%splice-lines (source-file-lines sf) at old-count new-lines))
    ;; positions strictly below the edited region move by DELTA.
    (clautolisp.source:shift-source-positions (source-file-path sf)
                                              (+ at old-count) delta)
    (setf (source-file-dirty sf) t)
    (%reparse sf)
    delta))

;;; --- editing: top-level forms ------------------------------------------

(defun %format-form (form)
  "FORM (a runtime cons) as indented source lines (a list of strings), laid out
by the sedit reflow rules."
  (let* ((text (clautolisp.autolisp-builtins-core::autolisp-value->string form nil))
         (pretty (clautolisp.sedit:unparse
                  (clautolisp.sedit:reflow (clautolisp.sedit:parse-form text)))))
    (%split-lines pretty)))

(defun source-file-insert-toplevel-form (sf ilinenum form)
  "Insert FORM (a cons) as a new top-level form before line ILINENUM, followed
by a blank line. ILINENUM must not fall inside an existing form. Maintains the
position table. Returns SF."
  (%check-boundary sf ilinenum "insert-toplevel-form")
  (%apply-edit sf ilinenum 0 (append (%format-form form) '("")))
  sf)

(defun source-file-replace-toplevel-form (sf flinenum form)
  "Replace the top-level form that starts at line FLINENUM with FORM (a cons).
FLINENUM must be that form's first line. Maintains the position table. Returns
SF."
  (let ((item (%item-starting-at sf flinenum)))
    (unless (and item (eq (sf-item-kind item) :form))
      (error "source-file replace-toplevel-form: no top-level form starts at line ~D." flinenum))
    (%apply-edit sf flinenum
                 (1+ (- (sf-item-end-line item) (sf-item-start-line item)))
                 (%format-form form)))
  sf)

(defun source-file-delete-toplevel-form (sf flinenum)
  "Delete the top-level form starting at line FLINENUM (and the blank lines that
follow it). FLINENUM must be that form's first line. Maintains the position
table. Returns SF."
  (let ((item (%item-starting-at sf flinenum)))
    (unless (and item (eq (sf-item-kind item) :form))
      (error "source-file delete-toplevel-form: no top-level form starts at line ~D." flinenum))
    (let* ((end (sf-item-end-line item))
           (lines (source-file-lines sf)))
      ;; also swallow immediately-following blank lines
      (loop while (and (< end (length lines))
                       (string= "" (string-trim '(#\Space #\Tab) (nth end lines))))
            do (incf end))
      (%apply-edit sf flinenum (1+ (- end (sf-item-start-line item))) '())))
  sf)

;;; --- editing: top-level comments ---------------------------------------

(defun %blank-or-comment-line-p (line)
  (let ((s (string-trim '(#\Space #\Tab) line)))
    (or (string= s "") (and (plusp (length s)) (char= (char s 0) #\;)))))

(defun source-file-insert-comment (sf linenum new-comment-lines)
  "Insert NEW-COMMENT-LINES (a list of strings forming one comment) before line
LINENUM. LINENUM must not fall inside a form. Maintains the position table.
Returns SF."
  (%check-boundary sf linenum "insert-comment")
  (%apply-edit sf linenum 0 (copy-list new-comment-lines))
  sf)

(defun source-file-replace-comment (sf start-linum end-linum new-comment-lines)
  "Replace the comment/blank lines in [START-LINUM, END-LINUM) with
NEW-COMMENT-LINES. The interval must hold only comment or blank lines (else an
error), and must not clip a form. Maintains the position table. Returns SF."
  (loop for l from start-linum below end-linum
        for line = (nth (1- l) (source-file-lines sf))
        unless (and line (%blank-or-comment-line-p line))
          do (error "source-file replace-comment: line ~D is not a comment or blank." l))
  (%apply-edit sf start-linum (- end-linum start-linum) (copy-list new-comment-lines))
  sf)

(defun source-file-delete-comment (sf start-linum end-linum)
  "Delete the comment/blank lines in [START-LINUM, END-LINUM). Same constraints
as SOURCE-FILE-REPLACE-COMMENT. Maintains the position table. Returns SF."
  (source-file-replace-comment sf start-linum end-linum '()))
