(:name "clautolisp-program-runs-dry-run"
 :description "--dribble, --dcl ncurses and -i are accepted with --clautolisp
and reach the plan. Such a run is the clautolisp program's, which alfe runs as
the subprocess variant -- a dry run needs no engine, so this holds without a
clautolisp-sbcl too."
 :classification :portable
 :argv ("--clautolisp" "--dribble=rec.log" "--dcl" "ncurses" "--dry-run"
        "-x" "(+ 1 2)" "-i")
 :expected-exit 0
 :expected-stdout-includes ("interactive")
 :covers-options ("--clautolisp" "--dribble" "--dcl" "--interactive" "--dry-run"))
