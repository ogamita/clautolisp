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

(test cadgui-supply-point-returns-a-typed-value
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (is (equal '(:point 3d0 4d0) (cadgui-supply-point 3 4)))))

(test cadgui-supply-entity-returns-a-typed-value
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (is (equal '(:entity "2A") (cadgui-supply-entity "2A")))))

(test cadgui-eval-command-reports-the-regen-entity-count
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (cadgui-add-line 0 0 1 1)
    (is (= 1 (cadgui-eval-command "LINE")))))
