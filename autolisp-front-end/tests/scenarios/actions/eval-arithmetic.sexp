(:name "actions-eval-arithmetic"
 :description "alfe --clautolisp -x '(+ 1 2)' prints 3 on stdout
and exits 0. This is the V1 headline acceptance criterion from
alfe.plan; the scenario keeps a regression watch on it."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "-x" "--eval"))
