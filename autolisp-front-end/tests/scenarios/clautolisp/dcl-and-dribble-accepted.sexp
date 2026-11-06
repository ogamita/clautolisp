(:name "clautolisp-dcl-and-dribble-options-accepted"
 :description "--dcl tui and --dribble-interactors (without --dribble) are
accepted with --clautolisp, keep the run in-process and do not disturb the
action plan: the -x form runs and the run exits 0. (--dribble itself, and
--dcl ncurses / gui, make the run the clautolisp program's: see
clautolisp-program-runs-dry-run and clautolisp-program-runs-not-direct.)"
 :classification :clautolisp-only
 :argv ("--clautolisp" "--dcl" "tui"
        "--dribble-interactors" "AUTOLISP"
        "-x" "(princ \"dcl-dribble-ok\")")
 :expected-exit 0
 :expected-stdout-includes ("dcl-dribble-ok")
 :covers-options ("--dcl" "--dribble-interactors"))
