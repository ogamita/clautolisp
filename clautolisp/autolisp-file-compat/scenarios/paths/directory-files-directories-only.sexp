(:name "directory-files-directories-only"
 :description "Filter directory entries down to directories only."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory-files)
 :setup-files ((:type :directory :relative-path "subdir/")
               (:relative-path "alpha.lsp" :input-text "alpha"))
 :current-directory "./"
 :builtin-name "VL-DIRECTORY-FILES"
 :arguments ("." "*" -1)
 :expected-value (:predicate :unordered-strings ("subdir")))
