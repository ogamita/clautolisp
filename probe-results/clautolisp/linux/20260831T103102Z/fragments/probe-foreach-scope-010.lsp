(defun cad-probe-foreach--return-value ()
  ;; The documented return: the last body value, and nil for an empty
  ;; LIST. The empty BODY case is probed separately, below, and not from
  ;; here -- see why.
  (list (foreach e (list 1 2 3) (* e 10))
        (foreach e nil 99)))

;;; SYNTAX A HOST MIGHT REJECT GOES IN A STRING, not in this file's forms.
;;;
;;; `(foreach e lst)' with NO BODY used to sit in the function above, and
;;; it cost two days: BricsCAD would not LOAD this file because of it --
;;; on both platforms, before a single probe ran, taking the other five
;;; cases down with it and looking for all the world like a crash in the
;;; harness. AutoCAD and clautolisp both accept the form, so nothing local
;;; showed it.
;;;
;;; A probe asks whether an engine accepts something. Writing the
;;; questionable form directly means the engine answers by refusing to
;;; read the file, which is not an answer, it is a silence. Held as text
;;; and READ at run time, a refusal becomes a recorded `error' status for
;;; that one case -- which is the answer -- and the rest of the suite
;;; still runs.
;;;
;;; (An empty loop body is not an exotic case: `(while (setq i (cdr i)))'
;;; is how AutoLISP drains a list, and the same shape broke clautolisp's
;;; own compiler -- issues/closed/compiled-loop-with-empty-body.issue.)

