(:name "clautolisp-host-null"
 :description "--host null wires the no-op NullHost backend. Same
plumbing as host-mock; the HAL backend itself just doesn't expose
any CAD entities."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "null" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "--host"))
