(:name "file-copy-directory-destination"
 :description "Return nil when copying to a directory destination."
 :kind :builtin
 :classification :portable
 :tags (:builtin :file :copy :negative)
 :setup-files ((:relative-path "source.txt" :input-text "copy")
               (:type :directory :relative-path "target/"))
 :builtin-name "VL-FILE-COPY"
 :arguments ("source.txt" "target/")
 :expected-value (:nil))
