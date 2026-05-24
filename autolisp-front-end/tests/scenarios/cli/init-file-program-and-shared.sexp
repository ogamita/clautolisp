(:name "init-file-program-and-shared"
 :description "Both ~/.alfe.lsp and ~/.autolisp.lsp present —
both load, in stem-list order. Per the documented contract, the
LATER load wins. The shared ~/.autolisp.lsp slot follows the
program-specific ~/.alfe.lsp slot in the lookup list, so its
value overrides. (This is opposite to the more common Unix
convention; flagged in init-files.issue's notes for review.)"
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "init-marker")
 :setup-files
   ((".alfe.lsp"     "(setq init-marker \"from-alfe-rc\")
")
    (".autolisp.lsp" "(setq init-marker \"from-autolisp-rc\")
"))
 :expected-exit 0
 :expected-stdout-includes ("from-autolisp-rc")
 :covers-options ("--clautolisp" "-x"))
