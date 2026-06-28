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
