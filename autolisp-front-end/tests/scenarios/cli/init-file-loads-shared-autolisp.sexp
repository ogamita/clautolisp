(:name "init-file-loads-shared-autolisp"
 :description "When ~/.autolisp.lsp exists, alfe loads it before
the user's -x action. The runner sandboxes $HOME to the scenario's
workdir so .autolisp.lsp is created relative to the sandboxed
home, not the test host's real $HOME."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(print init-marker)")
 :setup-files
   ((".autolisp.lsp" "(setq init-marker \"shared-init-ran\")
"))
 :expected-exit 0
 :expected-stdout-includes ("shared-init-ran")
 :covers-options ("--clautolisp" "-x"))
