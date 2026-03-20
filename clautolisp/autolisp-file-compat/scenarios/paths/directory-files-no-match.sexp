(:name "directory-files-no-match"
 :description "Return nil when no entries match the wildcard filter."
 :kind :builtin
 :classification :portable
 :tags (:builtin :paths :directory-files :negative)
 :setup-files ((:relative-path "alpha.lsp" :input-text "alpha"))
 :current-directory "./"
 :builtin-name "VL-DIRECTORY-FILES"
 :arguments ("." "*.txt" 1)
 :expected-value (:nil))
