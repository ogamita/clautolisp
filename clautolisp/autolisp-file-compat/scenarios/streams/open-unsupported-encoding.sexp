(:name "open-unsupported-encoding"
 :description "Return nil when OPEN is given an unsupported encoding designator."
 :kind :builtin
 :classification :implementation-sensitive
 :tags (:builtin :stream :file-descriptor :negative :encoding)
 :builtin-name "OPEN"
 :arguments ("encoded.txt" "w" "definitely-not-a-real-external-format")
 :expected-value (:nil))
