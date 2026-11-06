(:name "encoding-bare-e"
 :description "The bare -E ENCODING sets the source and the terminal
encodings at once. A --dry-run, like cli-io-encoding: an executed run would
reopen the test process's own standard streams (the corpus runs in-process)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-E" "utf-8" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "-E" "--dry-run"))
