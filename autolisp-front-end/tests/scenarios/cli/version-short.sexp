(:name "cli-version-short"
 :description "The -V short form behaves identically to --version."
 :classification :portable
 :argv ("-V")
 :version "0.0.5"
 :expected-exit 0
 :expected-stdout-includes ("alfe 0.0.5")
 :covers-options ("-V"))
