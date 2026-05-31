(in-package #:clautolisp.ui.tui.charms)

;;;; cl-charms implementation of the tui-screen protocol. Kept small and
;;;; isolated so the rest of the debugger never sees curses. Colour uses
;;;; charms' colour-pair API in 8-colour mode (spec §19.3); attributes map
;;;; a keyword to a pair or to A_BOLD. Mouse is not used — key-only
;;;; navigation is complete (spec §19.3).

(defclass charms-screen ()
  ((window :initform nil :accessor charms-window)
   (color-pairs :initform (make-hash-table :test 'eq) :accessor charms-color-pairs)))

(defun make-charms-screen () (make-instance 'charms-screen))

(defparameter +color-names+
  '((:black . 0) (:red . 1) (:green . 2) (:yellow . 3)
    (:blue . 4) (:magenta . 5) (:cyan . 6) (:white . 7)))

(defmethod tui-start ((screen charms-screen))
  (charms:initialize)
  (charms:disable-echoing)
  (charms:enable-raw-input :interpret-control-characters t)
  (charms:enable-extra-keys (charms:standard-window))
  (setf (charms-window screen) (charms:standard-window))
  (when (charms/ll:has-colors)
    (charms/ll:start-color)
    (loop for (name . fg) in +color-names+
          for pair from 1
          do (charms/ll:init-pair pair fg charms/ll:color_black)
             (setf (gethash name (charms-color-pairs screen)) pair)))
  (charms:clear-window (charms-window screen) :force-repaint t))

(defmethod tui-stop ((screen charms-screen))
  (when (charms-window screen)
    (charms:finalize)
    (setf (charms-window screen) nil)))

(defmethod tui-size ((screen charms-screen))
  (multiple-value-bind (cols rows) (charms:window-dimensions (charms-window screen))
    (values rows cols)))

(defmethod tui-clear ((screen charms-screen))
  (charms:clear-window (charms-window screen)))

(defmethod tui-put ((screen charms-screen) row col string &key (attr :normal))
  (let* ((window (charms-window screen))
         (pair (gethash attr (charms-color-pairs screen)))
         (bold (eq attr :bold)))
    (when (or pair bold) (apply-attr screen attr t))
    (charms:write-string-at-point window string col row)
    (when (or pair bold) (apply-attr screen attr nil))))

(defun apply-attr (screen attr on)
  (let ((pair (gethash attr (charms-color-pairs screen))))
    (cond
      (pair (if on
                (charms/ll:wattron (charms::window-pointer (charms-window screen))
                                   (charms/ll:color-pair pair))
                (charms/ll:wattroff (charms::window-pointer (charms-window screen))
                                    (charms/ll:color-pair pair))))
      ((eq attr :bold)
       (if on
           (charms/ll:wattron (charms::window-pointer (charms-window screen)) charms/ll:a_bold)
           (charms/ll:wattroff (charms::window-pointer (charms-window screen)) charms/ll:a_bold))))))

(defmethod tui-refresh ((screen charms-screen))
  (charms:refresh-window (charms-window screen)))

(defmethod tui-read-key ((screen charms-screen))
  "Translate a charms key into the protocol's key vocabulary."
  (let ((key (charms:get-char (charms-window screen) :ignore-error t)))
    (cond
      ((null key) :eof)
      ((characterp key)
       (case key
         ((#\Newline #\Return) :enter)
         ((#\Rubout #\Backspace) :backspace)
         (#\Escape :escape)
         (t key)))
      ((eq key :key-up) :up)
      ((eq key :key-down) :down)
      ((eq key :key-left) :left)
      ((eq key :key-right) :right)
      ((eq key :key-backspace) :backspace)
      ((eq key :key-enter) :enter)
      ((eq key :key-resize) :resize)
      (t key))))
