(:name "clautolisp-host-cador"
 :description "--host cador (the default) attaches the headless CAD core so
HAL-bound builtins have a deterministic backend, and *AUTOLISP-HOST* says so.
We don't exercise a HAL builtin here — just the option's plumbing."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "cador" "-x" "(princ *autolisp-host*)"
        "-x" "(print (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("CADOR" "3")
 :covers-options ("--clautolisp" "--host"))
