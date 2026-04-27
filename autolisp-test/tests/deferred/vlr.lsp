;;;; tests/deferred/vlr.lsp -- VLR-* (Visual LISP reactors)
;;;;
;;;; Reactor tests require a host that can fire real CAD events.
;;;; clautolisp's mock host (Phase 9) will simulate these; until then,
;;;; entries are deferred.

(deftest-skip "vlr-object-reactor-deferred"
  '((operator . "VLR-OBJECT-REACTOR") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-object-reactor nil nil nil)
  "deferred: requires reactor-capable host")

(deftest-skip "vlr-command-reactor-deferred"
  '((operator . "VLR-COMMAND-REACTOR") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-command-reactor nil nil)
  "deferred: requires reactor-capable host")

(deftest-skip "vlr-editor-reactor-deferred"
  '((operator . "VLR-EDITOR-REACTOR") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-editor-reactor nil nil)
  "deferred: requires reactor-capable host")

(deftest-skip "vlr-add-deferred"
  '((operator . "VLR-ADD") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-add nil)
  "deferred: requires reactor-capable host")

(deftest-skip "vlr-remove-deferred"
  '((operator . "VLR-REMOVE") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-remove nil)
  "deferred: requires reactor-capable host")

(deftest-skip "vlr-data-set-deferred"
  '((operator . "VLR-DATA-SET") (area . "vlr") (profile . strict)
    (runtime-tags . (vlr)))
  '(vlr-data-set nil nil)
  "deferred: requires reactor-capable host")
