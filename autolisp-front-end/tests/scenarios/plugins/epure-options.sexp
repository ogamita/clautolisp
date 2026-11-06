(:name "epure-options"
 :description "The three options of the epure plug-in parse, with a value for
the profile and the script, and the run goes on (dry run; off Windows the
plug-in ignores itself, on Windows it does not look for the script in a dry
run)."
 :classification :portable
 :argv ("--bricscad" "--dry-run" "--epure" "--epure-profile" "Site"
        "--epure-script" "control_path_epure_2022.scr" "-x" "(+ 1 2)")
 :expected-exit 0
 :expected-stdout-includes ("backend:   BRICSCAD")
 :covers-options ("--epure" "--epure-profile" "--epure-script"))
