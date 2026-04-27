;;;; tests/deferred/brx.lsp -- BRX (BricsCAD Runtime eXtension)
;;;;
;;;; BRX is BricsCAD's native module loader, analogous to ARX. The
;;;; spec inventory does not yet enumerate BRX-specific entries; the
;;;; placeholders below mirror the ARX surface and will be refined
;;;; once probe data lists actual BRX functions.

(deftest-skip "brxload-deferred"
  '((operator . "BRXLOAD") (area . "brx") (profile . bricscad)
    (runtime-tags . (brx)))
  '(brxload "module.brx")
  "deferred: requires BricsCAD BRX runtime; entry inferred from ARX analogue")

(deftest-skip "brxunload-deferred"
  '((operator . "BRXUNLOAD") (area . "brx") (profile . bricscad)
    (runtime-tags . (brx)))
  '(brxunload "module")
  "deferred: requires BricsCAD BRX runtime; entry inferred from ARX analogue")
