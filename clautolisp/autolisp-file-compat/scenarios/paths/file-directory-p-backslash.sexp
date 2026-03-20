(:name "file-directory-p-backslash"
 :description "Recognize a directory pathname written with backslashes."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory :backslash)
 :setup-files ((:type :directory :relative-path "folder/"))
 :current-directory "./"
 :builtin-name "VL-FILE-DIRECTORY-P"
 :arguments ("folder\\")
 :expected-value (:symbol "T"))
