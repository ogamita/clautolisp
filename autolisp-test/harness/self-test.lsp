;;;; autolisp-test/harness/self-test.lsp
;;;;
;;;; Harness regression tests (NOT part of the conformance corpus): they
;;;; exercise the harness' own detection / aggregation functions, which
;;;; the corpus cannot cover because they run once, around the corpus.
;;;;
;;;; Guards autolisp-test-recap-crash-got-t.issue /
;;;; deferred-autolisp-test-matrix-bug.issue: the descriptor's IMPL-NAME
;;;; was the symbol T (AutoLISP `or' returns T/nil, not a value, so the
;;;; `(or (getvar "PRODUCT") "unknown")' fallback yielded T), and
;;;; clautolisp was mis-detected as `unknown' because the detector only
;;;; looked for *clautolisp-version*. Both broke the "running N tests
;;;; on ..." line and the matrix/recap aggregation.
;;;;
;;;; Run: clautolisp --no-init -x '(progn (load "autolisp-test/harness/run.lsp")
;;;;                                      (load "autolisp-test/harness/self-test.lsp"))'
;;;; Exits with a non-zero status via (exit 1) analogue on first failure.

(setq *harness-self-test-failures* 0)

(defun harness-check (label got want)
  (cond ((equal got want)
         (princ (strcat "  ok   " label "\n")))
        (T
         (setq *harness-self-test-failures*
               (+ *harness-self-test-failures* 1))
         (princ (strcat "  FAIL " label
                        " -- got "))
         (prin1 got)
         (princ " want ")
         (prin1 want)
         (princ "\n"))))

(princ "[harness-self-test] descriptor detection\n")

;; 1. IMPL-NAME must be a STRING, never the symbol T (the reported crash).
(setq *hst-desc* (autolisp-test-detect-implementation))
(harness-check "impl-name is a string"
               (eq (type (cdr (assoc 'impl-name *hst-desc*))) 'str)
               T)

;; 2. Running under clautolisp, the implementation is detected as such
;;    (not `unknown'), via the PRODUCT system variable.
(harness-check "clautolisp is detected"
               (cdr (assoc 'impl *hst-desc*))
               'clautolisp)

;; 3. impl-name is exactly "clautolisp".
(harness-check "impl-name is \"clautolisp\""
               (cdr (assoc 'impl-name *hst-desc*))
               "clautolisp")

(princ "[harness-self-test] matrix with an empty runtimes list\n")

;; 4. The matrix aggregation must not raise when the descriptor's
;;    RUNTIMES list is empty -- the per-runtime intersection loop
;;    (foreach tag (cdr (assoc 'runtimes descriptor))) must degrade to
;;    the three base subsets, returning a proper list.
(setq *hst-empty-desc*
      '((impl . clautolisp) (impl-name . "clautolisp") (version . "0")
        (platforms) (runtimes) (profile-target . strict)))
(setq *hst-matrix*
      (autolisp-test-matrix (autolisp-test-registry-list)
                            *hst-empty-desc*
                            nil))
(harness-check "matrix returns a list on empty runtimes"
               (listp *hst-matrix*)
               T)
(harness-check "matrix has the 3 base subsets"
               (length *hst-matrix*)
               3)

(princ (strcat "[harness-self-test] "
               (itoa *harness-self-test-failures*)
               " failure(s)\n"))
(if (> *harness-self-test-failures* 0)
    (exit 1)
    (princ "[harness-self-test] PASS\n"))
