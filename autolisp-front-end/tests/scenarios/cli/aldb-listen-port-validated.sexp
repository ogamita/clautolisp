(:name "cli-aldb-listen-port-validated"
 :description "--aldb-listen [HOST:]PORT is parsed as the clautolisp program
parses it: a numeric port out of 0..65535 is a usage error."
 :classification :portable
 :argv ("--clautolisp" "--dry-run" "--aldb-listen" "localhost:70000" "-x" "(princ 1)")
 :expected-exit 64
 :expected-stderr-includes ("--aldb-listen" "out of range")
 :covers-options ("--aldb-listen"))
