(:name "clautolisp-host-mock"
 :description "--host mock attaches a MockHost so HAL-bound builtins
have a deterministic backend. We don't exercise any HAL builtin
here — just the option's plumbing — by running a trivial -x with
the host explicitly chosen."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "mock" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "--host"))
