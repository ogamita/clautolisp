(:name "cli-help"
 :description "--help prints the usage banner and exits 0. The
banner lists every documented backend selector + action flag."
 :classification :portable
 :argv ("--help")
 :expected-exit 0
 :expected-stdout-includes ("Usage: alfe"
                            "--clautolisp"
                            "--bricscad"
                            "--autocad"
                            "-l, --load"
                            "-x, --eval"
                            "--dry-run")
 :covers-options ("--help" "-h"))
