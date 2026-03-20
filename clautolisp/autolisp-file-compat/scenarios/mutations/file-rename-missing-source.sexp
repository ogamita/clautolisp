(:name "file-rename-missing-source"
 :description "Return nil when renaming a missing source file."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :negative)
 :builtin-name "VL-FILE-RENAME"
 :arguments ("old.txt" "new.txt")
 :expected-value (:nil))
