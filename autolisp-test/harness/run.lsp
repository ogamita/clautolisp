;;;; autolisp-test/harness/run.lsp
;;;;
;;;; Top-level entry point for the AutoLISP / Visual LISP conformance
;;;; test suite. Loaded with `(load "autolisp-test/harness/run.lsp")`
;;;; from any conforming implementation: AutoCAD, BricsCAD, clautolisp.
;;;;
;;;; The full sequence:
;;;;
;;;;   1. load the harness modules,
;;;;   2. detect the implementation,
;;;;   3. load every test file under autolisp-test/tests/,
;;;;   4. run all applicable tests,
;;;;   5. apply expectation overlays for the detected implementation,
;;;;   6. write the canonical s-expression report,
;;;;   7. print the human-readable recap.
;;;;
;;;; This file deliberately uses only AutoLISP features that are
;;;; available in every supported target. It does not depend on Common
;;;; Lisp, on Express Tools, on DOSLib, on COM/ActiveX, or on any
;;;; specific host integration.

;;; --- configuration -------------------------------------------------
;;;
;;; *autolisp-test-root* defaults to the parent directory of this file.
;;; To override, set the symbol before loading run.lsp, for example:
;;;
;;;   (setq *autolisp-test-root* "/path/to/autolisp-test/")
;;;   (load "autolisp-test/harness/run.lsp")
;;;
;;; *autolisp-test-output-directory* is where the report is written.
;;; Defaults to autolisp-test/results/<impl>/<version>/<host>/<unique>/

(if (not (boundp '*autolisp-test-root*))
    (setq *autolisp-test-root* "autolisp-test/"))

(if (not (boundp '*autolisp-test-output-directory*))
    (setq *autolisp-test-output-directory* nil))

;;; --- module load ---------------------------------------------------

(defun autolisp-test--load (relative)
  (load (strcat *autolisp-test-root* relative)))

(autolisp-test--load "harness/rt.lsp")
(autolisp-test--load "harness/profiles.lsp")
(autolisp-test--load "harness/platform-detect.lsp")
(autolisp-test--load "harness/report.lsp")
(autolisp-test--load "harness/expectations.lsp")
(autolisp-test--load "harness/test-loader.lsp")

;;; --- entry points --------------------------------------------------

(defun autolisp-test--guarded (label thunk-form / catcher)
  "Evaluate THUNK-FORM (a quoted lambda or quoted symbol of arity 0),
catching any AutoLISP-runtime error. On error, prints a diagnostic
on the AutoLISP standard output prefixed by LABEL and returns nil
so the rest of run-all can continue. The guard is engaged in every
mode: debug mode is a verbosity flag, not an error-propagation
switch."
  (setq catcher (vl-catch-all-apply thunk-form nil))
  (cond ((vl-catch-all-error-p catcher)
         (princ
          (strcat "[autolisp-test] "
                  label
                  " raised: "
                  (vl-catch-all-error-message catcher)
                  "\n"))
         nil)
        (T catcher)))

(defun autolisp-test--guarded-apply (label fn-symbol args / catcher)
  "Call FN-SYMBOL with ARGS inside VL-CATCH-ALL-APPLY. On error,
prints a diagnostic prefixed by LABEL and returns nil so the
caller can continue. ARGS is evaluated at the call site before
entering the catch, so values (not symbols) flow into the callee."
  (setq catcher (vl-catch-all-apply fn-symbol args))
  (cond ((vl-catch-all-error-p catcher)
         (princ
          (strcat "[autolisp-test] "
                  label
                  " raised: "
                  (vl-catch-all-error-message catcher)
                  "\n"))
         nil)
        (T catcher)))

(defun autolisp-test-run-all ( / descriptor entries results matrix overlay
                                 guard-tmp directory report-path)
  (autolisp-test-registry-clear)
  (autolisp-test-load-all-tests)
  (setq descriptor (autolisp-test-detect-implementation))
  (setq entries (autolisp-test-registry-list))
  (princ
   (strcat "[autolisp-test] running "
           (itoa (length entries))
           " tests on "
           (cdr (assoc 'impl-name descriptor))
           " "
           (cdr (assoc 'version descriptor))
           "\n"))
  ;; Step 1: run every test. Per-entry processing is already guarded
  ;; inside autolisp-test--process-entry, so this never raises.
  (setq results (autolisp-test-run-many entries descriptor))
  ;; Step 2: expectation overlays. Bracket the call in case the
  ;; overlay file itself is malformed.
  (setq overlay
        (autolisp-test--guarded-apply
         "load-expectations"
         'autolisp-test-load-expectations
         (list descriptor)))
  (progn
    (setq guard-tmp
          (autolisp-test--guarded-apply
           "apply-expectations"
           'autolisp-test-apply-expectations
           (list results overlay)))
    (if (listp guard-tmp)
        (setq results guard-tmp)))
  ;; Step 3: matrix.
  (setq matrix
        (autolisp-test--guarded-apply
         "matrix"
         'autolisp-test-matrix
         (list entries descriptor results)))
  ;; Step 4: report-directory + write report.
  (setq directory (autolisp-test--report-directory descriptor))
  (autolisp-test--ensure-directory directory)
  (setq report-path (strcat directory "report.sexp"))
  (autolisp-test--guarded-apply
   "write-sexp-report"
   'autolisp-test-write-sexp-report
   (list report-path descriptor entries results matrix))
  ;; Step 5: human-readable recap.
  (autolisp-test--guarded-apply
   "print-recap"
   'autolisp-test-print-recap
   (list descriptor results matrix))
  (princ (strcat "[autolisp-test] report written to: " report-path "\n"))
  (list (cons 'descriptor descriptor)
        (cons 'results results)
        (cons 'matrix matrix)
        (cons 'report-path report-path)))

(defun autolisp-test--report-directory (descriptor / impl version host)
  (cond ((not (null *autolisp-test-output-directory*))
         *autolisp-test-output-directory*)
        (T
         (setq impl    (vl-symbol-name (cdr (assoc 'impl descriptor))))
         (setq version (cdr (assoc 'version descriptor)))
         (setq host
               (cond ((member 'windows (cdr (assoc 'platforms descriptor))) "windows")
                     ((member 'macos   (cdr (assoc 'platforms descriptor))) "macos")
                     ((member 'linux   (cdr (assoc 'platforms descriptor))) "linux")
                     (T "unknown")))
         (strcat *autolisp-test-root*
                 "results/"
                 impl "/"
                 (autolisp-test--sanitize-name version) "/"
                 host "/"
                 (autolisp-test--timestamp) "/"))))

(defun autolisp-test--sanitize-name (string / out i ch)
  "Replace path-unfriendly characters in STRING. Defensive: ignores
nil and unexpected non-string types."
  (if (eq (type string) 'str)
      (progn
        (setq out "")
        (setq i 1)
        (while (<= i (strlen string))
          (setq ch (substr string i 1))
          (if (or (vl-string-search " " ch)
                  (vl-string-search "/" ch)
                  (vl-string-search "\\" ch)
                  (vl-string-search ":" ch))
              (setq out (strcat out "_"))
              (setq out (strcat out ch)))
          (setq i (+ i 1)))
        out)
      "unknown"))

(defun autolisp-test--timestamp ( / parts)
  (cond ((autolisp-test--subr-bound-p 'menucmd) "now")
        (T "now")))

(princ "[autolisp-test] run.lsp loaded. Run with: (autolisp-test-run-all)\n")
(princ)
