(in-package #:clautolisp.ui.ncurses)

;;;; Debugger-specific window identities for the four-pane ncurses UI. The
;;;; GENERIC layout-tree machinery — layout-leaves / window-cycle / layout-rects
;;;; / window-neighbor / tree-swap-leaves / tree-resize / tree-balance /
;;;; tree-remove-leaf / tree-split-active / the rect helpers — now lives in the
;;;; tui-core module (clautolisp.ui.tui, autolisp-debug-ui-tui/source/layout.lisp)
;;;; and is inherited here through :USE. Only the debugger's four window ids,
;;;; their titles, and the canonical layout stay here.

(defparameter +window-ids+ '(:stack :source :interactor :repl))

(defparameter +window-titles+
  '((:stack . "stack") (:source . "source")
    (:interactor . "interactor") (:repl . "repl")))

(defun window-title (id)
  (or (cdr (assoc id +window-titles+)) (string-downcase (symbol-name id))))

(defun default-layout ()
  "The canonical 2x2: (stack | source) above (interactor | repl)."
  (list :horizontal 1/2
        (list :vertical 1/2 :stack :source)
        (list :vertical 1/2 :interactor :repl)))
