(:name "clautolisp-on-error-debug-stops-in-aldo"
 :description "--on-error debug is the clautolisp program's option: under
--clautolisp an uncaught AutoLISP error stops in the aldo debugger (here the
dumb UI, chosen with --debugger-ui so a user aldo.conf cannot change it) at the
error; `q' aborts the program, so the next action never runs and the run exits
0. Same outcome under --backend subprocess, where the options are forwarded to
the clautolisp child."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--on-error" "debug" "--debugger-ui" "dumb"
        "-x" "(princ \"before\")" "-x" "(/ 1 0)" "-x" "(princ \"never-printed\")")
 :stdin "q
"
 :expected-exit 0
 :expected-stdout-includes ("DBG>" "before")
 :expected-stdout-excludes ("never-printed")
 :covers-options ("--on-error" "--debugger-ui"))
