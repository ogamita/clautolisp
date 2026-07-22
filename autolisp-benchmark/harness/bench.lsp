;;;; autolisp-benchmark/harness/bench.lsp
;;;;
;;;; The benchmark engine: registration, calibration, the timed run
;;;; loop, and human-readable reporting. Pure AutoLISP so the same code
;;;; runs on AutoCAD, BricsCAD, and clautolisp.
;;;;
;;;; A benchmark is a named workload attached to an operation *class*
;;;; (arithmetic, lists, strings, serialization, file-io, entity,
;;;; memory-gc). Its function takes a single integer REPS and performs
;;;; REPS units of work in a tight loop, so the per-call dispatch cost
;;;; is amortised away and what we measure is the operation itself.
;;;;
;;;; The engine runs each workload for about *bench-seconds* seconds and
;;;; reports throughput (iterations per second) and cost (microseconds
;;;; per iteration). Because every workload runs for roughly the same
;;;; wall-clock time, throughput -- not elapsed time -- is the figure
;;;; that distinguishes implementations.

;;; --- configuration -------------------------------------------------

;; Target wall-clock seconds per workload. The prompt asks for "about
;; five seconds" per operation class.
(if (not (boundp '*bench-seconds*))
    (setq *bench-seconds* 5.0))

;; Calibration aims for a batch whose single call takes at least this
;; many milliseconds, so timer resolution and loop overhead are noise.
(if (not (boundp '*bench-calibrate-ms*))
    (setq *bench-calibrate-ms* 50.0))

;; Registry of (NAME CATEGORY FUNCTION-SYMBOL) triples, in load order.
(if (not (boundp '*benchmarks*))
    (setq *benchmarks* nil))

;; Accumulated result alists from the last run.
(if (not (boundp '*bench-results*))
    (setq *bench-results* nil))

;;; --- registration --------------------------------------------------

(defun defbench (name category fn / )
  "Register workload FN (a quoted symbol naming a function of one
integer argument) under NAME within operation CATEGORY. Later
definitions with the same NAME replace earlier ones."
  (setq *benchmarks*
        (append (bench--remove-named name *benchmarks*)
                (list (list name category fn))))
  name)

(defun bench--remove-named (name entries / out)
  (setq out nil)
  (foreach e entries
    (if (/= 0 (bench--strcmp (car e) name))
        (setq out (cons e out))))
  (reverse out))

(defun bench-registry-clear ( / )
  (setq *benchmarks* nil))

;;; --- calibration and the timed loop --------------------------------

(defun bench--calibrate (fn / batch t0 elapsed)
  "Return a batch size whose single evaluation of FN takes at least
*bench-calibrate-ms* milliseconds (or the cap, whichever comes
first). Grows the batch geometrically."
  (setq batch 1)
  (while
    (progn
      (setq t0 (bench-clock-ms))
      (apply fn (list batch))
      (setq elapsed (- (bench-clock-ms) t0))
      (and (< elapsed *bench-calibrate-ms*)
           (< batch 200000000)))
    (setq batch (* batch 4)))
  batch)

(defun bench--guarded-run (entry / catcher)
  "Run one registry ENTRY, catching any AutoLISP error so a single
failing workload (e.g. no writable temp directory on some host) prints
a [skip] line and lets the remaining benchmarks proceed. Returns the
result alist, or nil on failure."
  (setq catcher
        (vl-catch-all-apply
         'bench--run-one
         (list (car entry) (cadr entry) (caddr entry))))
  (cond
    ((vl-catch-all-error-p catcher)
     (bench--out (strcat "  [skip] " (car entry) ": "
                         (vl-catch-all-error-message catcher)))
     (bench--nl)
     nil)
    (t catcher)))

(defun bench--run-one (name category fn / batch reps t0 elapsed target)
  "Run workload FN for about *bench-seconds* seconds and return a
result alist: NAME CATEGORY REPS MS."
  (setq target (* 1000.0 *bench-seconds*))
  (setq batch (bench--calibrate fn))
  (setq reps 0)
  (setq t0 (bench-clock-ms))
  (setq elapsed 0.0)
  (while (< elapsed target)
    (apply fn (list batch))
    (setq reps (+ reps batch))
    (setq elapsed (- (bench-clock-ms) t0)))
  (list (cons 'name name)
        (cons 'category category)
        (cons 'reps reps)
        (cons 'ms elapsed)
        (cons 'batch batch)))

;;; --- derived metrics -----------------------------------------------

(defun bench--reps (r) (cdr (assoc 'reps r)))
(defun bench--ms (r) (cdr (assoc 'ms r)))

(defun bench--per-sec (r / ms)
  "Iterations per second for result R."
  (setq ms (bench--ms r))
  (if (> ms 0.0)
      (/ (* (float (bench--reps r)) 1000.0) ms)
      0.0))

(defun bench--us-per-rep (r / reps)
  "Microseconds per iteration for result R."
  (setq reps (float (bench--reps r)))
  (if (> reps 0.0)
      (/ (* (bench--ms r) 1000.0) reps)
      0.0))

;;; --- reporting -----------------------------------------------------

(defun bench--out (s) (princ s) (princ))

(defun bench--nl ( / ) (princ "\n") (princ))

(defun bench--pad-right (s w / )
  (setq s (bench--as-string s))
  (while (< (strlen s) w) (setq s (strcat s " ")))
  s)

(defun bench--pad-left (s w / )
  (setq s (bench--as-string s))
  (while (< (strlen s) w) (setq s (strcat " " s)))
  s)

(defun bench--as-string (x / )
  (cond ((eq (type x) 'str) x)
        ((eq (type x) 'int) (itoa x))
        ((eq (type x) 'real) (rtos x 2 3))
        ((null x) "nil")
        (t (vl-princ-to-string x))))

(defun bench--strcmp (a b / )
  "Return 0 when strings A and B are equal, non-zero otherwise."
  (if (equal a b) 0 1))

(defun bench--fmt-real (x prec / )
  (rtos (float x) 2 prec))

;; Column widths for the result table.
(setq *bench-col-cat* 14)
(setq *bench-col-name* 16)
(setq *bench-col-num* 16)

(defun bench--print-table-header ( / )
  (bench--out (bench--pad-right "class" *bench-col-cat*))
  (bench--out (bench--pad-right "benchmark" *bench-col-name*))
  (bench--out (bench--pad-left "iters" *bench-col-num*))
  (bench--out (bench--pad-left "iters/sec" *bench-col-num*))
  (bench--out (bench--pad-left "us/iter" *bench-col-num*))
  (bench--nl))

(defun bench--print-row (r / )
  (bench--out (bench--pad-right (cdr (assoc 'category r)) *bench-col-cat*))
  (bench--out (bench--pad-right (cdr (assoc 'name r)) *bench-col-name*))
  (bench--out (bench--pad-left (itoa (bench--reps r)) *bench-col-num*))
  (bench--out (bench--pad-left (bench--fmt-real (bench--per-sec r) 1)
                               *bench-col-num*))
  (bench--out (bench--pad-left (bench--fmt-real (bench--us-per-rep r) 4)
                               *bench-col-num*))
  (bench--nl))

;;; --- top-level entry -----------------------------------------------

(defun autolisp-benchmark-run-all ( / entry r total-ms n)
  "Run every registered benchmark and print a report. Returns the list
of result alists."
  (bench-timer-init)
  (bench--print-banner)
  (bench--print-table-header)
  (setq *bench-results* nil)
  (foreach entry *benchmarks*
    (setq r (bench--guarded-run entry))
    (if r
        (progn
          (setq *bench-results* (cons r *bench-results*))
          (bench--print-row r))))
  (setq *bench-results* (reverse *bench-results*))
  (bench--print-summary *bench-results*)
  *bench-results*)

;; Run a single named benchmark (developer convenience).
(defun autolisp-benchmark-run (name / entry hit r)
  (bench-timer-init)
  (setq hit nil)
  (foreach entry *benchmarks*
    (if (= 0 (bench--strcmp (car entry) name)) (setq hit entry)))
  (cond
    ((null hit)
     (bench--out (strcat "[autolisp-benchmark] no such benchmark: " name))
     (bench--nl)
     nil)
    (t
     (bench--print-banner)
     (bench--print-table-header)
     (setq r (bench--run-one (car hit) (cadr hit) (caddr hit)))
     (bench--print-row r)
     r)))

(defun bench--print-banner ( / )
  (bench--out "===================================================================")
  (bench--nl)
  (bench--out "  AutoLISP benchmark suite")
  (bench--nl)
  (bench--out (strcat "  suite version  : "
                      (if (boundp '*autolisp-benchmark-version*)
                          *autolisp-benchmark-version*
                          "unknown")))
  (bench--nl)
  (bench--out (strcat "  implementation : " (bench--impl-name)))
  (bench--nl)
  (bench--out (strcat "  platform       : " (bench--platform-name)))
  (bench--nl)
  (bench--out (strcat "  clock source   : " (bench-timer-description)))
  (bench--nl)
  (bench--out (strcat "  seconds/class  : " (bench--fmt-real *bench-seconds* 1)))
  (bench--nl)
  (bench--out (strcat "  benchmarks     : " (itoa (length *benchmarks*))))
  (bench--nl)
  (bench--out "===================================================================")
  (bench--nl))

(defun bench--print-summary (results / total-reps total-ms r)
  (setq total-reps 0)
  (setq total-ms 0.0)
  (foreach r results
    (setq total-reps (+ total-reps (bench--reps r)))
    (setq total-ms (+ total-ms (bench--ms r))))
  (bench--out "-------------------------------------------------------------------")
  (bench--nl)
  (bench--out (strcat "  total iterations : " (itoa total-reps)))
  (bench--nl)
  (bench--out (strcat "  total time (ms)  : " (bench--fmt-real total-ms 1)))
  (bench--nl)
  (bench--out (strcat "  overall iters/s  : "
                      (bench--fmt-real
                       (if (> total-ms 0.0)
                           (/ (* (float total-reps) 1000.0) total-ms)
                           0.0)
                       1)))
  (bench--nl)
  (bench--out "===================================================================")
  (bench--nl))

;;; --- implementation / platform detection ---------------------------
;;;
;;; Kept deliberately small and self-contained: the benchmark must not
;;; depend on the autolisp-test harness.

(defun bench--subr-bound-p (name / )
  (and (boundp name)
       (member (type (eval name)) '(subr usubr exsubr subrf))))

(defun bench--safe-getvar (name / catcher)
  (cond
    ((not (bench--subr-bound-p 'getvar)) nil)
    ((bench--subr-bound-p 'vl-catch-all-apply)
     (setq catcher (vl-catch-all-apply '(lambda (n) (getvar n)) (list name)))
     (if (vl-catch-all-error-p catcher) nil catcher))
    (t (getvar name))))

(defun bench--safe-getenv (name / catcher)
  (cond
    ((not (bench--subr-bound-p 'getenv)) nil)
    ((bench--subr-bound-p 'vl-catch-all-apply)
     (setq catcher (vl-catch-all-apply '(lambda (n) (getenv n)) (list name)))
     (if (vl-catch-all-error-p catcher) nil catcher))
    (t (getenv name))))

(defun bench--safe-ver ( / catcher)
  (cond
    ((not (bench--subr-bound-p 'ver)) nil)
    ((bench--subr-bound-p 'vl-catch-all-apply)
     (setq catcher (vl-catch-all-apply '(lambda () (ver)) nil))
     (if (vl-catch-all-error-p catcher) nil catcher))
    (t (ver))))

(defun bench--impl-name ( / v)
  ;; (ver) is the canonical AutoLISP self-identification and is the
  ;; reliable discriminator across all three targets:
  ;;   clautolisp -> "clautolisp <version>"
  ;;   BricsCAD   -> "BricsCAD ..."
  ;;   AutoCAD    -> "Visual LISP ..."
  ;; (The mock host's PRODUCT sysvar reads "BricsCAD", so PRODUCT is
  ;; NOT a safe way to recognise clautolisp.)
  (setq v (bench--safe-ver))
  (cond ((eq (type v) 'str) v)
        ((setq v (bench--safe-getvar "PRODUCT")) (bench--as-string v))
        (t "unknown")))

(defun bench--platform-name ( / os)
  (setq os (bench--safe-getenv "OS"))
  (cond
    ((and (eq (type os) 'str) (vl-string-search "Windows" os)) "windows")
    ((progn (setq os (bench--safe-getenv "OSTYPE"))
            (and (eq (type os) 'str) (vl-string-search "darwin" (strcase os t))))
     "macos")
    ((and (eq (type os) 'str) (vl-string-search "linux" (strcase os t))) "linux")
    ((setq os (bench--safe-getvar "PLATFORM")) (bench--as-string os))
    (t "unknown")))

(princ)
