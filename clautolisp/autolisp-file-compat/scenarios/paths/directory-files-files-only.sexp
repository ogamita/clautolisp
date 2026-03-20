(:name "directory-files-files-only"
 :description "Filter directory entries down to matching files only."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory-files)
 :setup-files ((:type :directory :relative-path "subdir/")
               (:relative-path "alpha.lsp" :input-text "alpha")
               (:relative-path "beta.txt" :input-text "beta"))
 :current-directory "./"
 :builtin-name "VL-DIRECTORY-FILES"
 :arguments ("." "*.lsp" 1)
 :expected-value (:predicate :unordered-strings ("alpha.lsp")))
