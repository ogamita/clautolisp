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
               (is (eq :yellow (clautolisp.ui.tui:mock-attr-at screen row col))))))
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
                 (is (eq :red (clautolisp.ui.tui:mock-attr-at screen row col)))))))
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
    (multiple-value-bind (result ui screen)
        (run-ncurses (list :down #\a) :context context :thread-info ti
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
        (run-ncurses (list #\b #\b #\c) :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore result screen))
      (is (search "set at line 3" (clautolisp.ui.ncurses:ncurses-ui-message ui))))))

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

(test eof-continues
  (let* ((context (fresh-context))
         (metas (load-and-instrument context +two-source+ "TWO" "ID"))
         (ti (break-at context metas 3)))
    (multiple-value-bind (result ui screen)
        (run-ncurses '() :context context :thread-info ti
                     :thunk (lambda () (call-two context)))
      (declare (ignore ui screen))
      (is (eql 7 result)))))
