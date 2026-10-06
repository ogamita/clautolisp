(:name "clautolisp-dcl-and-dribble-options-accepted"
 :description "--dcl, --dribble and --dribble-interactors are accepted with
--clautolisp and do not disturb the action plan: the -x form runs and the
run exits 0. (Their effect differs by variant -- the in-process engine has
no DCL renderer and records no dribble; see the spec's semantic-parity
section -- so only acceptance is asserted here.)"
 :classification :clautolisp-only
 :argv ("--clautolisp" "--dcl" "tui" "--dribble=rec.log"
        "--dribble-interactors" "AUTOLISP"
        "-x" "(princ \"dcl-dribble-ok\")")
 :expected-exit 0
 :expected-stdout-includes ("dcl-dribble-ok")
 :covers-options ("--dcl" "--dribble" "--dribble-interactors"))
