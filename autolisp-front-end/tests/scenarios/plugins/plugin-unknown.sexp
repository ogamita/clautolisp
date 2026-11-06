(:name "plugin-unknown"
 :description "--plugin NAME for a plug-in that is not installed is a usage
error (EX_USAGE, 64) that names it and lists the installed ones."
 :classification :portable
 :argv ("--plugin" "no-such-plugin" "-x" "(+ 1 2)")
 :expected-exit 64
 :expected-stderr-includes ("Unknown plug-in no-such-plugin" "epure")
 :covers-options ("--plugin"))
