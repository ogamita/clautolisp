(:name "cli-debugger-options-refused-by-cad-backends"
 :description "The aldo options configure the clautolisp engine's debugger; a
CAD backend runs AutoLISP in the CAD, which has no aldo, so it refuses them with
a usage error (EX_USAGE 64) naming them -- never ignores them. Checked under
--dry-run, which resolves the backend by name, so no CAD is needed."
 :classification :portable
 :argv ("--bricscad" "--dry-run" "--on-interrupt" "quit" "--on-quit" "debug"
        "--debugger-ui" "ncurses" "--aldb-listen" "4301" "-x" "(princ 1)")
 :expected-exit 64
 :expected-stderr-includes ("--on-interrupt, --on-quit, --debugger-ui, --aldb-listen" "aldo")
 :covers-options ("--on-interrupt" "--on-quit" "--debugger-ui" "--aldb-listen"))
