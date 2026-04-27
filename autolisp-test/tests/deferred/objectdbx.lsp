;;;; tests/deferred/objectdbx.lsp -- entity / selection-set / table / dictionary
;;;;
;;;; These tests require either a live CAD database or a deterministic
;;;; mock host with DXF fixtures (clautolisp PLAN.md Phase 10).

(deftest-skip "entget-deferred"
  '((operator . "ENTGET") (area . "entity") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(entget (entlast))
  "deferred: requires CAD database fixture")

(deftest-skip "entlast-deferred"
  '((operator . "ENTLAST") (area . "entity") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(entlast)
  "deferred: requires CAD database fixture")

(deftest-skip "entnext-deferred"
  '((operator . "ENTNEXT") (area . "entity") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(entnext)
  "deferred: requires CAD database fixture")

(deftest-skip "entmod-deferred"
  '((operator . "ENTMOD") (area . "entity") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(entmod nil)
  "deferred: requires CAD database fixture")

(deftest-skip "ssget-deferred"
  '((operator . "SSGET") (area . "selection-set") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(ssget)
  "deferred: requires CAD database fixture")

(deftest-skip "sslength-deferred"
  '((operator . "SSLENGTH") (area . "selection-set") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(sslength nil)
  "deferred: requires CAD database fixture")

(deftest-skip "tblnext-deferred"
  '((operator . "TBLNEXT") (area . "table") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(tblnext "LAYER" T)
  "deferred: requires CAD database fixture")

(deftest-skip "tblsearch-deferred"
  '((operator . "TBLSEARCH") (area . "table") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(tblsearch "LAYER" "0")
  "deferred: requires CAD database fixture")

(deftest-skip "namedobjdict-deferred"
  '((operator . "NAMEDOBJDICT") (area . "dictionary") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(namedobjdict)
  "deferred: requires CAD database fixture")

(deftest-skip "handent-deferred"
  '((operator . "HANDENT") (area . "entity") (profile . strict)
    (runtime-tags . (objectdbx)))
  '(handent "1")
  "deferred: requires CAD database fixture")
