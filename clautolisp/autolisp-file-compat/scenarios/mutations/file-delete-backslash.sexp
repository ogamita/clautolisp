(:name "file-delete-backslash"
 :description "Delete a file referenced with backslash separators."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :delete :backslash)
 :setup-files ((:type :directory :relative-path "folder/")
               (:relative-path "folder/example.txt" :input-text "remove me"))
 :builtin-name "VL-FILE-DELETE"
 :arguments ("folder\\example.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "folder/example.txt")
