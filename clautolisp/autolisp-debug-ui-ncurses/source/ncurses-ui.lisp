(in-package #:clautolisp.ui.ncurses)

;;;; The four-pane ncurses UI (spec §19). It implements the
;;;; clautolisp.debug.ui protocol by rendering panes to a tui-screen and
;;;; driving a key event loop in UI-AWAIT-COMMAND. All output also accrues
;;;; into UI slots (message, repl-lines) so behaviour is assertable
;;;; without scraping the screen grid.

(defclass ncurses-ui ()
  ((screen :initarg :screen :accessor ncurses-ui-screen)
   (selected-frame :initform 0 :accessor ncurses-ui-selected-frame)
   (source-cursor :initform nil :accessor ncurses-ui-source-cursor)  ; line in shown file
   (message :initform "" :accessor ncurses-ui-message)               ; interactor line
   (repl-lines :initform '() :accessor ncurses-ui-repl-lines)        ; newest last
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
  (tui-start (ncurses-ui-screen ui))
  (set-message ui "clautolisp debugger — h for help"))

(defmethod ui-detached ((ui ncurses-ui))
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
            (and (source-position-p position) (source-position-start-line position))))))

;;;; --- rendering -----------------------------------------------------

(defun selected-frame-of (ui session)
  (let ((frames (and (current-snapshot session)
                     (snapshot-call-stack (current-snapshot session)))))
    (and frames (nth (min (ncurses-ui-selected-frame ui) (1- (length frames))) frames))))

(defun render-debugger (ui session)
  "Draw the four panes for the current stopping point."
  (let* ((screen (ncurses-ui-screen ui)))
    (tui-clear screen)
    (multiple-value-bind (rows cols) (tui-size screen)
      (destructuring-bind (stack-pane source-pane interactor-pane repl-pane)
          (four-pane-layout rows cols)
        (draw-box screen stack-pane)
        (draw-box screen source-pane)
        (draw-box screen interactor-pane)
        (draw-box screen repl-pane)
        (render-stack ui session stack-pane)
        (render-source ui session source-pane)
        (render-interactor ui interactor-pane)
        (render-repl ui repl-pane)
        (tui-refresh screen)))))

(defun render-stack (ui session pane)
  (let ((frames (and (current-snapshot session)
                     (snapshot-call-stack (current-snapshot session))))
        (screen (ncurses-ui-screen ui)))
    (loop for frame in frames
          for i from 0
          do (pane-put-line
              screen pane i
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

(defun render-source (ui session pane)
  "Source pane (spec §19.1): show the selected frame's source with
markers — current line :yellow, a breakpointed poll point :red, a plain
poll point :blue."
  (let* ((screen (ncurses-ui-screen ui))
         (frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (position (and frame (stack-frame-source-position frame)))
         (file (and (source-position-p position) (source-position-file position)))
         (current-line (and (source-position-p position) (source-position-start-line position)))
         (lines (and file (ignore-errors (lines-of file))))
         (poll-lines (and metadata (poll-point-lines metadata)))
         (bp-lines (breakpoint-lines session fid))
         (height (pane-interior-height pane)))
    (cond
      ((and lines (plusp (length lines)))
       (let* ((center (or current-line 1))
              (start (max 1 (- center (floor height 2)))))
         (loop for row from 0 below height
               for n = (+ start row)
               while (<= n (length lines))
               do (pane-put-line
                   screen pane row
                   (format nil "~A~3D: ~A"
                           (if (eql n current-line) ">>" "  ") n (aref lines (1- n)))
                   :attr (cond ((eql n current-line) :yellow)
                               ((member n bp-lines) :red)
                               ((member n poll-lines) :blue)
                               (t :normal))))))
      (t
       (pane-put-line screen pane 0
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

(defun render-interactor (ui pane)
  (let ((screen (ncurses-ui-screen ui)))
    (pane-put-line screen pane 0 (format nil "DBG> ~A" (ncurses-ui-message ui)))
    (pane-put-line screen pane 2 "c continue  s step  i in  o out  f finish")
    (pane-put-line screen pane 3 "b bkpt  e eval  x inspect  ^/v frame  q quit  h help")))

(defun render-repl (ui pane)
  (let* ((screen (ncurses-ui-screen ui))
         (height (pane-interior-height pane))
         (lines (last (ncurses-ui-repl-lines ui) height)))
    (loop for line in lines
          for row from 0
          do (pane-put-line screen pane row line))))

;;;; --- the event loop (spec §19.1) -----------------------------------

(defmethod ui-await-command ((ui ncurses-ui) session hit)
  (loop
    (render-debugger ui session)
    (let* ((key (tui-read-key (ncurses-ui-screen ui)))
           (directive (handle-key ui session hit key)))
      (when (eq key :eof) (return :continue))
      (when directive (return directive)))))

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
    ((eq key :up) (move-frame ui session -1) nil)
    ((eq key :down) (move-frame ui session +1) nil)
    ((key-char-p key #\b) (toggle-breakpoint ui session) nil)
    ((key-char-p key #\e) (eval-line ui session) nil)
    ((key-char-p key #\x) (inspect-loop ui session) nil)
    ((key-char-p key #\h) (set-message ui "keys: c s i o f | b e x | up/down frame | a abort r return q quit") nil)
    (t nil)))

(defun move-frame (ui session delta)
  (let* ((frames (snapshot-call-stack (current-snapshot session)))
         (n (length frames))
         (new (max 0 (min (1- n) (+ (ncurses-ui-selected-frame ui) delta)))))
    (setf (ncurses-ui-selected-frame ui) new)
    (cmd-select-frame session new)
    (let ((position (stack-frame-source-position (nth new frames))))
      (when (source-position-p position)
        (setf (ncurses-ui-source-cursor ui) (source-position-start-line position))))))

(defun toggle-breakpoint (ui session)
  "Toggle a breakpoint at the source cursor line of the selected frame's
function (spec §19.1: b at the line)."
  (let* ((frame (selected-frame-of ui session))
         (fid (and frame (stack-frame-fid frame)))
         (metadata (and fid (metadata-for-function-id fid)))
         (line (ncurses-ui-source-cursor ui)))
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
  "Replace the source pane with the inspector page (spec §19.2)."
  (let* ((screen (ncurses-ui-screen ui))
         (inspector (session-inspector session))
         (page (session-page inspector)))
    (tui-clear screen)
    (multiple-value-bind (rows cols) (tui-size screen)
      (destructuring-bind (stack-pane source-pane interactor-pane repl-pane)
          (four-pane-layout rows cols)
        (draw-box screen stack-pane)
        (setf (pane-title source-pane) "inspect")
        (draw-box screen source-pane)
        (draw-box screen interactor-pane)
        (draw-box screen repl-pane)
        (render-stack ui session stack-pane)
        (pane-put-line screen source-pane 0
                       (format nil "~A → ~A"
                               (preview (session-origin inspector))
                               (preview (path-string session))))
        (pane-put-line screen source-pane 1
                       (format nil "#<~A> ~A"
                               (inspect-page-type-name page) (inspect-page-header page)))
        (loop for component in (inspect-page-components page)
              for i from 0
              do (pane-put-line screen source-pane (+ i 3)
                                (format nil "~A ~A  ~A"
                                        (if (= i (ncurses-ui-inspector-cursor ui)) ">" " ")
                                        (inspect-component-label component)
                                        (preview (inspect-component-preview component)))
                                :attr (if (= i (ncurses-ui-inspector-cursor ui)) :bold :normal)))
        (pane-put-line screen interactor-pane 0
                       "INSPECT: up/down move  Enter/d descend  BS/u up  p path  b bind  q close")
        (render-repl ui repl-pane)
        (tui-refresh screen)))))

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
