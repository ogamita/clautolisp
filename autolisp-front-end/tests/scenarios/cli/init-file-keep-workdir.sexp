(:name "init-file-keep-workdir-flag-parses"
 :description "--keep-workdir parses cleanly. The flag's runtime
effect (skip the workdir cleanup-tree) is invisible from a
conformance scenario, but the parser must accept it. Pairs with
--dry-run so the scenario doesn't depend on a real backend."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--keep-workdir" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "--keep-workdir" "--dry-run"))
