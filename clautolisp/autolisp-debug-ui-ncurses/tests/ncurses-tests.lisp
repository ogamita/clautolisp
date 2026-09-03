;;;; clautolisp/autolisp-debug-ui-ncurses/tests/ncurses-tests.lisp
;;;;
;;;; The four-pane UI driven through the mock screen: scripted keys in,
;;;; resume directives + UI state + grid contents out.

(in-package #:clautolisp.ui.ncurses.tests)

(in-suite ncurses-suite)

(test sanitize-line-replaces-control-bytes-keeps-utf8
  ;; A stray control / C1 byte in rendered data (a function name, a value) made
  ;; curses draw '~@?' garbage in the stack pane; SANITIZE-LINE (applied by
  ;; WIN-PUT-LINE) turns such bytes into '?' while leaving printable text — all
  ;; UTF-8 included — untouched.
  (is (string= "SE?ND"
               (clautolisp.ui.ncurses::sanitize-line
                (concatenate 'string "SE" (string (code-char #x93)) "ND")))) ; C1 byte
  (is (string= "a?b"
               (clautolisp.ui.ncurses::sanitize-line
                (concatenate 'string "a" (string (code-char 127)) "b"))))    ; DEL
  ;; pure ASCII and legitimate UTF-8 (accents, ≥ 160) pass through unchanged
  (is (string= "> SEND  line 372"
               (clautolisp.ui.ncurses::sanitize-line "> SEND  line 372")))
  (is (string= "tolère café — méthode"
               (clautolisp.ui.ncurses::sanitize-line "tolère café — méthode"))))

(defun break-at (context metas line)
  (declare (ignore context))
  (let ((ti (clautolisp.debug:make-thread-debug-info :debug-flag t))
        (meta (first metas)))
    (clautolisp.debug:add-breakpoint
     ti (fid-of meta) (clautolisp.debug:find-form-id-at-line meta line) :when :before)
    ti))

(defun call-two (context)
  (clautolisp.autolisp-runtime:autolisp-eval (list (rt-sym "TWO") 7) context))

;;; The four panes are tui-core WINDOW objects now; a window's id is its ROLE.
;;; These helpers keep the assertions reading in terms of roles.
(defun active-role (ui)
  (clautolisp.ui.tui:window-role (clautolisp.ui.ncurses::active-window ui)))
(defun win-of (ui role) (clautolisp.ui.ncurses::ui-window ui role))
(defun rect-of (ui rects role) (cdr (assoc (win-of ui role) rects)))
(defun window-stack-of (ui role)
  (clautolisp.ui.tui:window-stack (win-of ui role)))
(defun ui-layout-roles (ui)
  "The frame layout projected to window ROLES, so it compares to a role-tree."
  (labels ((roles (node)
             (if (and (consp node) (member (first node) '(:horizontal :vertical)))
                 (destructuring-bind (split ratio a b) node
                   (list split ratio (roles a) (roles b)))
                 (clautolisp.ui.tui:window-role node))))
    (roles (clautolisp.ui.ncurses::ui-layout ui))))
(defparameter +canonical-role-layout+
  '(:horizontal 1/2 (:vertical 1/2 :stack :source) (:vertical 1/2 :interactor :repl)))

(test continue-key-resumes-and-draws-panes
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui))
      (is (eql 7 result))
      (is (grid-contains screen "stack"))
      (is (grid-contains screen "source"))
      (is (grid-contains screen "interactor"))
      (is (grid-contains screen "repl"))
      (is (grid-contains screen "TWO")))))

(test source-pane-marks-current-line-yellow
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (with-open-file (out "two.lsp" :direction :output :if-exists :supersede)
      (write-string +two-source+ out))
    (unwind-protect
         (multiple-value-bind (result ui screen)
             (run-ncurses (list #\c) :context context :thread-info ti
                          :thunk (lambda () (call-two context)))
           (declare (ignore result ui))
           (let ((row (clautolisp.ui.tui:mock-find-line screen "(setq z (id x))")))
             (is (integerp row))
             (let* ((line (nth row (clautolisp.ui.tui:mock-grid-lines screen)))
                    (col (search ">>" line)))
               (is (integerp col))
               (is (eq :current-line (clautolisp.ui.tui:mock-attr-at screen row col))))))
      (ignore-errors (delete-file "two.lsp")))))

(test source-pane-marks-breakpoint-line-red
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (meta (first metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    (with-open-file (out "two.lsp" :direction :output :if-exists :supersede)
      (write-string +two-source+ out))
    (unwind-protect
         (progn
           ;; Stop at line 3 (a real statement); set a second steady
           ;; breakpoint at line 4 — that line must render :red. (Line 2 is
           ;; the defun header, which has no poll point, so it is not a stop.)
           ;; Stop at line 3 (a real statement); a second steady breakpoint at
           ;; line 4 must render :red. Abort at the first (line-3) stop so the
           ;; LAST render is taken there — line 4 then shows as a pending
           ;; breakpoint (:red), not as the current line (:yellow, which it
           ;; would become if we continued into it). Line 2 (defun header) has
           ;; no poll point and is not a valid stop.
           (clautolisp.debug:add-breakpoint ti (fid-of meta)
                                            (clautolisp.debug:find-form-id-at-line meta 3) :when :before)
           (clautolisp.debug:add-breakpoint ti (fid-of meta)
                                            (clautolisp.debug:find-form-id-at-line meta 4) :when :before)
           (multiple-value-bind (result ui screen)
               (run-ncurses (list #\a) :context context :thread-info ti
                            :thunk (lambda () (call-two context)))
             (declare (ignore result ui))
             (let ((row (clautolisp.ui.tui:mock-find-line screen "(id z)")))
               (is (integerp row))
               (let ((col (1+ (search ":" (nth row (clautolisp.ui.tui:mock-grid-lines screen))))))
                 (is (eq :breakpoint (clautolisp.ui.tui:mock-attr-at screen row col)))))))
      (ignore-errors (delete-file "two.lsp")))))

(test step-key-runs-to-completion
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\s #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eql 7 result)))))

(test frame-navigation-selects-outer-frame
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (id (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; Break at ID's entry, reached via TWO → a 2-frame stack. Press Down to
    ;; select the outer frame (TWO), then abort. (TWO calls ID twice, so a
    ;; plain continue would stop at ID's entry again and reset the selected
    ;; frame to 0 — abort takes the reading at the first stop.)
    (clautolisp.debug:add-breakpoint ti (fid-of id) 0 :when :before)
    ;; Activate the stack window (C-w p C-w p: interactor -> source -> stack),
    ;; whose interactor moves frames; Down selects the outer frame, then
    ;; ,abort ends before the second stop resets the selection.
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list (code-char 23) #\p (code-char 23) #\p :down #\,)
                             (coerce "abort" 'list) (list :enter))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (= 1 (clautolisp.ui.ncurses:ncurses-ui-selected-frame ui))))))

(test toggle-breakpoint-at-cursor-line
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (meta (first metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; Stop at line 3 (a real form / poll point), so the source cursor lands
    ;; there. The cursor line already carries the stop breakpoint, so the
    ;; first 'b' CLEARS it and the second 'b' re-ADDS it — exercising both
    ;; directions of the toggle. (Line 2, the defun header, has no poll
    ;; point and is not a valid stop.)
    (clautolisp.debug:add-breakpoint ti (fid-of meta)
                                     (clautolisp.debug:find-form-id-at-line meta 3) :when :before)
    (is (= 1 (length (clautolisp.debug:list-breakpoints ti))))
    ;; At the line-3 stop the cursor is on the breakpointed line, so 'b'
    ;; CLEARS it and the next 'b' re-ADDS it; the interactor message records
    ;; the last toggle direction. (The session's teardown clears the table,
    ;; so we assert on the message, not a post-session count.)
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\p #\b #\b) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (search "set at line 3" (clautolisp.ui.ncurses:ncurses-ui-message ui))))))

(test structural-nav-forward-moves-selection-to-next-form
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (with-open-file (out "two.lsp" :direction :output :if-exists :supersede)
      (write-string +two-source+ out))
    (unwind-protect
         ;; Activate the source window (C-w p), whose interactor is the
         ;; navigator; the stop re-anchors on the innermost poll point (id x)
         ;; on line 3, 'u' ascends to the (setq …) statement and '>' selects
         ;; its next sibling — (id z) on line 4 — so the >> gutter follows.
         ;; (Keys exhaust -> EOF -> continue.)
         (multiple-value-bind (result ui screen)
             (run-ncurses (list (code-char 23) #\p #\u #\>)
                          :context context :thread-info ti
                          :thunk (lambda () (call-two context)))
           (declare (ignore result ui))
           (let ((row (clautolisp.ui.tui:mock-find-line screen "(id z)")))
             (is (integerp row))
             (is (search ">>" (nth row (clautolisp.ui.tui:mock-grid-lines screen))))))
      (ignore-errors (delete-file "two.lsp")))))

(test breakpoint-at-navigated-selection
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; Activate the source window (C-w p); 'u' then '>' move the structural
    ;; cursor onto the (id z) form (line 4), then 'b' breaks at the SELECTED
    ;; form's line — the cursor-based location rule (cmd-ref §0), not the stop
    ;; line.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\p #\u #\> #\b)
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (search "set at line 4" (clautolisp.ui.ncurses:ncurses-ui-message ui))))))

(test eval-line-shows-result-in-repl
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\e #\X :enter #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (some (lambda (l) (search "=> 7" l)) (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui))))))

(test abort-key-aborts
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\a) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eq :aborted result)))))

(test inspector-pane-navigation-and-path
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (clautolisp.autolisp-runtime:set-variable
     (rt-sym "L") (first (clautolisp.autolisp-runtime:read-runtime-from-string "(10 20)")) context)
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\x #\L :enter :enter #\p #\q #\c)
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (some (lambda (l) (search "(CAR L)" l))
                (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui))))))

(test windowed-layout-uses-single-separators-not-boxes
  ;; ncurses-windows.issue "display": single "|" separators + status lines,
  ;; no full boxes (which duplicated borders down the middle).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result ui))
      (let ((lines (clautolisp.ui.tui:mock-grid-lines screen)))
        ;; no box corners anywhere
        (is (notany (lambda (l) (find #\+ l)) lines))
        ;; a single vertical separator column is present
        (is (some (lambda (l) (find #\| l)) lines))))))

(test status-line-marks-active-and-inactive-windows
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result ui))
      ;; default active window is the interactor: its status line inverts;
      ;; the stack window's status line is underlined.
      (let ((irow (clautolisp.ui.tui:mock-find-line screen "interactor"))
            (srow (clautolisp.ui.tui:mock-find-line screen "stack")))
        (is (integerp irow))
        (is (integerp srow))
        (let ((icol (search "interactor" (nth irow (clautolisp.ui.tui:mock-grid-lines screen))))
              (scol (search "stack" (nth srow (clautolisp.ui.tui:mock-grid-lines screen)))))
          (is (eq :active-status (clautolisp.ui.tui:mock-attr-at screen irow icol)))
          (is (eq :inactive-status (clautolisp.ui.tui:mock-attr-at screen srow scol))))))))

(test window-select-next-moves-active-window
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; C-w n cycles the active window in reading order
    ;; (stack source interactor repl); from the default (interactor) the
    ;; next is repl.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\n #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (eq :repl (active-role ui))))))

(test window-swap-right-moves-active-to-the-right
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; default active = interactor (bottom-left); window-swap-right swaps it
    ;; with repl (its right neighbour), so interactor ends up on the right.
    ;; (>/< keys now scroll, so swap is invoked by name.)
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "window-swap-right" 'list) (list :enter #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (multiple-value-bind (rects vl)
          (clautolisp.ui.ncurses::layout-rects
           (clautolisp.ui.ncurses::ui-layout ui) 0 0 23 80)
        (declare (ignore vl))
        (is (> (clautolisp.ui.ncurses::rect-left (rect-of ui rects :interactor))
               (clautolisp.ui.ncurses::rect-left (rect-of ui rects :repl))))))))

(test window-reset-square-restores-canonical
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\> (code-char 23) #\4 #\c)
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (equal (ui-layout-roles ui) +canonical-role-layout+)))))

(test window-resize-grows-active-window
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; active = interactor, the first child of the bottom split; C-w + raises
    ;; that split's ratio above 1/2.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\+ #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (> (second (fourth (clautolisp.ui.ncurses::ui-layout ui))) 1/2)))))

(test window-split-below-stacks-active-over-next
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; active = interactor, next = repl; C-w 2 puts them in a :horizontal
    ;; (stacked) split — interactor above repl, same column.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\2 #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (multiple-value-bind (rects vl)
          (clautolisp.ui.ncurses::layout-rects
           (clautolisp.ui.ncurses::ui-layout ui) 0 0 23 80)
        (declare (ignore vl))
        (let ((ir (rect-of ui rects :interactor))
              (rr (rect-of ui rects :repl)))
          (is (< (clautolisp.ui.ncurses::rect-top ir)
                 (clautolisp.ui.ncurses::rect-top rr)))
          (is (= (clautolisp.ui.ncurses::rect-left ir)
                 (clautolisp.ui.ncurses::rect-left rr))))))))

(test layout-persists-across-stops-in-a-session
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (id (second metas))
         (ti (clautolisp.debug:make-thread-debug-info :debug-flag t)))
    ;; ID is entered twice (TWO calls id twice) → two stops. Swap windows at
    ;; the first stop; the layout must still be swapped at the second — the
    ;; UI instance (and its layout) persists across the curses enter/exit
    ;; cycles of one session.
    (clautolisp.debug:add-breakpoint ti (fid-of id) 0 :when :before)
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "window-swap-right" 'list)
                             (list :enter #\c #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (not (equal (ui-layout-roles ui) +canonical-role-layout+))))))

(test mx-runs-named-command-continue
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; Esc x  M-x, then the command name "continue" + RET → resumes.
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list :escape #\x) (coerce "continue" 'list) (list :enter))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eql 7 result)))))

(test comma-runs-named-window-command
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; , window-select-next RET moves the active window (interactor -> repl);
    ;; then c continues.
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "window-select-next" 'list) (list :enter #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (eq :repl (active-role ui))))))

(test comma-routes-line-through-aldo-vocabulary
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; , h  is not an ncurses built-in name, so it is routed through the shared
    ;; ALDO vocabulary; its printed output is captured into the repl pane.
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "h" 'list) (list :enter #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (plusp (length (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))))

(test comma-unknown-command-routes-and-reports
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; An unknown name is routed to ALDO, which reports it into the pane.
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "nosuchcmd" 'list) (list :enter #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (some (lambda (l) (search "unknown" l))
                (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui))))))

(test window-other-toggles-active-window
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; C-w o from interactor saves it and moves to the next (repl).
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\o #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (eq :repl (active-role ui))))))

(test cx-prefix-is-an-alias-for-cw
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; C-x (code 24) is an alias of C-w: C-x n selects the next window.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 24) #\n #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (eq :repl (active-role ui))))))

(test window-scroll-and-why-preserve-and-redisplay-the-message
  ;; Scrolling leaves the message alone; the `w' (why) key redisplays the stop
  ;; reason even after other commands. Uses a breakpoint stop (ui-thread-hit sets
  ;; the why-message).
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\v          ; C-w v : scroll (small cmd)
                           #\w                          ; w     : why
                           #\c)                         ; c     : continue
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      ;; a stop reason was captured, and the scroll did not turn the line into
      ;; a "scroll ..." status
      (is (stringp (clautolisp.ui.ncurses:ncurses-ui-why-message ui)))
      (is (not (search "scroll" (clautolisp.ui.ncurses:ncurses-ui-message ui))))
      ;; after `w', the interactor line shows the (sticky) why message
      (is (string= (clautolisp.ui.ncurses:ncurses-ui-why-message ui)
                   (clautolisp.ui.ncurses:ncurses-ui-message ui))))))

(test window-manager-rides-on-the-active-window-stack
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; C-w p activates the source window: the :window-manager interactor moves
    ;; onto the source window's stack (on top, over its :navi base) and off the
    ;; interactor window's stack.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\p) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (let ((src (window-stack-of ui :source))
            (int (window-stack-of ui :interactor)))
        ;; source pane = (:window-manager :navi . SHARED-(aldo lisp)-tail)
        (is (eq :window-manager (first src)))
        (is (equal '(:window-manager :navi) (subseq src 0 2)))
        (is (not (member :window-manager int)))
        ;; the (aldo lisp) tail is genuinely SHARED: the source pane and the
        ;; interactor pane carry the very same aldo + lisp activation objects, so
        ;; a command routes to the one document's debugger + evaluator (pjb —
        ;; multi-document mode needs each aldo window to refer to its own bottom).
        (is (eq (find-if #'clautolisp.ui.ncurses::window-entry-aldo-view-p src)
                (find-if #'clautolisp.ui.ncurses::window-entry-aldo-view-p int)))
        (is (eq (find-if #'clautolisp.ui.ncurses::window-entry-lisp-p src)
                (find-if #'clautolisp.ui.ncurses::window-entry-lisp-p int)))))))

(test eof-continues
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses '() :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eql 7 result)))))

(test comma-jump-carries-the-current-hit
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 4)))
    ;; At the line-4 stop in TWO, route ,jump 3 through the ALDO vocabulary.
    ;; jump is HIT-relative (cur-fid = (hit-fid hit)): with the stop's hit
    ;; carried into the , routing, the target resolves to the CURRENT function
    ;; (TWO) and a backward jump is rejected as "backward jump not supported".
    ;; Without the hit, cur-fid is NIL and it would misreport a "cross-function"
    ;; jump — so this asserts the hit is now carried (step 4).
    (multiple-value-bind (result ui screen)
        (run-ncurses (append (list #\,) (coerce "jump 3" 'list) (list :enter #\c))
                     :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (let ((repl (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))
        (is (some (lambda (l) (search "backward" l)) repl))
        (is (notany (lambda (l) (search "cross-function" l)) repl))))))

;;;; --- user key bindings (ncurses-key-bindings.issue, step 5) --------

(defmacro with-fresh-bindings (&body body)
  `(unwind-protect
        (progn (clautolisp.ui.ncurses::reset-user-bindings) ,@body)
     (clautolisp.ui.ncurses::reset-user-bindings)))

(test user-binding-map-and-remove
  (with-fresh-bindings
    (clautolisp.ui.ncurses::ui-bind "z" "window-select-next")
    (let ((seen '()))
      (clautolisp.ui.ncurses::ui-map-bindings (lambda (k c) (push (cons k c) seen)))
      (is (equal "window-select-next" (cdr (assoc "z" seen :test #'string=)))))
    (is (equal "window-select-next" (clautolisp.ui.ncurses::ui-binding-lookup "z")))
    (is (clautolisp.ui.ncurses::ui-unbind "z"))
    (is (null (clautolisp.ui.ncurses::ui-binding-lookup "z")))))

(test user-binding-shadows-builtin-key
  (with-fresh-bindings
    ;; rebind c (built-in continue) to a window command: c must now move the
    ;; active window, not resume.
    (clautolisp.ui.ncurses::ui-bind "c" "window-select-next")
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list #\c) :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore screen))
        (is (eq :repl (active-role ui)))     ; c moved the window (shadowed)
        (is (eql 7 result))))))              ; EOF then resumes

(test user-binding-fires-a-function
  (with-fresh-bindings
    (clautolisp.ui.ncurses::ui-bind
     "z" (lambda (ui session hit)
           (declare (ignore session hit))
           (clautolisp.ui.ncurses::push-repl ui "zzz") nil))
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list #\z #\c) :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (some (lambda (l) (search "zzz" l))
                  (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))))

(test user-binding-command-line-carries-hit
  (with-fresh-bindings
    ;; a command-LINE binding routes through the command table WITH the stop's
    ;; hit — ,jump 3 at the line-4 stop is a within-function backward jump.
    (clautolisp.ui.ncurses::ui-bind "z" "jump 3")
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 4)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list #\z #\c) :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (some (lambda (l) (search "backward" l))
                  (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))))

(test user-binding-prefix-chain-fires
  (with-fresh-bindings
    (clautolisp.ui.ncurses::ui-bind
     "C-x C-f" (lambda (ui session hit)
                 (declare (ignore session hit))
                 (clautolisp.ui.ncurses::push-repl ui "cxcf") nil))
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list (code-char 24) (code-char 6) #\c)
                       :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (some (lambda (l) (search "cxcf" l))
                  (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))))

(test user-binding-prefix-fallback-preserves-builtin
  (with-fresh-bindings
    ;; C-w becomes a user prefix (C-w >), but C-w n must still run the built-in
    ;; window-select-next via the fall-back — one bound sub-key never disables
    ;; the rest of the prefix.
    (clautolisp.ui.ncurses::ui-bind
     "C-w >" (lambda (ui session hit) (declare (ignore ui session hit)) nil))
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list (code-char 23) #\n #\c) :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (eq :repl (active-role ui)))))))

;;;; --- clal-binding AutoLISP surface (step 5c) -----------------------

(test ui-binding-hook-is-installed
  ;; loading the ncurses UI installs the CLAL-BINDING hook (a no-op in the
  ;; builtins otherwise).
  (is (eq #'clautolisp.ui.ncurses::%ui-binding-dispatch
          clautolisp.autolisp-runtime:*ui-binding-hook*)))

(test ui-binding-hook-bind-lookup-map-unbind
  ;; drive the hook exactly as builtin-clal-binding & co. do (CL string key +
  ;; command), then fire in the UI.
  (with-fresh-bindings
    (funcall clautolisp.autolisp-runtime:*ui-binding-hook*
             :bind "z" "window-select-next")
    ;; lookup returns the ORIGINAL command (a string comes back as an AutoLISP string)
    (is (equal "window-select-next"
               (clautolisp.autolisp-runtime:autolisp-string-value
                (funcall clautolisp.autolisp-runtime:*ui-binding-hook* :lookup "z"))))
    ;; and the key fires the named command in the running UI
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (list #\z #\c) :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (eq :repl (active-role ui)))))
    ;; unbind reverts
    (is (funcall clautolisp.autolisp-runtime:*ui-binding-hook* :unbind "z"))
    (is (null (clautolisp.ui.ncurses::ui-binding-lookup "z")))))

(test ui-binding-hook-define-command-and-fire-via-comma
  ;; :define-command registers a named command reachable from `,'; here it is
  ;; backed by a CL closure (the AutoLISP path is the same call-autolisp-function
  ;; wrapper, exercised by the builtins-core suite where builtins are installed).
  (with-fresh-bindings
    (clautolisp.ui.ncurses::ui-define-command
     "user-note" (lambda (ui session hit arg)
                   (declare (ignore session hit arg))
                   (clautolisp.ui.ncurses::push-repl ui "noted") nil))
    (let* ((context (fresh-context))
           (metas (load-and-instrument context +two-source+ "TWO" "ID"))
           (ti (break-at context metas 3)))
      (multiple-value-bind (result ui screen)
          (run-ncurses (append (list #\,) (coerce "user-note" 'list) (list :enter #\c))
                       :context context :thread-info ti
                       :thunk (lambda () (call-two context)))
        (declare (ignore result screen))
        (is (some (lambda (l) (search "noted" l))
                  (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))))

;;;; --- clal frame/window/face object surface (step 6) ----------------

(defun mkstr (s) (clautolisp.autolisp-runtime:make-autolisp-string s))

(test ui-object-hook-is-installed
  (is (eq #'clautolisp.ui.ncurses::%ui-object-dispatch
          clautolisp.autolisp-runtime:*ui-object-hook*)))

(test ui-object-frames-and-windows-are-opaque-typed-handles
  (clautolisp.autolisp-runtime:reset-lisp-object-wrappers)
  (clautolisp.ui.tui:reset-frames)
  (let ((hook clautolisp.autolisp-runtime:*ui-object-hook*))
    ;; (clal-make-frame '(("device" . "vdt") ("name" . "debug")))
    (let ((frame (funcall hook :make-frame
                          (list (cons (mkstr "device") (mkstr "vdt"))
                                (cons (mkstr "name") (mkstr "debug"))))))
      (is (clautolisp.autolisp-runtime:lisp-object-p frame "VDT-FRAME"))
      (is (eq (rt-sym "VDT-FRAME") (clautolisp.autolisp-runtime:autolisp-type frame)))
      (is (equal "debug" (clautolisp.autolisp-runtime:autolisp-string-value
                          (funcall hook :frame-name frame))))
      ;; the same underlying frame yields the EQ-stable handle
      (is (eq frame (first (funcall hook :frame-list))))
      (funcall hook :select-frame frame)
      ;; (clal-make-window '(("name" . "sedit")))
      (let ((w (funcall hook :make-window (list (cons (mkstr "name") (mkstr "sedit"))))))
        (is (clautolisp.autolisp-runtime:lisp-object-p w "WINDOW"))
        (is (eq (rt-sym "WINDOW") (clautolisp.autolisp-runtime:autolisp-type w)))
        (is (equal "sedit" (clautolisp.autolisp-runtime:autolisp-string-value
                            (funcall hook :window-name w))))
        (is (member w (funcall hook :window-list frame)))       ; interned handle
        ;; printed representation is the opaque #<WINDOW "sedit" …>
        (is (search "#<WINDOW \"sedit\"" (prin1-to-string w)))))))

(test ui-object-define-and-read-face
  (let ((hook clautolisp.autolisp-runtime:*ui-object-hook*))
    ;; (clal-define-face "warn" "red" nil T)
    (funcall hook :define-face (mkstr "warn") (mkstr "red") nil
             (clautolisp.autolisp-runtime:intern-autolisp-symbol "T"))
    (is (clautolisp.ui.tui:facep :warn))
    (let ((params (funcall hook :face-parameters (mkstr "warn"))))
      (is (find-if (lambda (pair)
                     (and (string-equal "fg" (clautolisp.autolisp-runtime:autolisp-string-value (car pair)))
                          (typep (cdr pair) 'clautolisp.autolisp-runtime:autolisp-string)
                          (string-equal "RED" (clautolisp.autolisp-runtime:autolisp-string-value (cdr pair)))))
                   params))
      (is (member "warn" (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                                 (funcall hook :list-faces)) :test #'string=)))))

(test call-with-temp-window-creates-then-deletes
  (clautolisp.ui.tui:reset-frames)
  (let ((frame (clautolisp.ui.tui:make-frame (list (cons :device :tty))))
        (seen nil) (alive-in-body nil))
    (clautolisp.ui.tui:select-frame frame)
    (let ((ret (clautolisp.ui.ncurses::call-with-temp-window
                (list (cons :name "temp"))
                (lambda (w)
                  (setf seen w
                        alive-in-body (and (member w (clautolisp.ui.tui:window-list frame)) t))
                  :done))))
      (is (eq :done ret))                                       ; returns the body value
      (is (eq t alive-in-body))                                 ; window alive in the body
      (is (not (null seen)))
      (is (not (member seen (clautolisp.ui.tui:window-list frame)))))))  ; gone after

;;;; --- per-module print IO-syntax (TUI module spec §13) --------------

(test clal-print-base-defaults-print-in-full
  ;; base defaults: *clal-print-length*/level nil -> the whole object
  (is (string= "(1 2 3 4 5 6)"
               (clautolisp.debug.ui:clal-prin1-to-string (list 1 2 3 4 5 6)))))

(test clal-stack-print-syntax-truncates-length-and-level
  (clautolisp.debug.ui:with-stack-print-syntax
    (is (string= "(1 2 3 ...)"                       ; *print-length* 3
                 (clautolisp.debug.ui:clal-prin1-to-string (list 1 2 3 4 5 6))))
    (is (string= "(1 (2 #))"                          ; *print-level* 2
                 (clautolisp.debug.ui:clal-prin1-to-string
                  (list 1 (list 2 (list 3 (list 4)))))))))

(test clal-repl-print-syntax-prints-in-full
  (clautolisp.debug.ui:with-repl-print-syntax
    (is (string= "(1 2 3 4 5 6)"                      ; repl length/level nil
                 (clautolisp.debug.ui:clal-prin1-to-string (list 1 2 3 4 5 6))))))

(test clal-princ-vs-prin1-escaping
  ;; princ vs prin1 differ on string escaping (AutoLISP surface syntax)
  (let ((s (clautolisp.autolisp-runtime:make-autolisp-string "hi")))
    (is (string= "hi"   (clautolisp.debug.ui:clal-princ-to-string s)))
    (is (string= "\"hi\"" (clautolisp.debug.ui:clal-prin1-to-string s)))))

;;;; --- sedit running live in a window (windows-and-interactor-templates) ---

(test sedit-runs-live-in-the-source-pane
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen)))
    ;; M-x sedit on a form: the source pane swaps its navigator for sedit
    (clautolisp.ui.ncurses::open-sedit-in-source ui nil nil "(+ 1 2)")
    (let* ((source (clautolisp.ui.ncurses::ui-window ui :source))
           (act (clautolisp.ui.ncurses::window-sedit-activation source)))
      (is (not (null act)))
      ;; the pane now renders the sedit selection (the edited form)
      (let ((buffer (clautolisp.ui.ncurses::window-content ui nil source)))
        (is (not (null (some (lambda (line) (search "+" (car line))) buffer)))))
      ;; a motion keystroke drives the sedit command and moves the selection
      (let ((before (clautolisp.sedit:sedit-activation-render act)))
        (clautolisp.ui.ncurses::sedit-window-key act ui #\d)     ; descend
        (is (not (string= before (clautolisp.sedit:sedit-activation-render act)))))
      ;; q swaps the navigator back
      (clautolisp.ui.ncurses::sedit-window-key act ui #\q)
      (is (null (clautolisp.ui.ncurses::window-sedit-activation source)))
      (is (not (null (member :navi (clautolisp.ui.tui:window-stack source))))))))

(test sedit-window-key-runs-a-motion-through-the-framework
  ;; The keystroke driver dispatches through the interactor framework against the
  ;; activation's own one-entry stack (no interactor-loop): a bare motion command
  ;; changes the sedit selection.
  (let* ((act (clautolisp.interactor:instantiate-interactor-template
               "sedit"
               (clautolisp.interactor:make-template-context
                :target (clautolisp.sedit:parse-form "(a (b c) d)"))))
         (before (clautolisp.sedit:sedit-activation-render act)))
    (clautolisp.interactor:run-command-line "d" :stack (list act))
    (is (not (string= before (clautolisp.sedit:sedit-activation-render act))))))

;;;; --- the list-selector interactor (windows-and-interactor-templates) ---

(test list-selector-runs-in-a-window-and-selects
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (chosen nil))
    (clautolisp.ui.ncurses::open-selector-in-source
     ui "Pick" (list (cons "one" :one) (cons "two" :two))
     (lambda (v) (setf chosen v)))
    (let* ((source (clautolisp.ui.ncurses::ui-window ui :source))
           (act (clautolisp.ui.ncurses::window-selector-activation source)))
      (is (not (null act)))
      ;; the pane renders the titled list
      (let ((buffer (clautolisp.ui.ncurses::window-content ui nil source)))
        (is (not (null (some (lambda (l) (search "one" (car l))) buffer)))))
      ;; down then Enter chooses the second item and closes the selector
      (clautolisp.ui.ncurses::selector-key act ui :down)
      (clautolisp.ui.ncurses::selector-key act ui :enter)
      (is (eq :two chosen))
      (is (null (clautolisp.ui.ncurses::window-selector-activation source)))
      (is (not (null (member :navi (clautolisp.ui.tui:window-stack source))))))))

(test list-windows-command-opens-a-window-picker
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen)))
    (clautolisp.ui.ncurses::list-windows-command ui nil nil "")
    (let* ((source (clautolisp.ui.ncurses::ui-window ui :source))
           (act (clautolisp.ui.ncurses::window-selector-activation source)))
      (is (not (null act)))
      ;; the list names the panes (e.g. the interactor pane)
      (let ((buffer (clautolisp.ui.ncurses::window-content ui nil source)))
        (is (not (null (some (lambda (l) (search "interactor" (car l))) buffer))))))))

(test list-selector-q-cancels
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (chosen :untouched))
    (clautolisp.ui.ncurses::open-selector-in-source
     ui "Pick" (list (cons "a" :a)) (lambda (v) (setf chosen v)))
    (let* ((source (clautolisp.ui.ncurses::ui-window ui :source))
           (act (clautolisp.ui.ncurses::window-selector-activation source)))
      (clautolisp.ui.ncurses::selector-key act ui #\q)
      (is (eq :untouched chosen))                    ; on-select not called
      (is (null (clautolisp.ui.ncurses::window-selector-activation source))))))

;;;; --- the repl pane runs a live Lisp instance (windows-and-interactor-templates) ---

(test repl-pane-evaluates-in-the-shared-lisp-image
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen)))
    (clautolisp.ui.ncurses::repl-window-eval ui "42")
    ;; the repl buffer echoes the form and its printed value
    (is (not (null (some (lambda (l) (search "42" l))
                         (clautolisp.ui.ncurses:ncurses-ui-repl-lines ui)))))
    ;; the pane now owns a real *AUTOLISP* activation over the shared evaluator
    (is (eq clautolisp.repl:*autolisp*
            (clautolisp.interactor:activation-interactor
             (clautolisp.ui.ncurses::ncurses-ui-repl-activation ui))))))

;;;; --- the shared (aldo) tail: debugger commands route from any pane -------

(test debugger-command-routes-from-any-pane
  ;; C-w p activates the source pane; `c' there is not a navi key, so it falls
  ;; through to the shared aldo tail (spec §C) and resumes execution.
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\p #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eql 7 result)))))

;;;; --- unified config persistence (cascade shares the settings files) -----

(test cascade-config-round-trips-through-the-shared-format
  (unwind-protect
       (progn
         (clautolisp.ui.tui:reset-configs)
         (clautolisp.ui.tui:ensure-standard-configs)
         (clautolisp.ui.tui:config-bind "aldo" "g" "trace")
         (clautolisp.ui.tui:set-config-face "aldo" :current-line '(:fg :red))
         ;; write aldo.conf: the bridge hook merges the cascade keys in
         (let ((text (with-output-to-string (s)
                       (clautolisp.debug.ui:write-aldo-configuration
                        s '((:value-line-width . 72))))))
           (is (not (null (search "value-line-width" text))))   ; scalar setting
           (is (not (null (search "bindings" text))))           ; cascade binding
           (is (not (null (search "faces" text))))              ; cascade face
           ;; read back: scalar stays for the settings store, cascade -> tui-core
           (clautolisp.ui.tui:reset-configs)
           (clautolisp.ui.tui:ensure-standard-configs)
           (let ((scalar (with-input-from-string (s text)
                           (clautolisp.ui.ncurses::%consume-cascade-entries
                            "aldo" (clautolisp.debug.ui:read-aldo-configuration s)))))
             (is (eql 72 (cdr (assoc :value-line-width scalar))))
             (is (equal "trace" (clautolisp.ui.tui:effective-binding "aldo" "g")))
             (is (equal '(:fg :red)
                        (clautolisp.ui.tui:resolve-face :current-line "aldo"))))))
    ;; leave the shared config registry clean for other systems' tests
    (clautolisp.ui.tui:reset-configs)))

(test settings-file-is-unchanged-when-the-cascade-is-empty
  ;; byte-compatibility: with no cascade faces/bindings, the hook is a no-op and
  ;; aldo.conf is exactly what it was before the unification.
  (clautolisp.ui.tui:reset-configs)
  (clautolisp.ui.tui:ensure-standard-configs)
  (let ((text (with-output-to-string (s)
                (clautolisp.debug.ui:write-aldo-configuration
                 s '((:value-line-width . 72))))))
    (is (null (search "bindings" text)))
    (is (null (search "faces" text))))
  (clautolisp.ui.tui:reset-configs))

;;;; --- named window layouts (windows-and-interactor-templates.issue Q5) ----

(test layout-serialises-to-a-role-tree
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen)))
    (is (equal +canonical-role-layout+
               (clautolisp.ui.ncurses::layout->spec (clautolisp.ui.ncurses::ui-layout ui))))))

(test save-and-load-layout-restores-the-arrangement
  (unwind-protect
       (let* ((screen (clautolisp.ui.tui:make-mock-screen))
              (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen)))
         (clautolisp.ui.tui:reset-configs)
         (clautolisp.ui.ncurses::save-layout ui "l1")     ; record the canonical layout
         ;; collapse the layout to a single pane, then restore it
         (setf (clautolisp.ui.ncurses::ui-layout ui)
               (clautolisp.ui.ncurses::ui-window ui :repl))
         (is (not (equal +canonical-role-layout+ (ui-layout-roles ui))))
         (is (eq t (clautolisp.ui.ncurses::load-layout ui "l1")))
         (is (equal +canonical-role-layout+ (ui-layout-roles ui)))
         ;; an unknown name leaves the layout untouched
         (is (null (clautolisp.ui.ncurses::load-layout ui "nope"))))
    (clautolisp.ui.tui:reset-configs)))

(test named-layouts-round-trip-through-the-shared-format
  (unwind-protect
       (progn
         (clautolisp.ui.tui:reset-configs)
         (let ((cfg (clautolisp.ui.tui:ensure-config "layouts"))
               (spec '(:horizontal 1/2 :stack :source)))
           (clautolisp.ui.tui:config-set-value cfg :layouts (list (cons "l1" spec)))
           (let ((text (with-output-to-string (s)
                         (clautolisp.debug.ui:write-configuration-file
                          s (clautolisp.ui.ncurses::%cascade-entries "layouts") '() '()
                          :name "layouts.conf" :what "layouts"))))
             (is (not (null (search "layouts" text))))
             (clautolisp.ui.tui:reset-configs)
             (with-input-from-string (s text)
               (clautolisp.ui.ncurses::%consume-cascade-entries
                "layouts" (clautolisp.debug.ui:read-aldo-configuration s)))
             (is (equal spec (cdr (assoc "l1" (clautolisp.ui.ncurses::saved-layouts)
                                         :test #'string=)))))))
    (clautolisp.ui.tui:reset-configs)))

;;;; --- make-sedit-window creates a real new window ------------------------

(test make-sedit-window-creates-and-removes-a-window
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
    (clautolisp.ui.ncurses::make-sedit-window ui nil nil "(+ 1 2)")
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (let ((w (clautolisp.ui.ncurses::active-window ui)))
      (is (eq :sedit (clautolisp.ui.tui:window-role w)))
      (let ((act (clautolisp.ui.ncurses::window-sedit-activation w)))
        (is (not (null act)))
        ;; the new pane renders the sedit selection
        (let ((buffer (clautolisp.ui.ncurses::window-content ui nil w)))
          (is (not (null (some (lambda (l) (search "+" (car l))) buffer)))))
        ;; q removes the dedicated window and its layout leaf
        (clautolisp.ui.ncurses::sedit-window-key act ui #\q)
        (is (= n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
        (is (null (find :sedit (clautolisp.ui.ncurses::ui-windows ui)
                        :key #'clautolisp.ui.tui:window-role)))))))

;;;; --- make-lisp-window: a dedicated REPL window --------------------------

(test make-lisp-window-creates-a-repl-window-and-evaluates
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
    (clautolisp.ui.ncurses::make-lisp-window ui nil nil "")
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (let* ((w (clautolisp.ui.ncurses::active-window ui))
           (act (clautolisp.ui.ncurses::window-lisp-activation w)))
      (is (eq :lisp-repl (clautolisp.ui.tui:window-role w)))
      (is (not (null act)))
      ;; evaluate a form into THIS window's own scrollback
      (setf (gethash w (clautolisp.ui.ncurses::ncurses-ui-lisp-lines ui))
            (append (gethash w (clautolisp.ui.ncurses::ncurses-ui-lisp-lines ui))
                    (clautolisp.ui.ncurses::%eval-in-lisp-activation act "42")))
      (let ((buffer (clautolisp.ui.ncurses::window-content ui nil w)))
        (is (not (null (some (lambda (l) (search "42" (car l))) buffer)))))
      ;; q closes the window
      (clautolisp.ui.ncurses::lisp-window-key act ui #\q)
      (is (= n0 (length (clautolisp.ui.ncurses::ui-windows ui)))))))

;;;; --- make-inspector-window: standalone inspector in a window ------------

(test make-inspector-window-inspects-in-a-window
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
    ;; a direct inspector activation over a list: render + descend + up + close
    (let* ((activation (clautolisp.ui.ncurses::make-inspector-activation (list 10 20 30)))
           (window (clautolisp.ui.tui:add-window-to-frame
                    (clautolisp.ui.ncurses::ncurses-ui-frame ui)
                    :name "inspect" :role :inspector
                    :beside (clautolisp.ui.ncurses::active-window ui) :split :vertical)))
      (setf (clautolisp.ui.tui:window-stack window) (list activation))
      (clautolisp.ui.ncurses::activate-window ui window)
      (is (eq :inspector (clautolisp.ui.tui:window-role window)))
      (is (not (null (clautolisp.ui.ncurses::window-inspector-activation window))))
      (is (>= (length (clautolisp.ui.ncurses::window-content ui nil window)) 1))
      (clautolisp.ui.ncurses::inspector-window-key activation ui #\d)   ; descend
      (clautolisp.ui.ncurses::inspector-window-key activation ui #\u)   ; ascend
      (clautolisp.ui.ncurses::inspector-window-key activation ui #\q)   ; close
      (is (= n0 (length (clautolisp.ui.ncurses::ui-windows ui)))))
    ;; the command path (evaluate a form) also creates an inspector window
    (clautolisp.ui.ncurses::make-inspector-window ui nil nil "nil")
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (is (eq :inspector (clautolisp.ui.tui:window-role
                        (clautolisp.ui.ncurses::active-window ui))))))

;;;; --- make-stack-browser-window: standalone backtrace browser -----------

(test stack-browser-window-renders-navigates-and-inspects
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui)))
         (frame (clautolisp.debug::make-stack-frame
                 :function-name "FOO"
                 :bindings-introduced
                 (list (clautolisp.debug::make-binding-entry
                        :symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "X")
                        :value 42)
                       (clautolisp.debug::make-binding-entry
                        :symbol (clautolisp.autolisp-runtime:intern-autolisp-symbol "Y")
                        :value 99))))
         (snapshot (clautolisp.debug::make-snapshot :call-stack (list frame)))
         (activation (clautolisp.ui.ncurses::make-stack-browser-activation snapshot))
         (window (clautolisp.ui.tui:add-window-to-frame
                  (clautolisp.ui.ncurses::ncurses-ui-frame ui)
                  :name "stack" :role :stack-browser
                  :beside (clautolisp.ui.ncurses::active-window ui) :split :vertical)))
    (setf (clautolisp.ui.tui:window-stack window) (list activation))
    (clautolisp.ui.ncurses::activate-window ui window)
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    ;; renders the frame name and its bindings from copied data
    (let ((buffer (clautolisp.ui.ncurses::window-content ui nil window)))
      (is (not (null (some (lambda (l) (search "FOO" (car l))) buffer))))
      (is (not (null (some (lambda (l) (search "X = 42" (car l))) buffer)))))
    ;; down moves the binding cursor within the frame
    (clautolisp.ui.ncurses::stack-browser-window-key activation ui :down)
    (is (= 1 (clautolisp.ui.ncurses::stack-browser-state-binding
              (clautolisp.interactor:activation-state activation))))
    ;; i inspects the selected binding's value (99) in a new inspector window
    (clautolisp.ui.ncurses::stack-browser-window-key activation ui #\i)
    (is (= (+ 2 n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (is (eq :inspector (clautolisp.ui.tui:window-role
                        (clautolisp.ui.ncurses::active-window ui))))))

;;;; --- make-navi-window: standalone read-only structure navigator --------

(test make-navi-window-navigates-a-form-read-only
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
    (clautolisp.ui.ncurses::make-navi-window ui nil nil "(a (b c) d)")
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (let* ((w (clautolisp.ui.ncurses::active-window ui))
           (act (clautolisp.ui.ncurses::window-navi-activation w)))
      (is (eq :navi-view (clautolisp.ui.tui:window-role w)))
      (is (not (null act)))
      ;; descend moves the selection
      (let ((before (mapcar #'car (clautolisp.ui.ncurses::window-content ui nil w))))
        (clautolisp.ui.ncurses::navi-window-key act ui #\d)
        (is (not (equal before (mapcar #'car (clautolisp.ui.ncurses::window-content ui nil w))))))
      ;; an editing key is not a motion here: unhandled (read-only)
      (multiple-value-bind (h d) (clautolisp.ui.ncurses::navi-window-key act ui #\i)
        (declare (ignore d))
        (is (null h)))
      ;; q closes
      (clautolisp.ui.ncurses::navi-window-key act ui #\q)
      (is (= n0 (length (clautolisp.ui.ncurses::ui-windows ui)))))))

;;;; --- make-aldo-window: a second debugger-command surface (aldo<2>) ------

(test make-aldo-window-creates-renders-and-closes
  (let* ((screen (clautolisp.ui.tui:make-mock-screen))
         (ui (clautolisp.ui.ncurses::make-ncurses-ui :screen screen))
         (n0 (length (clautolisp.ui.ncurses::ui-windows ui))))
    (clautolisp.ui.ncurses::make-aldo-window ui nil nil "")
    (is (= (1+ n0) (length (clautolisp.ui.ncurses::ui-windows ui))))
    (let* ((w (clautolisp.ui.ncurses::active-window ui))
           (act (clautolisp.ui.ncurses::window-aldo-view-activation w)))
      (is (eq :aldo-view (clautolisp.ui.tui:window-role w)))
      (is (not (null act)))
      ;; the aldo-view carries its OWN backend (session + hit), not a UI global
      (is (clautolisp.ui.ncurses::aldo-view-state-p
           (clautolisp.interactor:activation-state act)))
      (is (>= (length (clautolisp.ui.ncurses::window-content ui nil w)) 1))
      ;; q on a stand-alone aldo window (role :aldo-view) closes it
      (clautolisp.ui.ncurses::aldo-view-window-key act ui #\q)
      (is (= n0 (length (clautolisp.ui.ncurses::ui-windows ui)))))))
