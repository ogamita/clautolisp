;;;; Standalone ASDF system: the no-grovel CFFI (ncurses) backend for the
;;;; clautolisp.ui.tui screen protocol.
;;;;
;;;; Named as a standalone PRIMARY system matching this file's stem
;;;; (clautolisp-tui-curses.asd), so `(asdf:load-system "clautolisp-tui-curses")'
;;;; works once the .asd is on the source registry — unlike the old cl-charms
;;;; backend, whose secondary name did not match its file.
;;;;
;;;; It depends only on CFFI (pure Lisp — no C compilation, no grovel) plus the
;;;; screen protocol. The foreign library (libncurses) is opened on demand at
;;;; run time (see ENSURE-CURSES-LOADED), never at build or load time, so this
;;;; system can be compiled into the clautolisp image with no build- or
;;;; CI-time dependency on ncurses.

(asdf:defsystem "clautolisp-tui-curses"
  :description "No-grovel CFFI ncurses backend for clautolisp.ui.tui (Unix/macOS; libncurses loaded on demand)."
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui-tui" "cffi")
  :serial t
  :components
  ((:file "source/package")
   (:file "source/curses")))
