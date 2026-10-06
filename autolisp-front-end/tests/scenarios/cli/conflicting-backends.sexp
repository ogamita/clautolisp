(:name "cli-conflicting-backends"
 :description "Passing two different backend selectors exits EX_USAGE (64) with
a 'Conflicting backend selectors' diagnostic."
 :classification :portable
 :argv ("--bricscad" "--autocad")
 :expected-exit 64
 :expected-stderr-includes ("Conflicting backend selectors"))
