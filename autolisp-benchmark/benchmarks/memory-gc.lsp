;;;; autolisp-benchmark/benchmarks/memory-gc.lsp
;;;;
;;;; Memory class: allocation and garbage collection. Each iteration
;;;; builds a sizable transient structure (cons cells, nested lists and
;;;; freshly-allocated strings) and immediately drops it, generating
;;;; garbage. Every *bench-gc-interval* iterations it calls (gc)
;;;; explicitly, so the measured cost folds in both allocation and
;;;; reclamation -- the two halves of memory-management throughput.
;;;;
;;;; (gc) forces a collection on every supported target (a no-op-ish
;;;; hint on hosts that ignore it, a real full collection on
;;;; clautolisp's SBCL / CCL backend).
;;;;
;;;; The GC cadence is driven by a *persistent* counter, not by the
;;;; per-call loop index. The harness calls this workload many times
;;;; with a calibrated batch size; if the cadence reset every call, a
;;;; small batch would collect on every iteration while a large batch
;;;; would collect rarely, and the per-iteration cost would depend on
;;;; the (arbitrary) batch size rather than on the work. A counter that
;;;; survives across calls makes the collection rate exactly
;;;; one-per-*bench-gc-interval* iterations regardless of batching, so
;;;; the number is stable and comparable.

(if (not (boundp '*bench-gc-interval*))
    (setq *bench-gc-interval* 25))
(if (not (boundp '*bench-gc-counter*))
    (setq *bench-gc-counter* 0))

(defun bench-memory-gc (reps / i j lst)
  (setq i 0)
  (while (< i reps)
    ;; allocate ~200 cons cells plus nested lists and strings, then
    ;; abandon them.
    (setq lst nil)
    (setq j 0)
    (while (< j 200)
      (setq lst (cons (list j (float j) (strcat "x" (itoa j))) lst))
      (setq j (1+ j)))
    ;; force reclamation once every *bench-gc-interval* iterations,
    ;; counted across all calls so the rate is batch-independent.
    (setq *bench-gc-counter* (1+ *bench-gc-counter*))
    (if (>= *bench-gc-counter* *bench-gc-interval*)
        (progn (gc) (setq *bench-gc-counter* 0)))
    (setq i (1+ i)))
  t)

(defbench "memory-gc" "memory-gc" 'bench-memory-gc)

(princ)
