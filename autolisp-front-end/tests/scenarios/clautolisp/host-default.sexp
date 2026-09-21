(:name "clautolisp-host-default"
 :description "With no --host the host is cador, and *AUTOLISP-HOST* reports
CADOR."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-x" "(princ *autolisp-host*)")
 :expected-exit 0
 :expected-stdout-includes ("CADOR")
 :covers-options ("--clautolisp"))
