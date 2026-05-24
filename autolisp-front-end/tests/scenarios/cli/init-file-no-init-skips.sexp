(:name "init-file-no-init-skips"
 :description "--no-init skips every init file. With ~/.autolisp.lsp
present, the symbol it would have set stays unbound — proved here
via (boundp 'init-marker) because clautolisp's evaluator returns
NIL for an unbound symbol rather than signalling, so we can't rely
on an exit-1 path for the negative case."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--no-init"
        "-x" "(if (boundp 'init-marker) (princ \"loaded\") (princ \"not-loaded\"))")
 :setup-files
   ((".autolisp.lsp" "(setq init-marker \"would-have-loaded\")
"))
 :expected-exit 0
 :expected-stdout-includes ("not-loaded")
 :expected-stdout-excludes ("would-have-loaded")
 :covers-options ("--clautolisp" "--no-init" "-x"))
