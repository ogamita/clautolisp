;;;; Non-interactive regression tests for the ncurses backend's error
;;;; reporting (issue: --debugger-ui ncurses crashed with the opaque
;;;; "NIL is not of type SB-SYS:SYSTEM-AREA-POINTER" when libncurses could
;;;; not be found/linked or initscr could not open the terminal).
;;;;
;;;; Runs headless — it never brings up a real screen — so it can go anywhere
;;;; the curses backend loads (libncurses need only be present enough to load;
;;;; the guards under test fire without initscr succeeding). This system is
;;;; outside the clautolisp CI aggregate (which carries no libncurses), so run
;;;; it by hand from the clautolisp/ directory:
;;;;
;;;;   sbcl --script autolisp-debug-ui-tui-curses/test/unavailable-tests.lisp
;;;;
;;;; Exits non-zero on the first failed assertion.

(require :asdf)
(let ((ql (merge-pathnames #p"quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(dolist (s '("cffi"))
  (when (find-package :ql) (funcall (read-from-string "ql:quickload") s :silent t)))

(let* ((here (or *load-truename* *default-pathname-defaults*))
       ;; here = .../clautolisp/autolisp-debug-ui-tui-curses/test/…
       (clroot (merge-pathnames
                #p"../../" (make-pathname :directory (pathname-directory here)))))
  (asdf:load-asd (merge-pathnames "autolisp-debug-ui-tui/tui-core.asd" clroot))
  (asdf:load-asd (merge-pathnames
                  "autolisp-debug-ui-tui-curses/clautolisp-tui-curses.asd" clroot))
  (asdf:load-system "clautolisp-tui-curses"))

(defpackage #:curses-unavailable-tests (:use #:cl #:clautolisp.ui.tui.curses))
(in-package #:curses-unavailable-tests)

(defvar *failures* 0)

(defmacro check (form &optional (label (format nil "~S" form)))
  `(handler-case
       (if ,form
           (format t "  ok   ~A~%" ,label)
           (progn (incf *failures*) (format t "  FAIL ~A~%" ,label)))
     (error (c)
       (incf *failures*)
       (format t "  FAIL ~A — signalled ~S: ~A~%" ,label (type-of c) c))))

(format t "~&curses error-reporting regression tests~%")

;; (1) CURSES-AVAILABLE-P is a two-value probe that never signals.
(multiple-value-bind (ok reason) (curses-available-p)
  (check (member ok '(t nil)) "curses-available-p returns a boolean")
  (check (or ok reason) "an unavailable probe carries a reason"))

;; (2) A lost/NULL window on resume raises the actionable CURSES-UNAVAILABLE —
;;     NOT the raw "NIL is not of type SYSTEM-AREA-POINTER" the bindings signal.
(let ((screen (make-curses-screen)))
  (setf (slot-value screen 'clautolisp.ui.tui.curses::started) t
        (slot-value screen 'clautolisp.ui.tui.curses::window) nil)
  (check (handler-case (progn (clautolisp.ui.tui:tui-start screen) nil)
           (curses-unavailable () t)
           (error () nil))
         "a NULL window on resume signals CURSES-UNAVAILABLE, not a raw SAP error"))

;; (3) The condition's report is actionable — it names the tui fall-back.
(check (search "--debugger-ui tui"
               (princ-to-string
                (make-condition 'curses-unavailable :detail "test")))
       "the report points the user at --debugger-ui tui")

;; (4) TUI-SIZE answers BEFORE initscr (frames.lisp queries it at construction,
;;     while curses is entered lazily) — a conventional 24x80, not a NULL-window
;;     crash. This is the fault that took down --debugger-ui ncurses at startup.
(let ((screen (make-curses-screen)))            ; window still NIL (no initscr)
  (check (handler-case
             (multiple-value-bind (rows cols) (clautolisp.ui.tui:tui-size screen)
               (and (integerp rows) (plusp rows) (integerp cols) (plusp cols)))
           (error () nil))
         "tui-size returns sane dimensions on an un-started screen (no SAP crash)"))

(format t "~&~[all curses error-reporting tests passed~:;~:*~D FAILURE(S)~]~%"
        *failures*)
(finish-output)
#+sbcl (sb-ext:exit :code (if (zerop *failures*) 0 1))
