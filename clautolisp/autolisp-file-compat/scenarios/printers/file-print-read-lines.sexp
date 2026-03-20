(:name "file-print-read-lines"
 :description "Write PRINT output to a file and validate the blank line and printed form on read-back."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :stream :file-descriptor :print)
 :steps ((:builtin-name "OPEN"
          :arguments ("print-lines.txt" "w")
          :bind "out")
         (:builtin-name "PRINT"
          :arguments ((:list 1 (:symbol "FOO")) (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("print-lines.txt" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "blank-line"
          :expected-value (:string ""))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "printed-line"
          :expected-value (:string "(1 FOO)"))
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "eof"
          :expected-value (:nil))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in"))))
 :result-ref "printed-line"
 :expected-value (:string "(1 FOO)")
 :artifact-relative-path "print-lines.txt"
 :expected-artifact-exists-p t
 :expected-text "
(1 FOO)
")
