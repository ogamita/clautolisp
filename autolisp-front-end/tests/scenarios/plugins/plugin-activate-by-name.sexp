(:name "plugin-activate-by-name"
 :description "--plugin NAME activates an installed plug-in without its own
flag: the epuree plug-in is then in force and, having nothing to load its
ALPM from, refuses the run."
 :classification :portable
 :argv ("--plugin" "epuree" "--epuree-alpm" "/nonexistent/alpm.lsp"
        "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("alpm.lsp not found: /nonexistent/alpm.lsp")
 :covers-options ("--plugin" "--epuree-alpm" "--dry-run"))
