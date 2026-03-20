(:name "directory-files-basic"
 :description "List mixed file and directory entries with wildcard filtering."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory-files)
 :setup-files ((:type :directory :relative-path "subdir/")
               (:relative-path "alpha.lsp" :input-text "alpha")
               (:relative-path "README" :input-text "readme"))
 :current-directory "./"
 :builtin-name "VL-DIRECTORY-FILES"
 :arguments ("." "*.*" 0)
 :expected-value (:predicate :unordered-strings ("README" "alpha.lsp" "subdir")))
