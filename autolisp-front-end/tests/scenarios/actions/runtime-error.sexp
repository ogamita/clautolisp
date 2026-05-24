(:name "actions-runtime-error-exits-one"
 :description "When user code raises a runtime error, alfe exits
with code 1 and surfaces a structured 'runtime error' line on
stderr."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(/ 1 0)")
 :expected-exit 1
 :expected-stderr-includes ("runtime error")
 :covers-options ("--clautolisp" "-x"))
