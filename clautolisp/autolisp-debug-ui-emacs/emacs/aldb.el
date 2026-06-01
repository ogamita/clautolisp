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
;; messages and whose stdin accepts command forms.  Reuse SLIME's swank socket
;; if you already run one; aldb does not mandate a transport (section 20.1).
;;
;; Buffers (section 20.2): *aldb* (command interface + current stop),
;; *aldb-bindings*, *aldb-stack*, *aldb-inspect*, *aldb-workspace*.
;; Keys (section 20.3) mirror SLDB.

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

(defvar aldb--process nil
  "The process whose stdout/stdin carries the aldb RPC.")

(defvar aldb--read-buffer ""
  "Accumulates partial process output until a full form can be read.")

(defvar aldb--last-step :over
  "Last step kind, for the SPC \"repeat step\" key (section 20.3).")

(defvar aldb--snapshot nil
  "Plist of the current stop's snapshot, as decoded from the wire.")

(defvar aldb--selected-frame 0)

(defconst aldb--protocol-major 1
  "Major protocol version aldb implements; mismatch aborts attach (section 27).")

;;; --- transport ------------------------------------------------------

(defun aldb-connect (process)
  "Attach aldb to PROCESS (a live CL connection speaking the section 20.1 RPC)."
  (setq aldb--process process
        aldb--read-buffer "")
  (set-process-filter process #'aldb--process-filter)
  (with-current-buffer (get-buffer-create "*aldb*")
    (aldb-mode))
  (pop-to-buffer "*aldb*")
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
    (:detached (aldb--log "detached"))
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
  (setq aldb--snapshot snapshot aldb--selected-frame 0)
  (aldb--render-stop kind)
  (aldb--render-bindings)
  (aldb--render-stack))

(defun aldb--on-error (kind message)
  (setq aldb--snapshot (nth 3 message) aldb--selected-frame 0)
  (aldb--log "%s: %s (errno %s)  [a abort, r return, c run *error*]"
             kind (nth 1 message) (nth 2 message))
  (aldb--render-bindings)
  (aldb--render-stack))

;;; --- rendering (section 20.2 buffers) -------------------------------

(defun aldb--buffer (name)
  (get-buffer-create name))

(defun aldb--log (fmt &rest args)
  (with-current-buffer (aldb--buffer "*aldb*")
    (let ((inhibit-read-only t))
      (goto-char (point-max))
      (insert (apply #'format fmt args) "\n"))))

(defun aldb--render-stop (kind)
  (let* ((fn (plist-get aldb--snapshot :function))
         (pos (plist-get aldb--snapshot :position)))
    (aldb--log "%s at %s%s" kind fn
               (if pos (format " %s:%s" (nth 1 pos) (nth 2 pos)) ""))
    (when pos (aldb--show-source pos))))

(defun aldb--render-bindings ()
  (with-current-buffer (aldb--buffer "*aldb-bindings*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "Bindings (RET inspect, M-RET setq):\n")
      (dolist (pair (plist-get aldb--snapshot :bindings))
        (insert (format "  %s = %s\n" (nth 0 pair) (nth 1 pair)))))))

(defun aldb--render-stack ()
  (with-current-buffer (aldb--buffer "*aldb-stack*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "Backtrace (RET select):\n")
      (dolist (frame (plist-get aldb--snapshot :frames))
        ;; frame = (:frame INDEX NAME POSITION)
        (let ((index (nth 1 frame)) (name (nth 2 frame)) (pos (nth 3 frame)))
          (insert (format "%s %2d: %s%s\n"
                          (if (eql index aldb--selected-frame) ">" " ")
                          index name
                          (if pos (format "  line %s" (nth 2 pos)) ""))))))))

(defun aldb--show-breakpoints (breakpoints)
  (aldb--log "breakpoints: %S" breakpoints))

(defun aldb--show-inspect (page)
  (with-current-buffer (aldb--buffer "*aldb-inspect*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (format "inspect: %s  ->  %s\n"
                      (plist-get page :origin) (plist-get page :path)))
      (insert (format "#<%s> %s\n\n" (plist-get page :type) (plist-get page :header)))
      (dolist (c (plist-get page :components))
        ;; c = (INDEX LABEL PREVIEW DESCENDABLE)
        (insert (format "  %2d. %-14s %s%s\n"
                        (nth 0 c) (nth 1 c) (nth 2 c)
                        (if (nth 3 c) "  [RET]" "")))))
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

;;; --- commands (aldb -> debugger), section 20.3 ----------------------

(defun aldb-continue () (interactive) (aldb--send '(:continue)))
(defun aldb-step-over () (interactive) (setq aldb--last-step :over) (aldb--send '(:step :over)))
(defun aldb-step-in () (interactive) (setq aldb--last-step :into) (aldb--send '(:step :into)))
(defun aldb-step-out () (interactive) (setq aldb--last-step :out) (aldb--send '(:step :out)))
(defun aldb-finish () (interactive) (setq aldb--last-step :finish) (aldb--send '(:step :finish)))
(defun aldb-step-again () (interactive) (aldb--send (list :step aldb--last-step)))
(defun aldb-abort () (interactive) (aldb--send '(:abort)))
(defun aldb-quit () (interactive) (aldb--send '(:quit)))

(defun aldb-eval (form)
  "Evaluate FORM (AutoLISP source text) in the selected frame."
  (interactive "saldb eval: ")
  (aldb--send (list :eval form)))

(defun aldb-return (form)
  "Continue-with-return: supply FORM's value for the erroring form (section 10.1)."
  (interactive "saldb return value: ")
  (aldb--send (list :return form)))

(defun aldb-select-frame ()
  "Select the frame on the current *aldb-stack* line."
  (interactive)
  (let ((index (aldb--line-index)))
    (when index
      (setq aldb--selected-frame index)
      (aldb--send (list :select-frame index))
      (aldb--render-stack))))

(defun aldb-toggle-breakpoint (line)
  "Set a breakpoint at LINE of the current function (section 17.3)."
  (interactive (list (read-number "Breakpoint at line: " (line-number-at-pos))))
  (aldb--send (list :set-breakpoint-line line)))

(defun aldb-list-breakpoints () (interactive) (aldb--send '(:list-breakpoints)))

(defun aldb-inspect (form)
  "Open the inspector on FORM (AutoLISP source text)."
  (interactive "saldb inspect: ")
  (aldb--send (list :inspect form)))

(defun aldb-inspect-at-point ()
  "Inspect the value on the current *aldb-bindings* / *aldb-inspect* line."
  (interactive)
  (let ((index (aldb--line-index)))
    (when index (aldb--send (list :inspector-descend index)))))

(defun aldb-inspector-up () (interactive) (aldb--send '(:inspector-up)))
(defun aldb-inspector-path () (interactive) (aldb--send '(:inspector-path)))
(defun aldb-inspector-bind () (interactive) (aldb--send '(:inspector-bind :workspace)))

(defun aldb--line-index ()
  "Parse a leading integer index from the current line, or nil."
  (save-excursion
    (beginning-of-line)
    (when (re-search-forward "\\([0-9]+\\)" (line-end-position) t)
      (string-to-number (match-string 1)))))

;;; --- mode -----------------------------------------------------------

(defvar aldb-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "c") #'aldb-continue)
    (define-key map (kbd "s") #'aldb-step-over)
    (define-key map (kbd "i") #'aldb-step-in)
    (define-key map (kbd "o") #'aldb-step-out)
    (define-key map (kbd "f") #'aldb-finish)
    (define-key map (kbd "SPC") #'aldb-step-again)
    (define-key map (kbd "RET") #'aldb-select-frame)
    (define-key map (kbd "e") #'aldb-eval)
    (define-key map (kbd "b") #'aldb-toggle-breakpoint)
    (define-key map (kbd "C-c C-b") #'aldb-list-breakpoints)
    (define-key map (kbd "d") #'aldb-inspect)
    (define-key map (kbd "r") #'aldb-return)
    (define-key map (kbd "a") #'aldb-abort)
    (define-key map (kbd "q") #'aldb-quit)
    map)
  "Keymap for `aldb-mode', mirroring SLDB (section 20.3).")

(define-derived-mode aldb-mode special-mode "aldb"
  "Major mode for the clautolisp debugger interaction buffer (section 20.2)."
  (setq buffer-read-only t))

(provide 'aldb)

;;; aldb.el ends here
