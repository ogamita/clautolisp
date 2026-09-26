(:name "cli-list-hosts"
 :description "alfe --list-hosts prints the three --host backends with a
one-line summary each and exits 0, opening no REPL. It does NOT print
clautolisp's aliases note: alfe takes cador, cadtui and nihil and refuses
mock / null / none, so naming them would advertise spellings it rejects.
Up to alfe 2.2.106 the option was accepted and did nothing, and a bare
`alfe --list-hosts' opened the REPL instead (alfe-list-hosts-ignored)."
 :classification :portable
 :argv ("--list-hosts")
 :expected-exit 0
 :expected-stdout-includes ("Available --host backends:" "cador" "cadtui" "nihil")
 :expected-stdout-excludes ("aliases:" "mock" "alfe>")
 :covers-options ("--list-hosts"))
