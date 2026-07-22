;;;; autolisp-benchmark/harness/run.lsp
;;;;
;;;; Top-level entry point for the AutoLISP benchmark suite. Loaded with
;;;; `(load "autolisp-benchmark/harness/run.lsp")` from any conforming
;;;; implementation: AutoCAD, BricsCAD, or clautolisp -- directly, or
;;;; via `alfe --autocad|--bricscad|--clautolisp`.
;;;;
;;;; Sequence:
;;;;   1. load the harness modules (timer, engine, manifest),
;;;;   2. load every workload file under benchmarks/,
;;;;   3. run every benchmark for about *bench-seconds* seconds,
;;;;   4. print per-class throughput and an overall total.
;;;;
;;;; Then, in a REPL / batch session:
;;;;   (autolisp-benchmark-run-all)          ; run everything
;;;;   (autolisp-benchmark-run "strings")    ; run one class
;;;;
;;;; This file uses only AutoLISP features available on every supported
;;;; target: no Common Lisp, no Express Tools, no COM/ActiveX.

;;; --- configuration -------------------------------------------------
;;;
;;; *autolisp-benchmark-root* defaults to "autolisp-benchmark/". Set it
;;; before loading run.lsp to relocate the suite, e.g.:
;;;
;;;   (setq *autolisp-benchmark-root* "/path/to/autolisp-benchmark/")
;;;   (load "autolisp-benchmark/harness/run.lsp")
;;;
;;; *bench-seconds* (default 5.0) is the wall-clock budget per class.

(if (not (boundp '*autolisp-benchmark-root*))
    (setq *autolisp-benchmark-root* "autolisp-benchmark/"))

;;; --- module load ---------------------------------------------------

(defun autolisp-benchmark--load (relative)
  (load (strcat *autolisp-benchmark-root* relative)))

(autolisp-benchmark--load "harness/version.lsp")
(autolisp-benchmark--load "harness/timer.lsp")
(autolisp-benchmark--load "harness/bench.lsp")
(autolisp-benchmark--load "harness/manifest.lsp")

;;; --- load workloads ------------------------------------------------

(autolisp-benchmark-load-all)

(princ (strcat "[autolisp-benchmark] run.lsp loaded; "
               (itoa (length *benchmarks*))
               " benchmarks registered.\n"))
(princ "[autolisp-benchmark] run with: (autolisp-benchmark-run-all)\n")
(princ)
