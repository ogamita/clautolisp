;;;; FiveAM tests for the TUI pager (clautolisp.ui.dumb paged-out,
;;;; command reference §8 "Paging long output").

(in-package #:clautolisp.ui.dumb.tests)

(in-suite dumb-ui-suite)

(defun run-pager (text input-keys &key (pager :on) (height 3))
  "Run PAGED-OUT over TEXT with the pager configured, feeding INPUT-KEYS as the
page-prompt input. Returns the captured output string."
  (let ((clautolisp.debug.ui:*aldo-configuration*
          (copy-tree clautolisp.debug.ui:*default-aldo-configuration*)))
    (clautolisp.debug.ui:config-set :pager pager)
    (clautolisp.debug.ui:config-set :pager-height height)
    (let* ((out (make-string-output-stream))
           (ui (clautolisp.ui.dumb:make-dumb-ui
                :input (make-string-input-stream input-keys) :output out)))
      (clautolisp.ui.dumb::paged-out ui text)
      (get-output-stream-string out))))

(defparameter +five-lines+ (format nil "L1~%L2~%L3~%L4~%L5~%"))

(test pager-off-writes-straight-through
  (let ((out (run-pager +five-lines+ "" :pager :off)))
    (is (not (contains out "--More--")))
    (is (contains out "L1"))
    (is (contains out "L5"))))

(test pager-paginates-and-shows-all
  ;; height 3 => 2 lines/page; 5 lines => 3 pages, 2 "next" prompts
  (let ((out (run-pager +five-lines+ (format nil "~%~%") :height 3)))
    (is (contains out "--More--"))
    (is (contains out "L1"))
    (is (contains out "L3"))
    (is (contains out "L5"))))

(test pager-quit-stops-early
  (let ((out (run-pager +five-lines+ (format nil "q~%") :height 3)))
    (is (contains out "L1"))
    (is (contains out "--More--"))
    (is (not (contains out "L5")))))   ; quit before the last page

(test pager-eof-dumps-remainder
  ;; a non-interactive stream (immediate EOF) must not block: dump the rest
  (let ((out (run-pager +five-lines+ "" :pager :on :height 3)))
    (is (contains out "L1"))
    (is (contains out "L5"))))

(test pager-back-and-first
  ;; next, then back, then quit — L1/L2 shown again after going back
  (let ((out (run-pager (format nil "L1~%L2~%L3~%L4~%L5~%L6~%")
                        (format nil "~%b~%q~%") :height 3)))
    (is (contains out "--More--"))
    (is (contains out "L1"))))
