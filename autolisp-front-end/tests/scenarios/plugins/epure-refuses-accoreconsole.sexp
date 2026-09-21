(:name "epure-refuses-accoreconsole"
 :description "--epure under --autocad --mode batch (accoreconsole: no GUI, no
profiles) is refused, on Windows. Elsewhere the plug-in ignores itself, so
the scenario is Windows-only."
 :classification :portable
 :skip-on-os (:linux :macos)
 :argv ("--autocad" "--mode" "batch" "--dry-run" "--epure" "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("EPURE requires the full AutoCAD GUI" "accoreconsole")
 :covers-options ("--autocad" "--mode" "--epure"))
