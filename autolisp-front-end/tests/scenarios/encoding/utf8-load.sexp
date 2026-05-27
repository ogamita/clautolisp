(:name "encoding-utf8-load"
 :description "Load a UTF-8-encoded fixture via -l with -e utf-8.
Side effect (setq message \"ok\") is verified by a follow-up -x."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-e" "utf-8" "-l" "fixture.lsp" "-x" "(print message)")
 :setup-files
   (("fixture.lsp"
     "(setq message \"ok\")
"))
 :expected-exit 0
 :expected-stdout-includes ("ok")
 :covers-options ("--clautolisp" "-e" "-l" "-x"))
