(:name "cli-result-file-missing-fails-a-successful-run"
 :description "--result-file FILE names a file the run must have written (a
JUnit report...). Checked after the run, before a CAD the run created is
closed: here the script succeeds but writes nothing, so the run exits 66
(EX_NOINPUT) and says which file is missing. A run whose script failed keeps
its own status (alfe-owned-cad-termination-after-recorded-results)."
 :classification :clautolisp-only
 :argv ("--clautolisp" "--result-file" "junit.xml" "--cleanup-report" "cleanup.txt"
        "-x" "(princ (+ 1 2))")
 :expected-exit 66
 :expected-stdout-includes ("3")
 :expected-stderr-includes ("--result-file" "missing")
 :covers-options ("--clautolisp" "--result-file" "--cleanup-report" "-x"))
