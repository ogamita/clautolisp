(:name "cli-dwg-and-epure"
 :description "--dwg FILE is a CAD-bound flag whose semantics fire
inside the BricsCAD/AutoCAD backends, and --epure is the flag the epure
plug-in defines (plugins/epure/, found in the source tree). We exercise
the parser plumbing under --bricscad --dry-run so the scenario runs
CI-side without a CAD install (off Windows the plug-in ignores itself)."
 :classification :portable
 :argv ("--bricscad" "--dry-run"
        "--dwg" "fixture.dwg"
        "--epure"
        "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--bricscad" "--dry-run" "--dwg" "--epure"))
