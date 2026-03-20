(:name "file-size-directory"
 :description "Report zero for a directory pathname."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :size :directory)
 :setup-files ((:type :directory :relative-path "folder/"))
 :builtin-name "VL-FILE-SIZE"
 :arguments ("folder/")
 :expected-value 0)
