;;;; cadgui action layer -- SLICE E: record / replay.
;;;; cadgui-action-layer.issue.
;;;;
;;;; Because every state-mutating operation goes through CADGUI-INVOKE-ACTION
;;;; (the invariant slice D guards), a session records faithfully as a transcript
;;;; of (:invoke ID . ARGS) entries -- plain, serialisable s-expressions. That one
;;;; artefact is the test fixture, the AI's feedback loop, and the bug repro:
;;;; replay it on a fresh session and the final state is reproduced deterministically.
;;;;
;;;; Recording hangs off the dispatch point (*cadgui-transcript*, actions.lisp):
;;;; CADGUI-RECORDING-TRANSCRIPT binds the recorder, runs the body, and leaves the
;;;; chronological transcript in VAR. CADGUI-REPLAY-TRANSCRIPT re-invokes each
;;;; entry through the same single entry point.

(in-package #:clautolisp.cadgui)

(defmacro cadgui-recording-transcript ((var) &body body)
  "Run BODY recording every CADGUI-INVOKE-ACTION call, then set VAR (a settable
place) to the chronological transcript -- a list of (:invoke ID . ARGS). Returns
BODY's value(s). The transcript is plain s-expressions: print it, store it, diff
it, or hand it to CADGUI-REPLAY-TRANSCRIPT."
  (let ((header (gensym "TRANSCRIPT")))
    `(let* ((,header (list :transcript))
            (*cadgui-transcript* ,header))
       (multiple-value-prog1 (progn ,@body)
         (setf ,var (reverse (cdr ,header)))))))

(defun cadgui-replay-transcript (transcript &key (reset t))
  "Replay TRANSCRIPT -- a list of (:invoke ID . ARGS) entries -- by re-invoking
each through CADGUI-INVOKE-ACTION, in order. With RESET (default) start a fresh
cadgui session first, so replay reproduces the recorded run's final state from an
empty drawing (deterministic replay). Returns the number of actions replayed.
Ignores a non-:invoke entry (forward-compatible with future transcript entries)."
  (when reset (cadgui-start))
  (let ((n 0))
    (dolist (entry transcript)
      (when (and (consp entry) (eq (first entry) :invoke))
        (apply #'cadgui-invoke-action (second entry) (cddr entry))
        (incf n)))
    n))

(defun cadgui-transcript-actions (transcript)
  "The action ids named by TRANSCRIPT, in order -- a quick summary of a recorded
session for display / logging."
  (loop for entry in transcript
        when (and (consp entry) (eq (first entry) :invoke))
          collect (second entry)))
