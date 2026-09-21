(:name "clautolisp-host-cadtui-not-direct"
 :description "cadtui lives in the clautolisp executable, so asking for it
together with the in-process engine is a usage error."
 :classification :portable
 :argv ("--clautolisp" "--host" "cadtui" "--backend" "direct" "--dry-run"
        "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("--host cadtui" "--backend direct")
 :covers-options ("--host" "--backend"))
