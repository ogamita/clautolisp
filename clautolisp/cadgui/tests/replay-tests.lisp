;;;; Tests for cadgui record / replay (replay.lisp) -- slice E of
;;;; cadgui-action-layer. A session records as a transcript of invoke-action
;;;; calls -- plain s-expressions -- and replays deterministically to the same
;;;; final state on a fresh session.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(defun %cadgui-scene-geometry (display-list)
  "Project a display list to (TYPE POINTS) per item -- the drawing's state
independent of internal handle ids -- so two sessions compare by what was drawn."
  (mapcar (lambda (item) (list (first item) (sixth item))) display-list))

(test cadgui-record-and-replay-reproduces-the-final-state
  ;; Record a drawing session as a transcript, then replay it on a FRESH session
  ;; and get the identical final geometry -- the one artefact that is the test
  ;; fixture, the AI feedback loop and the bug repro.
  (cadgui-start)
  (let (tr)
    (cadgui-recording-transcript (tr)
      (cadgui-invoke-action :add-line 0 0 5 5)
      (cadgui-invoke-action :add-circle 2 2 1)
      (cadgui-invoke-action :add-line 1 1 3 3))
    (is (= 3 (length tr)))
    (is (equal '(:add-line :add-circle :add-line) (cadgui-transcript-actions tr)))
    (let ((original (%cadgui-scene-geometry (cadgui-display-list))))
      (is (= 3 (length original)))
      ;; replay from empty reproduces the same final state
      (is (= 3 (cadgui-replay-transcript tr)))
      (is (equal original (%cadgui-scene-geometry (cadgui-display-list)))))))

(test cadgui-transcript-is-plain-serialisable-sexp
  ;; The transcript is plain data: it round-trips through print / read unchanged,
  ;; so it can be stored as a fixture file and read back.
  (cadgui-start)
  (let (tr)
    (cadgui-recording-transcript (tr)
      (cadgui-invoke-action :add-line 0 0 1 1)
      (cadgui-invoke-action :add-circle 0 0 2))
    (is (equal '(:invoke :add-line 0 0 1 1) (first tr)))
    (is (equal '(:invoke :add-circle 0 0 2) (second tr)))
    (is (equal tr (read-from-string (prin1-to-string tr))))))

(test cadgui-replay-ignores-only-invoke-entries
  ;; Replay is forward-compatible: a non-:invoke entry (a future transcript kind)
  ;; is skipped, and the invoke entries still replay.
  (cadgui-start)
  (is (= 2 (cadgui-replay-transcript
            '((:invoke :add-line 0 0 4 4)
              (:note "a future entry kind the replayer does not know")
              (:invoke :add-circle 1 1 1)))))
  (is (= 2 (cadgui-entity-count))))
