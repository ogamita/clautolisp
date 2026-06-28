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

(defparameter *special-form-arg-roles*
  (list
   (cons "QUOTE"    (constantly :non-code))                          ; the datum
   (cons "FUNCTION" (lambda (i) (if (= i 1) :non-code :code)))       ; the designator
   (cons "SETQ"     (lambda (i) (if (oddp i) :non-code :code)))      ; var val var val …
   (cons "DEFUN"    (lambda (i) (if (<= i 2) :non-code :code)))      ; name arglist body…
   (cons "DEFUN-Q"  (lambda (i) (if (<= i 2) :non-code :code)))      ; name arglist body…
   (cons "LAMBDA"   (lambda (i) (if (= i 1) :non-code :code)))       ; arglist body…
   (cons "FOREACH"  (lambda (i) (if (= i 1) :non-code :code)))       ; var list body…
   (cons "COND"     (constantly :group))                            ; (test body…) clauses
   (cons "TRACE"    (constantly :non-code))                          ; function-name symbols
   (cons "UNTRACE"  (constantly :non-code)))                         ; function-name symbols
  "Per-special-operator role of each argument; see the commentary above.")

(defun %operator-name (head)
  "The upper-case operator name of a form head (an AutoLISP or CL symbol), or
NIL if HEAD is not a symbol."
  (cond ((typep head 'clautolisp.autolisp-runtime:autolisp-symbol)
         (string-upcase (clautolisp.autolisp-runtime:autolisp-symbol-name head)))
        ((symbolp head) (string-upcase (symbol-name head)))
        (t nil)))

(defun child-role (parent index)
  "The role of the child at INDEX of PARENT (0 = the operator/function position):
:code | :non-code | :group. The operator position is :non-code; arguments
default to :code unless PARENT is a special form with a role-table entry."
  (cond
    ((not (consp parent)) :code)
    ((zerop index) :non-code)
    (t (let* ((op (%operator-name (car parent)))
              (fn (and op (cdr (assoc op *special-form-arg-roles* :test #'string=)))))
         (if fn (funcall fn index) :code)))))

(defun nav-selected-role (nav)
  "The role of the selected node (:code at the root): whether it is an evaluated
sub-form, a non-code datum/name, or a structural group."
  (if (null (navigator-path nav))
      :code
      (child-role (nav-parent nav) (nav-index nav))))

(defun nav-code-p (nav)
  "True when the selected node sits in a *code* position — an evaluated form, so
poll-pointable. Non-code data/names and structural groups return NIL."
  (eq :code (nav-selected-role nav)))

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
(the selection decoration; command reference §8 / TUI decoration table)."
  (with-output-to-string (stream)
    (%render-marked (navigator-root nav) (navigator-path nav) open close stream)))
