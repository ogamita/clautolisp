(:name "clautolisp-host-nihil"
 :description "--host nihil wires the trivial backend: no CAD host at all, so
a host operation is refused while pure computation is unaffected."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--host" "nihil" "-x" "(princ *autolisp-host*)"
        "-x" "(print (+ 1 2))" "-x" "(getvar \"CLAYER\")")
 :expected-exit 1
 :expected-stdout-includes ("NIHIL" "3")
 :expected-stderr-includes ("HOST-NOT-SUPPORTED")
 :covers-options ("--clautolisp" "--host"))
