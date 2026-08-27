;;;; clautolisp/autolisp-debug-ui-ncurses/tests/ncurses-tests.lisp
;;;;
;;;; The four-pane UI driven through the mock screen: scripted keys in,
;;;; resume directives + UI state + grid contents out.

(in-package #:clautolisp.ui.ncurses.tests)

(in-suite ncurses-suite)

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

(test window-scroll-reports-on-active-window
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    ;; C-w v scrolls the active window (message records it); no crash.
    (multiple-value-bind (result ui screen)
        (run-ncurses (list (code-char 23) #\v #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (search "scroll" (clautolisp.ui.ncurses:ncurses-ui-message ui))))))

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
      (progn
        (is (eq :window-manager (first (window-stack-of ui :source))))
        (is (equal '(:window-manager :navi) (window-stack-of ui :source)))
        (is (not (member :window-manager (window-stack-of ui :interactor))))))))

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
