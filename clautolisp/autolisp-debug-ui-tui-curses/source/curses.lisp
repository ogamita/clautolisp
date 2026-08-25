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

(defun ensure-curses-loaded ()
  "Open libncurses on demand (idempotent). Signals a CFFI error when the
library cannot be found — the caller (the CLI) turns that into a clean
fall-back to the tui UI."
  (unless *curses-loaded*
    (cffi:load-foreign-library 'libncurses)
    (setf *curses-loaded* t))
  *curses-loaded*)

(defun curses-available-p ()
  "True when libncurses can be opened on this host (probe; never signals)."
  (handler-case (progn (ensure-curses-loaded) t)
    (error () nil)))

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
input modes and refresh, so stdscr and its state survive across the stops."
  (ensure-curses-loaded)
  (cond
    ((curses-started screen)
     ;; resume after endwin
     (let ((win (curses-window screen)))
       (%cbreak) (%noecho) (%keypad win 1) (ignore-errors (%curs-set 0))
       (%wrefresh win)))
    (t
     (let ((win (%initscr)))
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
       (%wrefresh win)))))

(defmethod tui-stop ((screen curses-screen))
  "Suspend curses, restoring the ordinary cooked terminal (echo on) for the
REPL between stops. stdscr is kept so the next TUI-START resumes it; endwin is
harmless if already suspended."
  (when (curses-started screen)
    (%endwin)))

(defmethod tui-size ((screen curses-screen))
  ;; getmaxy/getmaxx return the row and column COUNTS (ncurses adds 1 to the
  ;; stored max index); the protocol wants (values rows cols).
  (let ((win (curses-window screen)))
    (values (%getmaxy win) (%getmaxx win))))

(defmethod tui-clear ((screen curses-screen))
  (%wclear (curses-window screen)))

(defmethod tui-put ((screen curses-screen) row col string &key (attr :normal))
  (let* ((win (curses-window screen))
         (pair (gethash attr (curses-color-pairs screen)))
         (bits (cond (pair (color-pair pair))
                     ((eq attr :bold) +a-bold+)
                     ((eq attr :invert) +a-reverse+)
                     ((eq attr :underline) +a-underline+)
                     (t 0))))
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
