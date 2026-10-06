(:name "cli-missing-argument"
 :description "An action option without its required argument exits EX_USAGE (64)
with a 'Missing argument' diagnostic."
 :classification :portable
 :argv ("-l")
 :expected-exit 64
 :expected-stderr-includes ("Missing argument" "-l"))
