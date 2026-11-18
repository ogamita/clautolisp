(:name "cli-cad-exit-has-no-effect-under-clautolisp"
 :description "--cad-exit {quit,kill} says how a CAD alfe started ends after
the run: asked to quit (the default) or killed at once once the results are
recorded, for a CAD whose own exit crashes. The clautolisp engine has no CAD
to end: the option is accepted and has no effect, in both variants."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--cad-exit" "kill" "-x" "(princ (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "--cad-exit" "-x"))
