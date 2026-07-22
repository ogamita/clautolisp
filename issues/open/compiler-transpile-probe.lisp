;;;; issues/open/compiler-transpile-probe.lisp
;;;;
;;;; Companion to compiler.issue (see its 2026-07-23 addendum).
;;;;
;;;; Measures the performance ceiling of the Tier-2 AutoLISP->CL
;;;; compiler: the two autolisp-benchmark workloads where BricsCAD's
;;;; LispEx beats the clautolisp interpreter the hardest (arithmetic
;;;; 13.7x, lists 7.4x — benchmark-results.org, 2026-07-22, same
;;;; hardware) are hand-transpiled to CL exactly as the compiler
;;;; would emit them, and timed compiled under SBCL.
;;;;
;;;; Two codegen strategies per workload:
;;;;
;;;;   Variant A ("conservative faithful"): every AutoLISP local is a
;;;;   CL special (faithful dynamic scoping, no escape analysis),
;;;;   arithmetic is generic CL on boxed values, function positions
;;;;   late-bound where AutoLISP is. The floor: what the compiler can
;;;;   emit with NO cleverness while preserving semantics.
;;;;
;;;;   Variant B ("optimising"): locals proven private become
;;;;   lexicals with type declarations, letting SBCL infer and unbox.
;;;;   The ceiling.
;;;;
;;;; Run:  sbcl --non-interactive --no-userinit --load compiler-transpile-probe.lisp
;;;;
;;;; Results 2026-07-23 (same machine as benchmark-results.org;
;;;; us/iteration, autolisp-benchmark suite 1.0.0 iteration semantics):
;;;;
;;;;   workload    interpreter  BricsCAD-V26  Variant A  Variant B
;;;;   arithmetic     7.23         0.53         0.14       0.024
;;;;   lists          6.37         0.87         0.15       0.14
;;;;
;;;; i.e. even Variant A beats LispEx ~4x (arithmetic) / ~6x (lists),
;;;; and is 43-53x faster than the current interpreter. Caveat: A maps
;;;; AutoLISP ops onto raw CL ops; real codegen calling closed runtime
;;;; builtins (full funcall + checks per op) would erode the margin
;;;; ~3-5x — hence the issue's requirement to open-code the hot core
;;;; builtins.

;;; --- Variant A: conservative faithful transpile ---------------------

(defvar *a-i*) (defvar *a-x*) (defvar *a-y*)

(defun bench-arithmetic-special (reps)
  (declare (optimize (speed 1) (safety 1)))
  (let ((*a-i* 0) (*a-x* 1.0d0) (*a-y* nil))
    (declare (special *a-i* *a-x* *a-y*))
    (loop while (< *a-i* reps) do
      (setq *a-y* (+ (float *a-i* 1.0d0) 1.0d0))
      (setq *a-x* (+ 1.0d0
                     (* 3.0d0 (- 7 2))
                     (/ *a-y* 2.0d0)
                     (sqrt *a-y*)
                     (expt 1.0001d0 3)
                     (rem (+ *a-i* 7) 5)
                     (* (sin *a-y*) (cos *a-y*))
                     (abs (- 0.5d0 *a-x*))
                     (min *a-x* (max *a-y* 2.0d0))))
      (setq *a-i* (1+ *a-i*)))
    *a-x*))

(defvar *l-i*) (defvar *l-lst*) (defvar *l-acc*) (defvar *l-alist*)

(defun bench-lists-special (reps)
  (declare (optimize (speed 1) (safety 1)))
  (let ((*l-alist* (list (cons 1 "one") (cons 2 "two") (cons 3 "three")
                         (cons 4 "four") (cons 5 "five")))
        (*l-i* 0) (*l-lst* nil) (*l-acc* nil))
    (declare (special *l-i* *l-lst* *l-acc* *l-alist*))
    (loop while (< *l-i* reps) do
      (setq *l-lst* (list 1 2 3 4 5 6 7 8))
      (setq *l-lst* (cons 0 *l-lst*))
      (setq *l-lst* (append *l-lst* (list 9 10)))
      (setq *l-acc* (reverse *l-lst*))
      (setq *l-acc* (mapcar (symbol-function '1+) *l-acc*))
      (nth 6 *l-acc*)
      (member 5 *l-acc*)
      (assoc 3 *l-alist*)
      (length *l-acc*)
      (setq *l-i* (1+ *l-i*)))
    *l-acc*))

;;; --- Variant B: optimising transpile (lexicals + types) -------------

(defun bench-arithmetic-lexical (reps)
  (declare (optimize (speed 3) (safety 1)) (fixnum reps))
  (let ((i 0) (x 1.0d0) (y 0.0d0))
    (declare (fixnum i) (double-float x y))
    (loop while (< i reps) do
      (setq y (+ (float i 1.0d0) 1.0d0))
      (setq x (+ 1.0d0
                 (* 3.0d0 (- 7 2))
                 (/ y 2.0d0)
                 (sqrt y)
                 (expt 1.0001d0 3)
                 (rem (+ i 7) 5)
                 (* (sin y) (cos y))
                 (abs (- 0.5d0 x))
                 (min x (max y 2.0d0))))
      (setq i (1+ i)))
    x))

(defun bench-lists-lexical (reps)
  (declare (optimize (speed 3) (safety 1)) (fixnum reps))
  (let ((alist (list (cons 1 "one") (cons 2 "two") (cons 3 "three")
                     (cons 4 "four") (cons 5 "five")))
        (i 0) (lst nil) (acc nil))
    (declare (fixnum i))
    (loop while (< i reps) do
      (setq lst (list 1 2 3 4 5 6 7 8))
      (setq lst (cons 0 lst))
      (setq lst (append lst (list 9 10)))
      (setq acc (reverse lst))
      (setq acc (mapcar #'1+ acc))
      (nth 6 acc)
      (member 5 acc)
      (assoc 3 alist)
      (length acc)
      (setq i (1+ i)))
    acc))

;;; --- harness ---------------------------------------------------------

(defun time-one (label fn reps)
  (let ((start (get-internal-real-time)))
    (funcall fn reps)
    (let* ((ms (/ (- (get-internal-real-time) start)
                  (/ internal-time-units-per-second 1000.0d0)))
           (us/iter (/ (* ms 1000.0d0) reps))
           (iter/s (/ reps (/ ms 1000.0d0))))
      (format t "~30A ~10D reps  ~10,1F iters/sec  ~8,4F us/iter~%"
              label reps iter/s us/iter))))

(time-one "arith special+generic (A)" #'bench-arithmetic-special 3000000)
(time-one "arith lexical+typed   (B)" #'bench-arithmetic-lexical 10000000)
(time-one "lists special+generic (A)" #'bench-lists-special 2000000)
(time-one "lists lexical         (B)" #'bench-lists-lexical 3000000)
