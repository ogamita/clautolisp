;;;; tests/deferred/dcl.lsp -- DCL (Dialog Control Language)
;;;;
;;;; DCL functions require a UI host and a .dcl fixture. The mock-host
;;;; layer that would let us run them headlessly does not yet exist
;;;; (clautolisp PLAN.md Phase 9: "Build a deterministic mock host").
;;;;
;;;; Each entry is registered as deferred so the verdict matrix shows
;;;; the gap. When the mock host arrives the deferred placeholder is
;;;; replaced by an executable test.

(deftest-skip "load_dialog-deferred"
  '((operator . "LOAD_DIALOG") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(load_dialog "fixtures/dcl/sample.dcl")
  "deferred: requires mock-host UI driver")

(deftest-skip "new_dialog-deferred"
  '((operator . "NEW_DIALOG") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(new_dialog "sample" 0)
  "deferred: requires mock-host UI driver")

(deftest-skip "start_dialog-deferred"
  '((operator . "START_DIALOG") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(start_dialog)
  "deferred: requires mock-host UI driver")

(deftest-skip "action_tile-deferred"
  '((operator . "ACTION_TILE") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(action_tile "ok" "(done_dialog 1)")
  "deferred: requires mock-host UI driver")

(deftest-skip "set_tile-deferred"
  '((operator . "SET_TILE") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(set_tile "name" "value")
  "deferred: requires mock-host UI driver")

(deftest-skip "get_tile-deferred"
  '((operator . "GET_TILE") (area . "dcl") (profile . strict)
    (runtime-tags . (dcl)))
  '(get_tile "name")
  "deferred: requires mock-host UI driver")
