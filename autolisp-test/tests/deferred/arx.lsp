;;;; tests/deferred/arx.lsp -- ARX (AutoCAD ObjectARX runtime)
;;;;
;;;; ARX requires an AutoCAD-compatible runtime that can load native
;;;; ObjectARX modules. Tagged (arx) so it shows NOT-APPLICABLE on
;;;; clautolisp and BricsCAD.

(deftest-skip "arx-deferred"
  '((operator . "ARX") (area . "arx") (profile . autocad)
    (runtime-tags . (arx)))
  '(arx)
  "deferred: requires AutoCAD ObjectARX runtime")

(deftest-skip "arxload-deferred"
  '((operator . "ARXLOAD") (area . "arx") (profile . autocad)
    (runtime-tags . (arx)))
  '(arxload "module.arx")
  "deferred: requires AutoCAD ObjectARX runtime")

(deftest-skip "arxunload-deferred"
  '((operator . "ARXUNLOAD") (area . "arx") (profile . autocad)
    (runtime-tags . (arx)))
  '(arxunload "module")
  "deferred: requires AutoCAD ObjectARX runtime")

(deftest-skip "autoarxload-deferred"
  '((operator . "AUTOARXLOAD") (area . "arx") (profile . autocad)
    (runtime-tags . (arx)))
  '(autoarxload "module.arx" '(my-cmd))
  "deferred: requires AutoCAD ObjectARX runtime")
