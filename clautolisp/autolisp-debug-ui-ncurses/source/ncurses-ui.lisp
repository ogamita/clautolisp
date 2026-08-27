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
   (repl-lines :initform '() :accessor ncurses-ui-repl-lines)        ; newest last
   (navigator :initform nil :accessor ncurses-ui-navigator)          ; source selection
   ;; The UI runs in a tui-core vdt-frame; its four panes are real tui-core
   ;; WINDOW objects (roles :stack :source :interactor :repl) tiled by the
   ;; frame's layout tree. Per-window state (scroll, rect, interactor stack)
   ;; lives on the window structs — no ad-hoc UI hash tables.
   (frame :initform nil :accessor ncurses-ui-frame)                  ; the vdt-frame
   (saved-active :initform nil :accessor ncurses-ui-saved-active)    ; window, for C-w o
   (minibuffer :initform "" :accessor ncurses-ui-minibuffer)         ; last-row I/O
   (inspector-cursor :initform 0 :accessor ncurses-ui-inspector-cursor)))

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

(defun window-content (ui session window)
  "Return (values BUFFER FOLLOW-ROW) for WINDOW — a list of (STRING . ATTR)
lines and an optional 0-based row to keep in view. Dispatch on the pane role."
  (ecase (window-role window)
    (:stack      (values (stack-buffer ui session) nil))
    (:source     (source-buffer ui session))
    (:interactor (values (interactor-buffer ui) nil))
    (:repl       (let ((buffer (repl-buffer ui)))
                   (values buffer (and buffer (1- (length buffer)))))))) ; tail-follow

(defun render-window (ui session window rect)
  (setf (window-rect window) rect)
  (multiple-value-bind (buffer follow-row) (window-content ui session window)
    (setf (window-buffer window) buffer)
    (multiple-value-bind (sl sc) (clamp-scroll window buffer rect follow-row)
      (draw-window-buffer (ncurses-ui-screen ui) rect buffer sl sc))))

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

(defun interactor-buffer (ui)
  (mapcar (lambda (s) (cons s :normal))
          (list (format nil "DBG> ~A" (ncurses-ui-message ui))
                ""
                "c continue  s step  i in  o out  f finish"
                "d u > < nav  b bkpt  e eval  x inspect  ^/v frame"
                ", cmd   M-x name   C-w/C-x window ops   C-h m help   q quit")))

(defun repl-buffer (ui)
  (mapcar (lambda (s) (cons s :normal)) (ncurses-ui-repl-lines ui)))

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

;;;; --- user key bindings (ncurses-key-bindings.issue, step 5) --------
;;;; A user KEYMAP (a tui-core prefix tree) is consulted BEFORE the built-in
;;;; dispatch, so user bindings shadow the built-ins. A key unbound in the user
;;;; map falls through to the built-in dispatch; a key unbound partway through a
;;;; built-in prefix (C-w/C-x/Esc) falls back to the built-in command for the
;;;; key actually read — so binding one sub-key never disables the rest of the
;;;; prefix. Bindings are session-wide (not per-UI): the clal- AutoLISP surface
;;;; and the aldb UI share this one map.

(defvar *user-keymap* (make-keymap)
  "The user key bindings (a tui-core keymap). Shadows the built-in dispatch.")
(defvar *user-ui-commands* '()
  "User-registered named commands: NAME -> (lambda (ui session hit arg) -> dir).
Reached from M-x, `,', and as binding targets; shadow *ncurses-commands*.")

(defvar *user-binding-originals* (make-hash-table :test 'equal)
  "Canonical key string -> the command value as first given to clal-binding, so
clal-binding-lookup / clal-map-bindings report the AutoLISP value the user bound
(the keymap stores the wrapped/canonical form).")

(defun reset-user-bindings ()
  "Drop all user key bindings and user named commands (fresh session / tests)."
  (setf *user-keymap* (make-keymap) *user-ui-commands* '())
  (clrhash *user-binding-originals*))

(defun ui-bind (key-sequence command)
  "Bind KEY-SEQUENCE (an Emacs-style string) to COMMAND — a command name/line
STRING (routed through the command table) or a FUNCTION (ui session hit) ->
directive. Returns the canonical key string."
  (keymap-bind *user-keymap* (parse-key-sequence key-sequence) command)
  key-sequence)

(defun ui-unbind (key-sequence)
  "Remove the user binding at KEY-SEQUENCE (revert to the built-in). Returns T
if one was removed."
  (keymap-unbind *user-keymap* (parse-key-sequence key-sequence)))

(defun ui-binding-lookup (key-sequence)
  "The command bound to KEY-SEQUENCE in the user map, or NIL."
  (keymap-lookup *user-keymap* (parse-key-sequence key-sequence)))

(defun ui-map-bindings (function)
  "Call FUNCTION with (KEY-STRING COMMAND) for every user binding."
  (keymap-map *user-keymap* function))

(defun ui-define-command (name function)
  "Register (or replace) a user named command NAME -> FUNCTION (ui session hit
arg) -> directive, reachable from M-x / `,' and as a binding target."
  (setf *user-ui-commands* (remove name *user-ui-commands* :key #'car :test #'string-equal))
  (push (cons name function) *user-ui-commands*)
  name)

;;;; --- the clal-binding AutoLISP surface (step 5c) -------------------
;;;; The CLAL-BINDING family (autolisp-builtins-core) reaches here through
;;;; clautolisp.autolisp-runtime:*ui-binding-hook*, installed below. The builtins
;;;; stay UI-agnostic; the wrapping of an AutoLISP command value into a firing
;;;; closure (which needs the runtime) lives here.

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

(defun %wrap-binding-command (command)
  "Turn a clal-binding COMMAND value into what the keymap stores: a command
name/line STRING passes through; an AutoLISP function designator becomes a
(ui session hit) closure that runs it in the stopped frame."
  (cond
    ((stringp command) command)
    ((typep command 'clautolisp.autolisp-runtime:autolisp-string)
     (clautolisp.autolisp-runtime:autolisp-string-value command))
    (t (lambda (ui session hit)
         (declare (ignore ui session hit))
         (%run-autolisp-command command)
         nil))))

(defun %ui-binding-dispatch (op &rest args)
  "The *ui-binding-hook* implementation for the CLAL-BINDING family."
  (ecase op
    (:bind (destructuring-bind (key-string command) args
             (let ((canonical (%canonical-key key-string)))
               (setf (gethash canonical *user-binding-originals*) command)
               (ui-bind key-string (%wrap-binding-command command))
               canonical)))
    (:unbind (destructuring-bind (key-string) args
               (remhash (%canonical-key key-string) *user-binding-originals*)
               (ui-unbind key-string)))
    (:lookup (destructuring-bind (key-string) args
               (gethash (%canonical-key key-string) *user-binding-originals*)))
    (:map (destructuring-bind (function) args
            (ui-map-bindings
             (lambda (key command)
               (declare (ignore command))
               (let ((clautolisp.autolisp-runtime:*debugging* nil))
                 (clautolisp.autolisp-runtime:call-autolisp-function
                  (clautolisp.autolisp-runtime:resolve-autolisp-function-designator function)
                  (clautolisp.autolisp-runtime:make-autolisp-string key)
                  (or (gethash key *user-binding-originals*)
                      (clautolisp.autolisp-runtime:make-autolisp-string ""))))))
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
                         (list-faces)))))

(setf clautolisp.autolisp-runtime:*ui-object-hook* #'%ui-object-dispatch)

(defun fire-binding (ui session hit command)
  "Run a bound COMMAND: a STRING is a command name/line (routed through the
command table, so window + named + aldo commands are reachable); a FUNCTION is
called on (ui session hit). Returns the resume directive or NIL."
  (typecase command
    (string (let* ((s (string-trim " " command))
                   (sp (position #\Space s))
                   (name (if sp (subseq s 0 sp) s))
                   (arg  (if sp (string-left-trim " " (subseq s sp)) "")))
              (run-named-command ui session hit name arg)))
    (function (funcall command ui session hit))
    (t (set-message ui "unbindable command ~S" command) nil)))

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
  "Consult the user keymap before the built-in dispatch. Returns (values HANDLED
DIRECTIVE); HANDLED NIL means the key is unbound by the user — fall through."
  (if (eq key :escape)
      ;; Meta chord: Esc then k -> the (:meta . k) token.
      (let* ((k (tui-read-key (ncurses-ui-screen ui)))
             (token (cons :meta k)))
        (multiple-value-bind (kind value) (keymap-step *user-keymap* token)
          (case kind
            (:leaf   (values t (fire-binding ui session hit value)))
            (:prefix (user-prefix-loop ui session hit value (list token)))
            (t       (values t (run-meta-command ui session hit k))))))
      (multiple-value-bind (kind value) (keymap-step *user-keymap* key)
        (case kind
          (:leaf   (values t (fire-binding ui session hit value)))
          (:prefix (user-prefix-loop ui session hit value (list key)))
          (t       (values nil nil))))))

(defun handle-key (ui session hit key)
  "Dispatch one key: the user keymap first (shadowing the built-ins), then the
ACTIVE window's interactor stack (the :WINDOW-MANAGER on top, then the window's
own interactor). The first handler that claims the key wins; return its resume
directive or NIL."
  (multiple-value-bind (handled directive) (user-keymap-dispatch ui session hit key)
    (if handled
        directive
        (dolist (interactor (window-stack (active-window ui)) nil)
          (multiple-value-bind (h d) (interactor-key interactor ui session hit key)
            (when h (return d)))))))

(defun interactor-key (interactor ui session hit key)
  "Try to handle KEY in INTERACTOR; return (values HANDLED-P DIRECTIVE)."
  (ecase interactor
    (:window-manager (window-manager-key ui session hit key))
    (:aldo           (aldo-key ui session hit key))
    (:navi           (navi-key ui session hit key))
    (:framenav       (framenav-key ui session key))
    (:repl           (values nil nil))))

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
    ((key-char-p key #\h) (set-message ui "aldo: c s i o f | e eval x inspect r return | a abort q quit") (values t nil))
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
  "Grow (DELTA>0) or shrink the active window within its enclosing split."
  (setf (ui-layout ui) (tree-resize (ui-layout ui) (active-window ui) delta))
  (set-message ui "resize ~A" (window-name (active-window ui))))

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
  "Scroll the active window by DL lines / DC columns (clamped at next render)."
  (let ((window (active-window ui)))
    (multiple-value-bind (sl sc) (win-scroll-values window)
      (set-win-scroll window (+ sl dl) (+ sc dc))
      (set-message ui "scroll ~A" (window-name window)))))

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
   (cons "help-key-bindings"   (lambda (ui s h a) (declare (ignore s h a)) (help-key-bindings ui) nil)))
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
