(:name "init-file-program-and-shared"
 :description "Both ~/.alfe.lsp and ~/.autolisp.lsp present —
both load, in stem-list order. Per the documented contract, the
LATER load wins. The shared ~/.autolisp.lsp slot loads FIRST in
the lookup list, so the program-specific ~/.alfe.lsp slot (loaded
later) wins. This matches the conventional Unix layering:
more-specific overrides less-specific."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "init-marker")
 :setup-files
   ((".alfe.lsp"     "(setq init-marker \"from-alfe-rc\")
")
    (".autolisp.lsp" "(setq init-marker \"from-autolisp-rc\")
"))
 :expected-exit 0
 :expected-stdout-includes ("from-alfe-rc")
 :expected-stdout-excludes ("from-autolisp-rc")
 :covers-options ("--clautolisp" "-x"))
