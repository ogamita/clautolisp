(:name "clautolisp-command-mock-log"
 :description "The COMMAND special form under the MockHost records the
normalized token sequence on the per-session command log
(deferred-command-special-form issue): strings verbatim, points as
comma-separated coordinates, \"\" as the RETURN token. The
CLAL-COMMAND-LOG extension reads the log back, oldest first."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "mock" "-x"
        "(progn (command \"._LINE\" (list 0.0 0.0 0.0) (list 10.0 10.0 0.0) \"\") (print (clal-command-log)))")
 :expected-exit 0
 :expected-stdout-includes ("._LINE" "0.0,0.0,0.0" "10.0,10.0,0.0")
 :covers-options ("--clautolisp" "--host"))
