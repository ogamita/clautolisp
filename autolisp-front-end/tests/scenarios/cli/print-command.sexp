(:name "cli-print-command-requires-cad-backend"
 :description "--print-command prints the command line a CAD backend
would be launched with. The clautolisp backend runs in-process and has
no external command line, so asking for one there is a usage error
(exit 2) rather than an empty answer — a caller doing
`cmd=$(alfe --print-command ...)' must fail loudly. The success path
needs a real CAD install and is exercised by the FiveAM suite
(bricscad-print-command-plan-* in backend-cad-tests.lisp)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--print-command" "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("--print-command"
                            "no external command line")
 :covers-options ("--print-command" "--clautolisp"))
