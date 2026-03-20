(:name "basic-text-roundtrip"
 :description "Round-trip a small UTF-8 text file with LF newlines."
 :classification :portable
 :tags (:text :utf-8 :lf)
 :relative-path "artifacts/basic-text-roundtrip.txt"
 :external-format :utf-8
 :newline-mode :lf
 :input-text "alpha
beta
"
 :expected-text "alpha
beta
")
