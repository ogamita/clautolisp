(:name "cli-io-encoding"
 :description "-Eterminal sets the encoding of alfe's own standard
streams (reopened on POSIX; over SBCL's std HANDLEs, or the console
code page, on Windows); this scenario asserts the run reconfigures
them and still completes."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-Eterminal" "utf-8" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "-Eterminal" "--dry-run"))
