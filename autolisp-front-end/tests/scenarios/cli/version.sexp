(:name "cli-version"
 :description "Bare --version prints the alfe version and exits 0."
 :classification :portable
 :argv ("--version")
 :version "1.0.0"
 :expected-exit 0
 :expected-stdout-includes ("alfe 1.0.0")
 :covers-options ("--version" "-V"))
