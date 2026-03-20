(:name "file-copy-missing-source"
 :description "Return nil when copying a missing source file."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :negative)
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target.txt")
 :expected-value (:nil))
