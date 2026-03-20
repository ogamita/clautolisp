(:name "file-princ-read-roundtrip"
 :description "Print a symbol with PRINC to a file, read the line back, and parse it again with READ."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :read :file-descriptor)
 :steps ((:builtin-name "OPEN"
          :arguments ("roundtrip-symbol.lsp" "w")
          :bind "out")
         (:builtin-name "PRINC"
          :arguments ((:symbol "FOO") (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("roundtrip-symbol.lsp" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "printed-line"
          :expected-value (:string "FOO"))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in")))
         (:builtin-name "READ"
          :arguments ((:ref "printed-line"))
          :bind "roundtrip"))
 :result-ref "roundtrip"
 :expected-value (:symbol "FOO")
 :artifact-relative-path "roundtrip-symbol.lsp"
 :expected-artifact-exists-p t
 :expected-text "FOO")
