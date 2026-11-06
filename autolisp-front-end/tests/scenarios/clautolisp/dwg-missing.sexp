(:name "clautolisp-dwg-missing-exits-noinput"
 :description "A --dwg drawing that does not exist cannot be opened: exit
status EX_NOINPUT (66), as for a -l file (sysexits-exit-statuses.issue),
in both engine variants."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "cador" "--dwg" "/nonexistent/drawing.dxf"
        "-x" "(princ 1)")
 :expected-exit 66
 :expected-stderr-includes ("--dwg" "cannot open the drawing")
 :covers-options ("--clautolisp" "--dwg"))
