(:name "autocad-unsupported-os"
 :description "On macOS / Linux, --autocad exits 3 with a structured
'AutoCAD is not distributed for this OS' diagnostic. The scenario
runs on every platform — on Windows the DETECT succeeds, the
backend tries to launch, hits a different error path; the scenario
is portable in the sense that its assertion only fires on
non-Windows, where the message is observable."
 :classification :portable
 :argv ("--autocad" "-x" "(+ 1 2)")
 :expected-exit 3
 :expected-stderr-includes ("AutoCAD" "not distributed")
 :covers-options ("--autocad"))
