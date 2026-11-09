(:name "cli-ready-timeout-has-no-effect-under-clautolisp"
 :description "--ready-timeout SECS bounds a CAD's start (READY), apart from
--timeout, a request's (alfe-cad-lifecycle-rules, timeouts). The clautolisp
engine has no CAD start to wait for: the option is accepted and has no
effect, in both variants."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--ready-timeout" "30" "-x" "(princ (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "--ready-timeout" "-x"))
