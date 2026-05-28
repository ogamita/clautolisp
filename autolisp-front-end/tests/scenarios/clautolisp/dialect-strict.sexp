(:name "clautolisp-dialect-strict"
 :description "--dialect strict selects the portable
AutoCAD ∩ BricsCAD profile. A trivial -x checks the option is
plumbed without errors."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--dialect" "strict" "-x" "(print (+ 1 2))")
 :expected-exit 0
 :expected-stdout-includes ("3")
 :covers-options ("--clautolisp" "--dialect"))
