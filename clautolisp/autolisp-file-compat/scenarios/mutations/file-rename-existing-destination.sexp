(:name "file-rename-existing-destination"
 :description "Return nil when renaming onto an existing destination."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :rename :negative)
 :setup-files ((:relative-path "old.txt" :input-text "old")
               (:relative-path "new.txt" :input-text "new"))
 :builtin-name "VL-FILE-RENAME"
 :arguments ("old.txt" "new.txt")
 :expected-value (:nil))
