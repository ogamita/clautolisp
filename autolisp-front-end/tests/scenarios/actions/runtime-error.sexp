(:name "actions-runtime-error-exits-one"
 :description "When user code raises a runtime error, alfe exits
with status 1 and surfaces a structured 'runtime error' line on
stderr. 1 is deliberately not a sysexits code: the command line, the
files and the engine were all fine, the program ran and failed
(sysexits-exit-statuses.issue)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(/ 1 0)")
 :expected-exit 1
 :expected-stderr-includes ("runtime error")
 :covers-options ("--clautolisp" "-x"))
