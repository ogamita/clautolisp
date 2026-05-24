(:name "bricscad-dry-run-renders-backend"
 :description "--bricscad --dry-run resolves the BricsCAD backend
(registered eagerly on package load) and prints the action plan,
even on a host without a BricsCAD install. Lets us cover the
--bricscad flag's CLI surface in CI without depending on a CAD
binary."
 :classification :portable
 :argv ("--bricscad" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("alfe --dry-run" "BRICSCAD")
 :covers-options ("--bricscad" "--dry-run"))
