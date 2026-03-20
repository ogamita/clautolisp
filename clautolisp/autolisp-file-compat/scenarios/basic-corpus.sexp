((:name "lf-lines"
  :description "A basic LF text scenario grouped in a small corpus file."
  :classification :portable
  :tags (:text :lf)
  :relative-path "artifacts/lf-lines.txt"
  :external-format :utf-8
  :newline-mode :lf
  :input-text "one
two
"
  :expected-text "one
two
")
 (:name "binary-octets"
  :description "A grouped byte-level scenario in the same corpus file."
  :classification :implementation-sensitive
  :tags (:bytes :binary)
  :relative-path "artifacts/binary-octets.bin"
  :input-bytes (10 20 30 40)
  :expected-bytes (10 20 30 40)))
