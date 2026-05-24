(:name "cli-version"
 :description "Bare --version prints the alfe version and exits 0."
 :classification :portable
 :argv ("--version")
 :version "0.0.5"
 :expected-exit 0
 :expected-stdout-includes ("alfe 0.0.5")
 :covers-options ("--version" "-V"))
