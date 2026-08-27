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

;;;; --- faces (TUI module spec §5.3) ----------------------------------

(test faces-define-and-resolve
  (is (equal '(:fg :yellow :bg nil :bold nil :underline nil :invert nil)
             (clautolisp.ui.tui:face-parameters :current-line)))
  (is (clautolisp.ui.tui:facep :active-status))
  (is (not (clautolisp.ui.tui:facep :no-such-face)))
  ;; the tui-core nickname addresses the same package
  (clautolisp.ui.tui:define-face :test-face :fg :green :bold t)
  (is (equal '(:fg :green :bg nil :bold t :underline nil :invert nil)
             (tui-core:face-parameters :test-face))))

;;;; --- frames (TUI module spec §4) -----------------------------------

(test frames-make-select-delete
  (clautolisp.ui.tui:reset-frames)
  (let ((tty (clautolisp.ui.tui:ensure-initial-tty-frame)))
    (is (clautolisp.ui.tui:framep tty))
    (is (eq :tty (clautolisp.ui.tui:frame-device tty)))
    (is (eq tty (clautolisp.ui.tui:selected-frame)))
    (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 10 :cols 40))
           (vdt (clautolisp.ui.tui:make-frame
                 (list (cons :name "temp") (cons :device :vdt)
                       (cons :minibuffer t) (cons :screen screen)))))
      (is (eq :vdt (clautolisp.ui.tui:frame-device vdt)))
      (is (= 10 (clautolisp.ui.tui:frame-height vdt)))   ; from the screen
      (is (= 40 (clautolisp.ui.tui:frame-width vdt)))
      (is (= 2 (length (clautolisp.ui.tui:frame-list))))
      (clautolisp.ui.tui:select-frame vdt)
      (is (eq vdt (clautolisp.ui.tui:selected-frame)))
      (clautolisp.ui.tui:delete-frame vdt)
      (is (eq tty (clautolisp.ui.tui:selected-frame)))   ; falls back
      (is (= 1 (length (clautolisp.ui.tui:frame-list)))))))

;;;; --- windows (TUI module spec §5) ----------------------------------

(test windows-make-select-list
  (clautolisp.ui.tui:reset-frames)
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 10 :cols 40))
         (frame (clautolisp.ui.tui:make-frame
                 (list (cons :device :vdt) (cons :screen screen)))))
    (clautolisp.ui.tui:select-frame frame)
    (let ((w1 (clautolisp.ui.tui:make-window (list (cons :name "a"))))
          (w2 (clautolisp.ui.tui:make-window (list (cons :name "b"))))
          (mb (clautolisp.ui.tui:make-window (list (cons :role :minibuffer)))))
      (is (eq w1 (clautolisp.ui.tui:frame-selected-window frame))) ; first selected
      (is (= 2 (length (clautolisp.ui.tui:window-list frame nil))))  ; excludes minibuffer
      (is (= 3 (length (clautolisp.ui.tui:window-list frame t))))    ; includes it
      (is (eq mb (clautolisp.ui.tui:frame-minibuffer frame)))
      (clautolisp.ui.tui:select-window w2)
      (is (eq w2 (clautolisp.ui.tui:selected-window)))
      (clautolisp.ui.tui:delete-window w2)
      (is (= 1 (length (clautolisp.ui.tui:window-list frame nil)))))))

(test window-layout-tree-over-objects
  (clautolisp.ui.tui:reset-frames)
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 10 :cols 40))
         (frame (clautolisp.ui.tui:make-frame
                 (list (cons :device :vdt) (cons :screen screen)))))
    (clautolisp.ui.tui:select-frame frame)
    (let ((w1 (clautolisp.ui.tui:make-window (list (cons :name "a"))))
          (w2 (clautolisp.ui.tui:make-window (list (cons :name "b")))))
      ;; the generic layout tree tiles window OBJECTS (leaf = any non-split)
      (is (equal (list w1 w2)
                 (clautolisp.ui.tui:layout-leaves (clautolisp.ui.tui:frame-layout frame))))
      (is (eq w2 (clautolisp.ui.tui:window-cycle (clautolisp.ui.tui:frame-layout frame) w1 +1)))
      (multiple-value-bind (rects vlines)
          (clautolisp.ui.tui:layout-rects (clautolisp.ui.tui:frame-layout frame) 0 0 9 40)
        (is (= 2 (length rects)))
        (is (= 1 (length vlines)))
        (is (< (clautolisp.ui.tui:rect-left (cdr (assoc w1 rects)))
               (clautolisp.ui.tui:rect-left (cdr (assoc w2 rects)))))))))

;;;; --- keymaps (ncurses-key-bindings.issue) --------------------------

(test keymap-parse-and-unparse-round-trip
  (flet ((rt (s) (clautolisp.ui.tui:unparse-key-sequence
                  (clautolisp.ui.tui:parse-key-sequence s))))
    (is (equal "b" (rt "b")))
    (is (equal ">" (rt ">")))
    (is (equal "C-x C-f" (rt "C-x C-f")))
    (is (equal "M-x" (rt "M-x")))
    (is (equal "C-w >" (rt "C-w >")))
    (is (equal "RET" (rt "RET")))
    (is (equal "UP" (rt "UP")))))

(test keymap-parses-tokens-to-the-read-key-alphabet
  ;; C-<c> is the control code character; M-<c> is a (:meta . char) chord;
  ;; named keys are keywords — the same values a screen's read-key yields.
  (is (equal (list (code-char 24) (code-char 6))
             (clautolisp.ui.tui:parse-key-sequence "C-x C-f")))
  (is (equal (list (cons :meta #\x)) (clautolisp.ui.tui:parse-key-sequence "M-x")))
  (is (equal (list (code-char 23) #\>) (clautolisp.ui.tui:parse-key-sequence "C-w >")))
  (is (equal (list :enter) (clautolisp.ui.tui:parse-key-sequence "RET"))))

(test keymap-bind-lookup-shadow-prefix-unbind
  (let ((map (clautolisp.ui.tui:make-keymap)))
    (clautolisp.ui.tui:keymap-bind map (clautolisp.ui.tui:parse-key-sequence "b") "toggle")
    (clautolisp.ui.tui:keymap-bind map (clautolisp.ui.tui:parse-key-sequence "C-x C-f") "sedit load")
    ;; leaf lookup
    (is (equal "toggle" (clautolisp.ui.tui:keymap-lookup
                         map (clautolisp.ui.tui:parse-key-sequence "b"))))
    ;; prefix chain resolves only when complete
    (is (equal "sedit load" (clautolisp.ui.tui:keymap-lookup
                             map (clautolisp.ui.tui:parse-key-sequence "C-x C-f"))))
    (is (null (clautolisp.ui.tui:keymap-lookup
               map (clautolisp.ui.tui:parse-key-sequence "C-x"))))       ; bare prefix
    ;; stepping: C-x is a :prefix, then C-f is a :leaf
    (multiple-value-bind (kind sub)
        (clautolisp.ui.tui:keymap-step map (code-char 24))
      (is (eq :prefix kind))
      (is (eq :leaf (clautolisp.ui.tui:keymap-step sub (code-char 6)))))
    ;; shadow a leaf with a prefix (b -> "b n")
    (clautolisp.ui.tui:keymap-bind map (clautolisp.ui.tui:parse-key-sequence "b n") "new")
    (is (eq :prefix (clautolisp.ui.tui:keymap-step map #\b)))
    (is (equal "new" (clautolisp.ui.tui:keymap-lookup
                      map (clautolisp.ui.tui:parse-key-sequence "b n"))))
    ;; map lists every binding as canonical key strings
    (let ((seen (let ((acc '()))
                  (clautolisp.ui.tui:keymap-map map (lambda (k c) (push (cons k c) acc)))
                  acc)))
      (is (equal "sedit load" (cdr (assoc "C-x C-f" seen :test #'string=))))
      (is (equal "new" (cdr (assoc "b n" seen :test #'string=)))))
    ;; unbind reverts, pruning the emptied prefix node
    (is (clautolisp.ui.tui:keymap-unbind map (clautolisp.ui.tui:parse-key-sequence "C-x C-f")))
    (is (eq :none (clautolisp.ui.tui:keymap-step map (code-char 24))))))

;;;; --- window drawing operations (tty-safe) --------------------------

(test window-ops-draw-on-a-vdt-window
  (clautolisp.ui.tui:reset-frames)
  (let* ((screen (clautolisp.ui.tui:make-mock-screen :rows 10 :cols 20))
         (frame (clautolisp.ui.tui:make-frame
                 (list (cons :device :vdt) (cons :screen screen)))))
    (clautolisp.ui.tui:select-frame frame)
    (let ((w (clautolisp.ui.tui:make-window (list (cons :name "w")))))
      (setf (clautolisp.ui.tui:window-rect w) (list 1 2 4 10))  ; top1 left2 h4 w10
      (clautolisp.ui.tui:window-put 0 0 "hello" :window w)
      (is (search "hello" (nth 1 (clautolisp.ui.tui:mock-grid-lines screen))))
      ;; move-cursor-to records window-relative + moves the hardware cursor
      (clautolisp.ui.tui:move-cursor-to 2 3 w)
      (is (equal (cons 2 3) (clautolisp.ui.tui:window-cursor w)))
      (is (equal (cons 3 5) (clautolisp.ui.tui:mock-cursor screen)))   ; +top +left
      ;; clear-window blanks the rect
      (clautolisp.ui.tui:clear-window w)
      (is (not (search "hello" (nth 1 (clautolisp.ui.tui:mock-grid-lines screen))))))))

(test window-ops-are-no-ops-on-a-tty-frame
  (clautolisp.ui.tui:reset-frames)
  (let* ((frame (clautolisp.ui.tui:make-frame (list (cons :device :tty)))))
    (clautolisp.ui.tui:select-frame frame)
    (let ((w (clautolisp.ui.tui:make-window (list (cons :name "w")))))
      (setf (clautolisp.ui.tui:window-rect w) (list 0 0 3 5))
      (is (not (clautolisp.ui.tui:window-vdt-p w)))
      ;; no screen: the ops do not error and have no vdt effect...
      (clautolisp.ui.tui:window-put 0 0 "x" :window w)
      (clautolisp.ui.tui:clear-window w)
      ;; ...but the logical cursor is still recorded
      (clautolisp.ui.tui:move-cursor-to 1 2 w)
      (is (equal (cons 1 2) (clautolisp.ui.tui:window-cursor w))))))

;;;; --- configuration cascade (matches the interactor stacks) ---------

(test config-cascade-resolves-through-parents
  (clautolisp.ui.tui:reset-configs)
  (clautolisp.ui.tui:ensure-standard-configs)
  (clautolisp.ui.tui:config-set-value "aldo" :indent 3)
  ;; stack -> aldo -> lisp inherits aldo's setting; so does navi
  (is (eql 3 (clautolisp.ui.tui:config-value "stack" :indent)))
  (is (eql 3 (clautolisp.ui.tui:config-value "navi" :indent)))
  ;; inspector -> lisp does NOT see aldo
  (is (eq :none (clautolisp.ui.tui:config-value "inspector" :indent :none)))
  ;; a local override on stack shadows the inherited value; navi is unaffected
  (clautolisp.ui.tui:config-set-value "stack" :indent 9)
  (is (eql 9 (clautolisp.ui.tui:config-value "stack" :indent)))
  (is (eql 3 (clautolisp.ui.tui:config-value "navi" :indent)))
  ;; the cascade names match the interactor stack
  (is (equal '("stack" "aldo" "lisp")
             (mapcar #'clautolisp.ui.tui:config-name
                     (clautolisp.ui.tui:config-cascade "stack")))))

(test config-persists-and-reloads
  (clautolisp.ui.tui:reset-configs)
  (let ((src (clautolisp.ui.tui:ensure-config "sedit" "lisp")))
    (clautolisp.ui.tui:config-set-value src :face-current-line :yellow)
    (clautolisp.ui.tui:config-set-value src :tab-width 4)
    (let ((text (with-output-to-string (s) (clautolisp.ui.tui:write-config src s))))
      (clautolisp.ui.tui:reset-configs)                    ; fresh registry
      (let ((dst (clautolisp.ui.tui:ensure-config "sedit" "lisp")))
        (with-input-from-string (s text) (clautolisp.ui.tui:read-config dst s))
        (is (eq :yellow (clautolisp.ui.tui:config-value dst :face-current-line)))
        (is (eql 4 (clautolisp.ui.tui:config-value dst :tab-width)))
        (is (not (clautolisp.ui.tui:config-dirty dst)))))))
