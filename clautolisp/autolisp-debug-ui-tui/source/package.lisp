(defpackage #:clautolisp.ui.tui
  (:use #:cl)
  (:documentation
   "Thin terminal-UI abstraction for the ncurses debugger UI
(clautolisp-debugger spec §19.3). A TUI-SCREEN is a backend implementing
a small protocol (start/stop/size/clear/put/refresh/read-key); the
four-pane debugger UI draws against it and never calls curses directly.
Backends: a MOCK-SCREEN (a character grid + scripted keys, for tests, no
curses dependency) and — in the separate clautolisp/autolisp-debug-ui-tui-charms
system — a cl-charms backend for real terminals. PDCurses/Windows is a
future backend behind the same protocol.")
  (:export
   ;; screen protocol
   #:tui-screen
   #:tui-start #:tui-stop #:tui-size #:tui-clear #:tui-put #:tui-refresh #:tui-read-key
   ;; panes + layout
   #:pane #:make-pane #:pane-title #:pane-top #:pane-left #:pane-height #:pane-width
   #:draw-box #:pane-put-line #:pane-clear #:pane-interior-height #:pane-interior-width
   #:four-pane-layout
   ;; mock backend
   #:mock-screen #:make-mock-screen
   #:mock-screen-rows #:mock-screen-cols
   #:mock-grid-lines #:mock-attr-at #:mock-find-line #:mock-feed-keys
   ;; key helpers
   #:key-char-p))
