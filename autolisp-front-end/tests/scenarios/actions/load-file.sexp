(:name "actions-load-then-eval"
 :description "A -l action reads + evaluates the file; a subsequent
-x sees the side effects. Tests the shared-context invariant
across load + eval."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-l" "fixture.lsp" "-x" "z")
 :setup-files
   (("fixture.lsp"
     "(setq z 41)
(setq z (+ z 1))
"))
 :expected-exit 0
 :expected-stdout-includes ("42")
 :covers-options ("--clautolisp" "-l" "--load" "-x"))
