(:name "file-size-basic"
 :description "Report the size of a file in bytes."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :size)
 :setup-files ((:relative-path "sized.txt" :input-text "12345"))
 :builtin-name "VL-FILE-SIZE"
 :arguments ("sized.txt")
 :expected-value 5)
