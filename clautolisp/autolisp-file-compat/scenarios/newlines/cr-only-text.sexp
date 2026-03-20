(:name "cr-only-text"
 :description "Round-trip text normalized to CR line endings."
 :classification :portable
 :tags (:text :newline :cr)
 :relative-path "artifacts/cr-only-text.txt"
 :external-format :utf-8
 :newline-mode :cr
 :input-text "alpha
beta
"
 :expected-lines ("alpha" "beta")
 :expected-bytes (97 108 112 104 97 13 98 101 116 97 13))
