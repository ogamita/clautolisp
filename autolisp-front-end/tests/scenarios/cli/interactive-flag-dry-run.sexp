(:name "cli-interactive-flag-parses"
 :description "-i / --interactive is parsed and surfaces in the
dry-run plan. We don't drive the REPL here — that needs a real
stdin TTY — but the parser plumbing must accept the flag."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-i" "--dry-run")
 :expected-exit 0
 :expected-stdout-includes ("interactive")
 :covers-options ("--clautolisp" "-i" "--interactive" "--dry-run"))
