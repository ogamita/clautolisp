(:name "cli-debug"
 :description "--debug enables debug-level diagnostics. Same
shape as --verbose: pair with --dry-run so the scenario doesn't
need an engine."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--debug" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "--debug" "--dry-run"))
