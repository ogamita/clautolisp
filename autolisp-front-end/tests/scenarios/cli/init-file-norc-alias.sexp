(:name "init-file-norc-alias"
 :description "-norc is an alias for --no-init (matches the legacy
bash autolisp wrapper's spelling). Same fixture and assertions as
init-file-no-init-skips: the marker stays unbound."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-norc"
        "-x" "(if (boundp 'init-marker) (princ \"loaded\") (princ \"not-loaded\"))")
 :setup-files
   ((".autolisp.lsp" "(setq init-marker \"would-have-loaded\")
"))
 :expected-exit 0
 :expected-stdout-includes ("not-loaded")
 :expected-stdout-excludes ("would-have-loaded")
 :covers-options ("--clautolisp" "-norc"))
