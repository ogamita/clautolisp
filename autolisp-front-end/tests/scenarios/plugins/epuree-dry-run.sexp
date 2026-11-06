(:name "epuree-dry-run"
 :description "--epuree puts its actions in front of the plan — load
alpm.lsp, register each --epuree-path, load the system, initialize it — visible
in the dry run and before the user's own action."
 :classification :portable
 :argv ("--epuree" "--epuree-alpm" "alpm.lsp" "--epuree-path" "lisp"
        "--dry-run" "-x" "(+ 1 2)")
 :setup-files (("alpm.lsp" "(princ)
"))
 :expected-exit 0
 :expected-stdout-includes ("alpm.lsp" "alpm-register-directory"
                            "alpm-load-system \\\"epuree\\\"" "(epuree-initialize)"
                            "(+ 1 2)")
 :covers-options ("--epuree" "--epuree-alpm" "--epuree-path"))
