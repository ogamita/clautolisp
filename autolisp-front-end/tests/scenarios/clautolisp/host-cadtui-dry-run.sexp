(:name "clautolisp-host-cadtui-dry-run"
 :description "--host cadtui is accepted and reaches the plan; alfe transmits
it to the clautolisp executable (the subprocess variant), which a dry run does
not need."
 :classification :portable
 :argv ("--clautolisp" "--host" "cadtui" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("host:      CADTUI")
 :covers-options ("--clautolisp" "--host" "--dry-run"))
