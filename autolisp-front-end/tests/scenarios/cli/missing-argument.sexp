(:name "cli-missing-argument"
 :description "An action option without its required argument exits 2
with a 'Missing argument' diagnostic."
 :classification :portable
 :argv ("-l")
 :expected-exit 2
 :expected-stderr-includes ("Missing argument" "-l"))
