(:name "cli-version-short"
 :description "The -V short form behaves identically to --version."
 :classification :portable
 :argv ("-V")
 :version "1.0.0"
 :expected-exit 0
 :expected-stdout-includes ("alfe 1.0.0")
 :covers-options ("-V"))
