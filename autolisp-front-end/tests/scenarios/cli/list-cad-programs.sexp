(:name "list-cad-programs-exits-zero"
 :description "--list-cad-programs scans the host, prints each installed CAD
with its canonical denotation, and exits 0. The embedded clautolisp is always
listed, so the assertion holds on any runner (no CAD needed). Covers the
--list-cad-programs option for the spec-coverage check."
 :classification :portable
 :argv ("--list-cad-programs")
 :expected-exit 0
 :expected-stdout-includes ("clautolisp")
 :covers-options ("--list-cad-programs"))
