(:name "open-missing-for-read"
 :description "Return nil when opening a missing file for reading."
 :kind :builtin
 :classification :portable
 :tags (:builtin :stream :file-descriptor :negative)
 :builtin-name "OPEN"
 :arguments ("missing.txt" "r")
 :expected-value (:nil))
