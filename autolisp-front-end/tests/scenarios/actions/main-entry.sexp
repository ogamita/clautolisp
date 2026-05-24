(:name "actions-main-calls-entry-point"
 :description "--main FN looks the function up in the shared
context (defined via a prior -l) and calls it as the script entry
point."
 :classification :clautolisp-only
 :argv ("--clautolisp" "-l" "entry.lsp" "--main" "THE-ENTRY")
 :setup-files
   (("entry.lsp"
     "(defun the-entry () (princ \"entry-result\") 0)
"))
 :expected-exit 0
 :expected-stdout-includes ("entry-result")
 :covers-options ("--clautolisp" "-l" "--main"))
