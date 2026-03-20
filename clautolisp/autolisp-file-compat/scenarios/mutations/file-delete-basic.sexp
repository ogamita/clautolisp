(:name "file-delete-basic"
 :description "Delete a file and verify that it no longer exists."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :delete)
 :setup-files ((:relative-path "obsolete.txt" :input-text "remove me"))
 :current-directory "./"
 :builtin-name "VL-FILE-DELETE"
 :arguments ("obsolete.txt")
 :expected-value (:symbol "T")
 :artifact-relative-path "obsolete.txt"
 :expected-artifact-exists-p nil)
