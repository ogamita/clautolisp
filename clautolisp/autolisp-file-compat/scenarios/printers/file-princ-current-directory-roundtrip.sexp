(:name "file-princ-current-directory-roundtrip"
 :description "Print a symbol with PRINC to a relative file under the configured AutoLISP current directory, then read and parse it again."
 :kind :builtin
 :classification :portable
 :tags (:builtin :printer :read :file-descriptor :current-directory)
 :current-directory "cwd/"
 :steps ((:builtin-name "OPEN"
          :arguments ("symbol.lsp" "w")
          :bind "out")
         (:builtin-name "PRINC"
          :arguments ((:symbol "BAR") (:ref "out")))
         (:builtin-name "CLOSE"
          :arguments ((:ref "out")))
         (:builtin-name "OPEN"
          :arguments ("symbol.lsp" "r")
          :bind "in")
         (:builtin-name "READ-LINE"
          :arguments ((:ref "in"))
          :bind "printed-line"
          :expected-value (:string "BAR"))
         (:builtin-name "CLOSE"
          :arguments ((:ref "in")))
         (:builtin-name "READ"
          :arguments ((:ref "printed-line"))
          :bind "roundtrip"))
 :result-ref "roundtrip"
 :expected-value (:symbol "BAR")
 :artifact-relative-path "cwd/symbol.lsp"
 :expected-artifact-exists-p t
 :expected-text "BAR")
