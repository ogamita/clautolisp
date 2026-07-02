;;;; autolisp-benchmark/benchmarks/file-io.lsp
;;;;
;;;; I/O class: file input and output. One iteration opens a scratch
;;;; file for writing, writes a block of lines, closes it, reopens it
;;;; for reading, reads every line back, and closes it. This exercises
;;;; the open / write-line / read-line / close path and the underlying
;;;; filesystem round-trip.
;;;;
;;;; The scratch file lives in the platform temp directory and is reused
;;;; (truncated) every iteration, so the benchmark leaves a single small
;;;; file behind rather than churning the directory.

(defun bench--tmpdir ( / d)
  (setq d (cond ((getenv "TMPDIR"))
                ((getenv "TEMP"))
                ((getenv "TMP"))
                (t "/tmp")))
  d)

(defun bench--tmpfile ( / d)
  (setq d (bench--tmpdir))
  ;; Accept a trailing separator either way; forward slashes work on
  ;; every supported host including Windows CAD.
  (if (or (= "/" (substr d (strlen d) 1))
          (= "\\" (substr d (strlen d) 1)))
      (strcat d "clautolisp-bench-io.tmp")
      (strcat d "/clautolisp-bench-io.tmp")))

(defun bench-file-io (reps / i path fp n line)
  (setq path (bench--tmpfile))
  (setq i 0)
  (while (< i reps)
    ;; write phase
    (setq fp (open path "w"))
    (if fp
        (progn
          (setq n 0)
          (while (< n 16)
            (write-line
             (strcat "line " (itoa n) " value "
                     (rtos (float (* i n)) 2 3))
             fp)
            (setq n (1+ n)))
          (close fp)))
    ;; read phase
    (setq fp (open path "r"))
    (if fp
        (progn
          (while (setq line (read-line fp)))
          (close fp)))
    (setq i (1+ i)))
  path)

(defbench "file-io" "file-io" 'bench-file-io)

(princ)
