(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; ERRNO coupling tests (Phase-3 follow-up).
;;;;
;;;; Each test asserts the documented (failure-code, success-reset)
;;;; pair for an in-scope builtin per the AutoLISP "Error Codes
;;;; Reference" -- the 86-row table at
;;;;   help.autodesk.com/cloudhelp/2015/ENU/AutoCAD-AutoLISP/files/
;;;;   GUID-97327347-2A13-4CBC-BDBF-979C7F1CABD5.htm
;;;;
;;;; Tests do NOT assert that ERRNO is reset to 0 on every call:
;;;; per AutoCAD's own note, ERRNO "is not always cleared to zero",
;;;; so the contract is "reset on success of an ERRNO-coupling
;;;; builtin" -- which is what the wiring in api.lisp does.

(defun setup-mock-evaluation-context ()
  "Install a fresh evaluation context backed by a default MockHost.
Returns the context."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock    (clautolisp.autolisp-mock-host:make-mock-host)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- File / IO --------------------------------------------------

(test errno-findfile-on-miss-sets-22
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-findfile
                 (make-autolisp-string "/no/such/path/anywhere"))))
    (is (null result))
    (is (eql 22 (autolisp-errno)))))

(test errno-findfile-on-hit-resets-to-0
  (setup-mock-evaluation-context)
  (set-autolisp-errno 99)
  (let* ((tempdir (uiop:temporary-directory))
         (tempfile (merge-pathnames
                    (format nil "errno-coupling-~A.txt" (random 1000000))
                    tempdir)))
    (with-open-file (s tempfile :direction :output :if-does-not-exist :create
                       :if-exists :supersede)
      (write-string "ok" s))
    (let ((result (clautolisp.autolisp-builtins-core::builtin-findfile
                   (make-autolisp-string (namestring tempfile)))))
      (is (typep result 'autolisp-string))
      (is (eql 0 (autolisp-errno))))
    (when (probe-file tempfile) (delete-file tempfile))))

(test errno-findtrustedfile-on-miss-sets-22
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-findtrustedfile
                 (make-autolisp-string "/no/such/trusted/path"))))
    (is (null result))
    (is (eql 22 (autolisp-errno)))))

(test errno-open-on-miss-sets-22
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-open
                 (make-autolisp-string "/no/such/file")
                 (make-autolisp-string "r"))))
    (is (null result))
    (is (eql 22 (autolisp-errno)))))

;; (LOAD without onfailure) signals an AutoLISP runtime error rather
;; than returning nil, and the signalling path overwrites ERRNO via
;; the project's existing condition-to-errno mapping
;; (:load-file-not-found -> 5). The "set ERRNO to 73 on miss" wiring
;; is therefore only observable on the onfailure-supplied path; the
;; signalling path keeps the legacy 5 to avoid breaking pre-Phase-3-
;; followup conformance tests.

(test errno-load-with-onfailure-sets-73
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-load (make-autolisp-string "/no/such/script")
                              :marker-symbol)))
    (is (eq :marker-symbol result))
    (is (eql 73 (autolisp-errno)))))

(test errno-read-line-on-eof-sets-8
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let* ((tempfile (merge-pathnames
                    (format nil "errno-readline-~A.txt" (random 1000000))
                    (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (s tempfile :direction :output
                              :if-does-not-exist :create
                              :if-exists :supersede)
             (write-line "one" s))
           (let ((file (clautolisp.autolisp-builtins-core::builtin-open (make-autolisp-string (namestring tempfile))
                                     (make-autolisp-string "r"))))
             (let ((first (clautolisp.autolisp-builtins-core::builtin-read-line file)))
               (is (typep first 'autolisp-string))
               (is (eql 0 (autolisp-errno))))
             (let ((eof (clautolisp.autolisp-builtins-core::builtin-read-line file)))
               (is (null eof))
               (is (eql 8 (autolisp-errno))))
             (clautolisp.autolisp-builtins-core::builtin-close file)))
      (when (probe-file tempfile) (delete-file tempfile)))))

;;; --- Entity access ---------------------------------------------

(test errno-handent-bad-handle-sets-13
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  ;; A handle like "ZZZ" never resolves on a fresh MockHost.
  (let ((result (clautolisp.autolisp-builtins-core::builtin-handent (make-autolisp-string "ZZZ"))))
    (is (null result))
    (is (eql 13 (autolisp-errno)))))

(test errno-entget-on-bad-ename-sets-2
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let* ((host (clautolisp.autolisp-runtime:current-evaluation-host))
         ;; A fabricated ename that doesn't correspond to any entity.
         (ename (clautolisp.autolisp-runtime:make-autolisp-ename
                 :value "NOTAREALENAME")))
    (declare (ignore host))
    (let ((result (clautolisp.autolisp-builtins-core::builtin-entget ename)))
      (is (null result))
      (is (eql 2 (autolisp-errno))))))

;;; --- Selection sets --------------------------------------------

(test errno-ssname-out-of-range-sets-22
  ;; Construct a real (singleton) pickset via the public SSADD path
  ;; so SSNAME's out-of-range path returns nil cleanly without
  ;; triggering the "released pickset" error.
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let* ((host (clautolisp.autolisp-runtime:current-evaluation-host))
         ;; The mock host populates a few default entities; entlast
         ;; gives us a real ename we can SSADD into a pickset.
         (data (list (cons 0 "LINE") (cons 8 "0")
                     (cons 10 (list 0.0d0 0.0d0 0.0d0))
                     (cons 11 (list 1.0d0 1.0d0 0.0d0))))
         (ename-list (clautolisp.autolisp-host:host-entmake host data))
         (ename (cdr (assoc -1 ename-list)))
         (pickset (clautolisp.autolisp-host:host-ssadd host nil ename)))
    (declare (ignorable ename-list))
    ;; Index 99 is well beyond a singleton's [0..0] range.
    (let ((result (clautolisp.autolisp-builtins-core::builtin-ssname pickset 99)))
      (is (null result))
      (is (eql 22 (autolisp-errno))))))

;;; --- Symbol tables ---------------------------------------------

(test errno-tblsearch-miss-leaves-errno-alone
  ;; A missing NAME in a valid table KIND is documented to return
  ;; nil but is NOT an error -- ERRNO is left alone.
  (setup-mock-evaluation-context)
  (set-autolisp-errno 99)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-tblsearch
                 (make-autolisp-string "LAYER")
                 (make-autolisp-string "Nonexistent"))))
    (is (null result))
    ;; 99 was the pre-call value; the spec note about "ERRNO is not
    ;; always cleared to zero" applies: we do NOT clobber it on a
    ;; legitimate not-found return.
    (is (eql 99 (autolisp-errno)))))

(test errno-tblsearch-hit-resets-to-0
  (setup-mock-evaluation-context)
  (set-autolisp-errno 99)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-tblsearch
                 (make-autolisp-string "LAYER")
                 (make-autolisp-string "0"))))
    (is (not (null result)))
    (is (eql 0 (autolisp-errno)))))

;;; --- Tablet stub ------------------------------------------------

(test errno-tablet-stub-sets-68
  (setup-mock-evaluation-context)
  (set-autolisp-errno 0)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-tablet)))
    (is (null result))
    (is (eql 68 (autolisp-errno)))))
