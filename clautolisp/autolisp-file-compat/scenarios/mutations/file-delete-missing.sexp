(:name "file-delete-missing"
 :description "Return nil when deleting a missing file."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :delete :negative)
 :builtin-name "VL-FILE-DELETE"
 :arguments ("missing.txt")
 :expected-value (:nil))
