(:name "crlf-text"
 :description "Round-trip text with CRLF newline normalization and exact byte expectations."
 :classification :portable
 :tags (:text :newline :crlf :bytes)
 :relative-path "artifacts/crlf-text.txt"
 :external-format :utf-8
 :newline-mode :crlf
 :input-text "alpha
beta
"
 :expected-lines ("alpha" "beta")
 :expected-bytes (97 108 112 104 97 13 10 98 101 116 97 13 10))
