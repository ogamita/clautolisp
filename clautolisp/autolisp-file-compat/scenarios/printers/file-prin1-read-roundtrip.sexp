(:name "file-prin1-read-roundtrip"
 :description "Print a form to a file, read the line back, and parse it again with READ."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :read :file-descriptor)
 :steps ((:builtin-name "OPEN"
          :arguments ("roundtrip.lsp" "w")
          :bind "out")
         (:builtin-name "PRIN1"
          :arguments ((:list 1 (:symbol "FOO") "bar") (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("roundtrip.lsp" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "printed-line"
          :expected-value (:string "(1 FOO \"bar\")"))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in")))
         (:builtin-name "READ"
          :arguments ((:ref "printed-line"))
          :bind "roundtrip"))
 :result-ref "roundtrip"
 :expected-value (:list 1 (:symbol "FOO") "bar")
 :artifact-relative-path "roundtrip.lsp"
 :expected-artifact-exists-p t
 :expected-text "(1 FOO \"bar\")")
