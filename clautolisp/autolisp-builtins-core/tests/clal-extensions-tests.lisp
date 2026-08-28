(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Tests for the CLAL-* clautolisp extensions.
;;;;
;;;; See autolisp-spec §16 ~clautolisp Extensions~ for the normative
;;;; entries.

(defun setup-cador-context ()
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock    (clautolisp.cador:make-cador)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- clal-sysvar-list ---------------------------------------------

(test clal-sysvar-list-returns-1836-entries-on-default-mock
  (setup-cador-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list)))
    (is (listp result))
    (is (= 1836 (length result)))
    (is (every (lambda (x)
                 (typep x 'clautolisp.autolisp-runtime:autolisp-string))
               result))))

(test clal-sysvar-list-is-sorted-lexicographically
  (setup-cador-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (is (equal values (sort (copy-list values) #'string<)))))

(test clal-sysvar-list-includes-well-known-names
  (setup-cador-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (dolist (n '("ANGBASE" "CMDECHO" "ERRNO" "LISPSYS" "OSMODE"
                 "PROJECTAWARE" "TRUSTEDPATHS" "USERI1"))
      (is (member n values :test #'string=)
          "expected ~A in CLAL-SYSVAR-LIST" n))))

;;; --- clal-sysvar-apropos ------------------------------------------

(test clal-sysvar-apropos-ang-matches-angle-family
  (setup-cador-context)
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
  (setup-cador-context)
  (let* ((upper (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ANG")))
         (lower (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ang")))
         (mixed (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "Ang"))))
    (is (= (length upper) (length lower)))
    (is (= (length upper) (length mixed)))))

(test clal-sysvar-apropos-empty-string-returns-all-1836
  (setup-cador-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string ""))))
    (is (= 1836 (length result)))))

(test clal-sysvar-apropos-no-match-returns-nil
  (setup-cador-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string
                  "DEFINITELY_NOT_A_SUBSTRING_OF_ANY_NAME_xyzzy"))))
    (is (null result))))

(test clal-sysvar-apropos-rejects-non-string-pattern
  (setup-cador-context)
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
  "Set up a fresh cador context and write SYS / DWG into the
host's SYSCODEPAGE / DWGCODEPAGE cells via the launch-time bypass."
  (setup-cador-context)
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
  (setup-cador-context) ; SYSCODEPAGE stays at the catalogue's ""
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
  (setup-cador-context)
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
  (setup-cador-context)
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
  (setup-cador-context)
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
  (setup-cador-context)
  (let* ((host (clautolisp.autolisp-runtime:current-evaluation-host))
         (clautolisp.autolisp-runtime:*enc-diagnostic-suppress-p* t))
    (clautolisp.autolisp-host:host-set-derived-sysvar host "SYSCODEPAGE" "ANSI_1252")
    (clautolisp.autolisp-builtins-core::set-drawing-codepage "ANSI_1250")
    (is (string= "ANSI_1250"
                 (clautolisp.cador::sysvar-cell-value
                  (clautolisp.cador:cador-sysvar host "DWGCODEPAGE"))))))

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

;;; --- aldo configuration (CLAL-*-ALDO-CONFIGURATION) ----------------

(defun %aldo-config-assoc (key-name config)
  "Value of KEY-NAME (a string) in the AutoLISP assoc-list CONFIG."
  (cdr (assoc (clautolisp.autolisp-runtime:intern-autolisp-symbol key-name)
              config :test #'eq)))

(defun %aldo-sym-name (object)
  (and (typep object 'clautolisp.autolisp-runtime:autolisp-symbol)
       (clautolisp.autolisp-runtime:autolisp-symbol-name object)))

(test aldo-config-default-parses
  (setup-cador-context)
  (let ((config (clautolisp.autolisp-builtins-core::default-aldo-configuration-value)))
    (is (consp config))
    (is (string= "SEXP" (%aldo-sym-name (%aldo-config-assoc "NAVIGATOR" config))))
    (is (string= "UNICODE" (%aldo-sym-name (%aldo-config-assoc "THEME" config))))
    (is (eql 24 (%aldo-config-assoc "SOURCE-WINDOW-HEIGHT" config)))
    (is (eql 4301 (%aldo-config-assoc "DEFAULT-ALDB-LISTENING-PORT" config)))))

(test aldo-config-lazy-seed
  (setup-cador-context)
  (let ((sym (clautolisp.autolisp-builtins-core::aldo-config-symbol)))
    (is (not (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p sym)))
    (let ((value (clautolisp.autolisp-builtins-core::aldo-configuration-value)))
      (is (consp value))
      (is (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p sym))
      (is (string= "SEXP" (%aldo-sym-name (%aldo-config-assoc "NAVIGATOR" value)))))))

(test aldo-config-save-load-roundtrip
  (setup-cador-context)
  (let ((path (merge-pathnames "aldo-core-roundtrip.conf" (uiop:temporary-directory)))
        (sym (clautolisp.autolisp-builtins-core::aldo-config-symbol)))
    (unwind-protect
         (progn
           ;; set the variable to a modified configuration, then save
           (clautolisp.autolisp-runtime:set-variable
            sym (first (clautolisp.autolisp-runtime:read-runtime-from-string
                        "((navigator . line) (pager-height . 42))"
                        :source-name "test")))
           (clautolisp.autolisp-builtins-core::save-aldo-configuration-to path)
           (is (probe-file path))
           ;; clobber the variable, then load it back from the file
           (clautolisp.autolisp-runtime:set-variable
            sym (clautolisp.autolisp-builtins-core::default-aldo-configuration-value))
           (is (string= "SEXP" (%aldo-sym-name
                                (%aldo-config-assoc "NAVIGATOR"
                                                    (clautolisp.autolisp-runtime:autolisp-symbol-value sym)))))
           (let ((loaded (clautolisp.autolisp-builtins-core::load-aldo-configuration-from path)))
             (is (string= "LINE" (%aldo-sym-name (%aldo-config-assoc "NAVIGATOR" loaded))))
             (is (eql 42 (%aldo-config-assoc "PAGER-HEIGHT" loaded)))
             ;; the variable itself was updated
             (is (string= "LINE" (%aldo-sym-name
                                  (%aldo-config-assoc "NAVIGATOR"
                                                      (clautolisp.autolisp-runtime:autolisp-symbol-value sym)))))))
      (ignore-errors (delete-file path)))))

(test aldo-config-strings-survive-the-save-load-roundtrip
  ;; the saved file must READ back: the ASCII decoration glyphs ("^" "["
  ;; "]") and the listening address are STRINGS and must be written quoted
  ;; (prin1 semantics). The bug: the save used princ semantics, writing
  ;; (selection ascii [ ]) — not readable back as strings.
  (setup-cador-context)
  (let ((path (merge-pathnames "aldo-core-strings.conf" (uiop:temporary-directory)))
        (sym (clautolisp.autolisp-builtins-core::aldo-config-symbol)))
    (unwind-protect
         (progn
           (clautolisp.autolisp-runtime:set-variable
            sym (clautolisp.autolisp-builtins-core::default-aldo-configuration-value))
           (clautolisp.autolisp-builtins-core::save-aldo-configuration-to path)
           (let ((text (uiop:read-file-string path)))
             (is (search "\"^\"" text))              ; glyph written as a string
             (is (search "\"127.0.0.1\"" text)))     ; address too
           (let ((loaded (clautolisp.autolisp-builtins-core::load-aldo-configuration-from path)))
             (is (typep (%aldo-config-assoc "DEFAULT-ALDB-LISTENING-ADDRESS" loaded)
                        'clautolisp.autolisp-runtime:autolisp-string))))
      (ignore-errors (delete-file path)))))

(test aldo-config-file-is-ascii-friendly
  (setup-cador-context)
  (let ((path (merge-pathnames "aldo-core-ascii.conf" (uiop:temporary-directory)))
        (sym (clautolisp.autolisp-builtins-core::aldo-config-symbol)))
    (unwind-protect
         (progn
           (clautolisp.autolisp-runtime:set-variable
            sym (clautolisp.autolisp-builtins-core::default-aldo-configuration-value))
           (clautolisp.autolisp-builtins-core::save-aldo-configuration-to path)
           (let ((text (uiop:read-file-string path)))
             (is (every (lambda (ch) (< (char-code ch) 128)) text)) ; pure ASCII
             (is (search "navigator" text :test #'char-equal)) ; reader upcases symbols
             (is (search "9205" text))   ; current-pp glyph as a code point
             ;; and it reads back as valid AutoLISP data
             (is (consp (first (clautolisp.autolisp-runtime:read-runtime-from-string text
                                                                                     :source-name "rt"))))))
      (ignore-errors (delete-file path)))))

;;; --- CL drop: CLAUTOLISPDROP / CLAL-COMMON-LISP (cl-debugging.issue) ---

;;; AutoLISP -> Common Lisp form conversion.

(test clal-al->cl-passes-numbers-and-nil-through
  (is (eql 5 (clautolisp.autolisp-builtins-core::%clal-al->cl 5)))
  (is (eql 2.5d0 (clautolisp.autolisp-builtins-core::%clal-al->cl 2.5d0)))
  (is (null (clautolisp.autolisp-builtins-core::%clal-al->cl nil))))

(test clal-al->cl-unwraps-strings-and-reads-symbols
  (is (string= "hi" (clautolisp.autolisp-builtins-core::%clal-al->cl
                     (clautolisp.autolisp-runtime:make-autolisp-string "hi"))))
  (is (string= "CAR" (symbol-name
                      (clautolisp.autolisp-builtins-core::%clal-al->cl
                       (clautolisp.autolisp-runtime:intern-autolisp-symbol "CAR"))))))

(test clal-al->cl-recurses-into-conses
  (is (equal '(1 2 3)
             (clautolisp.autolisp-builtins-core::%clal-al->cl (list 1 2 3)))))

;;; Common Lisp -> AutoLISP conversion.

(test clal-cl->al-numbers-nil-and-strings
  (is (eql 7 (clautolisp.autolisp-builtins-core::%clal-cl->al 7)))
  (is (typep (clautolisp.autolisp-builtins-core::%clal-cl->al 1.5)
             'double-float))
  (is (null (clautolisp.autolisp-builtins-core::%clal-cl->al nil)))
  (is (string= "hi" (clautolisp.autolisp-runtime:autolisp-string-value
                     (clautolisp.autolisp-builtins-core::%clal-cl->al "hi")))))

(test clal-cl->al-keyword-gets-leading-colon
  (is (string= ":BAR"
               (clautolisp.autolisp-runtime:autolisp-symbol-name
                (clautolisp.autolisp-builtins-core::%clal-cl->al :bar)))))

(test clal-cl->al-symbol-interns-upcased-name
  (is (string= "FOO"
               (clautolisp.autolisp-runtime:autolisp-symbol-name
                (clautolisp.autolisp-builtins-core::%clal-cl->al 'foo)))))

(test clal-cl->al-recurses-into-conses
  (is (equal '(1 2 3)
             (clautolisp.autolisp-builtins-core::%clal-cl->al '(1 2 3)))))

(test clal-cl->al-rejects-out-of-range-integer
  (is (eq :caught
          (handler-case
              (progn (clautolisp.autolisp-builtins-core::%clal-cl->al (expt 2 40))
                     :no-error)
            (error () :caught)))))

(test clal-cl->al-rejects-circular-structure
  (let ((x (list 1)))
    (setf (cdr x) x)
    (is (eq :caught
            (handler-case
                (progn (clautolisp.autolisp-builtins-core::%clal-cl->al x)
                       :no-error)
              (error () :caught))))))

;;; CLAL-COMMON-LISP evaluation entry.

(test clal-common-lisp-evaluates-autolisp-form
  (setup-cador-context)
  (is (= 3 (clautolisp.autolisp-builtins-core::builtin-clal-common-lisp
            (list (clautolisp.autolisp-runtime:intern-autolisp-symbol "+") 1 2)))))

(test clal-common-lisp-evaluates-string-form
  (setup-cador-context)
  (is (= 42 (clautolisp.autolisp-builtins-core::builtin-clal-common-lisp
             (clautolisp.autolisp-runtime:make-autolisp-string "(* 6 7)")))))

(test clal-common-lisp-on-error-ignore-returns-nil
  (setup-cador-context)
  (let ((common-lisp-user::*clal-on-error* :ignore))
    (is (null (clautolisp.autolisp-builtins-core::builtin-clal-common-lisp
               (clautolisp.autolisp-runtime:make-autolisp-string "(error \"x\")"))))))

(test clal-common-lisp-on-error-object-returns-value
  (setup-cador-context)
  (let ((common-lisp-user::*clal-on-error* 99))
    (is (= 99 (clautolisp.autolisp-builtins-core::builtin-clal-common-lisp
               (clautolisp.autolisp-runtime:make-autolisp-string "(error \"x\")"))))))

;;; CLAUTOLISPDROP shadow / restore of the CLAL-COMMON-LISP binding.

(defun %reset-clautolisp-drop ()
  (setf clautolisp.autolisp-builtins-core::*clautolisp-drop-active* nil
        clautolisp.autolisp-builtins-core::*clautolisp-drop-saved-binding* nil)
  (clautolisp.autolisp-runtime:autolisp-makunbound
   (clautolisp.autolisp-runtime:intern-autolisp-symbol "CLAL-COMMON-LISP")))

(test clautolisp-drop-installs-and-unbinds-clal-common-lisp
  (setup-cador-context)
  (%reset-clautolisp-drop)
  (let ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "CLAL-COMMON-LISP")))
    (is (not (clautolisp.autolisp-runtime:autolisp-symbol-function-bound-p sym)))
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 1)
    (is (clautolisp.autolisp-runtime:autolisp-symbol-function-bound-p sym))
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 0)
    (is (not (clautolisp.autolisp-runtime:autolisp-symbol-function-bound-p sym)))))

(test clautolisp-drop-preserves-user-binding
  (setup-cador-context)
  (%reset-clautolisp-drop)
  (let* ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "CLAL-COMMON-LISP"))
         (stub (clautolisp.autolisp-runtime:make-autolisp-string "USER")))
    (clautolisp.autolisp-runtime:set-autolisp-symbol-value sym stub)
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 1)
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 0)
    (is (eq stub (clautolisp.autolisp-runtime:autolisp-symbol-value sym)))))

(test clautolisp-drop-is-idempotent-on-repeated-enable
  (setup-cador-context)
  (%reset-clautolisp-drop)
  (let* ((sym (clautolisp.autolisp-runtime:intern-autolisp-symbol "CLAL-COMMON-LISP"))
         (stub (clautolisp.autolisp-runtime:make-autolisp-string "USER")))
    (clautolisp.autolisp-runtime:set-autolisp-symbol-value sym stub)
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 1)
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 1) ; must not re-save the builtin
    (clautolisp.autolisp-builtins-core::%apply-clautolisp-drop 0)
    (is (eq stub (clautolisp.autolisp-runtime:autolisp-symbol-value sym)))))

;;; --- clal-clipboard-* + clal-sedit (sedit spec §2, §5.4) ----------

(defun %mock-clipboard-provider (box)
  (clautolisp.sedit:make-clipboard-provider
   :mock :available-p (constantly t)
   :put-text (lambda (s) (setf (car box) s) nil)
   :get-text (lambda () (car box))))

(defun %al-string (x) (clautolisp.autolisp-runtime:make-autolisp-string x))
(defun %al->src (v) (clautolisp.autolisp-builtins-core:autolisp-value->string v nil))
(defun %al-read (s) (clautolisp.autolisp-runtime:autolisp-read-from-string s))

(test clal-clipboard-put-and-get-text-round-trip
  (let* ((box (list nil))
         (clautolisp.sedit:*clipboard-provider* (%mock-clipboard-provider box)))
    (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-put-text (%al-string "hi there"))
    (is (equal "hi there" (car box)))
    (let ((got (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-get-text)))
      (is (typep got 'clautolisp.autolisp-runtime:autolisp-string))
      (is (equal "hi there" (clautolisp.autolisp-runtime:autolisp-string-value got))))))

(test clal-clipboard-copy-and-paste-sexp-round-trip
  (setup-cador-context)
  (let* ((box (list nil))
         (clautolisp.sedit:*clipboard-provider* (%mock-clipboard-provider box)))
    ;; copy an AutoLISP list; its source text lands on the system clipboard
    (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-copy-sexp (%al-read "(1 2 3)"))
    (is (equal "(1 2 3)" (car box)))
    ;; paste parses it back into an equivalent AutoLISP object (never evaluated)
    (let ((pasted (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-paste-sexp)))
      (is (equal "(1 2 3)" (%al->src pasted))))))

(test clal-clipboard-copy-paste-round-trips-through-the-internal-clipboard
  ;; with the :NULL provider the system clipboard is empty, so paste falls back
  ;; to the in-process *clipboard* set by copy (clipboard-interface.org §Public API)
  (setup-cador-context)
  (let ((clautolisp.sedit:*clipboard-provider* :null))
    (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-copy-sexp (%al-read "(a b c)"))
    (let ((pasted (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-paste-sexp)))
      (is (string-equal "(a b c)" (%al->src pasted))))))

(test clal-clipboard-paste-does-not-evaluate-foreign-text
  (setup-cador-context)
  (let* ((box (list "#.(error \"boom\")"))
         (clautolisp.sedit:*clipboard-provider* (%mock-clipboard-provider box)))
    ;; a malicious read-macro on the clipboard must not run (no error signalled)
    (let ((pasted (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-paste-sexp)))
      (is (not (null pasted))))))

(test clal-sedit-quitting-immediately-returns-the-form
  (setup-cador-context)
  (let* ((*standard-input* (make-string-input-stream (format nil "q~%")))
         (*standard-output* (make-string-output-stream))
         (result (clautolisp.autolisp-builtins-core::builtin-clal-sedit
                  (%al-read "(defun foo () 1)"))))
    (is (string-equal "(defun foo nil 1)" (%al->src result)))
    (is (not (null clautolisp.sedit:*clal-sedit-initial-form*)))))

(test clal-sedit-recalls-a-recorded-definition
  (setup-cador-context)
  (let ((clautolisp.sedit:*sedit-recording* nil))
    (clautolisp.sedit:record-source "(defun bar (x) (* x x))" "<test>")
    (let* ((*standard-input* (make-string-input-stream (format nil "q~%")))
           (*standard-output* (make-string-output-stream))
           (result (clautolisp.autolisp-builtins-core::builtin-clal-sedit
                    (clautolisp.autolisp-runtime:intern-autolisp-symbol "BAR"))))
      (is (string-equal "(defun bar (x) (* x x))" (%al->src result))))))

(test clal-sedit-edits-then-returns-the-modified-form
  (setup-cador-context)
  (let* ((*standard-input* (make-string-input-stream
                            ;; select the body, replace it, then quit
                            (format nil "d~%>>~%replace (* x 2)~%q~%")))
         (*standard-output* (make-string-output-stream))
         (result (clautolisp.autolisp-builtins-core::builtin-clal-sedit
                  (%al-read "(defun foo (x) x)"))))
    (is (string-equal "(defun foo (x) (* x 2))" (%al->src result)))))

(test clal-sedit-debug-prefix-routes-to-the-debug-command-hook
  ;; spec §7: `debug'/`aldo' CMD in the editor runs CMD in the attached session
  ;; via *debug-command-hook* (so `aldo help' shows the debugger help)
  (setup-cador-context)
  (let* ((calls '())
         (clautolisp.autolisp-runtime:*debug-command-hook* (lambda (c) (push c calls) nil))
         (*standard-input* (make-string-input-stream (format nil "nav~%aldo help~%q~%")))
         (*standard-output* (make-string-output-stream)))
    (clautolisp.autolisp-builtins-core::builtin-clal-sedit (%al-read "(a b)"))
    (is (equal '("help") calls))))

(test clal-sedit-debug-prefix-without-a-debugger-notes-it
  (setup-cador-context)
  (let* ((clautolisp.autolisp-runtime:*debug-command-hook* nil)
         (out (make-string-output-stream))
         (*standard-input* (make-string-input-stream (format nil "aldo help~%q~%")))
         (*standard-output* out))
    (clautolisp.autolisp-builtins-core::builtin-clal-sedit (%al-read "(a b)"))
    (is (search "no debugger attached" (get-output-stream-string out)))))

(test clal-sedit-evaluates-a-lisp-form-at-the-prompt
  ;; a (form) at the SEDIT/NAV prompt evaluates and prints, like the REPL
  (setup-cador-context)
  (let* ((out (make-string-output-stream))
         ;; `quote' is a special form — no arithmetic builtins needed here
         (*standard-input* (make-string-input-stream (format nil "(quote 30)~%q~%")))
         (*standard-output* out))
    (clautolisp.autolisp-builtins-core::builtin-clal-sedit (%al-read "(a b)"))
    (is (search "30" (get-output-stream-string out)))))

;;; --- the public *clal-* extension variables are bound + updated ---

(test clal-extension-variables-are-bound-after-install
  ;; install-core-builtins binds the spec's public *clal-* variables so AutoLISP
  ;; code can read them and alref-apropos (which lists only BOUND symbols) finds
  ;; them (sedit spec §2/§5.4/§5.6)
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (flet ((bound (n) (clautolisp.autolisp-runtime:autolisp-symbol-value-bound-p
                     (clautolisp.autolisp-runtime:intern-autolisp-symbol n))))
    (dolist (n '("*CLAL-CLIPBOARD*" "*CLAL-SEDIT-INITIAL-FORM*" "*CLAL-SEDIT-LAST-RESULT*"
                 "*CLAL-FORM*" "*CLAL-RESULT*" "*CLAL-SOURCE-FORM*"
                 "*CLAL-ON-ERROR*" "*CLAL-ALDO-CONFIGURATION*"))
      (is (bound n) "expected ~A to be bound" n))))

(test clal-clipboard-copy-sexp-sets-the-autolisp-variable
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (let ((clautolisp.sedit:*clipboard-provider* :null))
    (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-copy-sexp (%al-read "(a b c)"))
    (let ((v (clautolisp.autolisp-runtime:autolisp-symbol-value
              (clautolisp.autolisp-runtime:intern-autolisp-symbol "*CLAL-CLIPBOARD*"))))
      (is (string-equal "(sexp (a b c) \"(a b c)\")" (%al->src v))))))

(test clal-sedit-eval-shifts-the-history-variables
  ;; §5.6: each sedit evaluation shifts *clal-result*/-1/-2 and *clal-form*/-1/-2
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (flet ((ev (s) (clautolisp.autolisp-builtins-core::%clal-sedit-eval
                  (clautolisp.sedit:parse-form s)))
         (v (n) (%al->src (clautolisp.autolisp-builtins-core::%clal-var-value n))))
    (ev "(quote 10)") (ev "(quote 20)") (ev "(quote 30)")
    (is (equal "30" (v "*CLAL-RESULT*")))
    (is (equal "20" (v "*CLAL-RESULT-1*")))
    (is (equal "10" (v "*CLAL-RESULT-2*")))
    (is (string-equal "(quote 30)" (v "*CLAL-FORM*")))
    (is (string-equal "(quote 20)" (v "*CLAL-FORM-1*")))
    (is (string-equal "(sexp (quote 30) \"(quote 30)\")" (v "*CLAL-SOURCE-FORM*")))))

(test clal-clipboard-put-text-sets-the-autolisp-variable
  ;; put-text records the string in *clal-clipboard* so the variable reflects it
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins)
  (let ((clautolisp.sedit:*clipboard-provider* :null))
    (clautolisp.autolisp-builtins-core::builtin-clal-clipboard-put-text (%al-string "Hello World"))
    (is (equal "Hello World"
               (clautolisp.autolisp-runtime:autolisp-string-value
                (clautolisp.autolisp-runtime:autolisp-symbol-value
                 (clautolisp.autolisp-runtime:intern-autolisp-symbol "*CLAL-CLIPBOARD*")))))))

;;; --- clal-optimize / clal-optimization ------------------------------
;;;
;;; The optimization qualities are the AutoLISP-facing surface of the
;;; compiler and the debugger's instrumentation, so what is tested here
;;; is the ALGEBRA -- which levels, in which relation, produce which
;;; forks -- not the wording of the list that comes back.
;;;
;;;   non-instrumented fork   always present; compiled iff SPEED >= 1
;;;   instrumented fork       present iff DEBUG >= SPACE; compiled iff SPEED >= 2
;;;   eager (at definition)   iff SPEED >= 3
;;;
;;; Until 2.0.8 SPEED was pinned at 0 and none of this existed to test.

(defun %optimize (text)
  "Set qualities from an AutoLISP source list, return the resulting alist
of QUALITY -> level."
  (clautolisp.autolisp-builtins-core::builtin-clal-optimize
   (first (clautolisp.autolisp-runtime:read-runtime-from-string text)))
  (mapcar (lambda (quality)
            (cons quality
                  (clautolisp.autolisp-builtins-core::clal-optimization-level
                   quality)))
          '(:debug :space :speed)))

(defun %signals-runtime-error-p (thunk)
  "True iff THUNK signals an AutoLISP runtime error. Written as a
predicate rather than with FiveAM's SIGNALS because this suite imports
IS and not SIGNALS, and an unimported FiveAM macro fails at RUN time on
the branch you expect never to take."
  (handler-case (progn (funcall thunk) nil)
    (autolisp-runtime-error () t)))

(defun %signals-error-p (thunk)
  "True iff THUNK signals a CL ERROR. SET-CLAL-OPTIMIZATION-LEVELS is not an
AutoLISP builtin -- it is called from the CLI, before any AutoLISP evaluation
context exists -- so it signals a plain ERROR, not an AUTOLISP-RUNTIME-ERROR."
  (handler-case (progn (funcall thunk) nil)
    (error () t)))

(defun %reset-optimization ()
  (setf clautolisp.autolisp-builtins-core::*clal-optimization*
        (list (cons :debug 3) (cons :space 0) (cons :speed 2)))
  (clautolisp.autolisp-builtins-core::apply-clal-optimization))

(test clal-optimize-no-longer-pins-speed-to-zero
  "The regression test for unpinning SPEED. It was forced back to 0 on
every call, so that asking for it was silently ineffective -- documented
as such, because there was no compiler for it to reach. There is now."
  (%reset-optimization)
  (unwind-protect
       (let ((levels (%optimize "((speed 3))")))
         (is (eql 3 (cdr (assoc :speed levels)))))
    (%reset-optimization)))

(test speed-decides-which-forks-compile
  "SPEED 1 compiles the plain fork; the instrumented fork needs SPEED 2.
Different levels on purpose: compiling the instrumented fork costs a
second compilation of every function and buys less."
  (%reset-optimization)
  (unwind-protect
       (progn
         (%optimize "((speed 0))")
         (is (not (clautolisp.autolisp-runtime:autolisp-compile-plain-fork-p)))
         (is (not (clautolisp.autolisp-runtime:autolisp-compile-instrumented-fork-p)))
         (%optimize "((speed 1))")
         (is (clautolisp.autolisp-runtime:autolisp-compile-plain-fork-p))
         (is (not (clautolisp.autolisp-runtime:autolisp-compile-instrumented-fork-p)))
         (%optimize "((speed 2))")
         (is (clautolisp.autolisp-runtime:autolisp-compile-plain-fork-p))
         (is (clautolisp.autolisp-runtime:autolisp-compile-instrumented-fork-p))
         (is (not (clautolisp.autolisp-runtime:autolisp-compile-eagerly-p)))
         (%optimize "((speed 3))")
         (is (clautolisp.autolisp-runtime:autolisp-compile-eagerly-p)))
    (%reset-optimization)))

(test the-instrumented-fork-is-kept-when-debug-is-at-least-space
  "SPACE is not a switch of its own: it is what DEBUG is weighed against.
The EQUAL case is the boundary worth pinning -- (DEBUG 3) (SPACE 3) says
the two matter equally, and the fork is kept."
  (%reset-optimization)
  (unwind-protect
       (progn
         (%optimize "((debug 3) (space 0))")
         (is (not (null clautolisp.autolisp-runtime:*debug-instrumentation-enabled*)))
         (%optimize "((debug 3) (space 3))")
         (is (not (null clautolisp.autolisp-runtime:*debug-instrumentation-enabled*))
             "DEBUG = SPACE dropped the instrumented fork")
         (%optimize "((debug 0) (space 3))")
         (is (null clautolisp.autolisp-runtime:*debug-instrumentation-enabled*))
         (%optimize "((debug 0) (space 0))")
         (is (not (null clautolisp.autolisp-runtime:*debug-instrumentation-enabled*))
             "DEBUG 0 with SPACE 0 asked for no size saving, so the fork stays"))
    (%reset-optimization)))

(test a-bare-quality-symbol-means-level-three
  (%reset-optimization)
  (unwind-protect
       (let ((levels (%optimize "(speed)")))
         (is (eql 3 (cdr (assoc :speed levels)))))
    (%reset-optimization)))

(test unmentioned-qualities-keep-their-level
  (%reset-optimization)
  (unwind-protect
       (let ((levels (%optimize "((speed 1))")))
         (is (eql 3 (cdr (assoc :debug levels))))
         (is (eql 0 (cdr (assoc :space levels))))
         (is (eql 1 (cdr (assoc :speed levels)))))
    (%reset-optimization)))

(test clal-optimization-reports-what-the-engine-is-actually-doing
  "Reading back a setting must describe the engine's real configuration.
While SPEED was pinned this was the documented trap -- you asked for 3
and read back 0 -- and it is worth a test now that the answer is honest."
  (%reset-optimization)
  (unwind-protect
       (progn
         (%optimize "((speed 1))")
         (let ((reported
                 (clautolisp.autolisp-builtins-core::builtin-clal-optimization)))
           (is (= 3 (length reported)))
           (is (equal '("DEBUG" "SPACE" "SPEED")
                      (mapcar (lambda (entry)
                                (clautolisp.autolisp-runtime:autolisp-symbol-name
                                 (first entry)))
                              reported)))
           (is (equal '(3 0 1) (mapcar #'second reported)))
           (is (eql 1 clautolisp.autolisp-runtime:*autolisp-speed-level*))))
    (%reset-optimization)))

(test clal-optimize-rejects-nonsense
  (%reset-optimization)
  (unwind-protect
       (progn
         (is (%signals-runtime-error-p (lambda () (%optimize "((debug 4))")))
             "a level above 3 was accepted")
         (is (%signals-runtime-error-p (lambda () (%optimize "((debug -1))")))
             "a negative level was accepted")
         (is (%signals-runtime-error-p (lambda () (%optimize "((quickness 3))")))
             "an unknown quality was accepted")
         (is (%signals-runtime-error-p (lambda () (%optimize "(42)")))
             "a non-symbol element was accepted"))
    (%reset-optimization)))

(test set-clal-optimization-levels-is-the-same-request-by-another-door
  "SET-CLAL-OPTIMIZATION-LEVELS is what --optimize / -O calls. It takes
(QUALITY . LEVEL) conses instead of an AutoLISP list, so that the CLI does
not build a list only for CLAL-OPTIMIZE to take it apart again -- but it must
land on exactly the same configuration, because both go through
APPLY-CLAL-OPTIMIZATION. If these two ever disagreed, the same level would
mean one thing from the command line and another from AutoLISP."
  (%reset-optimization)
  (unwind-protect
       (progn
         (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
          '((:speed . 3) (:debug . 0) (:space . 1)))
         (is (eql 3 (clautolisp.autolisp-builtins-core::clal-optimization-level :speed)))
         (is (eql 0 (clautolisp.autolisp-builtins-core::clal-optimization-level :debug)))
         (is (eql 1 (clautolisp.autolisp-builtins-core::clal-optimization-level :space)))
         ;; The gates, not just the bookkeeping: DEBUG 0 < SPACE 1 drops the
         ;; instrumented fork, and SPEED 3 is the eager level.
         (is (eql 3 clautolisp.autolisp-runtime:*autolisp-speed-level*))
         (is (null clautolisp.autolisp-runtime:*debug-instrumentation-enabled*)))
    (%reset-optimization)))

(test set-clal-optimization-levels-leaves-unmentioned-qualities-alone
  "An option that mentions SPEED says nothing about DEBUG or SPACE. This is
what makes `-O2' safe to type: it must not quietly reset the other two."
  (%reset-optimization)
  (unwind-protect
       (progn
         (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
          '((:speed . 0)))
         (is (eql 0 (clautolisp.autolisp-builtins-core::clal-optimization-level :speed)))
         (is (eql 3 (clautolisp.autolisp-builtins-core::clal-optimization-level :debug)))
         (is (eql 0 (clautolisp.autolisp-builtins-core::clal-optimization-level :space))))
    (%reset-optimization)))

(test set-clal-optimization-levels-applies-pairs-left-to-right
  "A repeated quality takes its LAST value, so `-O2 -O3' means 3. The CLI
accumulates occurrences rather than replacing them, so the list handed here
really can name one quality twice."
  (%reset-optimization)
  (unwind-protect
       (progn
         (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
          '((:speed . 2) (:speed . 3)))
         (is (eql 3 (clautolisp.autolisp-builtins-core::clal-optimization-level :speed))))
    (%reset-optimization)))

(test set-clal-optimization-levels-rejects-nonsense
  "The same range and vocabulary CLAL-OPTIMIZE enforces. The CLI parser
rejects these first, but this entry point is exported and must not be a way
around the check."
  (%reset-optimization)
  (unwind-protect
       (progn
         (is (%signals-error-p
              (lambda () (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
                          '((:speed . 4)))))
             "a level above 3 was accepted")
         (is (%signals-error-p
              (lambda () (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
                          '((:quickness . 3)))))
             "an unknown quality was accepted"))
    (%reset-optimization)))

(test set-clal-optimization-levels-is-all-or-nothing
  "A bad pair half-way through must leave the qualities exactly as they were.
Applying the good pairs and then signalling would leave a configuration nobody
asked for, and the caller would never see it -- it only gets the error."
  (%reset-optimization)
  (unwind-protect
       (progn
         (is (%signals-error-p
              (lambda () (clautolisp.autolisp-builtins-core:set-clal-optimization-levels
                          '((:speed . 0) (:quickness . 3)))))
             "the bad pair was accepted")
         (is (eql 2 (clautolisp.autolisp-builtins-core::clal-optimization-level :speed))
             "SPEED was changed by a call that signalled")
         (is (eql 2 clautolisp.autolisp-runtime:*autolisp-speed-level*)
             "the runtime gate was changed by a call that signalled"))
    (%reset-optimization)))

;;; --- clal-compile-file / clal-compile-system ------------------------
;;;
;;; A .lap is a native host FASL, renamed: loadable into a running image
;;; alongside other applications, and therefore specific to the host Lisp
;;; and the clautolisp version that built it (pjb, 2026-08-28).
;;;
;;; The test that matters is the ROUND TRIP -- compile to an artefact,
;;; then load the artefact into a FRESH context and run what it defines.
;;; Checking only that a file appeared would pass for an artefact that is
;;; empty, or one whose symbols are interned in a table nobody reads.

(defun %write-lsp (pathname text)
  (with-open-file (out pathname :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create)
    (write-string text out))
  pathname)

(defun %eval-here (text)
  "Evaluate TEXT in the CURRENT context. Not RUN-AUTOLISP-STRING: that
starts a fresh session, which would discard the definitions a freshly
loaded artefact just installed."
  (clautolisp.autolisp-runtime:autolisp-eval
   (first (clautolisp.autolisp-runtime:read-runtime-from-string text))
   (clautolisp.autolisp-runtime:current-evaluation-context)))

(defun %as-autolisp-path (pathname)
  (clautolisp.autolisp-runtime:make-autolisp-string (namestring pathname)))

(defun %fresh-builtin-context ()
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.autolisp-builtins-core:install-core-builtins))

(defun %load-here (pathname)
  (clautolisp.autolisp-builtins-core::builtin-load (%as-autolisp-path pathname)))

(test clal-compile-file-writes-an-artefact-that-loads-and-runs
  "The round trip. The artefact must define its functions in whatever
image loads it -- which is the claim that a printed AUTOLISP-SYMBOL, or
one read back as a fresh struct, would silently break."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname p :type "lsp" :keep nil)
    (%write-lsp p "(defun sq (x) (* x x))
(defun twice (x) (+ x x))")
    (let* ((lap (make-pathname :type "lap" :defaults p))
           (result (clautolisp.autolisp-builtins-core::builtin-clal-compile-file
                    (%as-autolisp-path p))))
      (unwind-protect
           (progn
             (is (not (null result)) "clal-compile-file reported failure")
             (is (not (null (probe-file lap))) "no .lap was written")
             ;; A FRESH context: nothing the compilation did in this image
             ;; may be what makes the next assertions pass.
             (%fresh-builtin-context)
             (is (not (null (%load-here lap))) "the .lap did not load")
             (is (eql 81 (%eval-here "(sq 9)")))
             (is (eql 14 (%eval-here "(twice 7)"))))
        (ignore-errors (delete-file lap))))))

(test a-loaded-artefact-brings-its-compiled-bodies-with-it
  "The point of an artefact over its source: the functions arrive already
compiled, so they never pay the threshold or the host compiler again."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname p :type "lsp" :keep nil)
    (%write-lsp p "(defun sq3 (x) (* x x))")
    (let ((lap (make-pathname :type "lap" :defaults p)))
      (unwind-protect
           (progn
             (clautolisp.autolisp-builtins-core::builtin-clal-compile-file
              (%as-autolisp-path p))
             (%fresh-builtin-context)
             (%load-here lap)
             (is (not (null
                       (clautolisp.autolisp-runtime:autolisp-usubr-compiled-body
                        (clautolisp.autolisp-runtime:lookup-function
                         (clautolisp.autolisp-runtime:intern-autolisp-symbol
                          "SQ3")))))
                 "a function from a .lap arrived without its compiled body"))
        (ignore-errors (delete-file lap))))))

(test an-artefact-keeps-the-source-body-so-it-stays-debuggable
  "Dropping BODY would make artefacts load faster and functions from them
impossible to instrument. The debugger weaves its fork FROM the body."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname p :type "lsp" :keep nil)
    (%write-lsp p "(defun sq4 (x) (* x x))")
    (let ((lap (make-pathname :type "lap" :defaults p)))
      (unwind-protect
           (progn
             (clautolisp.autolisp-builtins-core::builtin-clal-compile-file
              (%as-autolisp-path p))
             (%fresh-builtin-context)
             (%load-here lap)
             (is (not (null
                       (clautolisp.autolisp-runtime:autolisp-usubr-body
                        (clautolisp.autolisp-runtime:lookup-function
                         (clautolisp.autolisp-runtime:intern-autolisp-symbol
                          "SQ4")))))
                 "a function from a .lap lost its source body"))
        (ignore-errors (delete-file lap))))))

(test an-artefact-carries-non-defun-top-level-forms-too
  "A source file is not only DEFUNs. Whatever else it does at top level
has to happen when the artefact is loaded, in the same order."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname p :type "lsp" :keep nil)
    (%write-lsp p "(setq greeting \"hello\")
(defun greet () greeting)")
    (let ((lap (make-pathname :type "lap" :defaults p)))
      (unwind-protect
           (progn
             (clautolisp.autolisp-builtins-core::builtin-clal-compile-file
              (%as-autolisp-path p))
             (%fresh-builtin-context)
             (%load-here lap)
             (is (equal "hello"
                        (clautolisp.autolisp-runtime:autolisp-string-value
                         (%eval-here "(greet)")))))
        (ignore-errors (delete-file lap))))))

(test clal-compile-file-reports-a-missing-file-the-way-load-does
  (%fresh-builtin-context)
  (is (null (clautolisp.autolisp-builtins-core::builtin-clal-compile-file
             (clautolisp.autolisp-runtime:make-autolisp-string
              "/nonexistent/definitely-not-here.lsp")))))

(test clal-compile-system-needs-an-output-name
  "There is no sensible default name for an artefact built from several
sources, so the argument is required rather than guessed at."
  (%fresh-builtin-context)
  (is (%signals-runtime-error-p
       (lambda ()
         (clautolisp.autolisp-builtins-core::builtin-clal-compile-system
          nil (list (clautolisp.autolisp-runtime:make-autolisp-string "a.lsp")))))))

(test clal-compile-system-builds-one-artefact-from-several-sources
  "The reason the system form exists: one compilation over all the files,
so a call in an earlier file to a function defined in a later one
resolves -- and one artefact to ship, not one per source."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname a :type "lsp" :keep nil)
    (uiop:with-temporary-file (:pathname b :type "lsp" :keep nil)
      (uiop:with-temporary-file (:pathname out :type "lap" :keep nil)
        ;; A calls B's function; B is compiled second.
        (%write-lsp a "(defun caller (x) (callee x))")
        (%write-lsp b "(defun callee (x) (* x 3))")
        (let ((result
                (clautolisp.autolisp-builtins-core::builtin-clal-compile-system
                 (%as-autolisp-path out)
                 (list (%as-autolisp-path a) (%as-autolisp-path b)))))
          (is (not (null result)) "clal-compile-system reported failure"))
        (%fresh-builtin-context)
        (is (not (null (%load-here out))) "the system .lap did not load")
        (is (eql 21 (%eval-here "(caller 7)")))))))

(test loading-a-lap-that-is-not-one-fails-with-its-own-diagnostic
  "A .lap is host- and version-specific by design, so `this file will not
load' is a normal outcome and needs a message that says why, rather than
the reader's confusion at finding a FASL where source was expected."
  (%fresh-builtin-context)
  (uiop:with-temporary-file (:pathname p :type "lap" :keep nil)
    (%write-lsp p "this is not a fasl")
    (is (%signals-runtime-error-p (lambda () (%load-here p))))))
