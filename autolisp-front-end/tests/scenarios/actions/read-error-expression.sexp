(:name "actions-read-error-exits-dataerr"
 :description "An -x expression the reader refuses (here an unbalanced
parenthesis) is a data format error: exit status EX_DATAERR (65), and a
`read error' diagnostic naming the place (<-x>:LINE:COLUMN) on stderr --
not the host Lisp's printed structure (sysexits-exit-statuses.issue)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(princ")
 :expected-exit 65
 :expected-stderr-includes ("read error" "<-x>:1:")
 :covers-options ("--clautolisp" "-x"))
