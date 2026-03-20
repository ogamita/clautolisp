(:name "file-systime-basic"
 :description "Return a seven-element file timestamp list."
 :kind :builtin
 :classification :host-sensitive
 :tags (:builtin :file :systime)
 :setup-files ((:relative-path "stamp.txt" :input-text "stamp"))
 :builtin-name "VL-FILE-SYSTIME"
 :arguments ("stamp.txt")
 :expected-value (:predicate :list-length 7))
