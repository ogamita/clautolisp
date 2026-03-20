(:name "latin-1-text"
 :description "Round-trip text through latin-1 decoding."
 :classification :implementation-sensitive
 :tags (:text :encoding :latin-1)
 :relative-path "artifacts/latin-1-text.txt"
 :external-format :latin-1
 :newline-mode :lf
 :input-text "Café
"
 :expected-text "Café
"
 :expected-lines ("Café")
 :expected-bytes (67 97 102 233 10))
