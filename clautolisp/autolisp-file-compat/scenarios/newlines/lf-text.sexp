(:name "lf-text"
 :description "Round-trip text with LF line endings."
 :classification :portable
 :tags (:text :newline :lf)
 :relative-path "artifacts/lf-text.txt"
 :external-format :utf-8
 :newline-mode :lf
 :input-text "one
two
"
 :expected-text "one
two
"
 :expected-lines ("one" "two")
 :expected-bytes (111 110 101 10 116 119 111 10))
