(:name "clautolisp-host-unknown"
 :description "alfe knows three hosts. Any other name — the historical
spellings included — is a usage error that lists the three."
 :classification :portable
 :argv ("--clautolisp" "--host" "mock" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("Unknown --host" "cador, cadtui, nihil")
 :covers-options ("--host"))
