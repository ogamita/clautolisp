(:name "clautolisp-on-error-quit-reports-and-exits"
 :description "--on-error quit (the batch default, made explicit): the error is
reported in the engine's words and the run exits 1 without running the next
action -- no debugger, nothing read from stdin."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--on-error" "quit"
        "-x" "(/ 1 0)" "-x" "(princ \"never-printed\")")
 :expected-exit 1
 :expected-stderr-includes ("DIVISION-BY-ZERO")
 :expected-stdout-excludes ("never-printed")
 :covers-options ("--on-error"))
