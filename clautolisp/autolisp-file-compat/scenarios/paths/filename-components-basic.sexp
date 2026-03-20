((:name "filename-base-basic"
  :description "Extract the base name from a pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename)
  :builtin-name "VL-FILENAME-BASE"
  :arguments ("alpha/beta/example.txt")
  :expected-value (:string "example"))
 (:name "filename-directory-basic"
  :description "Extract the directory part from a pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename)
  :builtin-name "VL-FILENAME-DIRECTORY"
  :arguments ("alpha/beta/example.txt")
  :expected-value (:string "alpha/beta"))
 (:name "filename-extension-basic"
  :description "Extract the extension from a pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename)
  :builtin-name "VL-FILENAME-EXTENSION"
  :arguments ("alpha/beta/example.txt")
  :expected-value (:string ".txt"))
 (:name "file-directory-p-basic"
  :description "Recognize a directory pathname."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :directory)
  :setup-files ((:type :directory :relative-path "folder/"))
  :current-directory "./"
  :builtin-name "VL-FILE-DIRECTORY-P"
  :arguments ("folder/")
  :expected-value (:symbol "T")))
