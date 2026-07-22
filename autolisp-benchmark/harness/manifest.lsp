;;;; autolisp-benchmark/harness/manifest.lsp
;;;;
;;;; Explicit, ordered list of benchmark workload files. AutoLISP has no
;;;; portable directory walker, so -- exactly as the autolisp-test
;;;; harness does -- the set of files is enumerated here by hand. Adding
;;;; a benchmark means dropping a file under benchmarks/ and adding one
;;;; line to this list.
;;;;
;;;; Paths are relative to *autolisp-benchmark-root*.

(setq *autolisp-benchmark-files*
      (list
        "benchmarks/arithmetic.lsp"
        "benchmarks/lists.lsp"
        "benchmarks/strings.lsp"
        "benchmarks/serialization.lsp"
        "benchmarks/file-io.lsp"
        "benchmarks/entity.lsp"
        "benchmarks/memory-gc.lsp"))

(defun autolisp-benchmark-load-all ( / )
  "Load every workload file named in *autolisp-benchmark-files*.
Registration happens as a side effect of loading (each file ends with
a (defbench ...) call)."
  (bench-registry-clear)
  (foreach relative *autolisp-benchmark-files*
    (load (strcat *autolisp-benchmark-root* relative)))
  (length *benchmarks*))

(princ)
