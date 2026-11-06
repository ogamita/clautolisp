(:name "actions-quit-ends-the-plan"
 :description "--quit ends the plan: the actions after it never run, in
either clautolisp variant (the subprocess child is handed only the actions
before the first :quit -- alfe-clautolisp-backend-semantic-parity.issue)."
 :classification :clautolisp-only
 :argv ("--clautolisp"
        "-x" "(princ \"before-quit\")"
        "--quit"
        "-x" "(princ \"after-quit\")")
 :expected-exit 0
 :expected-stdout-includes ("before-quit")
 :expected-stdout-excludes ("after-quit")
 :covers-options ("--clautolisp" "-x" "--quit"))
