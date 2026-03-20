(:name "file-rename-basic"
 :description "Rename a file and verify the renamed artifact."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename)
 :setup-files ((:relative-path "old.txt" :input-text "rename me"))
 :builtin-name "VL-FILE-RENAME"
 :arguments ("old.txt" "new.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "new.txt"
 :expected-text "rename me")
