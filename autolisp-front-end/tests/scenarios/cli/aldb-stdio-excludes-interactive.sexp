(:name "cli-aldb-stdio-excludes-interactive"
 :description "--aldb-stdio makes stdin/stdout the aldb RPC channel, so it
excludes --interactive -- the same usage error as the clautolisp program's."
 :classification :portable
 :argv ("--clautolisp" "--aldb-stdio" "-i")
 :expected-exit 64
 :expected-stderr-includes ("--aldb-stdio" "mutually exclusive")
 :covers-options ("--aldb-stdio"))
