(in-package #:clautolisp.debug)

;;;; Form-level jump (command reference §1 jump). A jump resumes control flow at
;;;; a target poll point, *skipping the evaluation* of the forms in between
;;;; rather than running them (unlike `advance', which runs the intervening
;;;; code). The mechanism is the one in the command reference: a poll point
;;;; consults the pending target before evaluating its form's body —
;;;;
;;;;   - the poll point IS the target          → resume here (leave jump mode);
;;;;   - the target is a descendant of the form → evaluate it to descend, keep
;;;;     jumping (so we reach a target nested inside this form);
;;;;   - otherwise                              → skip the form (do not evaluate
;;;;     its body); the surrounding control structure carries execution onward.
;;;;
;;;; eval-poll-form (poll.lisp) performs the skip; poll-point suppresses stops
;;;; while a jump is pending. Because the jump re-enters through the genuine
;;;; control structures, re-running them re-establishes bindings and frames.
;;;;
;;;; This is a v1: it implements *forward jumps within the current function*
;;;; (the "clean" case of the spec — skip-forward, optionally descending). A
;;;; target that control flow never reaches (e.g. inside an un-taken branch) is
;;;; abandoned by a safety net (JUMP-EXIT-CHECK) when the target's function
;;;; returns, so a missed jump degrades to "the rest of the function is skipped"
;;;; rather than skipping the remainder of the program. Backward and
;;;; cross-function jumps — the ancestor re-drive worked through in
;;;; documentation/jump-back.lsp — are not yet implemented.

(defun request-jump (ti fid form-id)
  "Arm a jump to poll point (FID, FORM-ID) on TI."
  (setf (thread-debug-info-jump-target ti) (cons fid form-id)))

(defun clear-jump (ti)
  "Cancel any pending jump on TI."
  (setf (thread-debug-info-jump-target ti) nil))

(defun jump-pending-p (ti)
  (and (thread-debug-info-jump-target ti) t))

(defun jump-disposition (ti fid form-id)
  "With a jump pending, classify the poll point (FID, FORM-ID): :RESUME (it IS
the target — clears the jump and resumes normal execution here), :DESCEND (the
target is nested in this form — evaluate it to descend, keep jumping), or :SKIP
(skip this form's body). NIL when no jump is pending."
  (let ((target (thread-debug-info-jump-target ti)))
    (cond
      ((null target) nil)
      ((and (eql (car target) fid) (eql (cdr target) form-id))
       (clear-jump ti)
       :resume)
      ((and (eql (car target) fid)
            (form-ancestor-p (metadata-for-function-id fid) form-id (cdr target)))
       :descend)
      (t :skip))))

(defun jump-exit-check (ti fid form-id)
  "Safety net: if a jump to a poll point in function FID is still pending when
that function's entry form (FORM-ID 0) finishes evaluating, the target was never
reached (an un-taken branch). Cancel the jump so execution resumes normally
instead of skipping the rest of the program."
  (let ((target (thread-debug-info-jump-target ti)))
    (when (and target (eql form-id 0) (eql (car target) fid))
      (clear-jump ti))))
