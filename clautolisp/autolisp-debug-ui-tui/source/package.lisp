(defpackage #:tui-core
  ;; TUI module spec: this package IS the tui-core module (screen protocol,
  ;; panes, faces, frames, windows, layout tree). It has no clautolisp
  ;; dependency. TUI-CORE is now the primary name; CLAUTOLISP.UI.TUI stays as a
  ;; nickname so existing clautolisp.ui.tui: references keep resolving.
  (:nicknames #:clautolisp.ui.tui)
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
   #:tui-move-cursor
   ;; window drawing operations (tty-safe)
   #:window-cursor #:window-screen #:window-vdt-p
   #:clear-window #:move-cursor-to #:window-put
   ;; panes + layout
   #:pane #:make-pane #:pane-title #:pane-top #:pane-left #:pane-height #:pane-width
   #:draw-box #:pane-put-line #:pane-clear #:pane-interior-height #:pane-interior-width
   #:four-pane-layout #:truncate-string #:pad-string
   ;; mock backend
   #:mock-screen #:make-mock-screen
   #:mock-screen-rows #:mock-screen-cols
   #:mock-grid-lines #:mock-attr-at #:mock-find-line #:mock-feed-keys #:mock-cursor
   ;; key helpers
   #:key-char-p
   ;; faces (TUI module spec §5.3)
   #:define-face #:face-parameters #:facep #:list-faces #:*faces*
   ;; frames (spec §4)
   #:frame #:framep #:make-frame #:frame-list #:selected-frame
   #:frame-name #:set-frame-name #:frame-width #:set-frame-width
   #:frame-height #:set-frame-height #:frame-minibuffer #:frame-minibuffer-p
   #:frame-device #:frame-screen #:frame-windows #:frame-layout
   #:frame-selected-window
   #:select-frame #:delete-frame #:terminal-device-supports-vdt-p
   #:ensure-initial-tty-frame #:reset-frames #:*frames* #:*selected-frame*
   ;; windows (spec §5) — the ncurses UI is now wired onto the window struct, so
   ;; its per-window state (buffer / scroll / rect / interactor stack) lives on
   ;; these exported accessors rather than in ad-hoc UI hash tables.
   #:window #:windowp #:make-window #:window-name #:set-window-name
   #:window-role #:window-frame
   #:window-buffer #:window-scroll #:window-rect #:window-stack
   #:window-list #:delete-window #:selected-window #:select-window
   ;; keymaps (spec §6 / ncurses-key-bindings.issue)
   #:parse-key-sequence #:unparse-key-sequence
   #:keymap #:keymap-p #:make-keymap #:keymap-bind #:keymap-unbind
   #:keymap-step #:keymap-lookup #:keymap-leaves #:keymap-map
   ;; layout tree (spec §5.1)
   #:layout-leaves #:window-cycle #:layout-rects
   #:rect-top #:rect-left #:rect-bottom #:rect-right
   #:rects-row-overlap-p #:rects-col-overlap-p #:window-neighbor
   #:tree-swap-leaves #:clamp-ratio #:tree-resize #:tree-balance
   #:tree-remove-leaf #:tree-split-active))
