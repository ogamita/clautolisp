(:name "file-copy-append"
 :description "Append copied bytes to an existing destination file."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :append)
 :setup-files ((:relative-path "source.txt" :input-text "copy")
               (:relative-path "target.txt" :input-text "old"))
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt" (:symbol "T"))
 :expected-value 4
 :artifact-relative-path "target.txt"
 :expected-artifact-exists-p t
 :expected-text "oldcopy")
