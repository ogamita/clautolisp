(:name "actions-eval-arithmetic"
 :description "alfe --clautolisp -x '(print (+ 1 2))' prints 3 on
stdout and exits 0. Per the alfe spec (Action output semantics),
-x EXPR does NOT auto-print; the user must (print …) explicitly,
hence the explicit wrapping. Headline acceptance criterion from
alfe.plan; scenario keeps a regression watch on it."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(print (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "-x" "--eval"))
