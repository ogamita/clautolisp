(:name "cli-dwg-and-epure"
 :description "--dwg FILE and --epure are CAD-bound flags whose
semantics fire inside the BricsCAD/AutoCAD backends. We exercise
the parser plumbing under --bricscad --dry-run so the scenario
runs CI-side without a CAD install."
 :classification :portable
 :argv ("--bricscad" "--dry-run"
        "--dwg" "fixture.dwg"
        "--epure"
        "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--bricscad" "--dry-run" "--dwg" "--epure"))
