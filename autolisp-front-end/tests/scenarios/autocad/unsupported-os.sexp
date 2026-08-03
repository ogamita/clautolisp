(:name "autocad-unsupported-os"
 :description "On macOS / Linux, --autocad exits 3 with a structured
'AutoCAD is not distributed for this OS' diagnostic. Skipped on
Windows: there AutoCAD *is* the supported platform, so DETECT
structurally succeeds and the backend fails down a different path
(exit 4, not 3) — the unsupported-os premise simply does not hold,
so asserting exit 3 there is wrong, not merely unobservable. The
corpus unsets AUTOCAD_ACCORECONSOLE per-scenario so this runs
against a clean AutoCAD-absent baseline on macOS/Linux regardless of
the runner's vendor env."
 :classification :portable
 :skip-on-os (:windows)
 :argv ("--autocad" "-x" "(+ 1 2)")
 :expected-exit 3
 :expected-stderr-includes ("AutoCAD" "not distributed")
 :covers-options ("--autocad"))
