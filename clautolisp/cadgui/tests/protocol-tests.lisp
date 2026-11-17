;;;; Tests for the cadgui host CL protocol (protocol.lisp + session.lisp).
;;;; cadgui-2-qt6-gui-host.issue slices A/C/D/E/F (CL side).

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-start-makes-an-empty-session
  (let ((*cadgui-session* nil))
    (let ((s (cadgui-start)))
      (is (not (null (cadgui-session-host s))))
      (is (null (cadgui-display-list)))
      (is (zerop (cadgui-entity-count)))
      (is (null (cadgui-extents))))))

(test cadgui-add-line-shows-in-the-display-list
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-line 0 0 10 5 :layer "G" :color 2)
    (let ((dl (cadgui-display-list)))
      (is (= 1 (length dl)))
      (destructuring-bind (type handle layer aci closed points) (first dl)
        (declare (ignore handle closed))
        (is (eq :polyline type))
        (is (string= "G" layer))
        (is (= 2 aci))
        (is (equal '(0d0 0d0 10d0 5d0) points))))))

(test cadgui-add-circle-and-zoom-extents
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-circle 5 5 2)
    (is (= 1 (cadgui-entity-count)))
    (destructuring-bind (x0 y0 x1 y1) (cadgui-extents)
      (is (= 3d0 x0)) (is (= 3d0 y0)) (is (= 7d0 x1)) (is (= 7d0 y1)))))

(test cadgui-builds-the-real-model-so-several-entities-accumulate
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-line 0 0 1 0)
    (cadgui-add-line 1 0 1 1)
    (cadgui-add-circle 0 0 3)
    (is (= 3 (cadgui-entity-count)))))

(test cadgui-eval-command-runs-autolisp-that-draws-and-reports-regen-count
  ;; Slice E: an AutoLISP command string evaluated against the active drawing
  ;; through the real engine draws, and the regen count reflects it.
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (is (zerop (cadgui-entity-count)))
    (let ((n (cadgui-eval-command
              "(entmake (list (cons 0 \"LINE\") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 5.0 5.0 0.0))))")))
      (is (= 1 n))
      (is (= 1 (cadgui-entity-count))))))

(test cadgui-eval-command-command-builtin-draws-on-the-session-drawing
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-eval-command "(command \"CIRCLE\" (list 0.0 0.0) 2.0)")
    (is (= 1 (cadgui-entity-count)))))

;;; ssget window / crossing driven by TWO corners read from the canvas through
;;; the input bridge (cadgui-2 "ssget window/crossing (two-point)"). The command
;;; reads both corners with (getpoint) -- fed by scripted clicks via
;;; *cadgui-input-hook* -- then ssget "W"/"C" selects through the real cador
;;; engine. Observed via an erase of the selected member: the entity count is
;;; the regen signal cadgui-eval-command returns.

(test cadgui-ssget-window-two-corners-from-the-canvas-selects-enclosed
  ;; Window over (0,0)-(5,5) selects the fully-enclosed line A and erases it;
  ;; the outside line B remains.
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-line 1 1 4 4)                 ; A: fully inside the window
    (cadgui-add-line 20 20 25 25)            ; B: outside
    (let* ((clicks (list (cadgui-point-line 0 0) (cadgui-point-line 5 5)))
           (*cadgui-input-hook* (lambda () (pop clicks))))
      (cadgui-eval-command
       "(setq ss (ssget \"W\" (getpoint) (getpoint))) (if ss (entdel (ssname ss 0)))"))
    (is (= 1 (cadgui-entity-count)))))        ; A erased, B remains

(test cadgui-ssget-window-excludes-a-crossing-line-but-crossing-selects-it
  ;; A line crossing the window boundary: "W" (fully-enclosed only) selects
  ;; nothing; "C" (crossing) selects and erases it.
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-line 3 3 10 10)              ; crosses (0,0)-(5,5)
    (let* ((wc (list (cadgui-point-line 0 0) (cadgui-point-line 5 5)))
           (*cadgui-input-hook* (lambda () (pop wc))))
      (cadgui-eval-command
       "(setq ss (ssget \"W\" (getpoint) (getpoint))) (if ss (entdel (ssname ss 0)))"))
    (is (= 1 (cadgui-entity-count)))          ; window excluded the crossing line
    (let* ((cc (list (cadgui-point-line 0 0) (cadgui-point-line 5 5)))
           (*cadgui-input-hook* (lambda () (pop cc))))
      (cadgui-eval-command
       "(setq ss (ssget \"C\" (getpoint) (getpoint))) (if ss (entdel (ssname ss 0)))"))
    (is (= 0 (cadgui-entity-count)))))        ; crossing erased it
