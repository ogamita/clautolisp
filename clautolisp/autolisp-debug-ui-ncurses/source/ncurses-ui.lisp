(in-package #:clautolisp.ui.ncurses)

;;;; The four-pane ncurses UI (spec §19). It implements the
;;;; clautolisp.debug.ui protocol by rendering panes to a tui-screen and
;;;; driving a key event loop in UI-AWAIT-COMMAND. All output also accrues
;;;; into UI slots (message, repl-lines) so behaviour is assertable
;;;; without scraping the screen grid.

(defclass ncurses-ui ()
  ((screen :initarg :screen :initform nil :accessor ncurses-ui-screen)
   (selected-frame :initform 0 :accessor ncurses-ui-selected-frame)
   (source-cursor :initform nil :accessor ncurses-ui-source-cursor)  ; line in shown file
   (message :initform "" :accessor ncurses-ui-message)               ; interactor line
   (repl-lines :initform '() :accessor ncurses-ui-repl-lines)        ; newest last
   (navigator :initform nil :accessor ncurses-ui-navigator)          ; source selection
   (layout :initform (default-layout) :accessor ncurses-ui-layout)   ; window tree
   (active-window :initform :interactor :accessor ncurses-ui-active-window)
   (minibuffer :initform "" :accessor ncurses-ui-minibuffer)         ; last-row I/O
   (inspector-cursor :initform 0 :accessor ncurses-ui-inspector-cursor)))

(defun make-ncurses-ui (&rest initargs)
  (apply #'make-instance 'ncurses-ui initargs))

(register-ui :ncurses (lambda (&rest initargs) (apply #'make-ncurses-ui initargs)))
(register-ui :tui     (lambda (&rest initargs) (apply #'make-ncurses-ui initargs)))

(defun push-repl (ui control &rest args)
  (setf (ncurses-ui-repl-lines ui)
        (append (ncurses-ui-repl-lines ui) (list (apply #'format nil control args)))))

(defun set-message (ui control &rest args)
  (setf (ncurses-ui-message ui) (apply #'format nil control args)))

;;;; --- protocol: lifecycle + notifications ---------------------------

(defmethod ui-attached ((ui ncurses-ui) session)
  (declare (ignore session))
  ;; The screen is supplied by the caller (a real curses screen on the CLI
  ;; path, a mock screen in tests). Fail with an actionable message rather than
  ;; an unbound-slot error when no backend was wired.
  ;;
  ;; NOTE: we do NOT enter full-screen (curses) mode here. The debugger session
  ;; is attached for the whole program, but the REPL between stops must run as
  ;; an ordinary line-disciplined terminal — echo on, cooked mode — not under
  ;; curses. So curses is entered only while actually stopped in the debugger
  ;; (UI-AWAIT-COMMAND) and left on resume.
  (unless (ncurses-ui-screen ui)
    (error "The ncurses debugger UI has no terminal screen: no curses backend ~
(clautolisp.ui.tui.curses) is loaded. Use --debugger-ui tui."))
  (set-message ui "clautolisp debugger — h for help"))

(defmethod ui-detached ((ui ncurses-ui))
  ;; Safety: leave curses if a stop was interrupted without resuming.
  (tui-stop (ncurses-ui-screen ui)))

(defmethod ui-show-message ((ui ncurses-ui) level control &rest args)
  (set-message ui "[~A] ~A" level (apply #'format nil control args)))

(defmethod ui-thread-hit ((ui ncurses-ui) session hit)
  (declare (ignore hit))
  (reset-stop-state ui session))

(defmethod ui-thread-unhandled-error ((ui ncurses-ui) session hit)
  (reset-stop-state ui session)
  (set-message ui "ERROR: ~A   (a abort, r return, c run *error*)"
               (hit-error-message hit)))

(defmethod ui-thread-caught-error ((ui ncurses-ui) session hit)
  (reset-stop-state ui session)
  (set-message ui "caught error: ~A" (hit-error-message hit)))

(defun reset-stop-state (ui session)
  (setf (ncurses-ui-selected-frame ui) 0
        (ncurses-ui-inspector-cursor ui) 0)
  (let ((snapshot (current-snapshot session)))
    (setf (ncurses-ui-source-cursor ui)
          (let ((position (and snapshot (snapshot-source-position snapshot))))
            (and (source-position-p position) (source-position-start-line position)))))
  (rebuild-navigator ui session))

(defun rebuild-navigator (ui session)
  "Build the source navigator for the selected frame, its selection
re-anchored to that frame's stopping position (§19.1 source pane). Stores NIL
when the frame has no reconstructable source form (e.g. a builtin)."
  (let* ((frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (position (and frame (stack-frame-source-position frame))))
    (setf (ncurses-ui-navigator ui)
          (and metadata (navigator-for-metadata metadata position)))))

(defun selection-line-of (ui)
  "The source line of the navigator's current selection (the cursor), or NIL."
  (let* ((nav (ncurses-ui-navigator ui))
         (position (and nav (nav-selected-position nav))))
    (and (source-position-p position) (source-position-start-line position))))

;;;; --- rendering -----------------------------------------------------

(defun selected-frame-of (ui session)
  (let ((frames (and (current-snapshot session)
                     (snapshot-call-stack (current-snapshot session)))))
    (and frames (nth (min (ncurses-ui-selected-frame ui) (1- (length frames))) frames))))

;;;; --- window rendering (ncurses-windows.issue) ----------------------
;;;; Each window is a rectangle (TOP LEFT HEIGHT WIDTH). Its bottom row is a
;;;; status line (title; active window INVERTed, others UNDERLINEd — the
;;;; horizontal separator between stacked windows). Vertical neighbours are
;;;; parted by a single "|" column. The last screen row is the minibuffer.

(defun win-content-height (rect) (max 0 (1- (third rect))))
(defun win-width (rect) (fourth rect))

(defun win-put-line (screen rect row text &key attr)
  "Write TEXT on content ROW (0-based) of RECT, padded/clipped to its width.
Rows are clipped to the window's content area (its last row is the status
line, written by WIN-STATUS)."
  (destructuring-bind (top left height width) rect
    (when (< -1 row (1- height))
      (tui-put screen (+ top row) left
               (pad-string (truncate-string text width) width) :attr attr))))

(defun win-status (screen rect title active-p)
  "Draw RECT's status line (its bottom row): the window TITLE across the full
width, INVERTed when active, UNDERLINEd otherwise."
  (destructuring-bind (top left height width) rect
    (tui-put screen (+ top height -1) left
             (pad-string (truncate-string (format nil " ~A " title) width) width)
             :attr (if active-p :invert :underline))))

(defun draw-vline (screen col top height)
  (loop for r from top below (+ top height) do (tui-put screen r col "|")))

(defun render-window (ui session id rect)
  (ecase id
    (:stack      (render-stack ui session rect))
    (:source     (render-source ui session rect))
    (:interactor (render-interactor ui rect))
    (:repl       (render-repl ui rect))))

(defun render-debugger (ui session)
  "Draw the four windows for the current stopping point per the current
layout tree: content + a status line per window, single \"|\" separators, and
the reserved minibuffer row."
  (let ((screen (ncurses-ui-screen ui)))
    (tui-clear screen)
    (multiple-value-bind (rows cols) (tui-size screen)
      (let ((window-rows (max 1 (1- rows))))     ; last row = minibuffer
        (multiple-value-bind (rects vlines)
            (layout-rects (ncurses-ui-layout ui) 0 0 window-rows cols)
          (dolist (id +window-ids+)
            (let ((rect (cdr (assoc id rects))))
              (when rect
                (render-window ui session id rect)
                (win-status screen rect (window-title id)
                            (eq id (ncurses-ui-active-window ui))))))
          (dolist (v vlines)
            (destructuring-bind (col top height) v (draw-vline screen col top height)))
          (render-minibuffer ui (1- rows) cols)
          (tui-refresh screen))))))

(defun render-minibuffer (ui row cols)
  (tui-put (ncurses-ui-screen ui) row 0
           (pad-string (truncate-string (ncurses-ui-minibuffer ui) cols) cols)))

(defun render-stack (ui session rect)
  (let ((frames (and (current-snapshot session)
                     (snapshot-call-stack (current-snapshot session))))
        (screen (ncurses-ui-screen ui)))
    (loop for frame in frames
          for i from 0 below (win-content-height rect)
          do (win-put-line
              screen rect i
              (format nil "~A ~A  ~A"
                      (if (= i (ncurses-ui-selected-frame ui)) ">" " ")
                      (or (stack-frame-function-name frame) "?")
                      (frame-line-label frame))
              :attr (if (= i (ncurses-ui-selected-frame ui)) :bold :normal)))))

(defun frame-line-label (frame)
  (let ((position (stack-frame-source-position frame)))
    (if (source-position-p position)
        (format nil "line ~D" (source-position-start-line position))
        "-")))

(defun render-source (ui session rect)
  "Source window (spec §19.1): show the selected frame's source with markers —
current stopping line :yellow, a breakpointed poll point :red, a plain poll
point :blue. The =>>= gutter follows the structural navigator's selection (the
cursor moved by d/u/&gt;/&lt;), and the window scrolls to keep it in view."
  (let* ((screen (ncurses-ui-screen ui))
         (frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (position (and frame (stack-frame-source-position frame)))
         (file (and (source-position-p position) (source-position-file position)))
         (current-line (and (source-position-p position) (source-position-start-line position)))
         (selection-line (or (selection-line-of ui) current-line))
         (lines (and file (ignore-errors (lines-of file))))
         (poll-lines (and metadata (poll-point-lines metadata)))
         (bp-lines (breakpoint-lines session fid))
         (height (win-content-height rect)))
    (cond
      ((and lines (plusp (length lines)))
       (let* ((center (or selection-line current-line 1))
              (start (max 1 (- center (floor height 2)))))
         (loop for row from 0 below height
               for n = (+ start row)
               while (<= n (length lines))
               do (win-put-line
                   screen rect row
                   (format nil "~A~3D: ~A"
                           (if (eql n selection-line) ">>" "  ") n (aref lines (1- n)))
                   :attr (cond ((eql n current-line) :yellow)
                               ((member n bp-lines) :red)
                               ((member n poll-lines) :blue)
                               (t :normal))))))
      (t
       (win-put-line screen rect 0
                     (format nil "~A:~@[~D~] (source unavailable)"
                             (or file "?") current-line))))))

(defun poll-point-lines (metadata)
  (let ((positions (function-debug-metadata-form-id->position metadata)) (lines '()))
    (loop for i from 0 below (length positions)
          for position = (aref positions i)
          when (source-position-p position)
            do (pushnew (source-position-start-line position) lines))
    lines))

(defun breakpoint-lines (session fid)
  (let ((metadata (metadata-for-function-id fid))
        (lines '()))
    (when metadata
      (dolist (bp (cmd-list-breakpoints session))
        (when (eql (breakpoint-fid bp) fid)
          (let ((position (form-id-position metadata (breakpoint-form-id bp))))
            (when (source-position-p position)
              (push (source-position-start-line position) lines))))))
    lines))

(defun render-interactor (ui rect)
  (let ((screen (ncurses-ui-screen ui)))
    (win-put-line screen rect 0 (format nil "DBG> ~A" (ncurses-ui-message ui)))
    (win-put-line screen rect 2 "c continue  s step  i in  o out  f finish")
    (win-put-line screen rect 3 "d u > < nav  b bkpt  e eval  x inspect  ^/v frame")
    (win-put-line screen rect 4 "C-w n/p sel >/</u/d swap 2/3 split 4 reset +/-/= size  q quit")))

(defun render-repl (ui rect)
  (let* ((screen (ncurses-ui-screen ui))
         (height (win-content-height rect))
         (lines (last (ncurses-ui-repl-lines ui) height)))
    (loop for line in lines
          for row from 0
          do (win-put-line screen rect row line))))

;;;; --- the event loop (spec §19.1) -----------------------------------

(defmethod ui-await-command ((ui ncurses-ui) session hit)
  ;; Enter curses only for the duration of this stop; leave it (restoring the
  ;; ordinary line-disciplined terminal) on resume, so the REPL between stops
  ;; behaves as a dumb terminal. The layout/active-window live in the UI
  ;; instance and so persist across the enter/exit cycles of one session.
  (tui-start (ncurses-ui-screen ui))
  (unwind-protect
       (loop
         (render-debugger ui session)
         (let* ((key (tui-read-key (ncurses-ui-screen ui)))
                (directive (handle-key ui session hit key)))
           (when (eq key :eof) (return :continue))
           (when directive (return directive))))
    (tui-stop (ncurses-ui-screen ui))))

(defun handle-key (ui session hit key)
  "Dispatch one command-mode key; return a resume directive or NIL."
  (cond
    ((key-char-p key #\c) (cmd-continue session))
    ((or (key-char-p key #\s) (key-char-p key #\n)) (cmd-step session :over))
    ((key-char-p key #\i) (cmd-step session :into))
    ((key-char-p key #\o) (cmd-step session :out))
    ((key-char-p key #\f) (cmd-step session :finish))
    ((key-char-p key #\a) (cmd-abort session))
    ((key-char-p key #\q) (cmd-abort session))
    ((key-char-p key #\r) (return-value ui session hit) )
    ;; C-w prefix: window-manipulation commands (ncurses-windows.issue).
    ((and (characterp key) (= (char-code key) 23)) (handle-window-command ui) nil)
    ((eq key :up) (move-frame ui session -1) nil)
    ((eq key :down) (move-frame ui session +1) nil)
    ;; structural navigation of the source form (spec §19.1 / cmd-ref §3):
    ;; d down, u up, > next sibling, < previous sibling. The selection is the
    ;; cursor location-taking commands (b) act on (cursor-based, cmd-ref §0).
    ((key-char-p key #\d) (nav-move ui #'nav-code-down) nil)
    ((key-char-p key #\u) (nav-move ui #'nav-up) nil)
    ((key-char-p key #\>) (nav-move ui #'nav-code-forward) nil)
    ((key-char-p key #\<) (nav-move ui #'nav-code-backward) nil)
    ((key-char-p key #\b) (toggle-breakpoint ui session) nil)
    ((key-char-p key #\e) (eval-line ui session) nil)
    ((key-char-p key #\x) (inspect-loop ui session) nil)
    ;; minibuffer command entry: `,' reads a command line, Esc-x is M-x.
    ((key-char-p key #\,) (comma-command ui session hit))
    ((eq key :escape) (meta-command ui session hit))
    ((key-char-p key #\h) (set-message ui "keys: c s i o f | d u > < nav | b e x | ^/v frame | , cmd  M-x name | a r q") nil)
    (t nil)))

(defun nav-move (ui motion)
  "Apply MOTION to the source navigator and echo the newly-selected subform
into the interactor line (so the selection is visible across the panes)."
  (let ((nav (ncurses-ui-navigator ui)))
    (when nav
      (funcall motion nav)
      (set-message ui "sel: ~A" (nav-render nav)))))

;;;; --- window commands (C-w prefix; ncurses-windows.issue) -----------

(defparameter +window-resize-step+ 1/16
  "Ratio change per C-w + / C-w - (a C-u prefix for larger steps is TODO).")

(defun window-select (ui delta)
  "Move the active window DELTA steps in reading order (C-w n / C-w p)."
  (setf (ncurses-ui-active-window ui)
        (window-cycle (ncurses-ui-layout ui) (ncurses-ui-active-window ui) delta))
  (set-message ui "active window: ~A"
               (window-title (ncurses-ui-active-window ui))))

(defun window-swap (ui direction)
  "Swap the active window with its neighbour in DIRECTION (with wrap-around),
exchanging their leaf positions in the layout tree."
  (multiple-value-bind (rows cols) (tui-size (ncurses-ui-screen ui))
    (multiple-value-bind (rects vlines)
        (layout-rects (ncurses-ui-layout ui) 0 0 (max 1 (1- rows)) cols)
      (declare (ignore vlines))
      (let* ((active (ncurses-ui-active-window ui))
             (neighbor (window-neighbor rects active direction)))
        (if (and neighbor (not (eq neighbor active)))
            (progn
              (setf (ncurses-ui-layout ui)
                    (tree-swap-leaves (ncurses-ui-layout ui) active neighbor))
              (set-message ui "swap ~A ~(~A~)" (window-title active) direction))
            (set-message ui "no window ~(~A~)" direction))))))

(defun window-resize (ui delta)
  "Grow (DELTA>0) or shrink the active window within its enclosing split."
  (setf (ncurses-ui-layout ui)
        (tree-resize (ncurses-ui-layout ui) (ncurses-ui-active-window ui) delta))
  (set-message ui "resize ~A" (window-title (ncurses-ui-active-window ui))))

(defun window-balance (ui)
  "Even out the split enclosing the active window (C-w =)."
  (setf (ncurses-ui-layout ui)
        (tree-balance (ncurses-ui-layout ui) (ncurses-ui-active-window ui)))
  (set-message ui "balanced ~A" (window-title (ncurses-ui-active-window ui))))

(defun window-reset-square (ui)
  "Revert to the canonical 2x2 layout (C-w 4)."
  (setf (ncurses-ui-layout ui) (default-layout))
  (set-message ui "layout reset (2x2)"))

(defun window-split (ui split-type)
  "Split the active window (C-w 2 = below/:horizontal, C-w 3 = right/:vertical),
re-homing the next window into the new split so four windows remain."
  (let* ((active (ncurses-ui-active-window ui))
         (next (window-cycle (ncurses-ui-layout ui) active +1)))
    (if (eq next active)
        (set-message ui "cannot split")
        (progn
          (setf (ncurses-ui-layout ui)
                (tree-split-active (ncurses-ui-layout ui) active next split-type))
          (set-message ui "split ~A ~A" (window-title active)
                       (if (eq split-type :horizontal) "below" "right"))))))

(defun handle-window-command (ui)
  "Read the key following a C-w prefix and run the window command
(ncurses-windows.issue). Split (C-w 2/3), layout save-load and M-x follow."
  (let ((k (tui-read-key (ncurses-ui-screen ui))))
    (cond
      ((key-char-p k #\n) (window-select ui +1))
      ((key-char-p k #\p) (window-select ui -1))
      ((key-char-p k #\>) (window-swap ui :right))
      ((key-char-p k #\<) (window-swap ui :left))
      ((key-char-p k #\u) (window-swap ui :above))
      ((key-char-p k #\d) (window-swap ui :below))
      ((key-char-p k #\2) (window-split ui :horizontal))
      ((key-char-p k #\3) (window-split ui :vertical))
      ((key-char-p k #\4) (window-reset-square ui))
      ((key-char-p k #\+) (window-resize ui +window-resize-step+))
      ((key-char-p k #\-) (window-resize ui (- +window-resize-step+)))
      ((key-char-p k #\=) (window-balance ui))
      (t (set-message ui "C-w: n/p select  >/</u/d swap  2/3 split  4 reset  +/-/= size")))))

;;;; --- minibuffer: M-x and , (ncurses-windows.issue) -----------------

(defun read-minibuffer (ui prompt)
  "Read a line in the minibuffer (last screen row), echoing PROMPT + input.
RET returns the string, Esc cancels (returns NIL), Backspace deletes."
  (let ((chars '()))
    (loop
      (setf (ncurses-ui-minibuffer ui)
            (concatenate 'string prompt (coerce (reverse chars) 'string)))
      (render-debugger ui (current-session-of ui))
      (let ((key (tui-read-key (ncurses-ui-screen ui))))
        (cond
          ((or (eq key :enter) (eq key :eof))
           (setf (ncurses-ui-minibuffer ui) "")
           (return (coerce (nreverse chars) 'string)))
          ((eq key :escape) (setf (ncurses-ui-minibuffer ui) "") (return nil))
          ((eq key :backspace) (when chars (pop chars)))
          ((characterp key) (push key chars))
          (t nil))))))

(defparameter *ncurses-commands*
  (list
   (cons "continue"  (lambda (ui s h a) (declare (ignore ui h a)) (cmd-continue s)))
   (cons "step"      (lambda (ui s h a) (declare (ignore ui h a)) (cmd-step s :over)))
   (cons "step-into" (lambda (ui s h a) (declare (ignore ui h a)) (cmd-step s :into)))
   (cons "step-out"  (lambda (ui s h a) (declare (ignore ui h a)) (cmd-step s :out)))
   (cons "finish"    (lambda (ui s h a) (declare (ignore ui h a)) (cmd-step s :finish)))
   (cons "abort"     (lambda (ui s h a) (declare (ignore ui h a)) (cmd-abort s)))
   (cons "window-select-next"     (lambda (ui s h a) (declare (ignore s h a)) (window-select ui +1) nil))
   (cons "window-select-previous" (lambda (ui s h a) (declare (ignore s h a)) (window-select ui -1) nil))
   (cons "window-swap-right"  (lambda (ui s h a) (declare (ignore s h a)) (window-swap ui :right) nil))
   (cons "window-swap-left"   (lambda (ui s h a) (declare (ignore s h a)) (window-swap ui :left) nil))
   (cons "window-swap-above"  (lambda (ui s h a) (declare (ignore s h a)) (window-swap ui :above) nil))
   (cons "window-swap-below"  (lambda (ui s h a) (declare (ignore s h a)) (window-swap ui :below) nil))
   (cons "window-split-below" (lambda (ui s h a) (declare (ignore s h a)) (window-split ui :horizontal) nil))
   (cons "window-split-right" (lambda (ui s h a) (declare (ignore s h a)) (window-split ui :vertical) nil))
   (cons "windows-split-square" (lambda (ui s h a) (declare (ignore s h a)) (window-reset-square ui) nil))
   (cons "window-size-increment" (lambda (ui s h a) (declare (ignore s h a)) (window-resize ui +window-resize-step+) nil))
   (cons "window-size-decrement" (lambda (ui s h a) (declare (ignore s h a)) (window-resize ui (- +window-resize-step+)) nil))
   (cons "window-size-balance"   (lambda (ui s h a) (declare (ignore s h a)) (window-balance ui) nil)))
  "Named debugger / window commands reachable through M-x and `,'. Maps a
command NAME to (lambda (ui session hit arg) -> resume-directive-or-nil). This
registry is the seed of the user-binding API — see ncurses-key-bindings.issue.
Full aldo / sedit / navi line commands need the per-window interactor stacks
(a later slice); they are not registered here yet.")

(defun run-named-command (ui session hit name arg)
  "Run the command NAME with ARG; return its resume directive or NIL. A name in
*NCURSES-COMMANDS* (window + core debugger commands) runs directly; any other
name is routed as a command line through the shared ALDO vocabulary, so the
full break / trace / watch / settings / … vocabulary is reachable from `,'
and M-x."
  (let ((entry (assoc name *ncurses-commands* :test #'string-equal)))
    (if entry
        (funcall (cdr entry) ui session hit arg)
        (run-aldo-line ui session
                       (format nil "~A~@[ ~A~]"
                               name (and (plusp (length arg)) arg))))))

(defun %split-lines (text)
  (loop with start = 0
        for nl = (position #\Newline text :start start)
        collect (string-right-trim '(#\Return #\Space)
                                   (subseq text start (or nl (length text))))
        while nl do (setf start (1+ nl))))

(defun run-aldo-line (ui session line)
  "Route LINE through the shared ALDO command vocabulary (ncurses-key-bindings.issue
option b): dispatch it with a throwaway dumb-ui whose output is captured into
the repl pane, and return the command's resume directive. HIT is NIL here, so
frame-relative commands degrade gracefully; carrying the current hit is part of
the per-window interactor-stack work."
  (let* ((out (make-string-output-stream))
         (dumb (make-dumb-ui :input (make-string-input-stream "")))
         ;; the generalised output seam: ALDO/NAVI OUT writes here, not to a
         ;; dumb-ui stream — the dumb-ui is only carried for command state.
         (*debugger-output* out))
    (prog1 (ui-run-command dumb session line)
      (dolist (l (%split-lines (get-output-stream-string out)))
        (when (plusp (length l)) (push-repl ui "~A" l))))))

(defun mx-command (ui session hit)
  "M-x: read a command NAME in the minibuffer and run it."
  (let ((name (read-minibuffer ui "M-x ")))
    (when (and name (plusp (length (string-trim " " name))))
      (run-named-command ui session hit (string-trim " " name) ""))))

(defun comma-command (ui session hit)
  "`,': read a full command line (NAME ARGS...) in the minibuffer and run it."
  (let ((line (read-minibuffer ui ",")))
    (when (and line (plusp (length (string-trim " " line))))
      (let* ((trimmed (string-left-trim " " line))
             (sp (position #\Space trimmed))
             (name (if sp (subseq trimmed 0 sp) trimmed))
             (arg  (if sp (string-left-trim " " (subseq trimmed sp)) "")))
        (run-named-command ui session hit name arg)))))

(defun meta-command (ui session hit)
  "Esc as a Meta prefix: Esc-x runs M-x. Other Esc-<key> are unbound for now."
  (let ((k (tui-read-key (ncurses-ui-screen ui))))
    (if (key-char-p k #\x)
        (mx-command ui session hit)
        (progn (set-message ui "M-~A unbound"
                            (if (characterp k) k "key")) nil))))

(defun move-frame (ui session delta)
  (let* ((frames (snapshot-call-stack (current-snapshot session)))
         (n (length frames))
         (new (max 0 (min (1- n) (+ (ncurses-ui-selected-frame ui) delta)))))
    (setf (ncurses-ui-selected-frame ui) new)
    (cmd-select-frame session new)
    (let ((position (stack-frame-source-position (nth new frames))))
      (when (source-position-p position)
        (setf (ncurses-ui-source-cursor ui) (source-position-start-line position))))
    (rebuild-navigator ui session)))

(defun toggle-breakpoint (ui session)
  "Toggle a breakpoint at the source cursor line of the selected frame's
function (spec §19.1: b at the line)."
  (let* ((frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (line (or (selection-line-of ui) (ncurses-ui-source-cursor ui))))
    (cond
      ((not (and metadata line)) (set-message ui "no source line to break on"))
      (t (let ((form-id (find-form-id-at-line metadata line)))
           (if (null form-id)
               (set-message ui "no poll point at line ~D" line)
               (let ((existing (find-if (lambda (bp)
                                          (and (eql (breakpoint-fid bp) fid)
                                               (eql (breakpoint-form-id bp) form-id)))
                                        (cmd-list-breakpoints session))))
                 (if existing
                     (progn (cmd-remove-breakpoint session existing)
                            (set-message ui "breakpoint cleared at line ~D" line))
                     (progn (cmd-set-breakpoint session fid form-id)
                            (set-message ui "breakpoint set at line ~D" line))))))))))

(defun eval-line (ui session)
  (let ((text (read-line-keys ui "eval: ")))
    (when (plusp (length text))
      (handler-case (push-repl ui "~A => ~A" text (preview (cmd-eval session text)))
        (error (e) (push-repl ui "eval error: ~A" e))))))

(defun return-value (ui session hit)
  (declare (ignore hit))
  (let ((text (read-line-keys ui "return: ")))
    (handler-case (cmd-return session (cmd-eval session (if (plusp (length text)) text "nil")))
      (error (e) (set-message ui "return error: ~A" e) nil))))

;;;; --- inspector pane (spec §19.2) -----------------------------------

(defun inspect-loop (ui session)
  "Open the inspector on a form read in the repl, then run a key loop in
the inspector pane (Enter/d descend, BS/u up, p path, b bind, q close)."
  (let ((text (read-line-keys ui "inspect: ")))
    (when (zerop (length text)) (return-from inspect-loop))
    (handler-case
        (let ((value (cmd-eval session text)))
          (cmd-inspect session value :origin (first (read-runtime-from-string text))))
      (error (e) (set-message ui "inspect error: ~A" e) (return-from inspect-loop)))
    (setf (ncurses-ui-inspector-cursor ui) 0)
    (loop
      (render-inspector ui session)
      (let ((key (tui-read-key (ncurses-ui-screen ui))))
        (cond
          ((eq key :eof) (return))
          ((or (key-char-p key #\q) (eq key :escape)) (return))
          ((eq key :up) (incf-inspector-cursor ui session -1))
          ((eq key :down) (incf-inspector-cursor ui session +1))
          ((or (eq key :enter) (key-char-p key #\d)) (inspector-descend ui session))
          ((or (eq key :backspace) (key-char-p key #\u)) (cmd-inspector-up session))
          ((key-char-p key #\p) (inspector-path ui session))
          ((key-char-p key #\b)
           (push-repl ui "bound to ~A" (cmd-inspector-bind session :workspace))))))))

(defun component-count (session)
  (length (inspect-page-components (session-page (session-inspector session)))))

(defun incf-inspector-cursor (ui session delta)
  (let ((n (component-count session)))
    (when (plusp n)
      (setf (ncurses-ui-inspector-cursor ui)
            (max 0 (min (1- n) (+ (ncurses-ui-inspector-cursor ui) delta)))))))

(defun inspector-descend (ui session)
  (handler-case (progn (cmd-inspector-descend session (ncurses-ui-inspector-cursor ui))
                       (setf (ncurses-ui-inspector-cursor ui) 0))
    (error (e) (set-message ui "~A" e))))

(defun inspector-path (ui session)
  (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
    (push-repl ui "path: ~A~A" (preview expr) (if (eq kind :partial) " …(opaque)" ""))))

(defun render-inspector (ui session)
  "Replace the source window with the inspector page (spec §19.2), keeping the
windowed layout (status lines + separators + minibuffer)."
  (let* ((screen (ncurses-ui-screen ui))
         (inspector (session-inspector session))
         (page (session-page inspector)))
    (tui-clear screen)
    (multiple-value-bind (rows cols) (tui-size screen)
      (let ((window-rows (max 1 (1- rows))))
        (multiple-value-bind (rects vlines)
            (layout-rects (ncurses-ui-layout ui) 0 0 window-rows cols)
          (flet ((rect (id) (cdr (assoc id rects))))
            (render-stack ui session (rect :stack))
            (let ((src (rect :source)))
              (win-put-line screen src 0
                            (format nil "~A → ~A"
                                    (preview (session-origin inspector))
                                    (preview (path-string session))))
              (win-put-line screen src 1
                            (format nil "#<~A> ~A"
                                    (inspect-page-type-name page) (inspect-page-header page)))
              (loop for component in (inspect-page-components page)
                    for i from 0
                    do (win-put-line screen src (+ i 3)
                                     (format nil "~A ~A  ~A"
                                             (if (= i (ncurses-ui-inspector-cursor ui)) ">" " ")
                                             (inspect-component-label component)
                                             (preview (inspect-component-preview component)))
                                     :attr (if (= i (ncurses-ui-inspector-cursor ui)) :bold :normal))))
            (win-put-line screen (rect :interactor) 0
                          "INSPECT: up/down move  Enter/d descend  BS/u up  p path  b bind  q close")
            (render-repl ui (rect :repl))
            ;; status lines (source window is the inspector now) + separators
            (dolist (id +window-ids+)
              (win-status screen (rect id)
                          (if (eq id :source) "inspect" (window-title id))
                          (eq id (ncurses-ui-active-window ui))))
            (dolist (v vlines)
              (destructuring-bind (col top height) v (draw-vline screen col top height)))
            (render-minibuffer ui (1- rows) cols)
            (tui-refresh screen)))))))

(defun path-string (session)
  (multiple-value-bind (expr kind) (cmd-inspector-path-expression session)
    (if (eq kind :partial) (format nil "~A …" expr) expr)))

;;;; --- line input built on read-key ----------------------------------

(defun read-line-keys (ui prompt)
  "Read a line character-by-character via TUI-READ-KEY, echoing into the
interactor message. Returns the string (Enter/EOF terminate; Backspace
deletes)."
  (let ((chars '()))
    (loop
      (set-message ui "~A~A" prompt (coerce (reverse chars) 'string))
      (render-debugger ui (current-session-of ui))
      (let ((key (tui-read-key (ncurses-ui-screen ui))))
        (cond
          ((or (eq key :enter) (eq key :eof))
           (return (coerce (nreverse chars) 'string)))
          ((eq key :backspace) (when chars (pop chars)))
          ((characterp key) (push key chars))
          (t nil))))))

;;; read-line-keys needs the session for redraw; stash it during a stop.
(defvar *current-session* nil)
(defun current-session-of (ui) (declare (ignore ui)) *current-session*)

(defmethod ui-await-command :around ((ui ncurses-ui) session hit)
  (declare (ignore hit))
  (let ((*current-session* session))
    (call-next-method)))

;;;; --- small helpers -------------------------------------------------

(defun preview (value &optional (limit 60))
  (let ((string (handler-case (prin1-to-string value) (error () "#<?>"))))
    (if (> (length string) limit)
        (concatenate 'string (subseq string 0 limit) "…")
        string)))
