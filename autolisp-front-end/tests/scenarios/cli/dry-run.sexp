(:name "cli-dry-run"
 :description "--dry-run resolves the action plan against the
in-process clautolisp backend, prints it to stdout, and exits 0."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("alfe --dry-run"
                            "backend"
                            "CLAUTOLISP"
                            "eval"
                            "(+ 1 2)"
                            "quit")
 :covers-options ("--dry-run" "--clautolisp"))
