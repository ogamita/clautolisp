(:name "cli-conflicting-backends"
 :description "Passing two different backend selectors exits 2 with
a 'Conflicting backend selectors' diagnostic."
 :classification :portable
 :argv ("--bricscad" "--autocad")
 :expected-exit 2
 :expected-stderr-includes ("Conflicting backend selectors"))
