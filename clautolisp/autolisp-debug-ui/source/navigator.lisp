;;;; Structural sexp navigator for the debugger TUI (command reference §3
;;;; Navigation; TUI spec "One tree").
;;;;
;;;; Adapted from the sedit structural editor (sedit/sedit.lisp on the sedit
;;;; branch), but *non-mutating*: the debugger must never alter the program's
;;;; source, so instead of splicing a selection marker into the sexp, the
;;;; navigator tracks a *path* — a list of element indices from the root form to
;;;; the selected sub-sexp — and renders a marked copy on demand. The motions
;;;; (down/up/forward/backward/first/last/skip) are the sedit ones expressed over
;;;; the path; they are the same keys (=d u > < << >> ±N=) the command reference
;;;; gives every level of the one tree.

(in-package #:clautolisp.debug.ui)

(defstruct (navigator (:constructor %make-navigator))
  (root nil)            ; the source form (read-only)
  (path '() :type list))  ; element indices root→selection; () selects the root

(defun make-navigator (sexp)
  "A navigator over SEXP, the root selected."
  (%make-navigator :root sexp :path '()))

(defun path-ref (sexp path)
  "The sub-sexp of SEXP reached by following the element-index PATH."
  (cond ((null path) sexp)
        ((consp sexp) (path-ref (nth (first path) sexp) (rest path)))
        (t sexp)))

(defun nav-selected (nav)
  "The currently-selected sub-sexp."
  (path-ref (navigator-root nav) (navigator-path nav)))

(defun nav-parent (nav)
  "The list containing the selection (NIL at the root)."
  (and (navigator-path nav)
       (path-ref (navigator-root nav) (butlast (navigator-path nav)))))

(defun nav-index (nav)
  "The selection's index in its parent, or NIL at the root."
  (car (last (navigator-path nav))))

(defun %set-last-index (nav i)
  (setf (navigator-path nav) (append (butlast (navigator-path nav)) (list i)))
  nav)

;;; --- motions (each returns NAV) ---------------------------------------

(defun nav-down (nav)
  "Descend into the first element of the selected list (no-op on an atom or
empty list)."
  (let ((sel (nav-selected nav)))
    (when (and (consp sel))
      (setf (navigator-path nav) (append (navigator-path nav) (list 0)))))
  nav)

(defun nav-up (nav)
  "Ascend to the enclosing list (no-op at the root)."
  (when (navigator-path nav)
    (setf (navigator-path nav) (butlast (navigator-path nav))))
  nav)

(defun nav-forward (nav)
  "Select the next sibling (clamped at the last; no-op at the root)."
  (let ((parent (nav-parent nav)) (i (nav-index nav)))
    (when (and (listp parent) i (< (1+ i) (length parent)))
      (%set-last-index nav (1+ i))))
  nav)

(defun nav-backward (nav)
  "Select the previous sibling (clamped at the first; no-op at the root)."
  (let ((i (nav-index nav)))
    (when (and i (plusp i))
      (%set-last-index nav (1- i))))
  nav)

(defun nav-first (nav)
  "Select the first sibling (no-op at the root)."
  (when (navigator-path nav) (%set-last-index nav 0))
  nav)

(defun nav-last (nav)
  "Select the last sibling (no-op at the root)."
  (let ((parent (nav-parent nav)))
    (when (and (listp parent) parent)
      (%set-last-index nav (1- (length parent)))))
  nav)

(defun nav-skip (nav n)
  "Skip N siblings forward (N>0) or backward (N<0), clamped (no-op at the root)."
  (let ((parent (nav-parent nav)) (i (nav-index nav)))
    (when (and (listp parent) parent i)
      (%set-last-index nav (max 0 (min (1- (length parent)) (+ i n))))))
  nav)

;;; --- code vs non-code sub-forms (per special operator) ----------------
;;;
;;; AutoLISP special operators have sub-forms that are NOT evaluated as code and
;;; therefore carry no poll point: the quoted datum of QUOTE, the variables of
;;; SETQ, the name and arg-list of DEFUN, etc. The navigator consults this table
;;; to tell code (poll-pointable) sub-forms from non-code ones, so a structural
;;; designation lands on a real poll point. To support a NEW special operator,
;;; add one (NAME . ROLE-FN) entry — ROLE-FN maps a 1-based argument index to a
;;; role: :code (an evaluated form), :non-code (a datum / name / variable), or
;;; :group (a structural list — e.g. a COND clause — whose own elements follow
;;; ordinary rules). Operators absent here are ordinary forms: every argument is
;;; :code. (The 17 runtime special operators of
;;; clautolisp.autolisp-runtime::*special-operator-dispatch* are covered; the
;;; all-:code ones — SET, PROGN, IF, AND, OR, WHILE, REPEAT — need no entry.)

;;; Each grammar entry is a function (FORM INDEX) → (values ROLE CHILD-CONTEXT):
;;; ROLE classifies the child at INDEX; CHILD-CONTEXT is the grammar context to
;;; use when descending INTO that child (NIL = no further structure). This makes
;;; the classification *context-aware*, so nested non-code structure works —
;;; e.g. a BricsCAD LET, =(let ((v1 e1) … (vn en)) body…)=, whose binding list
;;; is a group of bindings, each binding =(vi ei)= having a non-code variable
;;; =vi= and a code init =ei=.

(defparameter *special-form-grammars*
  (list
   (cons "QUOTE"    (lambda (form i) (declare (ignore form i)) (values :non-code nil)))
   (cons "FUNCTION" (lambda (form i) (declare (ignore form)) (if (= i 1) (values :non-code nil) (values :code :form))))
   (cons "SETQ"     (lambda (form i) (declare (ignore form)) (if (oddp i) (values :non-code nil) (values :code :form))))
   (cons "DEFUN"    (lambda (form i) (declare (ignore form)) (if (<= i 2) (values :non-code nil) (values :code :form))))
   (cons "DEFUN-Q"  (lambda (form i) (declare (ignore form)) (if (<= i 2) (values :non-code nil) (values :code :form))))
   (cons "LAMBDA"   (lambda (form i) (declare (ignore form)) (if (= i 1) (values :non-code nil) (values :code :form))))
   (cons "FOREACH"  (lambda (form i) (declare (ignore form)) (if (= i 1) (values :non-code nil) (values :code :form))))
   (cons "COND"     (lambda (form i) (declare (ignore form i)) (values :group :cond-clause)))
   (cons "TRACE"    (lambda (form i) (declare (ignore form i)) (values :non-code nil)))
   (cons "UNTRACE"  (lambda (form i) (declare (ignore form i)) (values :non-code nil)))
   ;; BricsCAD LET (not a clautolisp special operator today, but the grammar is
   ;; ready): the binding list is a group of bindings; the body is code.
   (cons "LET"      (lambda (form i) (declare (ignore form)) (if (= i 1) (values :group :let-bindings) (values :code :form))))
   (cons "LET*"     (lambda (form i) (declare (ignore form)) (if (= i 1) (values :group :let-bindings) (values :code :form)))))
  "Special-operator name → child grammar (FORM INDEX → (values ROLE CHILD-CONTEXT)).
Add a special operator with one entry. Operators absent here are ordinary forms
(all arguments :code).")

(defparameter *sub-grammars*
  (list
   ;; the LET binding list: each element is a binding
   (cons :let-bindings (lambda (form i) (declare (ignore form i)) (values :group :let-binding)))
   ;; a single LET binding (var init): var is non-code, init is code
   (cons :let-binding  (lambda (form i) (declare (ignore form)) (if (zerop i) (values :non-code nil) (values :code :form))))
   ;; a COND clause (test body…): every element is code
   (cons :cond-clause  (lambda (form i) (declare (ignore form i)) (values :code :form))))
  "Sub-structure context → child grammar, for the nested non-code structure a
:group child opens (e.g. a LET binding list, a COND clause). Same shape as
*special-form-grammars*.")

(defun %operator-name (head)
  "The upper-case operator name of a form head (an AutoLISP or CL symbol), or
NIL if HEAD is not a symbol."
  (cond ((typep head 'clautolisp.autolisp-runtime:autolisp-symbol)
         (string-upcase (clautolisp.autolisp-runtime:autolisp-symbol-name head)))
        ((symbolp head) (string-upcase (symbol-name head)))
        (t nil)))

(defun classify-in-context (context form index)
  "Classify the child at INDEX of FORM in grammar CONTEXT; return (values ROLE
CHILD-CONTEXT). CONTEXT :form is an ordinary code form (dispatch on the head's
operator); other contexts are sub-grammar names."
  (if (eq context :form)
      (if (zerop index)
          (values :non-code nil)               ; the operator / function position
          (let ((g (and (consp form)
                        (cdr (assoc (%operator-name (car form)) *special-form-grammars*
                                    :test #'string=)))))
            (if g (funcall g form index) (values :code :form))))
      (let ((g (cdr (assoc context *sub-grammars*))))
        (if g (funcall g form index) (values :code :form)))))

(defun role-at-path (root path)
  "Walk PATH from ROOT tracking grammar context; return the role (:code |
:non-code | :group) of the node at PATH (:code at the root)."
  (let ((context :form) (form root) (role :code))
    (dolist (index path role)
      (multiple-value-bind (r child-context) (classify-in-context context form index)
        (setf role r
              form (and (consp form) (nth index form))
              context (or child-context :form))))))

(defun child-role (parent index)
  "The role of the child at INDEX of PARENT treated as a top-level form (0 = the
operator position): :code | :non-code | :group. (One-level convenience; use
ROLE-AT-PATH for context-aware nested classification.)"
  (if (consp parent)
      (values (classify-in-context :form parent index))
      :code))

(defun nav-selected-role (nav)
  "The role of the selected node (:code at the root) — context-aware, so e.g. a
LET binding variable is :non-code even though it is nested two lists deep."
  (role-at-path (navigator-root nav) (navigator-path nav)))

(defun nav-code-p (nav)
  "True when the selected node sits in a *code* position — an evaluated form, so
poll-pointable. Non-code data/names and structural groups return NIL."
  (eq :code (nav-selected-role nav)))

;;; --- code-aware motions (debugger: skip non-expression sub-forms) -----
;;;
;;; The structural motions above land on every child, including non-code ones —
;;; a form's operator, DEFUN's name and arg-list, QUOTE's datum, SETQ's
;;; variables. The debugger navigator uses these variants instead: they step
;;; only onto navigable positions (:code / :group — the evaluated sub-forms you
;;; can breakpoint), skipping :non-code parts (aldo-pre-debug.issue).

(defun %nav-navigable-p (nav path)
  "True when the node at PATH is a navigable (non-:non-code) position."
  (not (eq :non-code (role-at-path (navigator-root nav) path))))

(defun %nav-navigable-child-indices (nav base)
  "Indices of the navigable (code/group) children of the node at BASE."
  (let ((node (path-ref (navigator-root nav) base)))
    (when (consp node)
      (loop for i from 0 below (length node)
            when (%nav-navigable-p nav (append base (list i)))
              collect i))))

(defun nav-code-down (nav)
  "Descend to the first navigable child of the selection, skipping leading
non-code parts (no-op on an atom or a form with no navigable child)."
  (let* ((base (navigator-path nav))
         (indices (and (consp (nav-selected nav))
                       (%nav-navigable-child-indices nav base))))
    (when indices
      (setf (navigator-path nav) (append base (list (first indices))))))
  nav)

(defun %nav-code-sibling (nav pick)
  "Move to the navigable sibling PICK selects from (CURRENT-INDEX INDICES); NAV."
  (let* ((i (nav-index nav))
         (indices (%nav-navigable-child-indices nav (butlast (navigator-path nav))))
         (target (and i indices (funcall pick i indices))))
    (when target (%set-last-index nav target)))
  nav)

(defun nav-code-forward (nav)
  "Select the next navigable sibling (no-op if none)."
  (%nav-code-sibling nav (lambda (i idxs) (find-if (lambda (j) (> j i)) idxs))))

(defun nav-code-backward (nav)
  "Select the previous navigable sibling (no-op if none)."
  (%nav-code-sibling nav (lambda (i idxs) (find-if (lambda (j) (< j i)) (reverse idxs)))))

(defun nav-code-first (nav)
  "Select the first navigable sibling (no-op if none)."
  (%nav-code-sibling nav (lambda (i idxs) (declare (ignore i)) (first idxs))))

(defun nav-code-last (nav)
  "Select the last navigable sibling (no-op if none)."
  (%nav-code-sibling nav (lambda (i idxs) (declare (ignore i)) (car (last idxs)))))

(defun nav-code-skip (nav n)
  "Skip N navigable siblings forward (N>0) or backward (N<0), clamped."
  (%nav-code-sibling nav
                     (lambda (i idxs)
                       (let ((pos (position i idxs)))
                         (and pos (nth (max 0 (min (1- (length idxs)) (+ pos n))) idxs))))))

;;; --- rendering --------------------------------------------------------

(defun %render-marked (sexp path open close stream)
  (cond
    ((null path) (write-string open stream) (prin1 sexp stream) (write-string close stream))
    ((consp sexp)
     (write-char #\( stream)
     (loop for rest on sexp
           for i from 0
           for first = t then nil
           do (unless first (write-char #\Space stream))
              (if (eql i (first path))
                  (%render-marked (car rest) (rest path) open close stream)
                  (prin1 (car rest) stream))
              ;; a dotted tail
              (when (and (cdr rest) (atom (cdr rest)))
                (write-string " . " stream)
                (prin1 (cdr rest) stream)))
     (write-char #\) stream))
    (t (prin1 sexp stream))))   ; path into a non-cons: just print it

(defun nav-render (nav &optional (open "【") (close "】"))
  "A string of the root form with the selected sub-sexp wrapped in OPEN/CLOSE
(the selection decoration; command reference §8 / TUI decoration table). Bound
non-pretty so a large form stays on one compact line — the host pretty-printer
would otherwise wrap it with deep, unwieldy indentation."
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (%render-marked (navigator-root nav) (navigator-path nav) open close stream))))

;;; --- verbatim source listing ------------------------------------------
;;;
;;; When the navigated form was read under source tracking, its sub-forms
;;; carry SOURCE-POSITIONs (clautolisp.source). We prefer to show the form
;;; using its ORIGINAL source text — the file's own line breaks and
;;; indentation — instead of re-printing the reconstructed sexp (which the
;;; pretty-printer lays out with its own, much larger, indentation). The
;;; selected sub-form's line is flagged with a >> gutter.

(defun %nav-collect-positions (node acc)
  "Collect every recorded SOURCE-POSITION under NODE (a form tree) into ACC,
iterating the list spine and recursing into cars."
  (loop
    (if (consp node)
        (progn
          (let ((position (clautolisp.source:position-of node)))
            (when position (push position acc)))
          (setf acc (%nav-collect-positions (car node) acc))
          (setf node (cdr node)))
        (return acc))))

(defun %nav-dominant-file (positions)
  "The file named by the most POSITIONS (the function's own file), or NIL."
  (let ((counts (make-hash-table :test 'equal))
        (best nil) (best-n 0))
    (dolist (position positions)
      (let ((file (clautolisp.source:source-position-file position)))
        (when file (incf (gethash file counts 0)))))
    (maphash (lambda (file n) (when (> n best-n) (setf best file best-n n))) counts)
    best))

(defun nav-selected-position (nav)
  "The SOURCE-POSITION of the selected node, or of its nearest positioned
ancestor, or NIL. (Atoms and the reconstructed root cons carry no position;
walking up the path lands on a positioned enclosing form.)"
  (let ((path (navigator-path nav)))
    (loop
      (let ((position (clautolisp.source:position-of
                       (path-ref (navigator-root nav) path))))
        (when position (return position)))
      (when (null path) (return nil))
      (setf path (butlast path)))))

(defun %nav-listing-for-node (nav node &optional breakpoint-lines (bp-glyph "^"))
  "A verbatim source listing of NODE (a sub-tree of NAV's root) — the file's own
lines spanning NODE, each with its line number and original indentation. The
selected node's line is flagged with a >> gutter; a line in BREAKPOINT-LINES gets
the BP-GLYPH breakpoint marker (the enabled-breakpoint decoration — ⏸ / ^, TUI
spec decoration table). NIL when no source text is available (not read under
source tracking, or the file is unreadable)."
  (let ((positions (%nav-collect-positions node '())))
    (when positions
      (let* ((file (%nav-dominant-file positions))
             (here (remove-if-not
                    (lambda (p) (equal (clautolisp.source:source-position-file p) file))
                    positions))
             (lines (and file (ignore-errors (clautolisp.source:lines-of file)))))
        (when (and file here lines (plusp (length lines)))
          (let* ((start (reduce #'min here
                                :key #'clautolisp.source:source-position-start-line))
                 (end   (reduce #'max here
                                :key #'clautolisp.source:source-position-end-line))
                 (selected (nav-selected-position nav))
                 (target (and selected
                              (equal (clautolisp.source:source-position-file selected) file)
                              (clautolisp.source:source-position-start-line selected))))
            (with-output-to-string (stream)
              (loop for n from (max 1 start) to (min (length lines) end)
                    for text = (aref lines (1- n))
                    do (format stream "~A~A~3D:   ~A~%"
                               (if (member n breakpoint-lines) bp-glyph " ")
                               (if (eql n target) ">>" "  ")
                               n text)))))))))

(defun nav-source-listing (nav &optional breakpoint-lines (bp-glyph "^"))
  "Verbatim source listing spanning NAV's whole root form (the whole function),
the selection flagged >> and any BREAKPOINT-LINES flagged with BP-GLYPH (the
enabled-breakpoint decoration). NIL when no source text is available."
  (%nav-listing-for-node nav (navigator-root nav) breakpoint-lines bp-glyph))
