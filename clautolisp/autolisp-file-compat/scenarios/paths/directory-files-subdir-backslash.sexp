(:name "directory-files-subdir-backslash"
 :description "List files in a subdirectory selected with backslash separators."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory-files :backslash)
 :setup-files ((:type :directory :relative-path "subdir/")
               (:relative-path "subdir/alpha.lsp" :input-text "alpha")
               (:relative-path "subdir/beta.txt" :input-text "beta"))
 :current-directory "./"
 :builtin-name "VL-DIRECTORY-FILES"
 :arguments ("subdir\\" "*.lsp" 1)
 :expected-value (:predicate :unordered-strings ("alpha.lsp")))
