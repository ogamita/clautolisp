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
        "--cad" "clautolisp"
        "--dry-run"
        "--mode" "auto"
        "--backend" "direct"
        "--bootstrap-phase" "full"
        "--no-init"
        "--no-color"
        "--quiet"
        "--timeout" "30"
        ;; --write-workdir-path only fires once a workdir is prepared,
        ;; which --dry-run never does; the parser must still accept it.
        "--write-workdir-path" "workdir-path.txt"
        "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "--cad" "--dry-run"
                  "--mode" "--backend"
                  "--bootstrap-phase" "--no-init"
                  "--no-color"
                  "--quiet" "--timeout"
                  "--write-workdir-path"))
