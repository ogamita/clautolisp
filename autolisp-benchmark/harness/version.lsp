;;;; autolisp-benchmark/harness/version.lsp
;;;;
;;;; Current version of the autolisp-benchmark suite (harness +
;;;; workloads).
;;;;
;;;; Format: MAJOR.MINOR.DEVELOP, mirroring the convention of
;;;; clautolisp/tools/clautolisp/source/version.lisp. The DEVELOP
;;;; counter is bumped on every change that touches the benchmark
;;;; sources (harness/*.lsp, benchmarks/*.lsp) -- and only THIS
;;;; version: a benchmark change does not bump clautolisp or alfe,
;;;; and vice versa. See PLAN.md, "Versioning".

(setq *autolisp-benchmark-version* "1.0.0")

(princ)
