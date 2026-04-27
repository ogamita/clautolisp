;;;; autolisp-test/harness/expectations.lsp
;;;;
;;;; Expected-failure overlays. Lets the harness reclassify a known
;;;; deviation as XFAIL (expected to fail) instead of FAIL, and an
;;;; unexpected pass as XPASS. Pure AutoLISP.
;;;;
;;;; Overlay file format: a sequence of S-expressions, each a list
;;;; describing one expectation:
;;;;
;;;;   (expect "test-name" :status xfail :reason "...")
;;;;
;;;; The harness loads the overlay file matching the detected
;;;; implementation, version and platform. Missing overlay files are
;;;; non-fatal: they simply add no expectations.

(setq *autolisp-test-expectations* nil)

(defun expect (name status reason)
  (setq *autolisp-test-expectations*
        (cons (list (cons 'name name)
                    (cons 'status status)
                    (cons 'reason reason))
              *autolisp-test-expectations*))
  T)

(defun autolisp-test--expectation-file (descriptor / impl version host path)
  (setq impl    (vl-symbol-name (cdr (assoc 'impl descriptor))))
  (setq version (autolisp-test--sanitize-name
                 (cdr (assoc 'version descriptor))))
  (setq host
        (cond ((member 'windows (cdr (assoc 'platforms descriptor))) "windows")
              ((member 'macos   (cdr (assoc 'platforms descriptor))) "macos")
              ((member 'linux   (cdr (assoc 'platforms descriptor))) "linux")
              (T "unknown")))
  (strcat *autolisp-test-root*
          "harness/expectations/"
          impl "/" version "/" host ".lsp"))

(defun autolisp-test-load-expectations (descriptor / path)
  (setq *autolisp-test-expectations* nil)
  (setq path (autolisp-test--expectation-file descriptor))
  (if (findfile path)
      (progn
        (princ (strcat "[autolisp-test] applying expectations: " path "\n"))
        (load path))
      (princ
       (strcat "[autolisp-test] no expectations file at: " path "\n")))
  (reverse *autolisp-test-expectations*))

(defun autolisp-test--find-expectation (name overlay)
  (cond ((null overlay) nil)
        ((equal name (cdr (assoc 'name (car overlay)))) (car overlay))
        (T (autolisp-test--find-expectation name (cdr overlay)))))

(defun autolisp-test--reclassify (result expectation / current-status expected-status)
  "Apply one EXPECTATION to RESULT. Returns the (possibly modified)
result alist."
  (setq current-status  (cdr (assoc 'status result)))
  (setq expected-status (cdr (assoc 'status expectation)))
  (cond
    ;; Expected to fail and did fail -> XFAIL
    ((and (eq expected-status 'xfail) (eq current-status 'fail))
     (subst (cons 'status 'xfail) (assoc 'status result) result))
    ;; Expected to fail but passed -> XPASS
    ((and (eq expected-status 'xfail) (eq current-status 'pass))
     (subst (cons 'status 'xpass) (assoc 'status result) result))
    ;; Marked unimplemented -> reclassify a fail to UNIMPLEMENTED
    ((and (eq expected-status 'unimplemented) (eq current-status 'fail))
     (subst (cons 'status 'unimplemented) (assoc 'status result) result))
    (T result)))

(defun autolisp-test-apply-expectations (results overlay / acc found new-result)
  "Walk RESULTS and apply matching expectations from OVERLAY."
  (setq acc nil)
  (foreach r results
    (setq found (autolisp-test--find-expectation
                 (cdr (assoc 'name r)) overlay))
    (cond ((null found) (setq acc (cons r acc)))
          (T (setq new-result (autolisp-test--reclassify r found))
             (setq acc (cons new-result acc)))))
  (reverse acc))

(princ "[autolisp-test] expectations.lsp loaded.\n")
(princ)
