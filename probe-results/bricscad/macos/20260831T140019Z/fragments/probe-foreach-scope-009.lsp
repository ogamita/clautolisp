(defun cad-probe-foreach--empty-list ( / e)
  ;; An empty list runs no iteration. Under binding semantics e is still
  ;; BEFORE; under assignment it is also BEFORE, so this case separates
  ;; "assigns per iteration" from "assigns once up front".
  (setq e 'before)
  (foreach e nil nil)
  e)

;;; THE RETURN VALUE, in three cases READ AT RUN TIME.
;;;
;;; These three sat in one function, written directly, and BricsCAD
;;; would not LOAD the file because of it -- on both platforms, before
;;; a single probe ran. Splitting the suite one form per file is what
;;; finally NAMED the function (form 10 of 13); until then the file
;;; simply went quiet after form 9 and the cause was guessed at twice,
;;; wrongly both times.
;;;
;;; Which of the three BricsCAD objects to is exactly what these
;;; separate them to find out: FOREACH in EXPRESSION POSITION (as an
;;; argument to LIST), FOREACH over an EMPTY LIST, or neither. Held as
;;; text and READ when the case runs, a refusal is recorded as that
;;; one case's `error' -- which is the answer -- instead of taking the
;;; suite down with it.

