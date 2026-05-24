(:name "cli-unknown-option"
 :description "An unknown long option exits 2 (CLI usage error) and
mentions the option on stderr."
 :classification :portable
 :argv ("--no-such-option")
 :expected-exit 2
 :expected-stderr-includes ("Unknown option" "--no-such-option")
 :expected-stdout-excludes ("Usage:"))
