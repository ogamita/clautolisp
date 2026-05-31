;;;; clautolisp/autolisp-debug-ui-ncurses/tests/tui-tests.lisp

(in-package #:clautolisp.ui.ncurses.tests)

(in-suite ncurses-suite)

(test mock-screen-records-and-reads
  (let ((screen (clautolisp.ui.tui:make-mock-screen :rows 5 :cols 20
                                                    :keys (list #\a :down :enter))))
    (multiple-value-bind (rows cols) (clautolisp.ui.tui:tui-size screen)
      (is (= 5 rows)) (is (= 20 cols)))
    (clautolisp.ui.tui:tui-put screen 1 2 "hello" :attr :red)
    (is (string= "  hello" (nth 1 (clautolisp.ui.tui:mock-grid-lines screen))))
    (is (eq :red (clautolisp.ui.tui:mock-attr-at screen 1 2)))
    (is (eql #\a (clautolisp.ui.tui:tui-read-key screen)))
    (is (eq :down (clautolisp.ui.tui:tui-read-key screen)))
    (is (eq :enter (clautolisp.ui.tui:tui-read-key screen)))
    (is (eq :eof (clautolisp.ui.tui:tui-read-key screen)))))

(test tui-put-clips-to-screen
  (let ((screen (clautolisp.ui.tui:make-mock-screen :rows 3 :cols 6)))
    (clautolisp.ui.tui:tui-put screen 0 3 "ABCDEF")   ; only ABC fit
    (is (string= "   ABC" (first (clautolisp.ui.tui:mock-grid-lines screen))))
    (clautolisp.ui.tui:tui-put screen 9 0 "off-screen")  ; row out of range: ignored
    ;; the out-of-range write did not corrupt any visible row
    (is (= 3 (length (clautolisp.ui.tui:mock-grid-lines screen))))))

(test four-pane-layout-tiles-the-screen
  (destructuring-bind (stack source interactor repl)
      (clautolisp.ui.tui:four-pane-layout 24 80)
    (is (string= "stack" (clautolisp.ui.tui:pane-title stack)))
    (is (string= "source" (clautolisp.ui.tui:pane-title source)))
    (is (string= "interactor" (clautolisp.ui.tui:pane-title interactor)))
    (is (string= "repl" (clautolisp.ui.tui:pane-title repl)))
    (is (= 0 (clautolisp.ui.tui:pane-top stack)))
    (is (= 0 (clautolisp.ui.tui:pane-left stack)))
    (is (= 40 (clautolisp.ui.tui:pane-left source)))
    (is (= 12 (clautolisp.ui.tui:pane-top interactor)))))

(test draw-box-renders-border-and-title
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 6 :cols 20))
         (pane (clautolisp.ui.tui:make-pane :title "p" :top 0 :left 0 :height 4 :width 10)))
    (clautolisp.ui.tui:draw-box screen pane)
    (let ((lines (clautolisp.ui.tui:mock-grid-lines screen)))
      (is (char= #\+ (char (first lines) 0)))
      (is (search "p" (first lines)))
      (is (char= #\| (char (nth 1 lines) 0))))))

(test pane-put-line-writes-inside-the-box
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 6 :cols 20))
         (pane (clautolisp.ui.tui:make-pane :title "" :top 0 :left 0 :height 5 :width 12)))
    (clautolisp.ui.tui:pane-put-line screen pane 0 "hi" :attr :yellow)
    (is (string= " hi" (subseq (nth 1 (clautolisp.ui.tui:mock-grid-lines screen)) 0 3)))
    (is (eq :yellow (clautolisp.ui.tui:mock-attr-at screen 1 1)))))
