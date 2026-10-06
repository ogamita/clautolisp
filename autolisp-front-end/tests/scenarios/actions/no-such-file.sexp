(:name "actions-load-missing-file"
 :description "Loading a non-existent file fails with an error message
and exit status EX_NOINPUT (66): under --clautolisp alfe exits with the
ENGINE's status, and EX_NOINPUT is the clautolisp program's status for a
file it cannot open -- in both engine variants (alfe-clautolisp-backend-
semantic-parity.issue; sysexits-exit-statuses.issue, it was 2 before), with
the engine's own message, whatever the host Lisp
(alfe-ccl-parity-missing-load-file-message.issue)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-l" "/nonexistent/path/that/does/not/exist.lsp")
 :expected-exit 66
 :expected-stderr-includes ("cannot open /nonexistent/path/that/does/not/exist.lsp: no such file or directory")
 :covers-options ("--clautolisp" "-l"))
