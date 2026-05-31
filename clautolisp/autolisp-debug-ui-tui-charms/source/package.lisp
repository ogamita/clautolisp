(defpackage #:clautolisp.ui.tui.charms
  (:use #:cl)
  (:documentation
   "A cl-charms (ncurses) backend for the clautolisp.ui.tui screen
protocol (clautolisp-debugger spec §19.3, Unix). This system is NOT part
of the clautolisp aggregate or its test suite: it depends on cl-charms /
libncurses and requires a real terminal, neither guaranteed in CI or on
every host. Load it explicitly on a Unix terminal to run the ncurses
debugger UI for real; the four-pane UI (clautolisp.ui.ncurses) and all its
tests run against the mock screen and never load this. PDCurses/Windows is
a future sibling backend behind the same protocol.")
  (:import-from #:clautolisp.ui.tui
                #:tui-start #:tui-stop #:tui-size #:tui-clear #:tui-put
                #:tui-refresh #:tui-read-key)
  (:export #:charms-screen #:make-charms-screen))
