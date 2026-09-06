;;;; tui-core.asd — the independent TUI module (TUI module spec §10).
;;;;
;;;; A standalone ASDF system with NO clautolisp dependency: the screen protocol
;;;; + panes + mock backend, plus faces, frames, windows and the window layout
;;;; tree. The clautolisp debugger UIs (ncurses, and the =clal-= AutoLISP
;;;; wrappers) are thin consumers of this module.
;;;;
;;;; It is loaded automatically whenever clautolisp.asd is loaded (that file
;;;; loads this one at read time), so dependents that name "tui-core" resolve it
;;;; without any source-registry configuration. It can also be loaded on its own:
;;;;   (asdf:load-asd #p".../autolisp-debug-ui-tui/tui-core.asd")
;;;;   (asdf:load-system "tui-core")

(asdf:defsystem "tui-core"
  :description "tui-core: clautolisp-independent terminal-UI module — screen protocol, faces, frames, windows, layout tree, mock backend (TUI module spec)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ()
  :serial t
  :components
  ((:file "source/package")
   (:file "source/faces")
   (:file "source/tui")
   (:file "source/layout")
   (:file "source/frames")
   (:file "source/windows")
   (:file "source/window-ops")
   (:file "source/keymap")
   (:file "source/config")))
