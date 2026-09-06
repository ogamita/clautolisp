(in-package #:clautolisp.ui.tui.curses)

;;;; No-grovel CFFI ncurses backend for the clautolisp.ui.tui screen protocol.
;;;;
;;;; The handful of ncurses functions the four-pane UI needs are bound with
;;;; plain DEFCFUN, and the few attribute / key constants are given explicitly
;;;; (they are stable across the ncurses ABI on Linux and macOS). The foreign
;;;; library is loaded ON DEMAND in ENSURE-CURSES-LOADED — never at load or
;;;; image-startup time — so this code lives in the image with no build- or
;;;; startup-time dependency on libncurses.

;;; --- foreign library (loaded on demand) -------------------------------

(cffi:define-foreign-library libncurses
  ;; Prefer the wide-character library where present; fall back to the
  ;; narrow one, then to common absolute locations (MacPorts / Homebrew /
  ;; system) that are not always on the default search path.
  (:darwin (:or "libncursesw.dylib" "libncurses.dylib" "libncurses.6.dylib"
                "/opt/local/lib/libncurses.dylib"
                "/opt/homebrew/opt/ncurses/lib/libncurses.dylib"
                "/usr/local/opt/ncurses/lib/libncurses.dylib"
                "/usr/lib/libncurses.dylib"))
  (:unix   (:or "libncursesw.so.6" "libncurses.so.6"
                "libncursesw.so" "libncurses.so"))
  (t       (:default "libncurses")))

(defvar *curses-loaded* nil
  "True once LIBNCURSES has been opened this session.")

;;; setlocale(LC_ALL, "") — MUST run before initscr so ncurses uses the user's
;;; locale (from $LANG / $LC_*) for CHARACTER-WIDTH accounting. Without it
;;; ncurses runs byte-wise: a UTF-8 line (accented source, the "…" truncation
;;; ellipsis = 3 bytes) is clipped to N CHARACTERS but counted as more COLUMNS,
;;; so it overruns the pane's right edge and ncurses auto-wraps the excess onto
;;; the next terminal row — whose left half is the neighbouring pane (the "~@?"
;;; that leaked from a long source line into the stack pane). setlocale lives in
;;; libc/libSystem, resolved via the default library. LC_ALL's value is
;;; platform-specific: 0 on macOS/BSD (Darwin), 6 on Linux/glibc.
(cffi:defcfun ("setlocale" %setlocale) :string (category :int) (locale :string))

(defparameter +lc-all+ #+bsd 0 #-bsd 6
  "The C LC_ALL category number: 0 on the BSDs (macOS/Darwin included — SBCL puts
:BSD in *FEATURES* there), 6 on Linux/glibc. setlocale returning non-NIL confirms
the choice at run time.")

(defvar *locale-initialized* nil)

(defun ensure-locale ()
  "Call setlocale(LC_ALL, \"\") once, so ncurses measures multibyte characters
in display columns rather than bytes (aldo-ncurses-utf8-overflow). setlocale
returns the locale string on success, NIL on a bad category number — so if the
compile-time +LC_ALL+ guess is wrong for this host, fall back to the other
common value rather than silently leaving the C locale in place."
  (unless *locale-initialized*
    (ignore-errors
      (or (%setlocale +lc-all+ "")
          (%setlocale (if (= +lc-all+ 6) 0 6) "")))
    (setf *locale-initialized* t)))

(define-condition curses-unavailable (error)
  ((detail :initarg :detail :initform nil :reader curses-unavailable-detail))
  (:documentation
   "Signalled when the ncurses screen cannot be brought up: libncurses could
not be found/linked, or initscr could not open the terminal. Carries a
human-readable DETAIL and reports an actionable message — the CLI turns it
into a clean fall-back to the terminal (tui) UI.")
  (:report (lambda (condition stream)
             (format stream
                     "the ncurses debugger screen could not be initialized: ~A~
                      ~@[~%(TERM=~A)~]~%~
                      libncurses may be missing or unusable on this host; ~
                      re-run with --debugger-ui tui for the line-mode debugger."
                     (or (curses-unavailable-detail condition) "unknown error")
                     (ignore-errors (uiop:getenv "TERM"))))))

(defun ensure-curses-loaded ()
  "Open libncurses on demand (idempotent). Signals CURSES-UNAVAILABLE — with the
underlying loader message — when the library cannot be found or linked, so the
caller sees an actionable error instead of a raw CFFI/alien failure."
  (unless *curses-loaded*
    (handler-case (cffi:load-foreign-library 'libncurses)
      (cffi:load-foreign-library-error (error)
        (error 'curses-unavailable
               :detail (format nil "libncurses could not be loaded (~A)" error))))
    ;; Establish the locale BEFORE any initscr so ncurses accounts for UTF-8
    ;; characters by display column, not byte (see ENSURE-LOCALE) — otherwise a
    ;; long accented source line overflows its pane and wraps into the next.
    (ensure-locale)
    (setf *curses-loaded* t))
  *curses-loaded*)

(defun curses-available-p ()
  "Probe whether libncurses can be opened on this host (never signals). Returns
two values: a boolean, and — when it is false — the condition explaining why (a
CURSES-UNAVAILABLE with the loader message), for the caller to report."
  (handler-case (progn (ensure-curses-loaded) (values t nil))
    (error (condition) (values nil condition))))

;;; --- bindings (plain DEFCFUN, no grovel) ------------------------------
;;;
;;; WINDOW* is an opaque :pointer; we drive the standard screen (stdscr)
;;; returned by initscr.

(cffi:defcfun ("initscr"   %initscr)   :pointer)
(cffi:defcfun ("endwin"    %endwin)    :int)
(cffi:defcfun ("cbreak"    %cbreak)    :int)
(cffi:defcfun ("noecho"    %noecho)    :int)
(cffi:defcfun ("keypad"    %keypad)    :int (win :pointer) (bf :int))
(cffi:defcfun ("curs_set"  %curs-set)  :int (visibility :int))
;; ncurses `bool' is char-sized — read the return as :char and test nonzero.
(cffi:defcfun ("has_colors" %has-colors) :char)
(cffi:defcfun ("start_color" %start-color) :int)
(cffi:defcfun ("init_pair" %init-pair) :int (pair :short) (fg :short) (bg :short))
(cffi:defcfun ("wattron"   %wattron)   :int (win :pointer) (attrs :int))
(cffi:defcfun ("wattroff"  %wattroff)  :int (win :pointer) (attrs :int))
(cffi:defcfun ("mvwaddstr" %mvwaddstr) :int (win :pointer) (y :int) (x :int) (str :string))
(cffi:defcfun ("wclear"    %wclear)    :int (win :pointer))
(cffi:defcfun ("wrefresh"  %wrefresh)  :int (win :pointer))
(cffi:defcfun ("getmaxx"   %getmaxx)   :int (win :pointer))  ; returns column count
(cffi:defcfun ("getmaxy"   %getmaxy)   :int (win :pointer))  ; returns row count
(cffi:defcfun ("wgetch"    %wgetch)    :int (win :pointer))

;;; --- constants (ncurses ABI, Linux/macOS) -----------------------------

(defparameter +a-bold+       #x00200000 "ncurses A_BOLD.")
(defparameter +a-underline+  #x00020000 "ncurses A_UNDERLINE.")
(defparameter +a-reverse+    #x00040000 "ncurses A_REVERSE (inverse video).")
(defparameter +a-color-mask+ #x0000ff00 "ncurses A_COLOR.")

(defun color-pair (n)
  "ncurses COLOR_PAIR(n): the attribute bits selecting colour pair N."
  (logand (ash n 8) +a-color-mask+))

;; ncurses KEY_* codes (octal in <curses.h>).
(defparameter +key-down+      #o402)
(defparameter +key-up+        #o403)
(defparameter +key-left+      #o404)
(defparameter +key-right+     #o405)
(defparameter +key-backspace+ #o407)
(defparameter +key-enter+     #o527)
(defparameter +key-resize+    #o632)

;;; --- the screen -------------------------------------------------------

(defclass curses-screen ()
  ((window :initform nil :accessor curses-window)
   (started :initform nil :accessor curses-started)   ; initscr done once/session
   (color-pairs :initform (make-hash-table :test 'eq) :accessor curses-color-pairs)))

(defun make-curses-screen () (make-instance 'curses-screen))

(defparameter +color-names+
  '((:black . 0) (:red . 1) (:green . 2) (:yellow . 3)
    (:blue . 4) (:magenta . 5) (:cyan . 6) (:white . 7)))

(defmethod tui-start ((screen curses-screen))
  "Enter (or resume) curses full-screen mode. initscr runs once per session;
later calls — a new debugger stop after a TUI-STOP (endwin) — just re-apply the
input modes and refresh, so stdscr and its state survive across the stops.

Any failure to bring curses up — libncurses missing, initscr returning no
screen (not a terminal), or a low-level alien/type error deep in the FFI — is
turned into a single CURSES-UNAVAILABLE with an actionable message, never the
raw \"NIL is not of type SYSTEM-AREA-POINTER\" the bare bindings would signal."
  (ensure-curses-loaded)
  (handler-case
      (cond
        ((curses-started screen)
         ;; resume after endwin
         (let ((win (curses-window screen)))
           (when (or (null win) (cffi:null-pointer-p win))
             (error 'curses-unavailable
                    :detail "the curses screen was lost between stops"))
           (%cbreak) (%noecho) (%keypad win 1) (ignore-errors (%curs-set 0))
           (%wrefresh win)))
        (t
         (let ((win (%initscr)))
           ;; initscr returns NULL when it cannot open the terminal (no tty,
           ;; unusable $TERM); go no further with a null window — passing it to
           ;; the window bindings is exactly what produced the opaque crash.
           (when (or (null win) (cffi:null-pointer-p win))
             (error 'curses-unavailable :detail "initscr() could not open the terminal"))
           (setf (curses-window screen) win
                 (curses-started screen) t)
           (%cbreak)
           (%noecho)
           (%keypad win 1)                  ; deliver arrow / function keys
           (ignore-errors (%curs-set 0))    ; hide the hardware cursor
           (when (/= 0 (%has-colors))
             (%start-color)
             (loop for (name . fg) in +color-names+
                   for pair from 1
                   do (%init-pair pair fg 0) ; foreground FG on COLOR_BLACK (0)
                      (setf (gethash name (curses-color-pairs screen)) pair)))
           (%wclear win)
           (%wrefresh win))))
    ;; our own clear condition passes straight through …
    (curses-unavailable (condition) (error condition))
    ;; … any other bring-up failure (undefined alien, NIL→SAP type error, …) is
    ;; wrapped so the user gets the actionable message, not the FFI internals.
    (serious-condition (condition)
      (error 'curses-unavailable :detail (princ-to-string condition)))))

(defmethod tui-stop ((screen curses-screen))
  "Suspend curses, restoring the ordinary cooked terminal (echo on) for the
REPL between stops. stdscr is kept so the next TUI-START resumes it; endwin is
harmless if already suspended."
  (when (curses-started screen)
    (%endwin)))

(defmethod tui-size ((screen curses-screen))
  ;; getmaxy/getmaxx return the row and column COUNTS (ncurses adds 1 to the
  ;; stored max index); the protocol wants (values rows cols).
  ;;
  ;; TUI-SIZE is queried at frame CONSTRUCTION — before TUI-START/initscr, since
  ;; curses is entered lazily at the first debugger stop — so there is no window
  ;; yet. Report a conventional 24x80 then; the real dimensions replace it on the
  ;; first render after initscr. (Passing a NULL window to getmaxy is exactly
  ;; what produced the opaque "NIL is not of type SYSTEM-AREA-POINTER" crash.)
  (let ((win (curses-window screen)))
    (if (or (null win) (cffi:null-pointer-p win))
        (values 24 80)
        (values (%getmaxy win) (%getmaxx win)))))

(defmethod tui-clear ((screen curses-screen))
  (%wclear (curses-window screen)))

(defmethod tui-put ((screen curses-screen) row col string &key (attr :normal))
  ;; ATTR is a face symbol (TUI module spec §5.3); resolve it to ncurses
  ;; attribute bits — a colour pair for its foreground plus bold / underline /
  ;; reverse. An unknown symbol resolves to plain text.
  (let* ((win (curses-window screen))
         ;; resolve the face through the active config cascade (pjb: per-config
         ;; face overrides), falling back to the global registry.
         (params (clautolisp.ui.tui:resolve-face attr))
         (fg (getf params :fg))
         (pair (and fg (gethash fg (curses-color-pairs screen))))
         (bits (logior (if pair (color-pair pair) 0)
                       (if (getf params :bold) +a-bold+ 0)
                       (if (getf params :underline) +a-underline+ 0)
                       (if (getf params :invert) +a-reverse+ 0))))
    (when (/= bits 0) (%wattron win bits))
    (%mvwaddstr win row col string)
    (when (/= bits 0) (%wattroff win bits))))

(defmethod tui-refresh ((screen curses-screen))
  (%wrefresh (curses-window screen)))

(defmethod tui-read-key ((screen curses-screen))
  "Translate an ncurses wgetch code into the protocol's key vocabulary."
  (let ((code (%wgetch (curses-window screen))))
    (cond
      ((= code -1) :eof)                       ; ERR — stream closed
      ((= code +key-up+) :up)
      ((= code +key-down+) :down)
      ((= code +key-left+) :left)
      ((= code +key-right+) :right)
      ((= code +key-backspace+) :backspace)
      ((= code +key-enter+) :enter)
      ((= code +key-resize+) :resize)
      ((or (= code 10) (= code 13)) :enter)
      ((= code 27) :escape)
      ((or (= code 8) (= code 127)) :backspace)
      ((<= 0 code 255) (code-char code))
      (t :unknown))))
