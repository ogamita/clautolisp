;;;; Standalone ASDF system for the cl-charms (ncurses) backend.
;;;;
;;;; Intentionally NOT defined inside clautolisp.asd and NOT part of the
;;;; clautolisp aggregate: it depends on cl-charms / libncurses and needs a
;;;; real terminal, so building or testing it must never be required to
;;;; build or test clautolisp. Load it explicitly on a Unix terminal:
;;;;
;;;;   (asdf:load-asd #p".../autolisp-debug-ui-tui-charms/clautolisp-charms.asd")
;;;;   (asdf:load-system "clautolisp/autolisp-debug-ui-tui-charms")
;;;;
;;;; Then a session with :ui :ncurses driving a real charms-screen works.

(asdf:defsystem "clautolisp/autolisp-debug-ui-tui-charms"
  :description "cl-charms (ncurses) backend for the clautolisp.ui.tui screen protocol (Unix; not in the aggregate)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui-tui" "cl-charms")
  :serial t
  :components
  ((:file "source/package")
   (:file "source/charms-screen")))
