(:name "actions-load-missing-file"
 :description "Loading a non-existent file fails with an error message
and exit status 2: under --clautolisp alfe exits with the ENGINE's
status, and 2 is the clautolisp program's code for a file it cannot
open -- in both engine variants (alfe-clautolisp-backend-semantic-
parity.issue; it was 1 in the in-process variant only). We don't
assert on the exact wording -- the underlying Lisp implementation
reports it -- but the run must NOT exit 0."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-l" "/nonexistent/path/that/does/not/exist.lsp")
 :expected-exit 2
 :covers-options ("--clautolisp" "-l"))
