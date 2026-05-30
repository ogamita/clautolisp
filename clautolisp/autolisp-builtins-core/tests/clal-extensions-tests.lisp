(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Tests for the CLAL-* clautolisp extensions.
;;;;
;;;; See autolisp-spec §16 ~clautolisp Extensions~ for the normative
;;;; entries.

(defun setup-mock-host-context ()
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock    (clautolisp.autolisp-mock-host:make-mock-host)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- clal-sysvar-list ---------------------------------------------

(test clal-sysvar-list-returns-1836-entries-on-default-mock
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list)))
    (is (listp result))
    (is (= 1836 (length result)))
    (is (every (lambda (x)
                 (typep x 'clautolisp.autolisp-runtime:autolisp-string))
               result))))

(test clal-sysvar-list-is-sorted-lexicographically
  (setup-mock-host-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (is (equal values (sort (copy-list values) #'string<)))))

(test clal-sysvar-list-includes-well-known-names
  (setup-mock-host-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (dolist (n '("ANGBASE" "CMDECHO" "ERRNO" "LISPSYS" "OSMODE"
                 "PROJECTAWARE" "TRUSTEDPATHS" "USERI1"))
      (is (member n values :test #'string=)
          "expected ~A in CLAL-SYSVAR-LIST" n))))

;;; --- clal-sysvar-apropos ------------------------------------------

(test clal-sysvar-apropos-ang-matches-angle-family
  (setup-mock-host-context)
  (let* ((pattern (clautolisp.autolisp-runtime:make-autolisp-string "ANG"))
         (result  (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos pattern))
         (values  (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                          result)))
    (is (member "ANGBASE" values :test #'string=))
    (is (member "ANGDIR"  values :test #'string=))
    ;; AUNITS does NOT contain the substring "ANG"; assert it's
    ;; excluded so the apropos result isn't an everything-fallthrough.
    (is (null (member "AUNITS" values :test #'string=)))))

(test clal-sysvar-apropos-is-case-insensitive
  (setup-mock-host-context)
  (let* ((upper (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ANG")))
         (lower (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ang")))
         (mixed (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "Ang"))))
    (is (= (length upper) (length lower)))
    (is (= (length upper) (length mixed)))))

(test clal-sysvar-apropos-empty-string-returns-all-1836
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string ""))))
    (is (= 1836 (length result)))))

(test clal-sysvar-apropos-no-match-returns-nil
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string
                  "DEFINITELY_NOT_A_SUBSTRING_OF_ANY_NAME_xyzzy"))))
    (is (null result))))

(test clal-sysvar-apropos-rejects-non-string-pattern
  (setup-mock-host-context)
  (let ((signalled-p nil))
    (handler-case
        (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos 42)
      (autolisp-runtime-error (c)
        (declare (ignore c))
        (setf signalled-p t)))
    (is (eq signalled-p t))))

;;; --- clal-{system,drawing}-codepage and clal-codepage-mismatch-p ---
;;;
;;; Canonicalisation contract: SYSCODEPAGE / DWGCODEPAGE may carry
;;; either the vendor "ANSI_NNNN" form (when alfe is bridging to a
;;; live CAD process) or clautolisp's canonical encoding name
;;; ("UTF-8" / "WINDOWS-1252" / "ISO-8859-1" / "US-ASCII") when the
;;; in-process engine runs. Both collapse onto the spec's CP-NNNN /
;;; Unicode-name form in the helpers' return value.

(defun %install-codepages (sys dwg)
  "Set up a fresh mock-host context and write SYS / DWG into the
host's SYSCODEPAGE / DWGCODEPAGE cells via the launch-time bypass."
  (setup-mock-host-context)
  (let ((host (clautolisp.autolisp-runtime:current-evaluation-host)))
    (clautolisp.autolisp-host:host-set-derived-sysvar host "SYSCODEPAGE" sys)
    (clautolisp.autolisp-host:host-set-derived-sysvar host "DWGCODEPAGE" dwg)))

(test clal-system-codepage-passes-through-unicode-name
  (%install-codepages "UTF-8" "UTF-8")
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-system-codepage)))
    (is (string= "UTF-8"
                 (clautolisp.autolisp-runtime:autolisp-string-value result)))))

(test clal-system-codepage-canonicalises-vendor-ansi-form
  ;; AutoCAD / BricsCAD spell the host code page as "ANSI_1252";
  ;; the helper collapses to "CP-1252".
  (%install-codepages "ANSI_1252" "ANSI_1252")
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-system-codepage)))
    (is (string= "CP-1252"
                 (clautolisp.autolisp-runtime:autolisp-string-value result)))))

(test clal-system-codepage-canonicalises-windows-form
  ;; clautolisp's resolve-effective-encoding emits "WINDOWS-1252"; the
  ;; helper folds that to the same "CP-1252" as the vendor form.
  (%install-codepages "WINDOWS-1252" "WINDOWS-1252")
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-system-codepage)))
    (is (string= "CP-1252"
                 (clautolisp.autolisp-runtime:autolisp-string-value result)))))

(test clal-system-codepage-empty-maps-to-ansi-placeholder
  ;; Pre-Phase-1 hosts left SYSCODEPAGE = ""; the helper renders
  ;; that as "ANSI" so user code never sees the empty placeholder.
  (setup-mock-host-context) ; SYSCODEPAGE stays at the catalogue's ""
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-system-codepage)))
    (is (string= "ANSI"
                 (clautolisp.autolisp-runtime:autolisp-string-value result)))))

(test clal-drawing-codepage-tracks-dwgcodepage
  (%install-codepages "UTF-8" "ANSI_1252")
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-drawing-codepage)))
    (is (string= "CP-1252"
                 (clautolisp.autolisp-runtime:autolisp-string-value result)))))

(test clal-codepage-mismatch-p-nil-when-equal
  (%install-codepages "UTF-8" "UTF-8")
  (is (null (clautolisp.autolisp-builtins-core::builtin-clal-codepage-mismatch-p))))

(test clal-codepage-mismatch-p-true-when-different
  (%install-codepages "ANSI_1252" "ANSI_1250")
  ;; Returns the AutoLISP T symbol, not the CL t.
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-codepage-mismatch-p)))
    (is (not (null result)))))

(test clal-codepage-mismatch-p-compares-canonical-forms
  ;; "ANSI_1252" and "WINDOWS-1252" name the same code page through
  ;; different spellings — must NOT register as a mismatch.
  (%install-codepages "ANSI_1252" "WINDOWS-1252")
  (is (null (clautolisp.autolisp-builtins-core::builtin-clal-codepage-mismatch-p))))
