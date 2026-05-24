(:name "cli-io-encoding"
 :description "-E sets the I/O (terminal) encoding. The flag is
currently plumbed but not yet acted on in alfe-front-end's I/O
layer; this scenario asserts the plumbing accepts the value and
the run still completes."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-E" "utf-8" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :covers-options ("--clautolisp" "-E" "--dry-run"))
