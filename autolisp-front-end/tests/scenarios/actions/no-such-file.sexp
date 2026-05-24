(:name "actions-load-missing-file"
 :description "Loading a non-existent file exits 1 with an error
message. We don't assert on the exact wording — the underlying Lisp
implementation reports it — but the run must NOT exit 0."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-l" "/nonexistent/path/that/does/not/exist.lsp")
 :expected-exit 1
 :covers-options ("--clautolisp" "-l"))
