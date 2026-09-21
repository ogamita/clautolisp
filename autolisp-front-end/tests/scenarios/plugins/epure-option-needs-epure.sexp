(:name "epure-option-needs-epure"
 :description "An option of a plug-in that is not active is a usage error
that names the flag to add."
 :classification :portable
 :argv ("--epure-profile" "Site" "--dry-run")
 :expected-exit 2
 :expected-stderr-includes ("--epure-profile" "add --epure")
 :covers-options ("--epure-profile"))
