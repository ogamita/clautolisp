(:name "file-copy-existing-target"
 :description "Return nil when copying onto an existing target without append."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :negative)
 :setup-files ((:relative-path "source.txt" :input-text "copy")
               (:relative-path "target.txt" :input-text "old"))
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt")
 :expected-value (:nil))
