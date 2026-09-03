(in-package #:clautolisp.ui.ncurses)

;;;; The four-pane ncurses UI (spec §19). It implements the
;;;; clautolisp.debug.ui protocol by rendering panes to a tui-screen and
;;;; driving a key event loop in UI-AWAIT-COMMAND. All output also accrues
;;;; into UI slots (message, repl-lines) so behaviour is assertable
;;;; without scraping the screen grid.

(defclass ncurses-ui ()
  ((screen :initarg :screen :initform nil :accessor ncurses-ui-screen)
   (selected-frame :initform 0 :accessor ncurses-ui-selected-frame) ; stack-frame index
   (source-cursor :initform nil :accessor ncurses-ui-source-cursor)  ; line in shown file
   (message :initform "" :accessor ncurses-ui-message)               ; interactor line
   ;; The reason we stopped (error / caught error / break message), captured at
   ;; UI-THREAD-* and NEVER overwritten by ordinary commands — so the `w' (why)
   ;; command can always redisplay it, and a scroll/resize can't lose it.
   (why-message :initform nil :accessor ncurses-ui-why-message)
   ;; A rolling history of the interactor-line messages (newest last, capped), so
   ;; a message scrolled past is not gone (M-x messages lists it).
   (message-history :initform '() :accessor ncurses-ui-message-history)
   (repl-lines :initform '() :accessor ncurses-ui-repl-lines)        ; newest last
   (navigator :initform nil :accessor ncurses-ui-navigator)          ; source selection
   ;; The UI runs in a tui-core vdt-frame; its four panes are real tui-core
   ;; WINDOW objects (roles :stack :source :interactor :repl) tiled by the
   ;; frame's layout tree. Per-window state (scroll, rect, interactor stack)
   ;; lives on the window structs — no ad-hoc UI hash tables.
   (frame :initform nil :accessor ncurses-ui-frame)                  ; the vdt-frame
   (saved-active :initform nil :accessor ncurses-ui-saved-active)    ; window, for C-w o
   (minibuffer :initform "" :accessor ncurses-ui-minibuffer)         ; last-row I/O
   (inspector-cursor :initform 0 :accessor ncurses-ui-inspector-cursor)
   ;; The repl pane's live Lisp instance (windows-and-interactor-templates.issue):
   ;; a real *AUTOLISP* activation over the shared evaluator, made on first use.
   (repl-activation :initform nil :accessor ncurses-ui-repl-activation)
   ;; Per-window output for make-lisp-window's dedicated REPL windows
   ;; (window -> list of lines, newest last); the repl PANE keeps repl-lines.
   (lisp-lines :initform (make-hash-table :test 'eq) :accessor ncurses-ui-lisp-lines)))

(defun make-ncurses-ui (&rest initargs)
  (apply #'make-instance 'ncurses-ui initargs))

;;;; --- frame / window access -----------------------------------------

(defun ui-windows (ui) (frame-windows (ncurses-ui-frame ui)))
(defun ui-window (ui role) (find role (ui-windows ui) :key #'window-role))
(defun ui-windows-alist (ui)
  (mapcar (lambda (w) (cons (window-role w) w)) (ui-windows ui)))
(defun ui-layout (ui) (frame-layout (ncurses-ui-frame ui)))
(defun (setf ui-layout) (tree ui) (setf (frame-layout (ncurses-ui-frame ui)) tree))
(defun active-window (ui) (frame-selected-window (ncurses-ui-frame ui)))

;;;; --- per-window interactor stacks (ncurses-windows.issue) ----------
;;;; Each window owns an interactor stack (its WINDOW-STACK slot); its base
;;;; interactor handles the window's own keys — source→NAVI, interactor→ALDO,
;;;; stack→FRAMENAV, repl→REPL. The :WINDOW-MANAGER interactor (window commands,
;;;; the C-w/C-x prefix, the minibuffer , and M-x) sits on TOP of the ACTIVE
;;;; window's stack. Keys are dispatched through the active window's stack, top
;;;; to bottom.

(defparameter +window-base-interactor+
  '((:stack . :framenav) (:source . :navi)
    (:interactor . :aldo) (:repl . :repl)))

(defun base-interactor (window)
  (cdr (assoc (window-role window) +window-base-interactor+)))

(defmethod initialize-instance :after ((ui ncurses-ui) &key)
  ;; Build the vdt-frame and its four panes, isolated from the global frame
  ;; list/selection (the UI owns its frame; entering curses happens later, in
  ;; UI-AWAIT-COMMAND, not at construction).
  (let ((*frames* '()) (*selected-frame* nil))
    (let ((frame (make-frame (list (cons :device :vdt) (cons :name "aldo")
                                   (cons :screen (ncurses-ui-screen ui))))))
      (build-debugger-windows frame)
      (setf (ncurses-ui-frame ui) frame)
      ;; each window's base interactor; the window manager rides on the active
      (dolist (w (frame-windows frame))
        (setf (window-stack w) (list (base-interactor w))))
      (push :window-manager (window-stack (frame-selected-window frame))))))

(defun activate-window (ui new)
  "Make window NEW the active window: pop the :WINDOW-MANAGER interactor from the
old active window's stack and push it onto NEW's stack (which becomes the active
interactor stack)."
  (let ((old (active-window ui)))
    (unless (eq old new)
      (setf (window-stack old) (remove :window-manager (window-stack old)))
      (setf (frame-selected-window (ncurses-ui-frame ui)) new)
      (pushnew :window-manager (window-stack new)))))

(register-ui :ncurses (lambda (&rest initargs) (apply #'make-ncurses-ui initargs)))
(register-ui :tui     (lambda (&rest initargs) (apply #'make-ncurses-ui initargs)))

(defun push-repl (ui control &rest args)
  (setf (ncurses-ui-repl-lines ui)
        (append (ncurses-ui-repl-lines ui) (list (apply #'format nil control args)))))

(defparameter +message-history-limit+ 200
  "How many interactor-line messages to keep (M-x messages).")

(defun set-message (ui control &rest args)
  "Set the interactor line to a freshly formatted message and record it in the
rolling history (so a message can be reviewed later even after a command
replaces it). Never touches the WHY-MESSAGE (the stop reason)."
  (let ((text (apply #'format nil control args)))
    (setf (ncurses-ui-message ui) text)
    (let ((history (cons text (ncurses-ui-message-history ui))))
      (setf (ncurses-ui-message-history ui)
            (if (> (length history) +message-history-limit+)
                (subseq history 0 +message-history-limit+)
                history)))
    text))

(defun set-why (ui control &rest args)
  "Record the reason execution stopped (error / caught error / break message).
Sticky: only a new stop overwrites it; ordinary commands never do. Also shown on
the interactor line at the stop, and redisplayable with the `w' (why) command."
  (let ((text (apply #'format nil control args)))
    (setf (ncurses-ui-why-message ui) text)
    (set-message ui "~A" text)))

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
  (reset-stop-state ui session)
  ;; Record WHY we stopped so `w' can redisplay it. A programmatic (clal-break
  ;; "MSG") carries MSG as the hit's error-message — surface it verbatim (the
  ;; user wants to see e.g. "collection.count-element") AND show it on the line,
  ;; since a break is a deliberate one-shot announcement. A plain breakpoint /
  ;; step / watch stop recurs, so we record the reason for `w' but DON'T touch
  ;; the interactor line (leaving it for the commands the user then runs).
  (let* ((reason (hit-stop-reason hit))
         (msg (hit-error-message hit))
         (why (case reason
                (:break (if (and msg (plusp (length msg)))
                            (format nil "break: ~A" msg)
                            "break"))
                (:watch "watchpoint hit")
                (:step "stepped")
                (t (if (and msg (plusp (length msg)))
                       (format nil "stopped: ~A" msg)
                       "stopped at breakpoint")))))
    (if (eq reason :break)
        (set-why ui "~A" why)                 ; announce + remember
        (setf (ncurses-ui-why-message ui) why)))) ; remember only (for `w')

(defmethod ui-thread-unhandled-error ((ui ncurses-ui) session hit)
  (reset-stop-state ui session)
  (set-why ui "ERROR: ~A   (a abort, r return, c run *error*, w why)"
           (hit-error-message hit)))

(defmethod ui-thread-caught-error ((ui ncurses-ui) session hit)
  (reset-stop-state ui session)
  (set-why ui "caught error: ~A   (w why)" (hit-error-message hit)))

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

(defun sanitize-line (string)
  "Replace control characters — C0 (< 32), DEL, and the C1 range (127–159) —
with a visible '?'. curses ADDSTR renders such bytes in caret/meta notation (a
C1 byte shows as \"~@\"…\"~?\"), so a stray control character embedded in data
(a function name, a printed value, a source line) turned the stack pane into
'~@?' garbage. Printable code points, including all UTF-8 text (≥ 160, e.g. the
accented source), pass through unchanged."
  (if (some (lambda (c) (let ((n (char-code c))) (or (< n 32) (<= 127 n 159)))) string)
      (map 'string
           (lambda (c) (let ((n (char-code c))) (if (or (< n 32) (<= 127 n 159)) #\? c)))
           string)
      string))

(defun win-put-line (screen rect row text &key attr)
  "Write TEXT on content ROW (0-based) of RECT, padded/clipped to its width.
Rows are clipped to the window's content area (its last row is the status
line, written by WIN-STATUS). TEXT is sanitized of control characters first
(SANITIZE-LINE) so stray bytes never render as terminal garbage."
  (destructuring-bind (top left height width) rect
    (when (< -1 row (1- height))
      (tui-put screen (+ top row) left
               (pad-string (truncate-string (sanitize-line text) width) width) :attr attr))))

(defun win-status (screen rect title active-p)
  "Draw RECT's status line (its bottom row): the window TITLE across the full
width, INVERTed when active, UNDERLINEd otherwise."
  (destructuring-bind (top left height width) rect
    (tui-put screen (+ top height -1) left
             (pad-string (truncate-string (format nil " ~A " title) width) width)
             :attr (if active-p :active-status :inactive-status))))

(defun draw-vline (screen col top height)
  (loop for r from top below (+ top height) do (tui-put screen r col "|")))

;;;; --- scroll state (window-scrolling.issue) -------------------------
;;;; Each window renders its content into a BUFFER (a list of (STRING . ATTR)
;;;; lines); the window shows a viewport of it at the scroll point (Sl, Sc) —
;;;; Sl the first buffer line, Sc the first column. Scrolling moves (Sl, Sc);
;;;; auto-follow keeps the source selection (and the repl tail) in view.

(defun win-scroll-values (window)
  "The (values SL SC) scroll point of WINDOW (its tui-core WINDOW-SCROLL cons)."
  (let ((cell (window-scroll window)))
    (if cell (values (car cell) (cdr cell)) (values 0 0))))

(defun set-win-scroll (window sl sc)
  (setf (window-scroll window) (cons (max 0 sl) (max 0 sc))))

(defun buffer-max-width (buffer)
  (reduce #'max buffer :key (lambda (c) (length (car c))) :initial-value 0))

(defun draw-window-buffer (screen rect buffer sl sc)
  "Draw BUFFER into RECT's content area from buffer line SL, column SC; lines
past the buffer end stay blank."
  (let ((height (win-content-height rect))
        (vec (coerce buffer 'vector)))
    (dotimes (row height)
      (let* ((idx (+ sl row))
             (cell (when (< -1 idx (length vec)) (aref vec idx)))
             (text (if cell (car cell) ""))
             (attr (if cell (cdr cell) :normal))
             (shown (cond ((zerop sc) text)
                          ((< sc (length text)) (subseq text sc))
                          (t ""))))
        (win-put-line screen rect row shown :attr attr)))))

(defun clamp-scroll (window buffer rect follow-row)
  "Clamp WINDOW's scroll point to the buffer and RECT sizes; when FOLLOW-ROW
falls outside the vertical viewport, re-centre on it (auto-follow). Returns
(values SL SC)."
  (multiple-value-bind (sl sc) (win-scroll-values window)
    (let* ((height (win-content-height rect))
           (max-sl (max 0 (- (length buffer) height)))
           (max-sc (max 0 (- (buffer-max-width buffer) (win-width rect)))))
      (when (and follow-row (or (< follow-row sl) (>= follow-row (+ sl height))))
        (setf sl (- follow-row (floor height 2))))
      (setf sl (min (max 0 sl) max-sl)
            sc (min (max 0 sc) max-sc))
      (set-win-scroll window sl sc)
      (values sl sc))))

(defun window-entry-sedit-p (entry)
  "True when a window interactor-stack ENTRY is a SEDIT activation (a window
running sedit live, windows-and-interactor-templates.issue)."
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry)
           clautolisp.sedit:*sedit*)))

(defun window-sedit-activation (window)
  "The SEDIT activation on WINDOW's interactor stack, or NIL."
  (find-if #'window-entry-sedit-p (window-stack window)))

(defun sedit-window-buffer (activation)
  "Buffer lines (STRING . ATTR) rendering the sedit ACTIVATION's selection."
  (mapcar (lambda (line) (cons line :normal))
          (%split-lines (clautolisp.sedit:sedit-activation-render activation))))

(defun window-primary (window)
  "WINDOW's OWN interactor: the first stack entry that is not the :WINDOW-MANAGER
marker. This is what the window renders and resolves its config through — NOT any
activation deeper in the stack. A pane shares the (aldo lisp) tail at the BOTTOM
of its stack for command ROUTING (handle-key walks the whole stack); that tail
must not hijack the pane's rendering, so dispatch keys off the primary alone."
  (find-if-not (lambda (e) (eq e :window-manager)) (window-stack window)))

(defun window-content (ui session window)
  "Return (values BUFFER FOLLOW-ROW) for WINDOW — a list of (STRING . ATTR)
lines and an optional 0-based row to keep in view. Dispatch on WINDOW's primary
interactor (a dedicated window runs sedit/inspector/…); a debug pane keyed by a
role keyword falls through to the role."
  (let ((primary (window-primary window)))
    (cond
      ((window-entry-sedit-p primary)         (values (sedit-window-buffer primary) nil))
      ((window-entry-selector-p primary)      (values (selector-window-buffer primary) nil))
      ((window-entry-inspector-p primary)     (values (inspector-window-buffer primary) nil))
      ((window-entry-stack-browser-p primary) (values (stack-browser-window-buffer primary) nil))
      ((window-entry-navi-p primary)          (values (navi-window-buffer primary) nil))
      ((window-entry-aldo-view-p primary)     (values (interactor-buffer ui window) nil))
      ((window-entry-lisp-p primary)          (let ((buffer (lisp-window-buffer ui window)))
                                                (values buffer (and buffer (1- (length buffer)))))) ; tail-follow
      (t (ecase (window-role window)
           (:stack      (values (stack-buffer ui session) nil))
           (:source     (source-buffer ui session))
           (:interactor (values (interactor-buffer ui window) nil))
           (:repl       (let ((buffer (repl-buffer ui)))
                          (values buffer (and buffer (1- (length buffer))))))))))) ; tail-follow

(defun render-window (ui session window rect)
  (setf (window-rect window) rect)
  ;; per-config face resolution: the backend resolves face symbols through this
  ;; window's config cascade while its content is drawn (pjb).
  (let ((*active-config* (ensure-config (window-config-name window))))
    (multiple-value-bind (buffer follow-row) (window-content ui session window)
      (setf (window-buffer window) buffer)
      (multiple-value-bind (sl sc) (clamp-scroll window buffer rect follow-row)
        (draw-window-buffer (ncurses-ui-screen ui) rect buffer sl sc)))))

(defun render-debugger (ui session)
  "Draw the four windows: scrollable content buffers + a status line each,
single \"|\" separators, and the reserved minibuffer row."
  (let ((screen (ncurses-ui-screen ui))
        (active (active-window ui)))
    (tui-clear screen)
    (multiple-value-bind (rows cols) (tui-size screen)
      (let ((window-rows (max 1 (1- rows))))     ; last row = minibuffer
        (multiple-value-bind (rects vlines)
            (layout-rects (ui-layout ui) 0 0 window-rows cols)
          (dolist (window (ui-windows ui))
            (let ((rect (cdr (assoc window rects))))
              (when rect
                (render-window ui session window rect)
                (win-status screen rect (window-name window)
                            (eq window active)))))
          (dolist (v vlines)
            (destructuring-bind (col top height) v (draw-vline screen col top height)))
          (render-minibuffer ui (1- rows) cols)
          (tui-refresh screen))))))

(defun render-minibuffer (ui row cols)
  (tui-put (ncurses-ui-screen ui) row 0
           (pad-string (truncate-string (ncurses-ui-minibuffer ui) cols) cols)))

;;;; --- content buffers ----------------------------------------------

(defun stack-buffer (ui session)
  (let ((frames (and (current-snapshot session)
                     (snapshot-call-stack (current-snapshot session)))))
    (loop for frame in frames for i from 0
          collect (cons (format nil "~A ~A  ~A"
                                (if (= i (ncurses-ui-selected-frame ui)) ">" " ")
                                (or (stack-frame-function-name frame) "?")
                                (frame-line-label frame))
                        (if (= i (ncurses-ui-selected-frame ui)) :bold :normal)))))

(defun frame-line-label (frame)
  (let ((position (stack-frame-source-position frame)))
    (if (source-position-p position)
        (format nil "line ~D" (source-position-start-line position))
        "-")))

(defun source-buffer (ui session)
  "Return (values BUFFER SELECTION-ROW): the whole function's source as a buffer
of (line . attr) — current stopping line :yellow, breakpointed poll point :red,
plain poll point :blue, the navigator selection flagged with a =>>= gutter — and
the 0-based row of that selection, to keep in view."
  (let* ((frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (position (and frame (stack-frame-source-position frame)))
         (file (and (source-position-p position) (source-position-file position)))
         (current-line (and (source-position-p position) (source-position-start-line position)))
         (selection-line (or (selection-line-of ui) current-line))
         (lines (and file (ignore-errors (lines-of file))))
         (poll-lines (and metadata (poll-point-lines metadata)))
         (bp-lines (breakpoint-lines session fid)))
    (if (and lines (plusp (length lines)))
        (values
         (loop for n from 1 to (length lines)
               collect (cons (format nil "~A~3D: ~A"
                                     (if (eql n selection-line) ">>" "  ")
                                     n (aref lines (1- n)))
                             (cond ((eql n current-line) :current-line)
                                   ((member n bp-lines) :breakpoint)
                                   ((member n poll-lines) :poll-point)
                                   (t :normal))))
         (and selection-line (1- selection-line)))
        (values (list (cons (format nil "~A:~@[~D~] (source unavailable)"
                                    (or file "?") current-line)
                            :normal))
                nil))))

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

(defun word-wrap (string width)
  "Wrap STRING to a list of lines no wider than WIDTH, breaking at spaces where
possible (a word longer than WIDTH is hard-split). WIDTH < 1 yields the string
unwrapped. Used so a long DBG> message flows over several lines instead of being
truncated to one (the reporter's request)."
  (if (or (< width 1) (<= (length string) width))
      (list string)
      (let ((lines '()) (start 0) (n (length string)))
        (loop while (< start n) do
          (let* ((remaining (- n start))
                 (end (min n (+ start width))))
            (if (>= width remaining)
                (progn (push (subseq string start) lines) (setf start n))
                (let ((break (position #\Space string :from-end t :start start :end end)))
                  (cond ((and break (> break start))
                         (push (subseq string start break) lines)
                         (setf start (1+ break)))     ; drop the break space
                        (t (push (subseq string start end) lines)
                           (setf start end)))))))
        (nreverse lines))))

(defun interactor-buffer (ui &optional window)
  "The interactor pane: the DBG> message (word-wrapped to the pane width so a
long error/why message flows instead of truncating) followed by the key legend."
  (let* ((rect (and window (window-rect window)))
         ;; wrap width = pane content width minus the \"DBG> \" indent; a sane
         ;; floor when the rect is not yet known (first render).
         (width (max 12 (- (if rect (win-width rect) 40) 6)))
         (wrapped (word-wrap (ncurses-ui-message ui) width)))
    (mapcar (lambda (s) (cons s :normal))
            (append
             (cons (format nil "DBG> ~A" (first wrapped))
                   (mapcar (lambda (l) (format nil "     ~A" l)) (rest wrapped)))
             (list ""
                   "c continue  s step  i in  o out  f finish"
                   "d u > < nav  b bkpt  e eval  x inspect  ^/v frame  w why"
                   ", cmd   M-x name   C-w/C-x window ops   C-h m help   q quit")))))

(defun repl-buffer (ui)
  (mapcar (lambda (s) (cons s :normal)) (ncurses-ui-repl-lines ui)))

;;;; --- the event loop (spec §19.1) -----------------------------------

(defmethod ui-await-command ((ui ncurses-ui) session hit)
  ;; Enter curses only for the duration of this stop; leave it (restoring the
  ;; ordinary line-disciplined terminal) on resume, so the REPL between stops
  ;; behaves as a dumb terminal. The layout/active-window live in the UI
  ;; instance and so persist across the enter/exit cycles of one session.
  (tui-start (ncurses-ui-screen ui))
  ;; seat this stop's shared (aldo lisp) tail under the debug panes (spec §C)
  (rebuild-shared-tail ui session hit)
  (unwind-protect
       (loop
         (render-debugger ui session)
         (let* ((key (tui-read-key (ncurses-ui-screen ui)))
                (directive (handle-key ui session hit key)))
           (when (eq key :eof) (return :continue))
           (when directive (return directive))))
    (tui-stop (ncurses-ui-screen ui))))

;;;; --- user key bindings (ncurses-key-bindings.issue, step 5) --------
;;;; A user KEYMAP (a tui-core prefix tree) is consulted BEFORE the built-in
;;;; dispatch, so user bindings shadow the built-ins. A key unbound in the user
;;;; map falls through to the built-in dispatch; a key unbound partway through a
;;;; built-in prefix (C-w/C-x/Esc) falls back to the built-in command for the
;;;; key actually read — so binding one sub-key never disables the rest of the
;;;; prefix. Bindings are session-wide (not per-UI): the clal- AutoLISP surface
;;;; and the aldb UI share this one map.

;;;; Bindings live PER-CONFIG (pjb: per-config resolution). Each debugger window
;;;; maps to a config; the active window's config cascade decides which command a
;;;; key fires — an innermost config's binding shadows its parents', and the
;;;; whole cascade shadows the built-ins. clal-binding writes into the config
;;;; named by *ACTIVE-CONFIG* (default "lisp", so a user init file binds globally,
;;;; inherited by every window); a bound key is stored as its ORIGINAL command
;;;; value (a name/line string or an AutoLISP function designator).

(defparameter +window-config-name+
  '((:stack . "stack") (:source . "navi") (:interactor . "aldo") (:repl . "repl"))
  "Debugger window role -> the config whose cascade its interactor runs under.")

(defun window-config-name (window)
  ;; A window running sedit resolves faces/bindings through the "sedit" config
  ;; (cascade sedit -> lisp), whatever pane it borrows (windows-and-interactor-
  ;; templates.issue). The full dynamic cascade from the live stack (sedit ->
  ;; aldo -> lisp above a stop) lands with the shared-tail activation stacks.
  (let ((primary (window-primary window)))
    (cond ((window-entry-sedit-p primary) "sedit")
          ((window-entry-inspector-p primary) "inspector")
          ((window-entry-stack-browser-p primary) "stack")
          ((window-entry-navi-p primary) "navi")
          ((window-entry-aldo-view-p primary) "aldo")
          (t (or (cdr (assoc (window-role window) +window-config-name+)) "lisp")))))

(defun active-window-config (ui)
  "The config for UI's active window (its cascade resolves faces + bindings)."
  (ensure-config (window-config-name (active-window ui))))

(defvar *user-ui-commands* '()
  "User-registered named commands: NAME -> (lambda (ui session hit arg) -> dir).
Reached from M-x, `,', and as binding targets; shadow *ncurses-commands*.
Global (not per-config): a command NAME resolves the same everywhere.")

(defun binding-config ()
  "The config clal-binding writes into: *ACTIVE-CONFIG* (a config or name) or the
base \"lisp\" config."
  (let ((a *active-config*))
    (cond ((null a) (ensure-config "lisp"))
          ((config-p a) a)
          (t (ensure-config a)))))

(defun reset-user-bindings ()
  "Drop all user key bindings (across every config) and user named commands."
  (setf *user-ui-commands* '())
  (ensure-standard-configs)
  (maphash (lambda (name config) (declare (ignore name))
             (config-unset config :bindings))
           *configs*))

(defun ui-bind (key-sequence command &optional (config (binding-config)))
  "Bind KEY-SEQUENCE (an Emacs-style string) to COMMAND in CONFIG (default the
active/binding config). Returns the canonical key string."
  (config-bind config (%canonical-key key-sequence) command))

(defun ui-unbind (key-sequence &optional (config (binding-config)))
  "Remove KEY-SEQUENCE's binding in CONFIG. Returns T if one was removed."
  (config-unbind config (%canonical-key key-sequence)))

(defun ui-binding-lookup (key-sequence &optional (config (binding-config)))
  "The command bound to KEY-SEQUENCE for CONFIG's cascade, or NIL."
  (effective-binding config (%canonical-key key-sequence)))

(defun ui-map-bindings (function &optional (config (binding-config)))
  "Call FUNCTION with (KEY-STRING COMMAND) for every effective binding of
CONFIG's cascade."
  (keymap-map (effective-keymap config) function))

(defun ui-define-command (name function)
  "Register (or replace) a user named command NAME -> FUNCTION (ui session hit
arg) -> directive, reachable from M-x / `,' and as a binding target."
  (setf *user-ui-commands* (remove name *user-ui-commands* :key #'car :test #'string-equal))
  (push (cons name function) *user-ui-commands*)
  name)

;;;; --- the clal-binding AutoLISP surface (step 5c) -------------------
;;;; The CLAL-BINDING family (autolisp-builtins-core) reaches here through
;;;; clautolisp.autolisp-runtime:*ui-binding-hook*, installed below.

(defun %canonical-key (key-string)
  (unparse-key-sequence (parse-key-sequence key-string)))

(defun %run-autolisp-command (command)
  "Run an AutoLISP COMMAND bound to a key: a function designator is applied with
no arguments; anything else is reported. Runs with debugging suppressed."
  (let ((clautolisp.autolisp-runtime:*debugging* nil))
    (handler-case
        (clautolisp.autolisp-runtime:call-autolisp-function
         (clautolisp.autolisp-runtime:resolve-autolisp-function-designator command))
      (error (e) (declare (ignore e)) nil))))

(defun %binding-command (command)
  "Normalise a clal-binding COMMAND to what is STORED in a config: an AutoLISP
string becomes a CL string (a command name/line); anything else (a function
designator / form) is kept as-is and run via %RUN-AUTOLISP-COMMAND when fired."
  (if (typep command 'clautolisp.autolisp-runtime:autolisp-string)
      (clautolisp.autolisp-runtime:autolisp-string-value command)
      command))

(defun %ui-binding-dispatch (op &rest args)
  "The *ui-binding-hook* implementation for the CLAL-BINDING family."
  (ecase op
    (:bind (destructuring-bind (key-string command) args
             (ui-bind key-string (%binding-command command))))
    (:unbind (destructuring-bind (key-string) args
               (ui-unbind key-string)))
    (:lookup (destructuring-bind (key-string) args
               (let ((command (ui-binding-lookup key-string)))
                 (if (stringp command)
                     (clautolisp.autolisp-runtime:make-autolisp-string command)
                     command))))
    (:map (destructuring-bind (function) args
            (ui-map-bindings
             (lambda (key command)
               (let ((clautolisp.autolisp-runtime:*debugging* nil))
                 (clautolisp.autolisp-runtime:call-autolisp-function
                  (clautolisp.autolisp-runtime:resolve-autolisp-function-designator function)
                  (clautolisp.autolisp-runtime:make-autolisp-string key)
                  (if (stringp command)
                      (clautolisp.autolisp-runtime:make-autolisp-string command)
                      (or command (clautolisp.autolisp-runtime:make-autolisp-string "")))))))
            nil))
    (:define-command (destructuring-bind (name function) args
                       (ui-define-command
                        name
                        (lambda (ui session hit arg)
                          (declare (ignore ui session hit))
                          (let ((clautolisp.autolisp-runtime:*debugging* nil))
                            (clautolisp.autolisp-runtime:call-autolisp-function
                             (clautolisp.autolisp-runtime:resolve-autolisp-function-designator function)
                             (clautolisp.autolisp-runtime:make-autolisp-string (or arg ""))))
                          nil))))))

;; Install the hook so the CLAL-BINDING builtins reach this UI (a no-op in the
;; builtins when the debugger UI is absent).
(setf clautolisp.autolisp-runtime:*ui-binding-hook* #'%ui-binding-dispatch)

;;;; --- the clal frame / window / face surface (step 6) ---------------
;;;; The CLAL-MAKE-FRAME / -MAKE-WINDOW / -DEFINE-FACE family reaches tui-core
;;;; through clautolisp.autolisp-runtime:*ui-object-hook*, installed below.
;;;; Frames and windows cross into AutoLISP as opaque, EQ-stable lisp-object
;;;; handles (#<WINDOW "name" …>, (type …) -> WINDOW); the marshalling of
;;;; AutoLISP values <-> tui-core objects (which needs the runtime + tui-core)
;;;; lives here, keeping the builtins UI-agnostic.

(defun %al-value->cl (value &optional keywordp)
  "Convert one AutoLISP option VALUE to a CL value: a string becomes a CL string
(or, when KEYWORDP, an upcased keyword); the AutoLISP truth symbol T becomes T;
numbers pass through; nil stays nil."
  (cond
    ((null value) nil)
    ((typep value 'clautolisp.autolisp-runtime:autolisp-string)
     (let ((s (clautolisp.autolisp-runtime:autolisp-string-value value)))
       (if keywordp (intern (string-upcase s) :keyword) s)))
    ((typep value 'clautolisp.autolisp-runtime:autolisp-symbol)
     (if (string-equal "T" (clautolisp.autolisp-runtime:autolisp-symbol-name value)) t nil))
    (t value)))

(defparameter +ui-keyword-option-keys+ '(:device :role)
  "Option keys whose values are tui-core keywords (interned from strings).")

(defun %al-options->alist (al-options)
  "Convert an AutoLISP option list — a list of (KEY . VALUE) conses, KEY a
string — into a tui-core option alist (KEYWORD . CL-VALUE)."
  (loop for entry in al-options
        when (consp entry)
          collect (let ((key (intern (string-upcase
                                      (%al-value->cl (car entry))) :keyword)))
                    (cons key (%al-value->cl (cdr entry)
                                             (member key +ui-keyword-option-keys+))))))

(defun %frame-type-name (frame)
  (if (eq (frame-device frame) :vdt) "VDT-FRAME" "TTY-FRAME"))

(defun %wrap-frame (frame)
  (and frame (clautolisp.autolisp-runtime:wrap-lisp-object
              frame (%frame-type-name frame) (lambda () (frame-name frame)))))

(defun %wrap-window (window)
  (and window (clautolisp.autolisp-runtime:wrap-lisp-object
               window "WINDOW" (lambda () (window-name window)))))

(defun %unwrap (object type-name who)
  (clautolisp.autolisp-runtime:unwrap-lisp-object object type-name who))

(defun %unwrap-frame (object who)
  ;; either a TTY-FRAME or a VDT-FRAME handle
  (if (clautolisp.autolisp-runtime:lisp-object-p object "VDT-FRAME")
      (%unwrap object "VDT-FRAME" who)
      (%unwrap object "TTY-FRAME" who)))

(defun %face-name->symbol (name)
  (intern (string-upcase (%al-value->cl name)) :keyword))

(defun %face-parameters->al (plist)
  "Marshal a tui-core face plist (:fg :red :bold t …) to an AutoLISP assoc list
of (\"fg\" . \"RED\") / (\"bold\" . T) pairs."
  (loop for (k v) on plist by #'cddr
        collect (cons (clautolisp.autolisp-runtime:make-autolisp-string
                       (string-downcase (symbol-name k)))
                      (cond ((null v) nil)
                            ((eq v t) (clautolisp.autolisp-runtime:intern-autolisp-symbol "T"))
                            ((symbolp v) (clautolisp.autolisp-runtime:make-autolisp-string
                                          (string-upcase (symbol-name v))))
                            (t v)))))

(defun call-with-temp-window (options thunk)
  "Create a temporary window per OPTIONS in the selected frame, call THUNK with
it, and delete the window afterwards (even on non-local exit). Returns THUNK's
value."
  (let ((window (make-window options)))
    (unwind-protect (funcall thunk window)
      (delete-window window))))

(defun %ui-object-dispatch (op &rest args)
  "The *ui-object-hook* implementation: marshal AutoLISP <-> tui-core objects."
  (ecase op
    (:make-frame (%wrap-frame (make-frame (%al-options->alist (first args)))))
    (:frame-list (mapcar #'%wrap-frame (frame-list)))
    (:selected-frame (%wrap-frame (selected-frame)))
    (:select-frame (%wrap-frame (select-frame (%unwrap-frame (first args) "CLAL-SELECT-FRAME"))))
    (:delete-frame (delete-frame (%unwrap-frame (first args) "CLAL-DELETE-FRAME")) nil)
    (:frame-name (clautolisp.autolisp-runtime:make-autolisp-string
                  (frame-name (%unwrap-frame (first args) "CLAL-FRAME-NAME"))))
    (:make-window (%wrap-window (make-window (%al-options->alist (first args)))))
    (:window-list (mapcar #'%wrap-window
                          (window-list (and (first args)
                                            (%unwrap-frame (first args) "CLAL-WINDOW-LIST")))))
    (:selected-window (%wrap-window (selected-window)))
    (:select-window (%wrap-window (select-window (%unwrap (first args) "WINDOW" "CLAL-SELECT-WINDOW"))))
    (:delete-window (delete-window (%unwrap (first args) "WINDOW" "CLAL-DELETE-WINDOW")) nil)
    (:window-name (clautolisp.autolisp-runtime:make-autolisp-string
                   (window-name (%unwrap (first args) "WINDOW" "CLAL-WINDOW-NAME"))))
    (:define-face (destructuring-bind (name &optional fg bg bold underline invert) args
                    (define-face (%face-name->symbol name)
                        :fg (%al-value->cl fg t) :bg (%al-value->cl bg t)
                        :bold (%al-value->cl bold) :underline (%al-value->cl underline)
                        :invert (%al-value->cl invert))
                    name))
    (:face-parameters (%face-parameters->al (face-parameters (%face-name->symbol (first args)))))
    (:list-faces (mapcar (lambda (s) (clautolisp.autolisp-runtime:make-autolisp-string
                                      (string-downcase (symbol-name s))))
                         (list-faces)))
    (:clear-window
     (%wrap-window (if (first args)
                       (clear-window (%unwrap (first args) "WINDOW" "CLAL-CLEAR-WINDOW"))
                       (clear-window))))
    (:move-cursor-to
     (destructuring-bind (row col &optional window) args
       (%wrap-window
        (if window
            (move-cursor-to row col (%unwrap window "WINDOW" "CLAL-MOVE-CURSOR-TO"))
            (move-cursor-to row col)))))
    (:window-put
     (destructuring-bind (row col string &optional face window) args
       (window-put row col (%al-value->cl string)
                   :face (if face (%face-name->symbol face) :normal)
                   :window (if window
                               (%unwrap window "WINDOW" "CLAL-WINDOW-PUT")
                               (selected-window)))
       nil))
    (:with-temp-window
     (destructuring-bind (options function) args
       (call-with-temp-window
        (%al-options->alist options)
        (lambda (window)
          (clautolisp.autolisp-runtime:call-autolisp-function
           (clautolisp.autolisp-runtime:resolve-autolisp-function-designator function)
           (%wrap-window window))))))))

(setf clautolisp.autolisp-runtime:*ui-object-hook* #'%ui-object-dispatch)

(defun fire-binding (ui session hit command)
  "Run a bound COMMAND: a STRING is a command name/line (routed through the
command table, so window + named + aldo commands are reachable); a CL FUNCTION is
called on (ui session hit); anything else is an AutoLISP function designator /
form, run in the stopped frame. Returns the resume directive or NIL."
  (typecase command
    (string (let* ((s (string-trim " " command))
                   (sp (position #\Space s))
                   (name (if sp (subseq s 0 sp) s))
                   (arg  (if sp (string-left-trim " " (subseq s sp)) "")))
              (run-named-command ui session hit name arg)))
    (function (funcall command ui session hit))
    (t (%run-autolisp-command command) nil)))

(defun user-prefix-loop (ui session hit node prefix)
  "Read further keys inside a user prefix NODE (PREFIX the tokens already
consumed). Fire a leaf; recurse into a deeper prefix; on an unbound key fall
back to the built-in command for the prefix's first token."
  (let ((k (tui-read-key (ncurses-ui-screen ui))))
    (multiple-value-bind (kind value) (keymap-step node k)
      (case kind
        (:leaf   (values t (fire-binding ui session hit value)))
        (:prefix (user-prefix-loop ui session hit value (append prefix (list k))))
        (t       (fallback-builtin ui session hit (first prefix) k))))))

(defun fallback-builtin (ui session hit prefix-token k)
  "A user prefix bottomed out unbound at K: run the built-in command for the key
K under the built-in prefix PREFIX-TOKEN (C-w/C-x window commands, or a Meta
chord), else report an undefined key."
  (cond
    ((and (characterp prefix-token) (member (char-code prefix-token) '(23 24)))
     (run-window-command ui k) (values t nil))
    ((and (consp prefix-token) (eq (car prefix-token) :meta))
     (values t (run-meta-command ui session hit k)))
    (t (set-message ui "undefined key") (values t nil))))

(defun user-keymap-dispatch (ui session hit key)
  "Consult the ACTIVE window's user keymap (its config cascade — pjb's per-config
resolution) before the built-in dispatch. Returns (values HANDLED DIRECTIVE);
HANDLED NIL means the key is unbound by the user — fall through."
  (let ((map (effective-keymap (active-window-config ui))))
    (if (eq key :escape)
        ;; Meta chord: Esc then k -> the (:meta . k) token.
        (let* ((k (tui-read-key (ncurses-ui-screen ui)))
               (token (cons :meta k)))
          (multiple-value-bind (kind value) (keymap-step map token)
            (case kind
              (:leaf   (values t (fire-binding ui session hit value)))
              (:prefix (user-prefix-loop ui session hit value (list token)))
              (t       (values t (run-meta-command ui session hit k))))))
        (multiple-value-bind (kind value) (keymap-step map key)
          (case kind
            (:leaf   (values t (fire-binding ui session hit value)))
            (:prefix (user-prefix-loop ui session hit value (list key)))
            (t       (values nil nil)))))))

(defun handle-key (ui session hit key)
  "Dispatch one key: the user keymap first (shadowing the built-ins), then the
ACTIVE window's interactor stack (the :WINDOW-MANAGER on top, then the window's
own interactor, then — for a debug pane — the SHARED (aldo lisp) tail at the
bottom). The first handler down the real stack that claims the key wins; the
bottom is where lookup ends (no fall-back to a global aldo — that would be wrong
once several documents each carry their own aldo). Returns the resume directive
or NIL."
  (multiple-value-bind (handled directive) (user-keymap-dispatch ui session hit key)
    (if handled
        directive
        (dolist (interactor (window-stack (active-window ui)) nil)
          (multiple-value-bind (h d) (interactor-key interactor ui session hit key)
            (when h (return d)))))))

(defun interactor-key (interactor ui session hit key)
  "Try to handle KEY in INTERACTOR (a keyword pane interactor, or a real
interactor ACTIVATION carried by the window); return (values HANDLED-P
DIRECTIVE)."
  (if (clautolisp.interactor:activation-p interactor)
      (activation-key interactor ui session hit key)
      (ecase interactor
        (:window-manager (window-manager-key ui session hit key))
        (:aldo           (aldo-key ui session hit key))
        (:navi           (navi-key ui session hit key))
        (:framenav       (framenav-key ui session key))
        (:repl           (repl-key ui key)))))

(defun activation-key (activation ui session hit key)
  "Dispatch KEY to a window's real interactor ACTIVATION (per-window interactor
stacks, windows-and-interactor-templates.issue). Sedit activations map keys to
sedit commands; a SELECT activation moves/chooses; other interactors do not yet
handle keystrokes here."
  (declare (ignore session hit))          ; each activation carries its own backend
  (cond ((window-entry-sedit-p activation) (sedit-window-key activation ui key))
        ((window-entry-selector-p activation) (selector-key activation ui key))
        ((window-entry-lisp-p activation) (lisp-window-key activation ui key))
        ((window-entry-inspector-p activation) (inspector-window-key activation ui key))
        ((window-entry-stack-browser-p activation) (stack-browser-window-key activation ui key))
        ((window-entry-navi-p activation) (navi-window-key activation ui key))
        ;; the aldo activation carries its own session/hit (shared tail)
        ((window-entry-aldo-view-p activation) (aldo-view-window-key activation ui key))
        (t (values nil nil))))

(defun window-manager-key (ui session hit key)
  "The umbrella interactor on the active window: the C-w/C-x window-command
prefix, the minibuffer , command line, Esc-x (M-x) and C-h help."
  (cond
    ((and (characterp key) (member (char-code key) '(23 24)))   ; C-w / C-x
     (handle-window-command ui) (values t nil))
    ((key-char-p key #\,) (values t (comma-command ui session hit)))
    ((eq key :escape) (values t (meta-command ui session hit)))
    ((eq key :backspace) (help-prefix ui) (values t nil))       ; C-h m
    (t (values nil nil))))

(defun aldo-key (ui session hit key)
  "The debugger interactor (the `interactor' window): resume/step, eval,
inspect, return, quit."
  (cond
    ((key-char-p key #\c) (values t (cmd-continue session)))
    ((or (key-char-p key #\s) (key-char-p key #\n)) (values t (cmd-step session :over)))
    ((key-char-p key #\i) (values t (cmd-step session :into)))
    ((key-char-p key #\o) (values t (cmd-step session :out)))
    ((key-char-p key #\f) (values t (cmd-step session :finish)))
    ((or (key-char-p key #\a) (key-char-p key #\q)) (values t (cmd-abort session)))
    ((key-char-p key #\r) (values t (return-value ui session hit)))
    ((key-char-p key #\e) (eval-line ui session) (values t nil))
    ((key-char-p key #\x) (inspect-loop ui session) (values t nil))
    ((key-char-p key #\w)
     ;; `w' why: redisplay the reason we entered the debugger (the error or
     ;; clal-break message), which ordinary commands may have scrolled past.
     (set-message ui "~A" (or (ncurses-ui-why-message ui)
                              "why: not stopped on an error or break"))
     (values t nil))
    ((key-char-p key #\h) (set-message ui "aldo: c s i o f | e eval x inspect r return | w why | a abort q quit") (values t nil))
    (t (values nil nil))))

(defun navi-key (ui session hit key)
  "The source navigator interactor (the `source' window): structural motion
d/u/>/< and a breakpoint at the selection."
  (declare (ignore hit))
  (cond
    ((key-char-p key #\d) (nav-move ui #'nav-code-down) (values t nil))
    ((key-char-p key #\u) (nav-move ui #'nav-up) (values t nil))
    ((key-char-p key #\>) (nav-move ui #'nav-code-forward) (values t nil))
    ((key-char-p key #\<) (nav-move ui #'nav-code-backward) (values t nil))
    ((key-char-p key #\b) (toggle-breakpoint ui session) (values t nil))
    (t (values nil nil))))

(defun framenav-key (ui session key)
  "The stack navigator interactor (the `stack' window): up/down select a frame."
  (cond
    ((eq key :up) (move-frame ui session -1) (values t nil))
    ((eq key :down) (move-frame ui session +1) (values t nil))
    (t (values nil nil))))

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
  "Move the active window DELTA steps in reading order (C-w n / C-w p), moving
the :WINDOW-MANAGER interactor onto the new active window's stack."
  (activate-window ui (window-cycle (ui-layout ui) (active-window ui) delta))
  (set-message ui "active window: ~A" (window-name (active-window ui))))

(defun window-swap (ui direction)
  "Swap the active window with its neighbour in DIRECTION (with wrap-around),
exchanging their leaf positions in the layout tree."
  (multiple-value-bind (rows cols) (tui-size (ncurses-ui-screen ui))
    (multiple-value-bind (rects vlines)
        (layout-rects (ui-layout ui) 0 0 (max 1 (1- rows)) cols)
      (declare (ignore vlines))
      (let* ((active (active-window ui))
             (neighbor (window-neighbor rects active direction)))
        (if (and neighbor (not (eq neighbor active)))
            (progn
              (setf (ui-layout ui) (tree-swap-leaves (ui-layout ui) active neighbor))
              (set-message ui "swap ~A ~(~A~)" (window-name active) direction))
            (set-message ui "no window ~(~A~)" direction))))))

(defun window-resize (ui delta)
  "Grow (DELTA>0) or shrink the active window within its enclosing split. A
`small' geometry command: it does NOT touch the interactor message, so the
stop reason and other useful text stay put (the resize is visible on screen)."
  (setf (ui-layout ui) (tree-resize (ui-layout ui) (active-window ui) delta)))

(defun window-balance (ui)
  "Even out the split enclosing the active window (C-w =)."
  (setf (ui-layout ui) (tree-balance (ui-layout ui) (active-window ui)))
  (set-message ui "balanced ~A" (window-name (active-window ui))))

(defun window-reset-square (ui)
  "Revert to the canonical 2x2 layout (C-w 4)."
  (setf (ui-layout ui) (default-layout (ui-windows-alist ui)))
  (set-message ui "layout reset (2x2)"))

(defun window-split (ui split-type)
  "Split the active window (C-w 2 = below/:horizontal, C-w 3 = right/:vertical),
re-homing the next window into the new split so four windows remain."
  (let* ((active (active-window ui))
         (next (window-cycle (ui-layout ui) active +1)))
    (if (eq next active)
        (set-message ui "cannot split")
        (progn
          (setf (ui-layout ui) (tree-split-active (ui-layout ui) active next split-type))
          (set-message ui "split ~A ~A" (window-name active)
                       (if (eq split-type :horizontal) "below" "right"))))))

(defparameter +window-scroll-step+ 3
  "Default lines/columns per scroll (a C-u N count prefix is TODO).")

(defun window-scroll-by (ui dl dc)
  "Scroll the active window by DL lines / DC columns (clamped at next render). A
`small' command: it leaves the interactor message alone (the scroll is visible
on screen), so scrolling never erases the stop reason / a useful message."
  (let ((window (active-window ui)))
    (multiple-value-bind (sl sc) (win-scroll-values window)
      (set-win-scroll window (+ sl dl) (+ sc dc)))))

(defun window-other (ui)
  "C-w o: toggle the active window with a saved one. First use saves the active
window and moves to the next; the second returns to the saved one and clears
the save (window-scrolling.issue)."
  (if (ncurses-ui-saved-active ui)
      (let ((saved (ncurses-ui-saved-active ui)))
        (setf (ncurses-ui-saved-active ui) nil)
        (activate-window ui saved)
        (set-message ui "active window: ~A" (window-name (active-window ui))))
      (progn (setf (ncurses-ui-saved-active ui) (active-window ui))
             (window-select ui +1))))

(defun help-key-bindings (ui)
  "C-h m: list the key bindings into the repl pane (window-scrolling.issue)."
  (dolist (line '("keys: c continue  s step  i into  o out  f finish  a abort  r return  q quit"
                  "  d u > < navigate source form   b breakpoint at selection   e eval   x inspect"
                  "  up/down select stack frame"
                  "  , <line> run a command   M-x <name> run a named command   C-h m this help"
                  "  C-w / C-x prefix: n/p select  o other  u/d swap  2/3 split  4 reset  +/-/= size"
                  "    > < v ^ scroll the active window"))
    (push-repl ui "~A" line)))

(defun help-prefix (ui)
  "C-h prefix (C-h is Backspace in most terminals): C-h m lists key bindings."
  (let ((k (tui-read-key (ncurses-ui-screen ui))))
    (if (key-char-p k #\m)
        (help-key-bindings ui)
        (set-message ui "C-h m : list key bindings"))))

;;;; --- sedit running live in a window (windows-and-interactor-templates) ---
;;;; `M-x sedit' swaps the source pane's navigator for a SEDIT activation (issue
;;;; §C: "pop the navi interactor from the source-window stack and push a new
;;;; sedit"). The pane then renders the sedit selection (WINDOW-CONTENT) and its
;;;; keys drive sedit commands, dispatched through the interactor framework
;;;; against the activation's own one-entry stack. `q' swaps the navigator back.

(defparameter +sedit-window-arg-keys+ '(#\i #\a #\r)
  "sedit editing keys needing a form/text argument (prompted in the minibuffer).")
(defparameter +sedit-window-command-keys+ "dufb<>zcxvmeslh"
  "sedit single-key commands run bare (motions + no-argument edits / eval / save
/ load / help).")

(defun run-sedit-key-command (activation ui line)
  "Run sedit command LINE against ACTIVATION's own one-entry stack — the
framework binds *COMMAND-ACTIVATION* so the sedit command body reaches this
session — echoing any output to the minibuffer. Returns (values T NIL)."
  (let ((out (make-string-output-stream)))
    (let ((*standard-output* out))
      (handler-case
          (clautolisp.interactor:run-command-line
           line :stack (list activation) :output out :error-output out)
        (error (e) (format out "~A" e))))
    (let ((text (string-trim '(#\Space #\Tab #\Newline)
                             (get-output-stream-string out))))
      (when (plusp (length text))
        (set-message ui "~A" (first (%split-lines text))))))
  (values t nil))

(defun sedit-window-key (activation ui key)
  "Map a keystroke to a sedit command on ACTIVATION. Argument edits (i/a/r)
prompt the minibuffer; `q' swaps the navigator back; other single-key commands
run bare; an unhandled key falls through (values NIL NIL)."
  (cond
    ((not (characterp key)) (values nil nil))
    ((char= key #\q) (close-sedit ui) (values t nil))
    ((member key +sedit-window-arg-keys+)
     (let ((arg (read-minibuffer ui (format nil "sedit ~C " key))))
       (when (and arg (plusp (length (string-trim " " arg))))
         (run-sedit-key-command activation ui (format nil "~C ~A" key arg))))
     (values t nil))
    ((find key +sedit-window-command-keys+)
     (run-sedit-key-command activation ui (string key)))
    (t (values nil nil))))

(defun %sedit-target-from-arg (arg ui)
  "The sedit target for `M-x sedit': ARG parsed as a form when non-empty, else a
form read from the minibuffer, else NIL (a stand-alone editor). A parse error is
reported and yields NIL."
  (let ((text (if (and arg (plusp (length (string-trim " " arg))))
                  arg
                  (read-minibuffer ui "sedit form: "))))
    (if (and text (plusp (length (string-trim " " text))))
        (handler-case (clautolisp.sedit:parse-form text)
          (error (e) (set-message ui "sedit: ~A" e) nil))
        nil)))

(defun open-sedit-in-source (ui session hit arg)
  "`M-x sedit': open a SEDIT activation over ARG (or a prompted form) in the
source pane, swapping its navigator out. Selects the source window so its keys
drive sedit. Returns NIL (no resume)."
  (declare (ignore session hit))
  (let* ((target (%sedit-target-from-arg arg ui))
         (activation (clautolisp.interactor:instantiate-interactor-template
                      "sedit"
                      (clautolisp.interactor:make-template-context :target target)))
         (window (ui-window ui :source)))
    (when window
      ;; drop the navigator / any prior sedit, keep :window-manager, push the new
      (setf (window-stack window)
            (append (remove-if (lambda (e) (or (eq e :navi) (window-entry-sedit-p e)))
                               (window-stack window))
                    (list activation)))
      (activate-window ui window)
      (set-message ui "sedit: d u > < move | i a r edit | z c x v | e eval s save | q close")))
  nil)

(defun close-sedit-in-source (ui)
  "`q' in a sedit source pane: drop the sedit activation and restore the source
navigator."
  (let ((window (ui-window ui :source)))
    (when window
      (let ((rest (remove-if #'window-entry-sedit-p (window-stack window))))
        (setf (window-stack window)
              (if (member :navi rest) rest (append rest (list :navi)))))))
  (set-message ui "sedit closed")
  nil)

(defun close-sedit (ui)
  "`q' in a sedit: a DEDICATED :sedit window (from make-sedit-window) is removed
from the frame; the source pane swaps its navigator back instead."
  (let ((window (active-window ui)))
    (if (eq (window-role window) :sedit)
        (progn
          (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
          (let ((now (active-window ui)))
            (when now (pushnew :window-manager (window-stack now))))
          (set-message ui "sedit window closed"))
        (close-sedit-in-source ui))))

(defun make-sedit-window (ui session hit arg)
  "`M-x make-sedit-window': open a SEDIT activation over ARG (or a prompted form)
in a NEW window beside the active one (the spec's create-a-window form; `sedit'
alone swaps the source pane instead). Returns NIL."
  (declare (ignore session hit))
  (let* ((target (%sedit-target-from-arg arg ui))
         (activation (clautolisp.interactor:instantiate-interactor-template
                      "sedit" (clautolisp.interactor:make-template-context :target target)))
         (window (clautolisp.ui.tui:add-window-to-frame
                  (ncurses-ui-frame ui) :name "sedit" :role :sedit
                  :beside (active-window ui) :split :vertical)))
    (setf (window-stack window) (list activation))
    (activate-window ui window)
    (set-message ui "sedit: d u > < move | i a r edit | q close"))
  nil)

;;;; --- the list-selector interactor (windows-and-interactor-templates.issue:
;;;; "a new class of interactor, to show and select an item in a list, eg. show
;;;; the list of windows"). A window carries a SELECT activation exactly like
;;;; sedit: it renders a titled list with the current item marked and is driven
;;;; by up/down (n/p) + Enter (select) / q (cancel).

(clautolisp.interactor:define-interactor *list-selector*
  :name "SELECT"
  :documentation "A list selector: pick one item from a list (windows,
interactor templates, …). Carried in a window and driven by the ncurses key
loop (windows-and-interactor-templates.issue).")

(defstruct selector-state
  "A SELECT activation's state: the TITLE, ITEMS (a list of (LABEL . VALUE)),
the current INDEX, and ON-SELECT — (function (value)) run on Enter."
  (title "Select") (items '()) (index 0) (on-select nil))

(defun make-list-selector-activation (title items on-select)
  "A SELECT activation over ITEMS (a list of (LABEL . VALUE)); ON-SELECT is
called with the chosen VALUE on Enter. The instance is named after TITLE."
  (clautolisp.interactor:make-activation
   *list-selector*
   (make-selector-state :title title :items items :index 0 :on-select on-select)
   title))

(defun window-entry-selector-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry) *list-selector*)))

(defun window-selector-activation (window)
  (find-if #'window-entry-selector-p (window-stack window)))

(defun selector-window-buffer (activation)
  "Buffer lines rendering the selector: the TITLE, then each item, the current
one marked with `> ' in the current-line face."
  (let ((st (clautolisp.interactor:activation-state activation)))
    (cons (cons (format nil "~A:" (selector-state-title st)) :active-status)
          (loop for (label) in (selector-state-items st)
                for i from 0
                collect (cons (format nil "~:[  ~;> ~]~A" (= i (selector-state-index st)) label)
                              (if (= i (selector-state-index st)) :current-line :normal))))))

(defun open-selector-in-source (ui title items on-select)
  "Open a SELECT activation over ITEMS in the source pane (the sedit swap
mechanism), selecting that window so its keys drive the selector."
  (let ((activation (make-list-selector-activation title items on-select))
        (window (ui-window ui :source)))
    (when window
      (setf (window-stack window)
            (append (remove-if (lambda (e) (or (eq e :navi)
                                               (window-entry-sedit-p e)
                                               (window-entry-selector-p e)))
                               (window-stack window))
                    (list activation)))
      (activate-window ui window)
      (set-message ui "select: up/down (n/p) move | RET choose | q cancel")))
  nil)

(defun close-selector-in-source (ui)
  "Drop the selector activation from the source pane and restore the navigator."
  (let ((window (ui-window ui :source)))
    (when window
      (let ((rest (remove-if #'window-entry-selector-p (window-stack window))))
        (setf (window-stack window)
              (if (member :navi rest) rest (append rest (list :navi))))))))

(defun selector-key (activation ui key)
  "Drive a SELECT activation: up/p and down/n move the cursor; Enter runs
ON-SELECT with the current value; q cancels. Returns (values HANDLED DIRECTIVE)."
  (let* ((st (clautolisp.interactor:activation-state activation))
         (n (length (selector-state-items st))))
    (flet ((move (d) (when (plusp n)
                       (setf (selector-state-index st)
                             (mod (+ (selector-state-index st) d) n)))))
      (cond
        ((or (eq key :up) (key-char-p key #\p)) (move -1) (values t nil))
        ((or (eq key :down) (key-char-p key #\n)) (move +1) (values t nil))
        ((eq key :enter)
         (let ((on (selector-state-on-select st))
               (value (cdr (nth (selector-state-index st) (selector-state-items st)))))
           (close-selector-in-source ui)
           (when on (funcall on value)))
         (values t nil))
        ((and (characterp key) (char= key #\q))
         (close-selector-in-source ui) (set-message ui "select cancelled") (values t nil))
        (t (values nil nil))))))

(defun list-windows-command (ui session hit arg)
  "`M-x windows': choose a window from the frame's windows and make it active."
  (declare (ignore session hit arg))
  (let ((items (mapcar (lambda (w)
                         (cons (format nil "~A (~A)" (window-name w)
                                       (string-downcase
                                        (symbol-name (or (window-role w) :window))))
                               w))
                       (remove :minibuffer (ui-windows ui) :key #'window-role))))
    (open-selector-in-source ui "Windows" items
                             (lambda (w) (activate-window ui w))))
  nil)

(defun list-interactors-command (ui session hit arg)
  "`M-x interactors': show the available interactor templates (the picker for
what a window can run, windows-and-interactor-templates.issue)."
  (declare (ignore session hit arg))
  (let ((items (mapcar (lambda (n) (cons n n))
                       (clautolisp.interactor:interactor-template-names))))
    (open-selector-in-source ui "Interactor templates" items
                             (lambda (name) (set-message ui "template: ~A" name))))
  nil)

;;;; --- the repl pane: a live Lisp instance over the shared evaluator ------
;;;; (windows-and-interactor-templates.issue). The :repl window (a no-op stub
;;;; before) drives a real *AUTOLISP* activation — the relocated REPL interactor
;;;; / "lisp" template — over the shared evaluation context: `e' prompts a form
;;;; and evaluates it in the running image, echoing the result into the repl
;;;; buffer. Made on first use (it needs the running context).

(defun ensure-repl-activation (ui)
  "The repl pane's Lisp activation, made on first use from the \"lisp\" template
over the shared evaluation context; NIL if the template is unavailable."
  (or (ncurses-ui-repl-activation ui)
      (setf (ncurses-ui-repl-activation ui)
            (ignore-errors
             (clautolisp.interactor:instantiate-interactor-template
              "lisp" (clautolisp.interactor:make-template-context))))))

(defun %eval-in-lisp-activation (activation line)
  "Evaluate LINE through ACTIVATION's interactor evaluator (*COMMAND-ACTIVATION*
bound to it, so it reaches its own repl-state / the shared evaluator), capturing
output. Returns the echoed prompt line + the non-empty output lines."
  (let ((out (make-string-output-stream)))
    (let ((clautolisp.interactor:*command-activation* activation)
          (*standard-output* out) (*error-output* out))
      (handler-case
          (funcall (clautolisp.interactor:interactor-evaluator
                    (clautolisp.interactor:activation-interactor activation))
                   (list :source line))
        (error (e) (format out "~A" e))))
    (cons (format nil "_$ ~A" line)
          (remove-if (lambda (l) (zerop (length l)))
                     (%split-lines (get-output-stream-string out))))))

(defun repl-window-eval (ui line)
  "Evaluate LINE in the repl pane's Lisp instance (over the shared evaluator),
echoing the prompt+form and the captured output into the repl buffer. Returns
(values T NIL)."
  (let ((activation (ensure-repl-activation ui)))
    (if (null activation)
        (set-message ui "repl: no Lisp evaluator available")
        (dolist (l (%eval-in-lisp-activation activation line))
          (push-repl ui "~A" l))))
  (values t nil))

(defun repl-key (ui key)
  "Drive the repl pane: `e' prompts for a form and evaluates it in the shared
Lisp image. Other keys fall through (values NIL NIL)."
  (cond
    ((and (characterp key) (char= key #\e))
     (let ((line (read-minibuffer ui "eval: ")))
       (when (and line (plusp (length (string-trim " " line))))
         (repl-window-eval ui line)))
     (values t nil))
    (t (values nil nil))))

;;;; --- make-lisp-window: a dedicated REPL window over the shared evaluator --
;;;; A second *AUTOLISP* instance in its own window (the slime-mrepl model),
;;;; with its own scrollback (ncurses-ui-lisp-lines, keyed by window) so it does
;;;; not share the repl pane's buffer. `e' evaluates a prompted form; `q' closes.

(defun %activation-interactor-name= (activation name)
  (string-equal name (clautolisp.interactor:interactor-name
                      (clautolisp.interactor:activation-interactor activation))))

(defun window-entry-lisp-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (%activation-interactor-name= entry "AUTOLISP")))

(defun window-lisp-activation (window)
  (find-if #'window-entry-lisp-p (window-stack window)))

(defun lisp-window-buffer (ui window)
  "Buffer lines (STRING . ATTR) for a make-lisp-window REPL window."
  (mapcar (lambda (s) (cons s :normal))
          (gethash window (ncurses-ui-lisp-lines ui))))

(defun lisp-window-key (activation ui key)
  "Drive a dedicated lisp window: `e' evaluates a prompted form in ACTIVATION and
appends the result to this window's scrollback; `q' closes the window."
  (let ((window (active-window ui)))
    (cond
      ((and (characterp key) (char= key #\e))
       (let ((line (read-minibuffer ui "eval: ")))
         (when (and line (plusp (length (string-trim " " line))))
           (setf (gethash window (ncurses-ui-lisp-lines ui))
                 (append (gethash window (ncurses-ui-lisp-lines ui))
                         (%eval-in-lisp-activation activation line)))))
       (values t nil))
      ((and (characterp key) (char= key #\q))
       (remhash window (ncurses-ui-lisp-lines ui))
       (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
       (let ((now (active-window ui)))
         (when now (pushnew :window-manager (window-stack now))))
       (set-message ui "lisp window closed")
       (values t nil))
      (t (values nil nil)))))

(defun make-lisp-window (ui session hit arg)
  "`M-x make-lisp-window': open a new *AUTOLISP* REPL over the shared evaluator
in its own window beside the active one. Returns NIL."
  (declare (ignore session hit arg))
  (let ((activation (ignore-errors
                     (clautolisp.interactor:instantiate-interactor-template
                      "lisp" (clautolisp.interactor:make-template-context)))))
    (if (null activation)
        (set-message ui "no Lisp evaluator available")
        (let ((window (clautolisp.ui.tui:add-window-to-frame
                       (ncurses-ui-frame ui) :name "lisp" :role :lisp-repl
                       :beside (active-window ui) :split :vertical)))
          (setf (window-stack window) (list activation))
          (setf (gethash window (ncurses-ui-lisp-lines ui))
                (list "AutoLISP REPL  -  e eval  q close"))
          (activate-window ui window)
          (set-message ui "lisp: e eval | q close"))))
  nil)

;;;; --- make-inspector-window: a standalone object inspector in a window ----
;;;; The inspector CORE (clautolisp.inspect) is session-independent: (inspect
;;;; VALUE) builds an inspector-session (misnamed — NOT the debug session) whose
;;;; pages / descend / ascend need no debugger. A window carries one + a cursor,
;;;; so any object is inspectable outside a stop (config cascade inspector->lisp).

(clautolisp.interactor:define-interactor *inspector*
  :name "INSPECTOR"
  :documentation "A standalone object inspector carried in a window: navigate a
value's structure (up/down move, d descend, u up, q close) with no debug session
(windows-and-interactor-templates.issue).")

(defstruct inspector-window-state
  "An INSPECTOR window activation's state: the standalone inspector object and
the current component cursor."
  inspector (cursor 0))

(defun make-inspector-activation (value)
  "An INSPECTOR activation over VALUE (a fresh standalone inspector)."
  (clautolisp.interactor:make-activation
   *inspector* (make-inspector-window-state :inspector (inspect value) :cursor 0)))

(defun window-entry-inspector-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry) *inspector*)))

(defun window-inspector-activation (window)
  (find-if #'window-entry-inspector-p (window-stack window)))

(defun inspector-window-buffer (activation)
  "Buffer lines rendering the inspector page: type/header, current path, and each
component (the cursor's marked)."
  (let* ((st (clautolisp.interactor:activation-state activation))
         (insp (inspector-window-state-inspector st))
         (page (clautolisp.inspect:session-page insp))
         (cursor (inspector-window-state-cursor st))
         (out (list (cons (format nil "~A" (clautolisp.inspect:inspect-page-type-name page))
                          :active-status))))
    (let ((header (clautolisp.inspect:inspect-page-header page)))
      (when header (push (cons (format nil "~A" header) :normal) out)))
    (push (cons (format nil "at: ~A"
                        (or (ignore-errors (clautolisp.inspect:session-path-expression insp))
                            (clautolisp.inspect:session-origin insp)))
                :normal)
          out)
    (loop for c in (clautolisp.inspect:inspect-page-components page)
          for i from 0
          do (push (cons (format nil "~:[  ~;> ~]~A = ~A"
                                 (= i cursor)
                                 (clautolisp.inspect:inspect-component-label c)
                                 (clautolisp.inspect:inspect-component-preview c))
                         (if (= i cursor) :current-line :normal))
                   out))
    (nreverse out)))

(defun close-inspector-window (ui)
  "`q' in an inspector window: remove it from the frame."
  (let ((window (active-window ui)))
    (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
    (let ((now (active-window ui)))
      (when now (pushnew :window-manager (window-stack now))))
    (set-message ui "inspector closed")))

(defun inspector-window-key (activation ui key)
  "Drive an INSPECTOR window: up/down move the cursor; d/Enter descends into the
current component; u ascends; q closes."
  (let* ((st (clautolisp.interactor:activation-state activation))
         (insp (inspector-window-state-inspector st))
         (n (length (clautolisp.inspect:inspect-page-components
                     (clautolisp.inspect:session-page insp)))))
    (flet ((move (d) (when (plusp n)
                       (setf (inspector-window-state-cursor st)
                             (mod (+ (inspector-window-state-cursor st) d) n)))))
      (cond
        ((eq key :up) (move -1) (values t nil))
        ((eq key :down) (move +1) (values t nil))
        ((or (eq key :enter) (and (characterp key) (char= key #\d)))
         (clautolisp.inspect:session-down insp (inspector-window-state-cursor st))
         (setf (inspector-window-state-cursor st) 0)
         (values t nil))
        ((or (eq key :backspace) (and (characterp key) (char= key #\u)))
         (clautolisp.inspect:session-up insp)
         (setf (inspector-window-state-cursor st) 0)
         (values t nil))
        ((and (characterp key) (char= key #\q)) (close-inspector-window ui) (values t nil))
        (t (values nil nil))))))

(defun %inspector-target-from-arg (ui arg)
  "The value make-inspector-window inspects: ARG (or a prompted form) evaluated
in the shared context; NIL (inspect nil) when empty or on error."
  (let ((text (if (and arg (plusp (length (string-trim " " arg)))) arg
                  (read-minibuffer ui "inspect: "))))
    (if (and text (plusp (length (string-trim " " text))))
        (handler-case
            (clautolisp.autolisp-runtime:autolisp-eval
             (clautolisp.autolisp-runtime:autolisp-read-from-string text)
             (clautolisp.autolisp-runtime:current-evaluation-context))
          (error (e) (set-message ui "inspect: ~A" e) nil))
        nil)))

(defun %open-inspector-window (ui value)
  "Open an inspector window over VALUE (a fresh standalone inspector) beside the
active window, and select it. Returns the window."
  (let ((activation (make-inspector-activation value))
        (window (clautolisp.ui.tui:add-window-to-frame
                 (ncurses-ui-frame ui) :name "inspect" :role :inspector
                 :beside (active-window ui) :split :vertical)))
    (setf (window-stack window) (list activation))
    (activate-window ui window)
    (set-message ui "inspect: up/down move | d descend | u up | q close")
    window))

(defun make-inspector-window (ui session hit arg)
  "`M-x make-inspector-window': inspect ARG (or a prompted form's value) in a new
window beside the active one. Returns NIL."
  (declare (ignore session hit))
  (%open-inspector-window ui (%inspector-target-from-arg ui arg))
  nil)

(clautolisp.interactor:define-interactor-template "inspector"
  :display-name "Object inspector"
  :description "Inspect a Lisp/AutoLISP object's structure in a window"
  :interactor *inspector*
  :constructor (lambda (context)
                 (make-inspector-activation
                  (clautolisp.interactor:template-context-target context)))
  :config-name "inspector")

;;;; --- make-stack-browser-window: a standalone backtrace browser ----------
;;;; Over a COPIED snapshot (autolisp-debug: build-snapshot copies frames +
;;;; bindings out of the dynamic context at the stop), so it browses the stack
;;;; and each frame's bindings with no live thread (pjb: "we could still inspect
;;;; the stack and bindings"). No in-frame eval (the frames are copies) — but a
;;;; binding's value opens in an inspector window (`i').

(clautolisp.interactor:define-interactor *stack-browser*
  :name "STACK"
  :documentation "A standalone backtrace browser in a window over a copied
snapshot: n/p frame, up/down binding, i inspect the binding's value, q close
(windows-and-interactor-templates.issue).")

(defstruct stack-browser-state
  "A STACK window activation's state: the copied SNAPSHOT, the selected frame
index, and the selected binding index within that frame."
  snapshot (frame 0) (binding 0))

(defun make-stack-browser-activation (snapshot)
  (clautolisp.interactor:make-activation
   *stack-browser* (make-stack-browser-state :snapshot snapshot)))

(defun window-entry-stack-browser-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry) *stack-browser*)))

(defun window-stack-browser-activation (window)
  (find-if #'window-entry-stack-browser-p (window-stack window)))

(defun %sb-frames (st) (snapshot-call-stack (stack-browser-state-snapshot st)))
(defun %sb-frame (st) (nth (stack-browser-state-frame st) (%sb-frames st)))
(defun %sb-bindings (st)
  (let ((f (%sb-frame st))) (and f (clautolisp.debug:stack-frame-bindings-introduced f))))

(defun %value-preview (value)
  (let ((s (handler-case (let ((*print-length* 6) (*print-level* 3))
                           (princ-to-string value))
             (error () "#<?>"))))
    (if (> (length s) 48) (concatenate 'string (subseq s 0 45) "...") s)))

(defun stack-browser-window-buffer (activation)
  "Lines: the backtrace (selected frame marked) then the selected frame's
bindings (selected binding marked)."
  (let* ((st (clautolisp.interactor:activation-state activation))
         (frames (%sb-frames st))
         (fcur (stack-browser-state-frame st))
         (bcur (stack-browser-state-binding st))
         (out (list (cons (format nil "Backtrace (~D frames):" (length frames))
                          :active-status))))
    (loop for f in frames for i from 0
          do (push (cons (format nil "~:[  ~;> ~]~A  ~A" (= i fcur)
                                 (or (stack-frame-function-name f) "?")
                                 (frame-line-label f))
                         (if (= i fcur) :current-line :normal))
                   out))
    (push (cons "" :normal) out)
    (push (cons (format nil "Frame ~A — bindings:"
                        (and (%sb-frame st) (or (stack-frame-function-name (%sb-frame st)) "?")))
                :active-status)
          out)
    (let ((bindings (%sb-bindings st)))
      (if (null bindings)
          (push (cons "  (no bindings)" :normal) out)
          (loop for b in bindings for i from 0
                do (push (cons (format nil "~:[  ~;> ~]~A = ~A" (= i bcur)
                                       (clautolisp.autolisp-runtime:autolisp-symbol-name
                                        (clautolisp.debug:binding-entry-symbol b))
                                       (%value-preview (clautolisp.debug:binding-entry-value b)))
                               (if (= i bcur) :current-line :normal))
                         out))))
    (nreverse out)))

(defun close-stack-browser-window (ui)
  (let ((window (active-window ui)))
    (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
    (let ((now (active-window ui)))
      (when now (pushnew :window-manager (window-stack now))))
    (set-message ui "stack browser closed")))

(defun stack-browser-window-key (activation ui key)
  "Drive a STACK window: n/p change frame; up/down move the binding cursor; i
inspects the selected binding's value in a new inspector window; q closes."
  (let* ((st (clautolisp.interactor:activation-state activation))
         (nf (length (%sb-frames st))))
    (flet ((frame-move (d)
             (when (plusp nf)
               (setf (stack-browser-state-frame st)
                     (mod (+ (stack-browser-state-frame st) d) nf)
                     (stack-browser-state-binding st) 0)))
           (binding-move (d)
             (let ((nb (length (%sb-bindings st))))
               (when (plusp nb)
                 (setf (stack-browser-state-binding st)
                       (mod (+ (stack-browser-state-binding st) d) nb))))))
      (cond
        ((and (characterp key) (char= key #\n)) (frame-move +1) (values t nil))
        ((and (characterp key) (char= key #\p)) (frame-move -1) (values t nil))
        ((eq key :down) (binding-move +1) (values t nil))
        ((eq key :up) (binding-move -1) (values t nil))
        ((and (characterp key) (char= key #\i))
         (let ((b (nth (stack-browser-state-binding st) (%sb-bindings st))))
           (if b
               (%open-inspector-window ui (clautolisp.debug:binding-entry-value b))
               (set-message ui "no binding to inspect")))
         (values t nil))
        ((and (characterp key) (char= key #\q)) (close-stack-browser-window ui) (values t nil))
        (t (values nil nil))))))

(defun make-stack-browser-window (ui session hit arg)
  "`M-x make-stack-browser-window': browse the current stop's copied stack in a
new window. Needs a stop (a captured snapshot). Returns NIL."
  (declare (ignore arg))
  (let ((snapshot (or (and session (current-snapshot session))
                      (and hit (clautolisp.debug:hit-snapshot hit)))))
    (if (null snapshot)
        (set-message ui "no stack to browse (not stopped)")
        (let ((activation (make-stack-browser-activation snapshot))
              (window (clautolisp.ui.tui:add-window-to-frame
                       (ncurses-ui-frame ui) :name "stack" :role :stack-browser
                       :beside (active-window ui) :split :vertical)))
          (setf (window-stack window) (list activation))
          (activate-window ui window)
          (set-message ui "stack: n/p frame | up/down binding | i inspect | q close"))))
  nil)

(clautolisp.interactor:define-interactor-template "stack-browser"
  :display-name "Stack browser"
  :description "Browse a copied backtrace and its frames' bindings"
  :interactor *stack-browser*
  :constructor (lambda (context)
                 (make-stack-browser-activation
                  (clautolisp.interactor:template-context-target context)))
  :config-name "stack")

;;;; --- make-navi-window: a standalone read-only structure navigator -------
;;;; Reuses the sedit zipper WITHOUT its editing: a sedit session over a form,
;;;; navigated by the exported motion functions (sedit-down/up/left/right, which
;;;; mutate the state's loc in place). No editing, no eval, no session — just
;;;; browse a structure safely (windows-and-interactor-templates.issue).

(clautolisp.interactor:define-interactor *form-navigator*
  :name "NAVI"
  :documentation "A standalone read-only structure navigator in a window: move
over a form's sub-expressions (d down, u up, > < siblings, [ ] first/last, q
close). Reuses the sedit zipper with no editing.")

(defstruct navi-window-state session)   ; a sedit session, navigated read-only

(defun make-navi-activation (form)
  "A NAVI activation over FORM (a sedit node / NIL): a fresh read-only sedit
session."
  (clautolisp.interactor:make-activation
   *form-navigator*
   (make-navi-window-state :session (clautolisp.sedit:sedit-open form))))

(defun window-entry-navi-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry) *form-navigator*)))

(defun window-navi-activation (window)
  (find-if #'window-entry-navi-p (window-stack window)))

(defun %navi-state (activation)
  (clautolisp.sedit:sedit-session-state
   (navi-window-state-session (clautolisp.interactor:activation-state activation))))

(defun navi-window-buffer (activation)
  "Buffer lines rendering the navigator's marked selection (the sedit view)."
  (mapcar (lambda (line) (cons line :normal))
          (%split-lines
           (clautolisp.sedit:render-selection
            (clautolisp.sedit:sedit-state-loc (%navi-state activation))))))

(defun close-navi-window (ui)
  (let ((window (active-window ui)))
    (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
    (let ((now (active-window ui)))
      (when now (pushnew :window-manager (window-stack now))))
    (set-message ui "navigator closed")))

(defun navi-window-key (activation ui key)
  "Read-only structure motions: d down, u up, >/f next sibling, </b previous,
[ first, ] last, q close. Editing keys do nothing here."
  (let ((state (%navi-state activation)))
    (cond
      ((not (characterp key)) (values nil nil))
      ((char= key #\d) (clautolisp.sedit:sedit-down state) (values t nil))
      ((char= key #\u) (clautolisp.sedit:sedit-up state) (values t nil))
      ((or (char= key #\>) (char= key #\f)) (clautolisp.sedit:sedit-right state) (values t nil))
      ((or (char= key #\<) (char= key #\b)) (clautolisp.sedit:sedit-left state) (values t nil))
      ((char= key #\[) (clautolisp.sedit:sedit-first state) (values t nil))
      ((char= key #\]) (clautolisp.sedit:sedit-last state) (values t nil))
      ((char= key #\q) (close-navi-window ui) (values t nil))
      (t (values nil nil)))))

(defun %navi-target-from-arg (ui arg)
  "A sedit node for make-navi-window: ARG (or a prompted form) parsed; NIL when
empty or on parse error (a stand-alone nil session)."
  (let ((text (if (and arg (plusp (length (string-trim " " arg)))) arg
                  (read-minibuffer ui "navigate form: "))))
    (if (and text (plusp (length (string-trim " " text))))
        (handler-case (clautolisp.sedit:parse-form text)
          (error (e) (set-message ui "navi: ~A" e) nil))
        nil)))

(defun make-navi-window (ui session hit arg)
  "`M-x make-navi-window': navigate ARG's (or a prompted form's) structure in a
new read-only window beside the active one. Returns NIL."
  (declare (ignore session hit))
  (let* ((form (%navi-target-from-arg ui arg))
         (activation (make-navi-activation form))
         (window (clautolisp.ui.tui:add-window-to-frame
                  (ncurses-ui-frame ui) :name "navi" :role :navi-view
                  :beside (active-window ui) :split :vertical)))
    (setf (window-stack window) (list activation))
    (activate-window ui window)
    (set-message ui "navi: d down u up | > < siblings | [ ] first/last | q close"))
  nil)

(clautolisp.interactor:define-interactor-template "navi"
  :display-name "Structure navigator"
  :description "Navigate a form's structure read-only"
  :interactor *form-navigator*
  :constructor (lambda (context)
                 (make-navi-activation (clautolisp.interactor:template-context-target context)))
  :config-name "navi")

;;;; --- the shared (aldo lisp) interactor-stack tail + make-aldo-window -----
;;;; The bottom of a debug window's interactor stack — the aldo debugger UI over
;;;; the lisp evaluator UI — is SHARED cons structure across that document's
;;;; windows (spec §C). A command is resolved by walking the window's real stack;
;;;; the bottom is where lookup ends (no magic fall-back to "some aldo"). Each
;;;; aldo activation carries its own backend (the stop SESSION/HIT), so several
;;;; aldo windows over DIFFERENT documents (multi-document mode: each a lisp repl
;;;; thread + an aldo thread) each refer to their own tail — sharing the tail is
;;;; what routes a window's commands to the right debugger + evaluator.

(clautolisp.interactor:define-interactor *aldo-view*
  :name "ALDO-VIEW"
  :documentation "The debugger command interactor in a window (the aldo half of
the shared tail): the aldo keys (c s i o f | e x r | a abort) act on ITS stop
(the session it carries); q closes a stand-alone aldo window.")

(defstruct aldo-view-state
  "An ALDO-VIEW activation's backend: the debugger SESSION and current HIT it
drives. Several aldo windows over one document share this activation (and its
lisp) as their stack bottom; different documents carry different ones."
  session hit)

(defun make-aldo-view-activation (session hit)
  (clautolisp.interactor:make-activation
   *aldo-view* (make-aldo-view-state :session session :hit hit)))

(defun window-entry-aldo-view-p (entry)
  (and (clautolisp.interactor:activation-p entry)
       (eq (clautolisp.interactor:activation-interactor entry) *aldo-view*)))

(defun window-aldo-view-activation (window)
  (find-if #'window-entry-aldo-view-p (window-stack window)))

(defun aldo-view-window-key (activation ui key)
  "q closes a stand-alone aldo window (role :ALDO-VIEW); every other key — and q in
a shared debug PANE that merely carries this aldo in its tail — is the debugger's:
ALDO-KEY on the SESSION/HIT THIS activation carries (its own backend, not a UI
global, so multi-document dispatch stays correct)."
  (let ((st (clautolisp.interactor:activation-state activation)))
    (if (and (characterp key) (char= key #\q)
             (eq (window-role (active-window ui)) :aldo-view))
        (progn
          (let ((window (active-window ui)))
            (clautolisp.ui.tui:remove-window-from-frame (ncurses-ui-frame ui) window)
            (let ((now (active-window ui)))
              (when now (pushnew :window-manager (window-stack now)))))
          (set-message ui "aldo window closed")
          (values t nil))
        (aldo-key ui (aldo-view-state-session st) (aldo-view-state-hit st) key))))

(defun make-aldo-window (ui session hit arg)
  "`M-x make-aldo-window': open a NEW aldo interactor (aldo<2>) beside the active
window, SHARING the current window's stack bottom — its lisp evaluator (hence its
document's backend) — so the new aldo refers to exactly the same tail. Returns
NIL."
  (declare (ignore arg))
  (let* ((bottom (member-if #'window-entry-lisp-p (window-stack (active-window ui))))
         (aldo (make-aldo-view-activation session hit))
         (window (clautolisp.ui.tui:add-window-to-frame
                  (ncurses-ui-frame ui) :name "aldo" :role :aldo-view
                  :beside (active-window ui) :split :vertical)))
    ;; a new aldo over the SHARED lisp bottom (the same cons cell, not a copy)
    (setf (window-stack window) (if bottom (cons aldo bottom) (list aldo)))
    (activate-window ui window)
    (set-message ui "aldo: c s i o f | e x r | a abort | q close"))
  nil)

(defun rebuild-shared-tail (ui session hit)
  "Seat this stop's shared (aldo lisp) tail under the debug panes (spec §C): the
aldo debugger UI over the lisp evaluator UI, as SHARED cons structure. Only the
canonical stack/source/interactor panes are reseated; the repl pane, the
minibuffer and any user-made window (sedit/inspector/…) are left alone. A command
is then resolved by walking the window's real stack — the bottom is where lookup
ends, with no fall-back to a global aldo."
  (let* ((lisp (ensure-repl-activation ui))
         (aldo (make-aldo-view-activation session hit))
         (tail (remove nil (list aldo lisp))))          ; the shared (aldo lisp)
    (dolist (w (ui-windows ui))
      (case (window-role w)
        (:interactor (setf (window-stack w) tail))       ; IS the tail
        (:stack      (setf (window-stack w) (cons :framenav tail)))
        (:source     (setf (window-stack w) (cons :navi tail)))))
    (let ((active (active-window ui)))
      (when active (pushnew :window-manager (window-stack active))))))

(defun handle-window-command (ui)
  "Read the key after a C-w / C-x prefix and run the built-in window command."
  (run-window-command ui (tui-read-key (ncurses-ui-screen ui))))

(defun run-window-command (ui k)
  "Run the built-in window command bound to K after a C-w / C-x prefix
(ncurses-windows.issue + window-scrolling.issue). NOTE: >/</v/^ now SCROLL the
active window; swap right/left are reachable as the named commands
window-swap-right/-left (,/M-x), swap above/below stay on u/d. Split out so an
already-read K (from a user-keymap fall-through) can be dispatched too."
  (progn
    (cond
      ((key-char-p k #\n) (window-select ui +1))
      ((key-char-p k #\p) (window-select ui -1))
      ((key-char-p k #\o) (window-other ui))
      ;; scrolling (window-scrolling.issue)
      ((key-char-p k #\>) (window-scroll-by ui 0 +window-scroll-step+))
      ((key-char-p k #\<) (window-scroll-by ui 0 (- +window-scroll-step+)))
      ((key-char-p k #\v) (window-scroll-by ui +window-scroll-step+ 0))
      ((key-char-p k #\^) (window-scroll-by ui (- +window-scroll-step+) 0))
      ;; swap above/below (right/left via named commands, keys now scroll)
      ((key-char-p k #\u) (window-swap ui :above))
      ((key-char-p k #\d) (window-swap ui :below))
      ((key-char-p k #\2) (window-split ui :horizontal))
      ((key-char-p k #\3) (window-split ui :vertical))
      ((key-char-p k #\4) (window-reset-square ui))
      ((key-char-p k #\+) (window-resize ui +window-resize-step+))
      ((key-char-p k #\-) (window-resize ui (- +window-resize-step+)))
      ((key-char-p k #\=) (window-balance ui))
      (t (set-message ui "C-w/C-x: n/p sel  o other  >/</v/^ scroll  u/d swap  2/3 split  4 reset  +/-/= size")))))

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
   (cons "window-size-balance"   (lambda (ui s h a) (declare (ignore s h a)) (window-balance ui) nil))
   (cons "window-scroll-right" (lambda (ui s h a) (declare (ignore s h a)) (window-scroll-by ui 0 +window-scroll-step+) nil))
   (cons "window-scroll-left"  (lambda (ui s h a) (declare (ignore s h a)) (window-scroll-by ui 0 (- +window-scroll-step+)) nil))
   (cons "window-scroll-up"    (lambda (ui s h a) (declare (ignore s h a)) (window-scroll-by ui +window-scroll-step+ 0) nil))
   (cons "window-scroll-down"  (lambda (ui s h a) (declare (ignore s h a)) (window-scroll-by ui (- +window-scroll-step+) 0) nil))
   (cons "window-other"        (lambda (ui s h a) (declare (ignore s h a)) (window-other ui) nil))
   (cons "help-key-bindings"   (lambda (ui s h a) (declare (ignore s h a)) (help-key-bindings ui) nil))
   ;; sedit live in the source pane (windows-and-interactor-templates.issue):
   ;; `make-sedit-window' is the spec name; `sedit' the short alias.
   (cons "sedit"             #'open-sedit-in-source)
   (cons "make-sedit-window" #'make-sedit-window)
   (cons "make-lisp-window"  #'make-lisp-window)
   (cons "make-inspector-window" #'make-inspector-window)
   (cons "inspect"               #'make-inspector-window)
   (cons "make-stack-browser-window" #'make-stack-browser-window)
   (cons "backtrace"                 #'make-stack-browser-window)
   (cons "make-navi-window" #'make-navi-window)
   (cons "navigate"         #'make-navi-window)
   (cons "make-aldo-window" #'make-aldo-window)
   ;; the list-selector (windows-and-interactor-templates.issue): pick a window
   ;; to activate, or browse the interactor templates available to a window.
   (cons "windows"     #'list-windows-command)
   (cons "interactors" #'list-interactors-command))
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
  (let ((entry (or (assoc name *user-ui-commands* :test #'string-equal)
                   (assoc name *ncurses-commands* :test #'string-equal))))
    (if entry
        (funcall (cdr entry) ui session hit arg)
        (run-aldo-line ui session hit
                       (format nil "~A~@[ ~A~]"
                               name (and (plusp (length arg)) arg))))))

(defun %split-lines (text)
  (loop with start = 0
        for nl = (position #\Newline text :start start)
        collect (string-right-trim '(#\Return #\Space)
                                   (subseq text start (or nl (length text))))
        while nl do (setf start (1+ nl))))

(defun run-aldo-line (ui session hit line)
  "Route LINE through the shared ALDO command vocabulary (ncurses-key-bindings.issue
option b): dispatch it with a throwaway dumb-ui whose output is captured into
the repl pane, and return the command's resume directive. The current stop HIT
is carried through, so frame-relative commands (up/down, frame, locals, …) act
on the real stop rather than degrading."
  (let* ((out (make-string-output-stream))
         (dumb (make-dumb-ui :input (make-string-input-stream "")))
         ;; the generalised output seam: ALDO/NAVI OUT writes here, not to a
         ;; dumb-ui stream — the dumb-ui is only carried for command state.
         (*debugger-output* out))
    (prog1 (ui-run-command dumb session line hit)
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
  (run-meta-command ui session hit (tui-read-key (ncurses-ui-screen ui))))

(defun run-meta-command (ui session hit k)
  "Run the built-in Meta command for the key K read after Esc: M-x runs M-x;
other M-<key> are unbound. Split out so a user-keymap fall-through can reuse it."
  (if (key-char-p k #\x)
      (mx-command ui session hit)
      (progn (set-message ui "M-~A unbound" (if (characterp k) k "key")) nil)))

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
      (let ((window-rows (max 1 (1- rows)))
            (active (active-window ui)))
        (multiple-value-bind (rects vlines)
            (layout-rects (ui-layout ui) 0 0 window-rows cols)
          (flet ((rect (role) (cdr (assoc (ui-window ui role) rects))))
            (render-window ui session (ui-window ui :stack) (rect :stack))
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
                    ;; INSPECT-COMPONENT-PREVIEW is already the value's PRIN1
                    ;; string (inspector-format.issue): show it directly — do
                    ;; NOT re-run PREVIEW, which would PRIN1 it again and quote
                    ;; it as a string. A colon separates the slot from the value.
                    do (win-put-line screen src (+ i 3)
                                     (format nil "~A ~A: ~A"
                                             (if (= i (ncurses-ui-inspector-cursor ui)) ">" " ")
                                             (inspect-component-label component)
                                             (inspect-component-preview component))
                                     :attr (if (= i (ncurses-ui-inspector-cursor ui)) :bold :normal))))
            (win-put-line screen (rect :interactor) 0
                          "INSPECT: up/down move  Enter/d descend  BS/u up  p path  b bind  q close")
            (render-window ui session (ui-window ui :repl) (rect :repl))
            ;; status lines (source window is the inspector now) + separators
            (dolist (window (ui-windows ui))
              (win-status screen (cdr (assoc window rects))
                          (if (eq (window-role window) :source) "inspect"
                              (window-name window))
                          (eq window active)))
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
