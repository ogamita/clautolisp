;;;; Tests for the cadgui input bridge (input.lisp). cadgui-2-qt6-gui-host.issue
;;;; slice D: getpoint / entsel driven from the canvas through the GUI prompt
;;;; stream, with the mouse "clicks" scripted via *cadgui-input-hook*.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-getpoint-reads-a-scripted-canvas-click
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let* ((host (cadgui-session-host *cadgui-session*))
           (clicks (list (cadgui-point-line 3 4)))
           (*cadgui-input-hook* (lambda () (pop clicks))))
      (let ((pt (host-getpoint host nil)))
        (is (not (null pt)))
        (is (= 3 (first pt)))
        (is (= 4 (second pt)))))))

(test cadgui-entsel-picks-the-entity-at-a-scripted-click
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let ((host (cadgui-session-host *cadgui-session*)))
      (cadgui-add-line 0 0 10 0)                        ; a line along y = 0
      (let* ((clicks (list (cadgui-point-line 5 0)))    ; click on it
             (*cadgui-input-hook* (lambda () (pop clicks)))
             (res (host-entsel host nil)))
        (is (not (null res)))                           ; (ename point)
        (is (= 2 (length res)))))))

(test cadgui-entsel-on-empty-space-returns-nil
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let ((host (cadgui-session-host *cadgui-session*)))
      (cadgui-add-line 0 0 10 0)
      (let* ((clicks (list (cadgui-point-line 5 50)))   ; far from the line
             (*cadgui-input-hook* (lambda () (pop clicks))))
        (is (null (host-entsel host nil)))))))

(test cadgui-pending-input-is-point-while-a-read-blocks-and-clears-after
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let* ((host (cadgui-session-host *cadgui-session*))
           (seen :unset)
           (*cadgui-input-hook*
             (lambda () (setf seen *cadgui-pending-input*) (cadgui-point-line 1 1))))
      (host-getpoint host nil)
      (is (eq :point seen))                 ; :point while the read blocked
      (is (null *cadgui-pending-input*)))))  ; cleared afterwards

(test cadgui-point-line-formats-a-coordinate-pair
  (is (string= "2.5,-3.0" (cadgui-point-line 2.5 -3))))

(test cadgui-entsel-sets-the-selection-for-highlight
  ;; A canvas entsel records the picked entity as the GUI selection; the shell
  ;; reads cadgui-selection-geometry to overdraw it highlighted.
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let ((host (cadgui-session-host *cadgui-session*)))
      (cadgui-add-line 0 0 10 0)
      (is (null (cadgui-selection)))                 ; nothing picked yet
      (let* ((clicks (list (cadgui-point-line 5 0))) ; click on the line
             (*cadgui-input-hook* (lambda () (pop clicks))))
        (host-entsel host nil))
      (is (= 1 (length (cadgui-selection))))         ; one entity selected
      (let ((geom (cadgui-selection-geometry)))
        (is (= 1 (length geom)))
        (destructuring-bind (type handle layer aci closed points) (first geom)
          (declare (ignore handle layer aci closed))
          (is (eq :polyline type))
          (is (equal '(0d0 0d0 10d0 0d0) points))))))) ; the line's outline, to highlight

(test cadgui-entsel-on-empty-space-leaves-no-selection
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (let ((host (cadgui-session-host *cadgui-session*)))
      (cadgui-add-line 0 0 10 0)
      (let* ((clicks (list (cadgui-point-line 5 50))) ; far from the line
             (*cadgui-input-hook* (lambda () (pop clicks))))
        (host-entsel host nil))
      (is (null (cadgui-selection))))))
