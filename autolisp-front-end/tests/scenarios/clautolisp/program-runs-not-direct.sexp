(:name "clautolisp-program-runs-not-direct"
 :description "A run that is the clautolisp program's -- here a recording,
--dribble -- cannot be honoured by alfe's embedded engine: with an explicit
--backend direct it is a usage error, reported before any engine starts,
naming the reason and the contradiction."
 :classification :portable
 :argv ("--clautolisp" "--dribble=rec.log" "--backend" "direct" "--dry-run"
        "-x" "(+ 1 2)")
 :expected-exit 64
 :expected-stderr-includes ("--dribble" "--backend direct")
 :covers-options ("--dribble" "--backend"))
