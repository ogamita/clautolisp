;;;; clautolisp/autolisp-debug-ui-tui-curses/source/package.lisp
;;;;
;;;; A no-grovel CFFI (ncurses) backend for the clautolisp.ui.tui screen
;;;; protocol (clautolisp-debugger spec §19.3). Unlike the retired cl-charms
;;;; backend, this uses plain CFFI-DEFCFUN bindings — NO cffi-grovel, so the
;;;; CL code compiles into the clautolisp image with NO build-time dependency
;;;; on ncurses headers or libraries. The foreign library (libncurses) is
;;;; opened ON DEMAND, only when the ncurses UI is actually started
;;;; (TUI-START), never at image build or startup. A PDCurses (native Windows)
;;;; sibling backend will follow behind the same protocol.

(defpackage #:clautolisp.ui.tui.curses
  (:use #:cl)
  (:import-from #:clautolisp.ui.tui
                #:tui-start #:tui-stop #:tui-size #:tui-clear #:tui-put
                #:tui-refresh #:tui-read-key)
  (:export #:curses-screen #:make-curses-screen
           #:ensure-curses-loaded #:curses-available-p))
