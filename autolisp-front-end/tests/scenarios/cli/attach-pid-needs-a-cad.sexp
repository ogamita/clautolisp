(:name "cli-attach-pid-needs-a-cad"
 :description "--attach-pid PID names a running CAD to attach to
(alfe-cad-launch-new-by-default): without a CAD backend it is a usage error."
 :classification :portable
 :argv ("--clautolisp" "--dry-run" "--attach-pid" "4242" "-x" "(princ 1)")
 :expected-exit 64
 :expected-stderr-includes ("--attach-pid" "--autocad")
 :covers-options ("--attach-pid"))
