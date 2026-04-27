;;;; autolisp-test/harness/profiles.lsp
;;;;
;;;; Profile and tag definitions, applicability filtering, and verdict
;;;; aggregation. Pure AutoLISP. Loaded after rt.lsp.

;;; --- canonical sets ------------------------------------------------

(setq *autolisp-test-profiles*
      '(strict autocad bricscad))

(setq *autolisp-test-platform-tags*
      '(windows linux macos))

(setq *autolisp-test-runtime-tags*
      '(com vla vlax vlax-curve vlr arx brx objectdbx
        dcl graphics user-input express-tools doslib))

(setq *autolisp-test-status-codes*
      '(pass fail skip xfail xpass unimplemented))

;;; --- verdict aggregation -------------------------------------------

(defun autolisp-test--count-status (status results / n)
  (setq n 0)
  (foreach r results
    (if (eq status (cdr (assoc 'status r)))
        (setq n (+ n 1))))
  n)

(defun autolisp-test-verdict-for (entries descriptor results
                                  / applicable applicable-results pass-n fail-n
                                    skip-n xfail-n xpass-n unimpl-n)
  "Compute the verdict for the subset (ENTRIES) given the implementation
DESCRIPTOR and the per-test RESULTS list (returned by run-all). Returns
an alist with KEYS verdict, applicable-count, total-count, pass, fail,
skip, xfail, xpass, unimplemented."
  (setq applicable nil)
  (setq applicable-results nil)
  (foreach entry entries
    (if (autolisp-test-applicable-p entry descriptor)
        (progn
          (setq applicable (cons entry applicable))
          (foreach r results
            (if (equal (cdr (assoc 'name r))
                       (autolisp-test-entry-name entry))
                (setq applicable-results (cons r applicable-results)))))))
  (setq pass-n   (autolisp-test--count-status 'pass applicable-results))
  (setq fail-n   (autolisp-test--count-status 'fail applicable-results))
  (setq skip-n   (autolisp-test--count-status 'skip applicable-results))
  (setq xfail-n  (autolisp-test--count-status 'xfail applicable-results))
  (setq xpass-n  (autolisp-test--count-status 'xpass applicable-results))
  (setq unimpl-n (autolisp-test--count-status 'unimplemented applicable-results))
  (list (cons 'verdict
              (cond ((null applicable) 'not-applicable)
                    ((> fail-n 0)      'deviates)
                    ((> xpass-n 0)     'deviates)
                    (T                 'conforms)))
        (cons 'applicable-count (length applicable))
        (cons 'total-count (length entries))
        (cons 'pass pass-n)
        (cons 'fail fail-n)
        (cons 'skip skip-n)
        (cons 'xfail xfail-n)
        (cons 'xpass xpass-n)
        (cons 'unimplemented unimpl-n)))

(defun autolisp-test-matrix (entries descriptor results / matrix
                                                          strict-set
                                                          autocad-set
                                                          bricscad-set
                                                          v-strict
                                                          v-autocad
                                                          v-bricscad
                                                          subsets)
  "Compute a verdict matrix grouping ENTRIES by profile and by selected
platform/runtime tag combinations. Returns an alist of (subset-label
verdict-alist) entries. The base subsets are: strict, autocad,
bricscad, plus the same intersected with each detected runtime tag."
  (setq strict-set   (autolisp-test-select-by-profile 'strict   entries))
  (setq autocad-set  (autolisp-test-select-by-profile 'autocad  entries))
  (setq bricscad-set (autolisp-test-select-by-profile 'bricscad entries))
  (setq v-strict     (autolisp-test-verdict-for strict-set descriptor results))
  (setq v-autocad    (autolisp-test-verdict-for autocad-set descriptor results))
  (setq v-bricscad   (autolisp-test-verdict-for bricscad-set descriptor results))
  (setq matrix
        (list
         (list "strict"    v-strict)
         (list "autocad"   v-autocad)
         (list "bricscad"  v-bricscad)))
  ;; Add per-runtime-tag intersections within strict (and per
  ;; vendor profile) so deferred / extension subsets are visible
  ;; in the report rather than buried inside the global verdict.
  (foreach tag (cdr (assoc 'runtimes descriptor))
    (setq subsets
          (list
           (list (strcat "strict + " (vl-symbol-name tag))
                 (autolisp-test-verdict-for
                  (autolisp-test-select-by-tag tag strict-set)
                  descriptor results))
           (list (strcat "autocad + " (vl-symbol-name tag))
                 (autolisp-test-verdict-for
                  (autolisp-test-select-by-tag tag autocad-set)
                  descriptor results))
           (list (strcat "bricscad + " (vl-symbol-name tag))
                 (autolisp-test-verdict-for
                  (autolisp-test-select-by-tag tag bricscad-set)
                  descriptor results))))
    (setq matrix (append matrix subsets)))
  matrix)

(princ "[autolisp-test] profiles.lsp loaded.\n")
(princ)
