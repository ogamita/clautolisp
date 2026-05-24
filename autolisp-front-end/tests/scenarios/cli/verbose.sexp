(:name "cli-verbose"
 :description "--verbose raises the verbosity. Combined with
--dry-run so we don't need a running engine. Exit must still be 0;
the plan dump may carry extra diagnostic lines but we only assert
on the action shape."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--verbose" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("--dry-run")
 :covers-options ("--clautolisp" "--verbose" "--dry-run"))
