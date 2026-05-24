(:name "actions-multiple-eval-share-context"
 :description "Two -x actions run against one shared evaluation
context: the variable set by the first is visible to the second.
This is the legacy bash wrapper's contract; alfe must preserve it."
 :classification :clautolisp-only
 :argv ("--clautolisp"
        "-x" "(setq x 40)"
        "-x" "(+ x 2)")
 :expected-exit 0
 :expected-stdout-includes ("42")
 :covers-options ("--clautolisp" "-x"))
