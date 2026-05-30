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

;;; --- clal-file-encoding (BOM sniff, Phase 5) ----------------------
;;;
;;; (clal-file-encoding PATH) opens the file, reads the first 4 bytes,
;;; and reports the canonical clautolisp encoding implied by the BOM
;;; (or "ANSI" when no BOM is present). Encoding-dispatch issue's
;;; cross-dialect translation table is the source of truth for the
;;; vocabulary; this test grid covers every row that produces a BOM.

(defun %write-bytes (path bytes)
  "Write the unsigned-byte-8 vector BYTES to PATH, overwriting."
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :element-type '(unsigned-byte 8))
    (write-sequence bytes out)))

(defun %fixture-encoding-string (sniff-path bom-bytes)
  "Write BOM-BYTES to SNIFF-PATH then return the encoding string
CLAL-FILE-ENCODING reports for that file."
  (%write-bytes sniff-path (coerce bom-bytes '(vector (unsigned-byte 8))))
  (setup-mock-host-context)
  (clautolisp.autolisp-runtime:autolisp-string-value
   (clautolisp.autolisp-builtins-core::builtin-clal-file-encoding
    (clautolisp.autolisp-runtime:make-autolisp-string (namestring sniff-path)))))

(test clal-file-encoding-no-bom-reports-ansi
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "ANSI"
                 (%fixture-encoding-string p #(72 73 10))))))   ; "HI\n"

(test clal-file-encoding-utf-8-bom-detected
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-8-BOM"
                 (%fixture-encoding-string p #(#xEF #xBB #xBF 72))))))

(test clal-file-encoding-utf-16-le-bom-detected
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-16-LE"
                 (%fixture-encoding-string p #(#xFF #xFE 72 0))))))

(test clal-file-encoding-utf-16-be-bom-detected
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-16-BE"
                 (%fixture-encoding-string p #(#xFE #xFF 0 72))))))

(test clal-file-encoding-utf-32-le-bom-detected
  ;; FF FE 00 00 — distinguishes from UTF-16-LE only by the 00 00.
  ;; The sniffer must check UTF-32 before UTF-16 to avoid the prefix
  ;; collision.
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-32-LE"
                 (%fixture-encoding-string p #(#xFF #xFE 0 0 72 0 0 0))))))

(test clal-file-encoding-utf-32-be-bom-detected
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-32-BE"
                 (%fixture-encoding-string p #(0 0 #xFE #xFF 0 0 0 72))))))

(test clal-file-encoding-missing-file-returns-nil
  ;; Resolution failure returns AutoLISP nil and sets ERRNO 73, matching
  ;; LOAD's missing-file behaviour. Don't open a fixture; pick a path
  ;; that demonstrably doesn't exist.
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-file-encoding
                 (clautolisp.autolisp-runtime:make-autolisp-string
                  "/this/path/definitely/does/not/exist/0xDEADBEEF.txt"))))
    (is (null result))))

(test clal-file-encoding-partial-prefix-not-mistaken-for-utf-32-le
  ;; A file containing only FF FE (no following 00 00) is UTF-16-LE,
  ;; NOT UTF-32-LE. Regression check on the ambiguity guard.
  (uiop:with-temporary-file (:pathname p :type "txt" :keep nil)
    (is (string= "UTF-16-LE"
                 (%fixture-encoding-string p #(#xFF #xFE))))))

;;; --- enc-codepage-mismatch (Phase 8 item 4) -----------------------
;;;
;;; set-drawing-codepage is the hook drawing-load code paths call when
;;; the runtime reads a DWG codepage header. Diagnostic fires when the
;;; canonical form differs from SYSCODEPAGE — covers the classic
;;; "Czech-authored drawing on a French host" mistake.

(defun %install-codepages-and-capture-mismatch (sys-codepage dwg-codepage)
  "Set SYSCODEPAGE via the launch bypass, then call set-drawing-codepage
with DWG-CODEPAGE and return the captured enc-* diagnostic string."
  (setup-mock-host-context)
  (let ((host (clautolisp.autolisp-runtime:current-evaluation-host))
        (sink (make-string-output-stream)))
    (clautolisp.autolisp-host:host-set-derived-sysvar host "SYSCODEPAGE" sys-codepage)
    (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* sink))
      (clautolisp.autolisp-builtins-core::set-drawing-codepage dwg-codepage))
    (get-output-stream-string sink)))

(test enc-codepage-mismatch-emitted-when-different
  (let ((diagnostics (%install-codepages-and-capture-mismatch "ANSI_1252" "ANSI_1250")))
    (is (search "[enc-codepage-mismatch]" diagnostics))
    (is (search "CP-1250" diagnostics))
    (is (search "CP-1252" diagnostics))))

(test enc-codepage-mismatch-silent-when-same
  (let ((diagnostics (%install-codepages-and-capture-mismatch "ANSI_1252" "ANSI_1252")))
    (is (string= "" diagnostics))))

(test enc-codepage-mismatch-silent-across-equivalent-spellings
  ;; "ANSI_1252" and "WINDOWS-1252" canonicalise to the same CP-1252
  ;; — the wrapper compares canonical forms, so no mismatch fires.
  (let ((diagnostics (%install-codepages-and-capture-mismatch "ANSI_1252" "WINDOWS-1252")))
    (is (string= "" diagnostics))))

(test set-drawing-codepage-actually-updates-the-sysvar
  (setup-mock-host-context)
  (let* ((host (clautolisp.autolisp-runtime:current-evaluation-host))
         (clautolisp.autolisp-runtime:*enc-diagnostic-suppress-p* t))
    (clautolisp.autolisp-host:host-set-derived-sysvar host "SYSCODEPAGE" "ANSI_1252")
    (clautolisp.autolisp-builtins-core::set-drawing-codepage "ANSI_1250")
    (is (string= "ANSI_1250"
                 (clautolisp.autolisp-mock-host::sysvar-cell-value
                  (clautolisp.autolisp-mock-host:mock-host-sysvar host "DWGCODEPAGE"))))))

;;; --- enc-unknown-codepage (Phase 8 item 10) ------------------------

(defun %capture-canonical-codepage-diagnostics (raw)
  (let ((sink (make-string-output-stream)))
    (let ((clautolisp.autolisp-runtime:*enc-diagnostic-stream* sink))
      (clautolisp.autolisp-builtins-core::%canonical-codepage-string raw))
    (get-output-stream-string sink)))

(test enc-unknown-codepage-silent-for-known-spellings
  (dolist (known '("UTF-8" "UTF-16-LE" "UTF-16-BE" "ISO-8859-1"
                    "US-ASCII" "ANSI" "MBCS" "CP-1252" "CP1252"
                    "ANSI_1252" "WINDOWS-1252" ""))
    (is (string= "" (%capture-canonical-codepage-diagnostics known))
        "Known codepage spelling ~S unexpectedly raised enc-unknown-codepage" known)))

(test enc-unknown-codepage-emitted-for-typo
  (let ((diagnostics
         (%capture-canonical-codepage-diagnostics "NOT-AN-ENCODING-NAME")))
    (is (search "[enc-unknown-codepage]" diagnostics))))

(test enc-unknown-codepage-passes-input-through-unchanged
  ;; The diagnostic is informational; the canonicaliser returns the
  ;; raw string so downstream code keeps working.
  (let ((clautolisp.autolisp-runtime:*enc-diagnostic-suppress-p* t))
    (is (string=
         "GARBAGE-ENCODING"
         (clautolisp.autolisp-builtins-core::%canonical-codepage-string
          "GARBAGE-ENCODING")))))
