((:name "filename-base-backslash"
  :description "Extract the base name from a backslash-delimited pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename :backslash)
  :builtin-name "VL-FILENAME-BASE"
  :arguments ("alpha\\beta\\example.txt")
  :expected-value (:string "example"))
 (:name "filename-directory-backslash"
  :description "Extract the directory part from a backslash-delimited pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename :backslash)
  :builtin-name "VL-FILENAME-DIRECTORY"
  :arguments ("alpha\\beta\\example.txt")
  :expected-value (:string "alpha/beta"))
 (:name "filename-extension-backslash"
  :description "Extract the extension from a backslash-delimited pathname string."
  :kind :builtin
  :classification :portable
  :tags (:builtin :paths :filename :backslash)
  :builtin-name "VL-FILENAME-EXTENSION"
  :arguments ("alpha\\beta\\example.txt")
  :expected-value (:string ".txt")))
