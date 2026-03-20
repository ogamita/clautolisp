(:name "utf8-roundtrip"
 :description "Round-trip a UTF-8 text file containing non-ASCII characters."
 :relative-path "artifacts/utf8-roundtrip.txt"
 :external-format :utf-8
 :newline-mode :lf
 :input-text "Héllo
monde
"
 :expected-text "Héllo
monde
")
