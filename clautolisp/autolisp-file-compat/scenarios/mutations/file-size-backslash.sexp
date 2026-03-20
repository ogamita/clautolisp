(:name "file-size-backslash"
 :description "Report file size when the pathname uses backslash separators."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :size :backslash)
 :setup-files ((:type :directory :relative-path "folder/")
               (:relative-path "folder/example.txt" :input-text "12345"))
 :builtin-name "VL-FILE-SIZE"
 :arguments ("folder\\example.txt")
 :expected-value 5)
