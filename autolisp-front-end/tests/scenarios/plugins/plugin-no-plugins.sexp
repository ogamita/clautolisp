(:name "plugin-no-plugins"
 :description "--no-plugins loads no plug-in, so the options a plug-in defines
are unknown."
 :classification :portable
 :argv ("--no-plugins" "--epure" "--dry-run" "-x" "(+ 1 2)")
 :expected-exit 2
 :expected-stderr-includes ("Unknown option --epure")
 :covers-options ("--no-plugins"))
