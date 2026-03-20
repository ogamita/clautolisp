(:name "file-copy-basic"
 :description "Copy a file and compare the resulting artifact."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy)
 :setup-files ((:relative-path "source.txt" :input-text "copy me"))
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt")
 :expected-value 7
 :artifact-relative-path "target.txt"
 :expected-artifact-exists-p t
 :expected-text "copy me")
