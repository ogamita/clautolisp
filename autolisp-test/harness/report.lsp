;;;; autolisp-test/harness/report.lsp
;;;;
;;;; Run the registered tests, classify each one, and produce two
;;;; reports: a canonical s-expression report (one record per line,
;;;; readable by any AutoLISP / Common Lisp reader) and a human
;;;; recap printed to *standard output* (or its AutoLISP analogue).
;;;;
;;;; Pure AutoLISP. Loaded after rt.lsp, profiles.lsp, platform-detect.lsp.

;;; --- formatting helpers --------------------------------------------

(defun autolisp-test--writeable-p (object)
  "True iff OBJECT can be passed safely to PRIN1 without losing
information for the report. Only basic types are accepted; complex
opaque objects (FILE, ENAME, PICKSET) are stringified instead."
  (member (type object) '(int real str sym list nil)))

(defun autolisp-test--format-value (object / catcher)
  "Return a printable representation of OBJECT, suitable for inclusion
in the report. Uses VL-PRIN1-TO-STRING when available, otherwise a
manual pretty-print."
  (cond ((null object) "NIL")
        ((autolisp-test--subr-bound-p 'vl-prin1-to-string)
         (vl-prin1-to-string object))
        (T
         (cond ((eq (type object) 'str) (strcat "\"" object "\""))
               ((eq (type object) 'sym) (vl-symbol-name object))
               (T (itoa 0))))))

(defun autolisp-test--write-record (file record)
  "Write RECORD as a single S-expression line to FILE."
  (write-line (autolisp-test--format-value record) file))

;;; --- run -----------------------------------------------------------

(defun autolisp-test-run-one (entry / outcome)
  "Run a single test. Returns the classification alist."
  (setq outcome (autolisp-test-classify entry))
  outcome)

(defun autolisp-test--safe-name (entry / catcher)
  "Best-effort accessor for an entry's NAME. Returns a fallback string
when the entry is not a well-formed alist."
  (setq catcher
        (vl-catch-all-apply
         '(lambda (e) (autolisp-test-entry-name e))
         (list entry)))
  (cond ((vl-catch-all-error-p catcher) "<malformed-entry>")
        ((null catcher) "<unnamed-entry>")
        ((eq (type catcher) 'str) catcher)
        (T (autolisp-test--coerce-to-string catcher))))

(defun autolisp-test--print-debug-trace (entry result-status detail)
  "When debug mode is on, print a single line for the test that just
ran. RESULT-STATUS is the symbol the harness assigned (PASS / FAIL /
SKIP / NOT-APPLICABLE / ...). DETAIL is the failure-detail string
when status is non-PASS; it is printed verbatim and already contains
the AutoLISP backtrace when one was captured."
  (if *autolisp-test-debug-p*
      (princ
       (autolisp-test--safe-strcat
        (list "[autolisp-test] "
              result-status
              "  "
              (autolisp-test--safe-name entry)
              (cond ((or (eq result-status 'pass)
                         (eq result-status 'skip)
                         (eq result-status 'not-applicable))
                     "")
                    (T (autolisp-test--safe-strcat
                        (list "  -- " detail))))
              "\n")))))

(defun autolisp-test--process-entry (entry descriptor / catcher applicable
                                                       result-or-error)
  "Process a single ENTRY against DESCRIPTOR and return a result alist.
Every step (applicability check, classification, NOT-APPLICABLE
record building) is wrapped in vl-catch-all-apply so a malformed
entry, a defensive mismatch in the harness, or an outright bug
becomes a FAIL with a descriptive detail string instead of
escaping. The same code path is taken in every mode -- debug mode
is a verbosity flag, not an error-propagation switch -- so the run
always completes and the report is always produced.

In debug mode, every test is announced on stdout
(`[autolisp-test] >>> NAME  form: FORM') before evaluation, and
the FAIL detail (which already includes the captured AutoLISP
backtrace) is echoed on stdout immediately after evaluation."
  (if *autolisp-test-debug-p*
      (princ
       (autolisp-test--safe-strcat
        (list "[autolisp-test] >>> "
              (autolisp-test--safe-name entry)
              "  form: "
              (autolisp-test-entry-form entry)
              "\n"))))
  (cond
    (T
     ;; Step 1: applicability.
     (setq catcher
           (vl-catch-all-apply
            '(lambda (e d) (autolisp-test-applicable-p e d))
            (list entry descriptor)))
     (cond
       ((vl-catch-all-error-p catcher)
        (list (cons 'name (autolisp-test--safe-name entry))
              (cons 'status 'fail)
              (cons 'detail
                    (autolisp-test--safe-strcat
                     (list "internal-harness-error in applicability check: "
                           (vl-catch-all-error-message catcher))))
              (cons 'evaluated nil)
              (cons 'expected nil)
              (cons 'assertion 'unknown)))
       (catcher
        ;; Applicable: classify (already guarded internally).
        (setq result-or-error
              (vl-catch-all-apply
               'autolisp-test-run-one
               (list entry)))
        (cond ((vl-catch-all-error-p result-or-error)
               (list (cons 'name (autolisp-test--safe-name entry))
                     (cons 'status 'fail)
                     (cons 'detail
                           (autolisp-test--safe-strcat
                            (list "internal-harness-error in classify wrapper: "
                                  (vl-catch-all-error-message result-or-error))))
                     (cons 'evaluated nil)
                     (cons 'expected nil)
                     (cons 'stack nil)
                     (cons 'assertion 'unknown)))
              (T result-or-error)))
       (T
        ;; Not applicable.
        (setq result-or-error
              (vl-catch-all-apply
               '(lambda (e)
                  (list (cons 'name (autolisp-test-entry-name e))
                        (cons 'status 'not-applicable)
                        (cons 'detail "required tag(s) not satisfied")
                        (cons 'evaluated nil)
                        (cons 'expected nil)
                        (cons 'stack nil)
                        (cons 'assertion (autolisp-test-entry-assertion-kind e))))
               (list entry)))
        (cond ((vl-catch-all-error-p result-or-error)
               (list (cons 'name (autolisp-test--safe-name entry))
                     (cons 'status 'fail)
                     (cons 'detail
                           (autolisp-test--safe-strcat
                            (list "internal-harness-error building NOT-APPLICABLE record: "
                                  (vl-catch-all-error-message result-or-error))))
                     (cons 'evaluated nil)
                     (cons 'expected nil)
                     (cons 'stack nil)
                     (cons 'assertion 'unknown)))
              (T result-or-error)))))))

(defun autolisp-test-run-many (entries descriptor / acc result)
  "Run every entry whose tags are satisfied by DESCRIPTOR. Tests that
are not applicable are recorded with status NOT-APPLICABLE so the
report includes them. Returns the list of result alists in the same
order as ENTRIES.

No iteration of this loop ever raises: every per-entry step is
guarded by autolisp-test--process-entry so a single faulty test or
malformed metadata cannot abort the run.

In debug mode the per-entry trace and the FAIL detail (with the
embedded backtrace) are echoed to stdout immediately after the
test, so a developer can identify a failing test as soon as it
runs without waiting for the final recap."
  (setq acc nil)
  (foreach entry entries
    (setq result (autolisp-test--process-entry entry descriptor))
    (autolisp-test--print-debug-trace
     entry
     (cdr (assoc 'status result))
     (cdr (assoc 'detail result)))
    (setq acc (cons result acc)))
  (reverse acc))

;;; --- s-expression report -------------------------------------------

(defun autolisp-test--ensure-directory (path)
  "Best-effort directory creation. AutoLISP has VL-MKDIR; missing it
is non-fatal because the caller may have created the directory."
  (cond ((null path) nil)
        ((autolisp-test--subr-bound-p 'vl-mkdir)
         (vl-mkdir path))
        (T nil)))

(defun autolisp-test-write-sexp-report (path descriptor entries results matrix
                                        / file)
  "Emit the canonical s-expression report at PATH. The report is one
record per line, suitable for diffing across runs."
  (setq file (open path "w"))
  (if (null file)
      (progn
        (princ (strcat "[autolisp-test] cannot open report file: " path "\n"))
        nil)
    (progn
      (autolisp-test--write-record
       file
       (list 'run-start
             (cons 'impl       (cdr (assoc 'impl descriptor)))
             (cons 'impl-name  (cdr (assoc 'impl-name descriptor)))
             (cons 'version    (cdr (assoc 'version descriptor)))
             (cons 'platforms  (cdr (assoc 'platforms descriptor)))
             (cons 'runtimes   (cdr (assoc 'runtimes descriptor)))
             (cons 'profile-target (cdr (assoc 'profile-target descriptor)))
             (cons 'inventory-version "0")
             (cons 'test-count (length entries))))
      (foreach r results
        (autolisp-test--write-record
         file
         (list 'test-result
               (cons 'name      (cdr (assoc 'name r)))
               (cons 'status    (cdr (assoc 'status r)))
               (cons 'assertion (cdr (assoc 'assertion r)))
               (cons 'detail    (cdr (assoc 'detail r)))
               (cons 'stack     (cdr (assoc 'stack r))))))
      (foreach pair matrix
        (autolisp-test--write-record
         file
         (list 'verdict
               (cons 'subset           (car pair))
               (cons 'verdict          (cdr (assoc 'verdict (cadr pair))))
               (cons 'applicable-count (cdr (assoc 'applicable-count (cadr pair))))
               (cons 'total-count      (cdr (assoc 'total-count (cadr pair))))
               (cons 'pass             (cdr (assoc 'pass (cadr pair))))
               (cons 'fail             (cdr (assoc 'fail (cadr pair))))
               (cons 'skip             (cdr (assoc 'skip (cadr pair))))
               (cons 'xfail            (cdr (assoc 'xfail (cadr pair))))
               (cons 'xpass            (cdr (assoc 'xpass (cadr pair))))
               (cons 'unimplemented    (cdr (assoc 'unimplemented (cadr pair)))))))
      (autolisp-test--write-record
       file
       (list 'run-end
             (cons 'impl    (cdr (assoc 'impl descriptor)))
             (cons 'version (cdr (assoc 'version descriptor)))))
      (close file)
      T)))

;;; --- text recap ---------------------------------------------------

(defun autolisp-test--print (text) (princ text))

(defun autolisp-test--print-line (text) (princ text) (princ "\n"))

(defun autolisp-test-print-recap (descriptor results matrix / total pass fail
                                                              skip xfail xpass
                                                              unimpl na)
  (setq total (length results))
  (setq pass    (autolisp-test--count-status 'pass results))
  (setq fail    (autolisp-test--count-status 'fail results))
  (setq skip    (autolisp-test--count-status 'skip results))
  (setq xfail   (autolisp-test--count-status 'xfail results))
  (setq xpass   (autolisp-test--count-status 'xpass results))
  (setq unimpl  (autolisp-test--count-status 'unimplemented results))
  (setq na      (autolisp-test--count-status 'not-applicable results))
  (autolisp-test--print-line "")
  (autolisp-test--print-line "============================================================")
  (autolisp-test--print-line "  autolisp-test conformance report")
  (autolisp-test--print-line "------------------------------------------------------------")
  (autolisp-test--print-line
   (strcat "  Implementation : "
           (or (cdr (assoc 'impl-name descriptor)) "?")
           " ("
           (vl-symbol-name (cdr (assoc 'impl descriptor)))
           ")"))
  (autolisp-test--print-line
   (strcat "  Version        : " (cdr (assoc 'version descriptor))))
  (autolisp-test--print-line
   (strcat "  Platforms      : "
           (autolisp-test--format-value (cdr (assoc 'platforms descriptor)))))
  (autolisp-test--print-line
   (strcat "  Runtimes       : "
           (autolisp-test--format-value (cdr (assoc 'runtimes descriptor)))))
  (autolisp-test--print-line
   (strcat "  Profile target : "
           (vl-symbol-name (cdr (assoc 'profile-target descriptor)))))
  (autolisp-test--print-line "------------------------------------------------------------")
  (autolisp-test--print-line
   (strcat "  Total tests    : " (itoa total)))
  (autolisp-test--print-line
   (strcat "  Pass           : " (itoa pass)))
  (autolisp-test--print-line
   (strcat "  Fail           : " (itoa fail)))
  (autolisp-test--print-line
   (strcat "  Skip           : " (itoa skip)))
  (autolisp-test--print-line
   (strcat "  Not applicable : " (itoa na)))
  (autolisp-test--print-line
   (strcat "  Unimplemented  : " (itoa unimpl)))
  (autolisp-test--print-line
   (strcat "  XFail          : " (itoa xfail)))
  (autolisp-test--print-line
   (strcat "  XPass          : " (itoa xpass)))
  (autolisp-test--print-line "------------------------------------------------------------")
  (autolisp-test--print-line "  Verdict matrix:")
  (foreach pair matrix
    (autolisp-test--print-line
     (strcat "    "
             (car pair)
             "  ->  "
             (vl-symbol-name (cdr (assoc 'verdict (cadr pair))))
             "   ("
             (itoa (cdr (assoc 'applicable-count (cadr pair))))
             "/"
             (itoa (cdr (assoc 'total-count (cadr pair))))
             " applicable; "
             (itoa (cdr (assoc 'fail (cadr pair))))
             " failing)")))
  (autolisp-test--print-line "============================================================"))

(princ "[autolisp-test] report.lsp loaded.\n")
(princ)
