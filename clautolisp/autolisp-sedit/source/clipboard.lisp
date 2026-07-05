;;;; clautolisp/autolisp-sedit/source/clipboard.lisp
;;;;
;;;; The clipboard (sedit spec §5.4 + clipboard-interface.org, normative). Two
;;;; clipboards kept in sync by cut/copy/paste: the INTERNAL one (a live node —
;;;; the source of truth for a sedit->sedit round trip) and the SYSTEM one (a
;;;; textual rendering other applications see). A provider is a plain struct of
;;;; closures; providers auto-select in preference order and degrade to :NULL, so
;;;; sedit never depends on a GUI toolkit and the feature only ever ADDS reach.
;;;; Subprocess providers use a fixed argv (no shell), UTF-8, via uiop:run-program.

(in-package #:clautolisp.sedit)

;;; --- the provider protocol ------------------------------------------------

(defstruct (clipboard-provider
            (:constructor make-clipboard-provider (name &key available-p put-text get-text)))
  name          ; a keyword, e.g. :X11, :MACOS, :OSC52, :NULL
  available-p   ; (lambda () -> boolean)          can we use it now?
  put-text      ; (lambda (string) -> nil)        set the system clipboard
  get-text)     ; (lambda () -> (or string null)) read it (NIL if none/write-only)

;;; --- configuration (clipboard-interface.org §Configuration summary) --------

(defvar *system-clipboard-enabled* t
  "When NIL, sedit uses only the in-process clipboard.")
(defvar *clipboard-provider* nil
  "The active provider: NIL auto-selects; a keyword or a clipboard-provider forces one.")
(defvar *clipboard-x11-also-primary* nil
  "When true, the :X11 provider also sets PRIMARY on copy.")
(defvar *clipboard-osc52-enabled* t
  "Allow the :OSC52 provider.")

(defvar *clipboard* nil
  "The internal clipboard: the last node copied (spec's *CLIPBOARD*).")
(defvar *clal-clipboard* nil
  "The AutoLISP-facing clipboard object (spec §5.4): (:SEXP sexp text) / (:COMMENT text).")

;;; --- subprocess plumbing (fixed argv, UTF-8, no shell) --------------------

(defun %run-in (argv string)
  "Feed STRING to ARGV's stdin. A non-zero exit signals (a transport error)."
  (with-input-from-string (in string)
    (uiop:run-program argv :input in :external-format :utf-8))
  nil)

(defun %run-out (argv)
  "Run ARGV and return its stdout, or NIL when empty. A non-zero exit signals."
  (multiple-value-bind (out err code)
      (uiop:run-program argv :output :string :ignore-error-status t :external-format :utf-8)
    (declare (ignore err))
    (unless (and (integerp code) (zerop code))
      (error "clipboard: ~A exited with status ~A" (first argv) code))
    (and (stringp out) (plusp (length out)) out)))

(defun %program-exists-p (name)
  "True when NAME is found on PATH (Unix tool detection)."
  (let ((path (uiop:getenv "PATH")))
    (and path
         (some (lambda (dir)
                 (and (plusp (length dir))
                      (probe-file (merge-pathnames name (uiop:ensure-directory-pathname dir)))))
               (uiop:split-string path :separator '(#\:))))))

(defun %env-set-p (name)
  (let ((v (uiop:getenv name))) (and v (plusp (length v)))))

;;; --- concrete providers (clipboard-interface.org §Backends) ---------------

(defun make-null-provider ()
  (make-clipboard-provider :null
    :available-p (constantly t)
    :put-text (lambda (s) (declare (ignore s)) nil)
    :get-text (lambda () nil)))

(defun make-x11-provider ()
  (make-clipboard-provider :x11
    :available-p (lambda () (and (%env-set-p "DISPLAY")
                                 (or (%program-exists-p "xclip") (%program-exists-p "xsel"))))
    :put-text (lambda (s)
                (if (%program-exists-p "xclip")
                    (progn (%run-in '("xclip" "-selection" "clipboard" "-i") s)
                           (when *clipboard-x11-also-primary*
                             (%run-in '("xclip" "-selection" "primary" "-i") s)))
                    (%run-in '("xsel" "-b" "-i") s)))
    :get-text (lambda () (if (%program-exists-p "xclip")
                             (%run-out '("xclip" "-selection" "clipboard" "-o"))
                             (%run-out '("xsel" "-b" "-o"))))))

(defun make-wayland-provider ()
  (make-clipboard-provider :wayland
    :available-p (lambda () (and (%env-set-p "WAYLAND_DISPLAY") (%program-exists-p "wl-copy")))
    :put-text (lambda (s) (%run-in '("wl-copy") s))
    :get-text (lambda () (%run-out '("wl-paste" "-n")))))

(defun make-macos-provider ()
  (make-clipboard-provider :macos
    :available-p (lambda () (and (uiop:os-macosx-p) (%program-exists-p "pbcopy")))
    :put-text (lambda (s) (%run-in '("pbcopy") s))
    :get-text (lambda () (%run-out '("pbpaste")))))

(defun make-windows-provider ()
  (make-clipboard-provider :windows
    :available-p (lambda () (uiop:os-windows-p))
    :put-text (lambda (s) (%run-in '("powershell" "-NoProfile" "-Command" "$input | Set-Clipboard") s))
    :get-text (lambda () (%run-out '("powershell" "-NoProfile" "-Command" "Get-Clipboard")))))

(defun make-osc52-provider ()
  (make-clipboard-provider :osc52
    :available-p (lambda () (and *clipboard-osc52-enabled*
                                 (interactive-stream-p *terminal-io*)))
    :put-text (lambda (s) (%osc52-write s))
    :get-text (lambda () nil)))            ; write-mostly (OSC 52 read is rarely answered)

;;; --- base64 + OSC 52 (write to the controlling terminal) ------------------

(defun %utf8-bytes (string)
  (let ((out (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
    (flet ((emit (b) (vector-push-extend b out)))
      (loop for ch across string for cp = (char-code ch) do
        (cond ((< cp #x80) (emit cp))
              ((< cp #x800) (emit (logior #xC0 (ash cp -6))) (emit (logior #x80 (logand cp #x3F))))
              ((< cp #x10000) (emit (logior #xE0 (ash cp -12)))
                              (emit (logior #x80 (logand (ash cp -6) #x3F)))
                              (emit (logior #x80 (logand cp #x3F))))
              (t (emit (logior #xF0 (ash cp -18)))
                 (emit (logior #x80 (logand (ash cp -12) #x3F)))
                 (emit (logior #x80 (logand (ash cp -6) #x3F)))
                 (emit (logior #x80 (logand cp #x3F)))))))
    out))

(defparameter +base64-alphabet+
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/")

(defun %base64 (bytes)
  (let ((out (make-string-output-stream)) (n (length bytes)))
    (loop for i from 0 below n by 3
          for b0 = (aref bytes i)
          for b1 = (if (< (+ i 1) n) (aref bytes (+ i 1)) 0)
          for b2 = (if (< (+ i 2) n) (aref bytes (+ i 2)) 0)
          do (write-char (char +base64-alphabet+ (ldb (byte 6 2) b0)) out)
             (write-char (char +base64-alphabet+ (logior (ash (ldb (byte 2 0) b0) 4)
                                                         (ldb (byte 4 4) b1))) out)
             (write-char (if (< (+ i 1) n)
                             (char +base64-alphabet+ (logior (ash (ldb (byte 4 0) b1) 2)
                                                            (ldb (byte 2 6) b2)))
                             #\=) out)
             (write-char (if (< (+ i 2) n) (char +base64-alphabet+ (ldb (byte 6 0) b2)) #\=) out))
    (get-output-stream-string out)))

(defun %osc52-write (string)
  "Write STRING to the controlling terminal as an OSC 52 clipboard-set sequence,
wrapped for tmux passthrough when running under tmux."
  (let* ((seq (format nil "~C]52;c;~A~C" #\Escape (%base64 (%utf8-bytes string)) #\Bel))
         (wrapped (if (%env-set-p "TMUX")
                      (format nil "~CPtmux;~C~A~C\\" #\Escape #\Escape seq #\Escape)
                      seq)))
    (write-string wrapped *terminal-io*)
    (finish-output *terminal-io*)
    nil))

;;; --- provider registry + selection ----------------------------------------

(defun default-clipboard-providers ()
  "The providers in preference order (clipboard-interface.org §selection)."
  (list (make-windows-provider) (make-macos-provider) (make-wayland-provider)
        (make-x11-provider) (make-osc52-provider) (make-null-provider)))

(defvar *clipboard-providers* (default-clipboard-providers)
  "Providers in preference order (most preferred first).")

(defvar %active-provider nil)
(defvar %active-registry nil)
(defvar *clipboard-demoted* nil
  "T once the active provider has failed and been demoted to :NULL this session.")
(defvar %demote-warned nil)

(defun %null-provider ()
  (or (find :null *clipboard-providers* :key #'clipboard-provider-name) (make-null-provider)))

(defun %auto-select ()
  (or (find-if (lambda (p) (ignore-errors (funcall (clipboard-provider-available-p p))))
               *clipboard-providers*)
      (%null-provider)))

(defun active-provider ()
  "The selected provider: a forced one, or the first available in the registry
(lazy + cached, re-checked when the registry changes; clipboard-interface.org
§Errors and fallback)."
  (let ((forced *clipboard-provider*))
    (cond
      ((clipboard-provider-p forced) forced)
      ((keywordp forced)
       (or (find forced *clipboard-providers* :key #'clipboard-provider-name) (%null-provider)))
      (t (unless (and %active-provider (eq %active-registry *clipboard-providers*))
           (setf %active-provider (%auto-select) %active-registry *clipboard-providers*))
         %active-provider))))

(defun %effective-provider ()
  (if *clipboard-demoted* (%null-provider) (active-provider)))

(defun %demote (condition)
  (unless %demote-warned
    (warn "sedit clipboard: provider failed (~A); using the in-process clipboard only." condition)
    (setf %demote-warned t))
  (setf *clipboard-demoted* t))

(defun reset-clipboard-selection ()
  "Forget the cached provider and any demotion (e.g. after changing the registry)."
  (setf %active-provider nil %active-registry nil *clipboard-demoted* nil %demote-warned nil))

;;; --- text layer (the public provider API) ---------------------------------

(defun clipboard-put-text (string)
  "Set the system clipboard to STRING (UTF-8, verbatim). No-op when disabled or
the provider fails (which demotes it). Returns T on success, NIL otherwise."
  (when *system-clipboard-enabled*
    (handler-case (progn (funcall (clipboard-provider-put-text (%effective-provider)) string) t)
      (error (e) (%demote e) nil))))

(defun clipboard-get-text ()
  "The system clipboard contents (UTF-8), or NIL when empty / write-only /
disabled / on a transport failure (which demotes the provider)."
  (when *system-clipboard-enabled*
    (handler-case (funcall (clipboard-provider-get-text (%effective-provider)))
      (error (e) (%demote e) nil))))

;;; --- sexp <-> text serialization (secure; §Sexp ↔ text) -------------------

(defun %parse-clipboard-text (text)
  "Parse TEXT into a node WITHOUT evaluating (the reader never evals — a foreign
#.(…) cannot run). Text that does not parse becomes a string atom."
  (or (ignore-errors (parse-form text)) (make-atom-node text)))

(defun node->clip-object (node)
  "The adorned clipboard object for NODE (spec §5.4): (:COMMENT text) for a
comment, else (:SEXP sexp source-text)."
  (if (comment-node-p node)
      (list :comment (comment-node-text node))
      (list :sexp (tree->sexp node) (unparse node))))

(defun clip-object->node (object)
  "The node an adorned clipboard OBJECT denotes; a bare value is turned into a tree."
  (cond
    ((and (consp object) (eq (first object) :sexp))
     (or (ignore-errors (parse-form (third object))) (sexp->tree (second object))))
    ((and (consp object) (eq (first object) :comment)) (make-comment-node (second object)))
    ((node-p object) object)
    (t (sexp->tree object))))

;;; --- node layer (what sedit-copy/cut/paste use) ---------------------------

(defun clipboard-copy-node (node)
  "Put NODE on the internal clipboard and mirror its source text to the system
clipboard (clipboard-interface.org §Public API). Returns NODE."
  (setf *clipboard* node
        *clal-clipboard* (node->clip-object node))
  (clipboard-put-text (unparse node))
  node)

(defun clipboard-paste-node (fallback)
  "The node to paste: the system clipboard parsed if non-empty, else FALLBACK
(the caller's in-process clipboard). Never evaluates the pasted text."
  (let ((text (clipboard-get-text)))
    (if (and text (plusp (length text)))
        (%parse-clipboard-text text)
        fallback)))
