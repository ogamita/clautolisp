(:name "cli-unknown-option"
 :description "An unknown long option exits EX_USAGE (64, CLI usage error) and
mentions the option on stderr."
 :classification :portable
 :argv ("--no-such-option")
 :expected-exit 64
 :expected-stderr-includes ("Unknown option" "--no-such-option")
 :expected-stdout-excludes ("Usage:"))
