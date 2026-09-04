;;; aldb.el --- Emacs UI for the clautolisp debugger (aldb)  -*- lexical-binding: t; -*-

;; Author: Codex
;; License: AGPL-3.0
;; Keywords: lisp, tools, debug

;;; Commentary:

;; aldb is the Emacs front-end for the clautolisp debugger, modelled on
;; SLDB (clautolisp-debugger spec section 20).  It speaks the line-oriented
;; S-expression RPC of clautolisp.ui.emacs (section 20.1): the CL side writes
;; one readable form per line, and aldb writes command forms back.  This file
;; is the client; the CL shim is autolisp-debug-ui-emacs/source/emacs-ui.lisp.
;;
;; Transport is intentionally pluggable.  `aldb-connect' takes a process
;; (a network or inferior-lisp connection) whose stdout carries the debugger's
;; messages and whose stdin accepts command forms; called interactively it
;; opens a TCP connection to the listener printed at the stop.
;;
;; Buffers (section 20.2): *aldb-stack* is the primary interaction buffer — a
;; SLDB-like backtrace whose frames expand to show their locals; *aldb* logs
;; the exchange and shows eval results; *aldb-bindings*, *aldb-inspect*.  At a
;; stop aldb tiles *aldb* over *aldb-stack*; on resume to the toplevel it
;; restores the windows that were up before (aldb-commands.issue).

;;; Code:

(require 'cl-lib)

(defgroup aldb nil
  "Emacs UI for the clautolisp debugger."
  :group 'tools
  :prefix "aldb-")

(defface aldb-poll-point-face
  '((t :underline t))
  "Face for poll-point overlays in source buffers (section 20.2).")

(defface aldb-breakpoint-face
  '((t :background "dark red" :foreground "white"))
  "Face for breakpoint overlays in source buffers.")

(defface aldb-current-face
  '((t :background "dark goldenrod" :foreground "black"))
  "Face for the current stopping form.")

;; aldb renders symbols and data through EMACS faces, never in-band escape
;; sequences: the clautolisp \"symbol/value accent\" maps to these faces, which
;; inherit standard font-lock faces so a user's theme / M-x customize drives
;; them (aldb-faces-not-escape-sequences).
(defface aldb-frame-face '((t :inherit font-lock-function-name-face))
  "Face for a frame's function name in *aldb-stack*.")
(defface aldb-local-name-face '((t :inherit font-lock-variable-name-face))
  "Face for a local/binding name.")
(defface aldb-value-face '((t :inherit font-lock-constant-face))
  "Face for a printed value (the symbol/data accent).")
(defface aldb-section-face '((t :inherit bold))
  "Face for a section header line.")

(defvar aldb--process nil
  "The process whose stdout/stdin carries the aldb RPC.")

(defvar aldb--read-buffer ""
  "Accumulates partial process output until a full form can be read.")

(defvar aldb--last-step :over
  "Last step kind, for the SPC \"repeat step\" key (section 20.3).")

(defvar aldb--snapshot nil
  "Plist of the current stop's snapshot, as decoded from the wire.")

(defvar aldb--selected-frame 0
  "Index of the frame the stack buffer has selected.")

(defvar aldb--details nil
  "List of frame indices currently expanded (their locals shown).")

(defvar aldb--last-error nil
  "The last error announcement line, for `aldb-inspect-error'.")

(defvar aldb--pre-window-config nil
  "Window configuration saved before aldb took the screen, restored on resume.")

(defconst aldb--protocol-major 1
  "Major protocol version aldb implements; mismatch aborts attach (section 27).")

;;; --- transport ------------------------------------------------------

(defun aldb-connect (process)
  "Attach aldb to PROCESS (a live CL connection speaking the section 20.1 RPC).
Called interactively, prompt for HOST and PORT and open a TCP connection to the
clautolisp aldb listener printed at the stop (\"M-x aldb-connect RET host RET
port RET\")."
  (interactive
   (list (open-network-stream
          "aldb" nil
          (read-string "aldb host: " "localhost")
          (read-number "aldb port: "))))
  (setq aldb--process process
        aldb--read-buffer ""
        aldb--pre-window-config (current-window-configuration))
  (set-process-filter process #'aldb--process-filter)
  ;; make both interaction buffers live and in aldb-mode up front
  (with-current-buffer (aldb--buffer "*aldb*") (aldb-mode))
  (with-current-buffer (aldb--buffer "*aldb-stack*") (aldb-mode))
  (aldb--setup-windows)
  (aldb--log "aldb connected; waiting for the debugger…"))

(defun aldb--send (form)
  "Send command FORM to the debugger (one readable line)."
  (unless (and aldb--process (process-live-p aldb--process))
    (user-error "aldb: not connected"))
  (process-send-string aldb--process (concat (prin1-to-string form) "\n")))

(defun aldb--process-filter (_proc chunk)
  "Accumulate CHUNK and dispatch every complete top-level form in it."
  (setq aldb--read-buffer (concat aldb--read-buffer chunk))
  (let ((continue t))
    (while continue
      (let ((parsed (aldb--read-one aldb--read-buffer)))
        (if parsed
            (progn
              (setq aldb--read-buffer (cdr parsed))
              (aldb--dispatch (car parsed)))
          (setq continue nil))))))

(defun aldb--read-one (string)
  "Try to read one form from STRING.  Return (FORM . REST) or nil if partial."
  (condition-case nil
      (let* ((result (read-from-string string))
             (form (car result))
             (end (cdr result)))
        (cons form (substring string end)))
    (error nil)))

;;; --- windows --------------------------------------------------------

(defun aldb--setup-windows ()
  "Tile *aldb* over *aldb-stack* (the primary interaction buffer), leaving the
cursor in *aldb-stack*.  Idempotent — re-applied at every stop."
  (delete-other-windows)
  (switch-to-buffer (aldb--buffer "*aldb-stack*"))
  (split-window-below 12)
  (switch-to-buffer (aldb--buffer "*aldb*"))
  (other-window 1))                     ; back to *aldb-stack*

(defun aldb--restore-windows ()
  "Restore the windows that were up before aldb took the screen."
  (when aldb--pre-window-config
    (set-window-configuration aldb--pre-window-config)))

;;; --- message dispatch (debugger -> aldb) ----------------------------

(defun aldb--dispatch (message)
  "Handle one wire MESSAGE (a list whose car is the tag)."
  (if (not (consp message))
      (aldb--log "ignoring malformed message: %S" message)
    (pcase (car message)
    (:attached
     (let ((version (plist-get (cdr message) :protocol-version)))
       (unless (eql (car version) aldb--protocol-major)
         (aldb--log "WARNING: debugger protocol major %s, aldb expects %s"
                    (car version) aldb--protocol-major))
       (aldb--log "attached (protocol %s.%s)" (car version) (cadr version))))
    (:detached (aldb--log "detached") (aldb--restore-windows))
    (:message (aldb--log "[%s] %s" (nth 1 message) (nth 2 message)))
    (:show-source (aldb--show-source (nth 1 message)))
    (:resumed (aldb--log "running…"))
    (:breakpoint-hit (aldb--on-stop "breakpoint" (nth 1 message)))
    (:step-hit (aldb--on-stop "step" (nth 1 message)))
    (:unhandled-error (aldb--on-error "unhandled error" message))
    (:caught-error (aldb--on-error "caught error" message))
    (:breakpoint-set (aldb--log "breakpoint #%s set at line %s" (nth 1 message) (nth 2 message)))
    (:breakpoint-added (aldb--log "breakpoint #%s added" (nth 1 message)))
    (:breakpoint-removed (aldb--log "breakpoint #%s removed" (nth 1 message)))
    (:breakpoints (aldb--show-breakpoints (nth 1 message)))
    (:eval-result (aldb--log "=> %s" (nth 1 message)))
    (:eval-error (aldb--log "eval error: %s" (nth 1 message)))
    (:inspect-page (aldb--show-inspect (nth 1 message)))
    (:inspect-error (aldb--log "inspect error: %s" (nth 1 message)))
    (:bound (aldb--log "bound to %s" (nth 1 message)))
    (:path (aldb--log "path: %s%s" (nth 1 message) (if (nth 2 message) " (opaque)" "")))
    (:await-command) ; nothing to do; aldb is event-driven
    (_ (aldb--log "unhandled: %S" message)))))

(defun aldb--on-stop (kind snapshot)
  (setq aldb--snapshot snapshot aldb--selected-frame 0 aldb--details nil)
  (aldb--setup-windows)                 ; windows first, then populate them
  (aldb--render-stop kind)
  (aldb--render-bindings)
  (aldb--render-stack))

(defun aldb--on-error (kind message)
  (setq aldb--snapshot (nth 3 message) aldb--selected-frame 0 aldb--details nil
        aldb--last-error (format "%s: %s (errno %s)" kind (nth 1 message) (nth 2 message)))
  (aldb--setup-windows)
  (aldb--log "%s  [a abort, R return, c run *error*]" aldb--last-error)
  (aldb--render-bindings)
  (aldb--render-stack))

;;; --- rendering (section 20.2 buffers) -------------------------------

(defun aldb--buffer (name)
  (get-buffer-create name))

(defun aldb--log (fmt &rest args)
  (with-current-buffer (aldb--buffer "*aldb*")
    (let ((inhibit-read-only t))
      (goto-char (point-max))
      (insert (apply #'format fmt args) "\n"))
    (let ((w (get-buffer-window (current-buffer))))
      (when w (set-window-point w (point-max))))))

(defun aldb--render-stop (kind)
  (let* ((fn (plist-get aldb--snapshot :function))
         (pos (plist-get aldb--snapshot :position)))
    (aldb--log "%s at %s%s" kind fn
               (if pos (format " %s:%s" (nth 1 pos) (nth 2 pos)) ""))))

(defun aldb--render-bindings ()
  (with-current-buffer (aldb--buffer "*aldb-bindings*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "Bindings (RET inspect, M-RET setq):\n"
                          'font-lock-face 'aldb-section-face))
      (dolist (pair (plist-get aldb--snapshot :bindings))
        (insert "  "
                (propertize (nth 0 pair) 'font-lock-face 'aldb-local-name-face)
                " = "
                (propertize (nth 1 pair) 'font-lock-face 'aldb-value-face)
                "\n")))))

(defun aldb--frames () (plist-get aldb--snapshot :frames))

(defun aldb--render-stack ()
  "Render the backtrace in *aldb-stack*, each frame's locals shown indented when
the frame is expanded (`aldb--details').  Frame/local lines carry text
properties so commands read the frame/local at point robustly; point is left on
the selected frame."
  (with-current-buffer (aldb--buffer "*aldb-stack*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "Backtrace  (RET open/inspect · n/p frame · t details · e eval · i inspect · h help)\n"
                          'font-lock-face 'aldb-section-face))
      (dolist (frame (aldb--frames))
        ;; frame = (:frame INDEX NAME POSITION LOCALS)
        (let* ((index (nth 1 frame)) (name (nth 2 frame))
               (pos (nth 3 frame)) (locals (nth 4 frame))
               (open (memq index aldb--details)))
          (insert (propertize
                   (concat (format "%s%s %2d: "
                                   (if (eql index aldb--selected-frame) ">" " ")
                                   (cond (open "-") (locals "+") (t " "))
                                   index)
                           (propertize name 'font-lock-face 'aldb-frame-face)
                           (if pos (format "  line %s" (nth 2 pos)) "")
                           "\n")
                   'aldb-frame index))
          (when open
            (if (null locals)
                (insert (propertize "        (no locals)\n" 'aldb-frame index))
              (dolist (l locals)
                ;; l = (NAME PREVIEW)
                (insert (propertize
                         (concat "        "
                                 (propertize (nth 0 l) 'font-lock-face 'aldb-local-name-face)
                                 " = "
                                 (propertize (nth 1 l) 'font-lock-face 'aldb-value-face)
                                 "\n")
                         'aldb-frame index 'aldb-local (nth 0 l))))))))
      (aldb--goto-frame aldb--selected-frame))))

(defun aldb--goto-frame (index)
  "Move point to the frame-line of frame INDEX in *aldb-stack*."
  (goto-char (point-min))
  (let ((target nil))
    (while (and (not target) (not (eobp)))
      (when (and (eql (get-text-property (point) 'aldb-frame) index)
                 (not (get-text-property (point) 'aldb-local)))
        (setq target (point)))
      (forward-line 1))
    (goto-char (or target (point-min)))
    (let ((w (get-buffer-window (aldb--buffer "*aldb-stack*"))))
      (when w (set-window-point w (point))))))

(defun aldb--frame-at-point ()
  "The frame index on the current *aldb-stack* line, or the selected frame."
  (or (get-text-property (line-beginning-position) 'aldb-frame)
      aldb--selected-frame))

(defun aldb--local-at-point ()
  "The local NAME on the current line, or nil when point is on a frame line."
  (get-text-property (line-beginning-position) 'aldb-local))

(defun aldb--show-breakpoints (breakpoints)
  (aldb--log "breakpoints: %S" breakpoints))

(defun aldb--show-inspect (page)
  (with-current-buffer (aldb--buffer "*aldb-inspect*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "inspect: "
              (propertize (format "%s" (plist-get page :origin)) 'font-lock-face 'aldb-value-face)
              "  ->  "
              (propertize (format "%s" (plist-get page :path)) 'font-lock-face 'aldb-local-name-face)
              "\n")
      (insert (propertize (format "#<%s> %s" (plist-get page :type) (plist-get page :header))
                          'font-lock-face 'aldb-section-face)
              "\n\n")
      (dolist (c (plist-get page :components))
        ;; c = (INDEX LABEL PREVIEW DESCENDABLE); the preview is already the
        ;; sexp representation — shown verbatim (aldb-inspect-values-not-strings)
        (insert (format "  %2d. " (nth 0 c))
                (propertize (format "%-14s" (nth 1 c)) 'font-lock-face 'aldb-local-name-face)
                " "
                (propertize (format "%s" (nth 2 c)) 'font-lock-face 'aldb-value-face)
                "\n")))
    (display-buffer (current-buffer))))

(defun aldb--show-source (pos)
  "Visit POS = (:pos FILE LINE COL) and transiently highlight the line."
  (when (and pos (stringp (nth 1 pos)) (file-readable-p (nth 1 pos)))
    (with-current-buffer (find-file-noselect (nth 1 pos))
      (save-excursion
        (goto-char (point-min))
        (forward-line (1- (nth 2 pos)))
        (let ((ov (make-overlay (line-beginning-position) (line-end-position))))
          (overlay-put ov 'face 'aldb-current-face)
          (run-at-time 1.0 nil (lambda () (when (overlayp ov) (delete-overlay ov))))))
      (display-buffer (current-buffer)))))

;;; --- resume commands (aldb -> debugger) -----------------------------

(defun aldb-continue () "Resume execution (aldo continue)." (interactive) (aldb--send '(:continue)))
(defun aldb-step-over () "Step over the current form." (interactive) (setq aldb--last-step :over) (aldb--send '(:step :over)))
(defun aldb-step-in () "Step into the current form." (interactive) (setq aldb--last-step :into) (aldb--send '(:step :into)))
(defun aldb-step-out () "Step out of the current frame." (interactive) (setq aldb--last-step :out) (aldb--send '(:step :out)))
(defun aldb-finish () "Finish the current frame." (interactive) (setq aldb--last-step :finish) (aldb--send '(:step :finish)))
(defun aldb-step-again () "Repeat the last step." (interactive) (aldb--send (list :step aldb--last-step)))
(defun aldb-abort () "Abort to the toplevel." (interactive) (aldb--send '(:abort)))
(defun aldb-quit () "Quit aldo to the toplevel." (interactive) (aldb--send '(:quit)))

;;; --- frame navigation -----------------------------------------------

(defun aldb--frame-count () (length (aldb--frames)))

(defun aldb--select (index)
  "Select frame INDEX (clamped), tell the debugger, and move point to it."
  (let ((n (aldb--frame-count)))
    (when (> n 0)
      (setq aldb--selected-frame (max 0 (min (1- n) index)))
      (aldb--send (list :select-frame aldb--selected-frame))
      (aldb--render-stack))))

(defun aldb-down () "Select the next (outer) frame." (interactive) (aldb--select (1+ aldb--selected-frame)))
(defun aldb-up   () "Select the previous (inner) frame." (interactive) (aldb--select (1- aldb--selected-frame)))
(defun aldb-beginning-of-backtrace () "Select the innermost frame." (interactive) (aldb--select 0))
(defun aldb-end-of-backtrace () "Select the outermost frame." (interactive) (aldb--select (1- (aldb--frame-count))))

(defun aldb-toggle-details (&optional on)
  "Toggle showing the locals under the frame at point (ON forces them open)."
  (interactive)
  (let ((index (aldb--frame-at-point)))
    (setq aldb--selected-frame index)
    (if (or on (not (memq index aldb--details)))
        (cl-pushnew index aldb--details)
      (setq aldb--details (delq index aldb--details)))
    (aldb--send (list :select-frame index))
    (aldb--render-stack)))

(defun aldb-details-down ()
  "Close the current frame's locals, move to the next frame, open its locals."
  (interactive)
  (setq aldb--details (delq aldb--selected-frame aldb--details))
  (aldb--select (1+ aldb--selected-frame))
  (aldb-toggle-details t))

(defun aldb-details-up ()
  "Close the current frame's locals, move to the previous frame, open its locals."
  (interactive)
  (setq aldb--details (delq aldb--selected-frame aldb--details))
  (aldb--select (1- aldb--selected-frame))
  (aldb-toggle-details t))

;;; --- examine the selected frame -------------------------------------

(defun aldb-show-source ()
  "Show the selected frame's source in another window."
  (interactive)
  (let* ((frame (nth (aldb--frame-at-point) (aldb--frames)))
         (pos (and frame (nth 3 frame))))
    (if pos (aldb--show-source pos) (message "aldb: no source for this frame"))))

(defun aldb-eval-in-frame (string)
  "Evaluate STRING in the frame at point; result to *aldb*."
  (interactive "saldb eval in frame: ")
  (aldb--send (list :eval-in-frame (aldb--frame-at-point) string)))

(defun aldb-pprint-eval-in-frame (string)
  "Evaluate STRING in the frame at point and pretty-print the result."
  (interactive "saldb pprint eval in frame: ")
  (aldb--send (list :pprint-eval-in-frame (aldb--frame-at-point) string)))

(defun aldb-inspect-in-frame (string)
  "Inspect STRING's value in the frame at point, in another window."
  (interactive "saldb inspect in frame: ")
  (aldb--send (list :inspect-in-frame (aldb--frame-at-point) string)))

(defun aldb-interactive-eval (string)
  "Evaluate STRING in the selected frame; value shown in *aldb*/minibuffer."
  (interactive "saldb eval: ")
  (aldb--send (list :eval-in-frame aldb--selected-frame string)))

(defun aldb-inspect-error ()
  "Redisplay the error message that entered the debugger."
  (interactive)
  (if aldb--last-error (message "%s" aldb--last-error) (message "aldb: no error")))

;;; --- misc / breakpoints / inspector ---------------------------------

(defun aldb-return-from-frame (string)
  "Continue-with-return: supply STRING's value for the erroring form (§10.1)."
  (interactive "saldb return value: ")
  (aldb--send (list :return string)))

(defun aldb-toggle-breakpoint (line)
  "Set a breakpoint at LINE of the current function (section 17.3)."
  (interactive (list (read-number "Breakpoint at line: " (line-number-at-pos))))
  (aldb--send (list :set-breakpoint-line line)))

(defun aldb-list-breakpoints () "List breakpoints." (interactive) (aldb--send '(:list-breakpoints)))

(defun aldb-inspect (form)
  "Open the inspector on FORM (AutoLISP source text)."
  (interactive "saldb inspect: ")
  (aldb--send (list :inspect form)))

(defun aldb-inspector-up () "Ascend in the inspector." (interactive) (aldb--send '(:inspector-up)))
(defun aldb-inspector-path () "Show the inspector path." (interactive) (aldb--send '(:inspector-path)))
(defun aldb-inspector-bind () "Bind the inspected value in the workspace." (interactive) (aldb--send '(:inspector-bind :workspace)))

(defun aldb-cycle ()
  "Move between the *aldb-stack* and *aldb* windows."
  (interactive)
  (let* ((names '("*aldb-stack*" "*aldb*"))
         (here (buffer-name))
         (other (car (or (cdr (member here names)) names)))
         (w (get-buffer-window other)))
    (if w (select-window w) (switch-to-buffer other))))

(defun aldb-default-action ()
  "RET: on a frame line toggle its locals; on a local line inspect it."
  (interactive)
  (if (aldb--local-at-point)
      (aldb-inspect-in-frame (aldb--local-at-point))
    (aldb-toggle-details)))

;;; --- restarts / misc (aldb-commands.issue) --------------------------
;;; aldo has no CL-style named restarts; the "restarts" are its resume
;;; commands (continue / abort / quit / return) plus restart-frame.

(defun aldb-restart-frame ()
  "Restart the frame at point: resume by jumping to the start of its function."
  (interactive)
  (aldb--send (list :restart-frame (aldb--frame-at-point))))

(defun aldb-invoke-restart-by-name ()
  "Invoke one of aldo's resume \"restarts\" chosen by name."
  (interactive)
  (let ((name (completing-read "aldo restart: "
                               '("continue" "abort" "quit" "return" "restart-frame")
                               nil t)))
    (pcase name
      ("continue" (aldb-continue))
      ("abort" (aldb-abort))
      ("quit" (aldb-quit))
      ("return" (call-interactively #'aldb-return-from-frame))
      ("restart-frame" (aldb-restart-frame)))))

(defun aldb-insert-frame-call-to-repl ()
  "Start an eval-in-frame pre-filled with the frame's function call, to edit."
  (interactive)
  (let* ((frame (nth (aldb--frame-at-point) (aldb--frames)))
         (name (and frame (nth 2 frame)))
         (initial (if name (format "(%s )" name) "()")))
    (aldb--send (list :eval-in-frame (aldb--frame-at-point)
                      (read-string "aldb eval in frame: " (cons initial (length initial)))))))

(defun aldb-break-with-aldo ()
  "Hand the NEXT stop to the native aldo UI (tui/ncurses) via *clal-debugger-ui*."
  (interactive)
  (let ((ui (completing-read "aldo UI for the next stop: " '("tui" "ncurses") nil t nil nil "tui")))
    (aldb--send (list :eval-in-frame aldb--selected-frame
                      (format "(setq *clal-debugger-ui* '%s)" ui)))
    (message "aldb: the next debugger stop will use the %s UI" ui)))

(defun aldb-break () "Set a breakpoint." (interactive) (call-interactively #'aldb-toggle-breakpoint))

;;; --- AutoLISP reference lookup (external `alref' commands) -----------
(declare-function alref-lookup "alref" ())
(declare-function alref-apropos "alref" ())

;;; --- mode -----------------------------------------------------------

(defvar aldb-mode-map (make-sparse-keymap)
  "Keymap for `aldb-mode', the *aldb-stack* interaction buffer.")

;; Bind at top level (NOT inside the defvar initializer) so that re-loading
;; aldb.el re-applies the bindings to the existing keymap — a `defvar' whose
;; variable is already bound does not re-run its initializer, which would leave
;; a reloaded aldb.el with stale keys (M-x works, but t/RET do not).
(let ((map aldb-mode-map))
  ;; examine the selected frame
  (define-key map (kbd "RET") #'aldb-default-action)
  (define-key map (kbd "<return>") #'aldb-default-action)
  (define-key map (kbd "TAB") #'aldb-cycle)
  (define-key map (kbd "t") #'aldb-toggle-details)
  (define-key map (kbd "v") #'aldb-show-source)
  (define-key map (kbd "e") #'aldb-eval-in-frame)
  (define-key map (kbd "d") #'aldb-pprint-eval-in-frame)
  (define-key map (kbd "i") #'aldb-inspect-in-frame)
  (define-key map (kbd ":") #'aldb-interactive-eval)
  (define-key map (kbd "C") #'aldb-inspect-error)
  ;; navigate frames
  (define-key map (kbd "n") #'aldb-down)
  (define-key map (kbd "p") #'aldb-up)
  (define-key map (kbd "M-n") #'aldb-details-down)
  (define-key map (kbd "M-p") #'aldb-details-up)
  (define-key map (kbd "<") #'aldb-beginning-of-backtrace)
  (define-key map (kbd ">") #'aldb-end-of-backtrace)
  ;; resume / restarts
  (define-key map (kbd "c") #'aldb-continue)
  (define-key map (kbd "q") #'aldb-quit)
  (define-key map (kbd "a") #'aldb-abort)
  (define-key map (kbd "s") #'aldb-step-in)
  (define-key map (kbd "o") #'aldb-step-out)
  (define-key map (kbd "x") #'aldb-step-over)
  (define-key map (kbd "f") #'aldb-finish)
  (define-key map (kbd "SPC") #'aldb-step-again)
  (define-key map (kbd "R") #'aldb-return-from-frame)
  (define-key map (kbd "r") #'aldb-restart-frame)
  (define-key map (kbd "I") #'aldb-invoke-restart-by-name)
  (define-key map (kbd "C-y") #'aldb-insert-frame-call-to-repl)
  (define-key map (kbd "A") #'aldb-break-with-aldo)
  (define-key map (kbd "B") #'aldb-break-with-aldo)
  (define-key map (kbd "b") #'aldb-break)
  ;; breakpoints / help
  (define-key map (kbd "C-c C-b") #'aldb-list-breakpoints)
  (define-key map (kbd "h") #'describe-mode)
  ;; AutoLISP reference lookup (the external `alref' package, if loaded)
  (define-key map (kbd "C-c C-d C-g") #'alref-lookup)
  (define-key map (kbd "C-c C-d g")   #'alref-lookup)
  (define-key map (kbd "C-c C-d a")   #'alref-apropos)
  (define-key map (kbd "C-c C-d C-a") #'alref-apropos))

(define-derived-mode aldb-mode special-mode "aldb"
  "Major mode for the clautolisp debugger interaction buffers (section 20.2).
The primary buffer is *aldb-stack*: a backtrace whose frames expand (t / RET) to
show their locals, with SLDB-like navigation and eval/inspect in a frame."
  (setq buffer-read-only t)
  (use-local-map aldb-mode-map))

(provide 'aldb)


;;; aldb.el ends here
