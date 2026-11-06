(:name "encoding-cad-log-under-clautolisp"
 :description "--cad-log FILE collects the CAD's own command-history log;
the clautolisp backend has no CAD log, so it warns and writes no file (both
variants), and the run still completes. -Elog names the encoding of that
log."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-Elog" "utf-8" "--cad-log" "cad.log"
        "-x" "(princ (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :expected-stderr-includes ("--cad-log" "ignored")
 :covers-options ("--clautolisp" "-Elog" "--cad-log" "-x"))
