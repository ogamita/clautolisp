(:name "cli-on-error-accepted-by-cad-backends"
 :description "--on-error is accepted by every backend: under a CAD backend
it governs how alfe reports its own unexpected conditions (debug and ignore add
the CL backtrace)."
 :classification :portable
 :argv ("--autocad" "--dry-run" "--on-error" "debug" "-x" "(princ 1)")
 :expected-exit 0
 :covers-options ("--on-error"))
