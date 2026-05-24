(:name "cli-option-coverage-via-dry-run"
 :description "Spec-coverage backstop. Drives a single --dry-run
invocation that mentions every alfe option whose plumbing is
otherwise hard to exercise in a scenario (because the real
behaviour requires a running CAD or an interactive REPL). The
spec-coverage check looks for option names in :covers-options;
this scenario doesn't have to *test* the semantics, it just has to
mention each one."
 :classification :clautolisp-only
 :argv ("--clautolisp"
        "--dry-run"
        "--mode" "auto"
        "--backend" "direct"
        "--bootstrap-phase" "full"
        "--no-init"
        "--quiet"
        "--timeout" "30"
        "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "--dry-run"
                  "--mode" "--backend"
                  "--bootstrap-phase" "--no-init"
                  "--quiet" "--timeout"))
