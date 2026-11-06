(:name "clautolisp-event-policies-mirrored"
 :description "--on-interrupt and --on-quit set the AutoLISP mirrors
*CLAL-ON-INTERRUPT* and *CLAL-ON-QUIT* (read live at each Control-C / (quit)),
as under the clautolisp program; --on-error sets *CLAL-ON-ERROR*."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--on-error" "ignore" "--on-interrupt" "quit" "--on-quit" "quit"
        "-x" "(princ (list *clal-on-error* *clal-on-interrupt* *clal-on-quit*))")
 :expected-exit 0
 :expected-stdout-includes ("(IGNORE QUIT QUIT)")
 :covers-options ("--on-error" "--on-interrupt" "--on-quit"))
