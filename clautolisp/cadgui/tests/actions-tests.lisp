;;;; Tests for the cadgui action layer (actions.lisp). cadgui-action-layer.issue
;;;; slice 1: the registry, uniform dispatch (invoke-action) and introspection
;;;; (list-actions / describe-action). The layer a test drives and an AI driver
;;;; drives are the same layer -- these tests ARE the driveability check for the
;;;; registered actions.

(in-package #:clautolisp.cadgui.tests)

(in-suite cadgui-suite)

(test cadgui-action-registry-lists-the-builtins
  (let ((actions (cadgui-list-actions)))
    (is (member :add-line actions))
    (is (member :add-circle actions))
    (is (member :eval-command actions))
    (is (member :entity-count actions))
    (is (member :selection actions)))
  ;; category filtering
  (is (member :add-line (cadgui-list-actions :draw)))
  (is (not (member :eval-command (cadgui-list-actions :draw)))))

(test cadgui-describe-action-is-structured-self-description
  (let ((d (cadgui-describe-action :add-line)))
    (is (not (null d)))
    (is (eq :add-line (getf d :id)))
    (is (eq :draw (getf d :category)))
    (is (stringp (getf d :doc)))
    (is (plusp (length (getf d :doc))))
    (is (= 6 (length (getf d :params))))        ; x1 y1 x2 y2 layer color
    ;; each param is (NAME TYPE DOC)
    (is (every (lambda (p) (= 3 (length p))) (getf d :params))))
  (is (null (cadgui-describe-action :no-such-action))))

(test cadgui-invoke-action-draws-through-the-single-entry-point
  (let ((*cadgui-session* nil))
    (cadgui-start)
    (is (zerop (cadgui-invoke-action :entity-count)))
    (cadgui-invoke-action :add-line 0 0 10 10 :color 1)
    (cadgui-invoke-action :add-circle 5 5 3)
    (is (= 2 (cadgui-invoke-action :entity-count)))
    ;; the script action runs AutoLISP through the same dispatch
    (cadgui-invoke-action :eval-command
                          "(entmake (list (cons 0 \"LINE\") (cons 10 (list 0.0 0.0 0.0)) (cons 11 (list 1.0 1.0 0.0))))")
    (is (= 3 (cadgui-invoke-action :entity-count)))))

(test cadgui-invoke-unknown-action-signals
  (signals cadgui-unknown-action (cadgui-invoke-action :no-such-action)))

(test cadgui-register-action-replaces-and-dispatches
  (cadgui-register-action :test-echo :category :query
                          :doc "echo" :params '((x t "anything"))
                          :fn (lambda (x) (list :echoed x)))
  (is (equal '(:echoed 42) (cadgui-invoke-action :test-echo 42)))
  (is (member :test-echo (cadgui-list-actions))))
