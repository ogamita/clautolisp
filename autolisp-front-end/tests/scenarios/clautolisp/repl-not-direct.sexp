(:name "clautolisp-repl-not-direct"
 :description "An interactive session is the clautolisp program's REPL (its
interactors, comma commands and aldo debugger): with an explicit --backend
direct, -i is a usage error, reported before any engine starts."
 :classification :portable
 :argv ("--clautolisp" "-i" "--backend" "direct" "--dry-run")
 :expected-exit 64
 :expected-stderr-includes ("interactive session" "--backend direct")
 :covers-options ("--interactive" "-i" "--backend"))
