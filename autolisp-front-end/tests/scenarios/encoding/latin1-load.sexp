(:name "encoding-latin1-load"
 :description "Loading with -e iso-8859-1 selects the documented
8-bit external format. The fixture content is ASCII so the byte
sequence is identical across encodings; the scenario verifies the
encoding option is plumbed without breaking the load path."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-e" "iso-8859-1" "-l" "fixture.lsp")
 :setup-files
   (("fixture.lsp"
     "(setq m 1)
"))
 :expected-exit 0
 :covers-options ("--clautolisp" "-e" "-l"))
