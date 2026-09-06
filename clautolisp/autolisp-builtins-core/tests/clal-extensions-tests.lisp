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

;;; --- clal-binding family (ncurses-key-bindings.issue) ------------------

(test clal-binding-builtins-forward-to-the-ui-hook
  ;; The CLAL-BINDING family converts the key to a CL string and forwards to
  ;; *ui-binding-hook* (installed by the debugger UI). With no UI loaded the
  ;; builtins are a no-op; here a stub hook records the calls.
  (let ((calls '()))
    (let ((clautolisp.autolisp-runtime:*ui-binding-hook*
            (lambda (op &rest args) (push (list* op args) calls) "z")))
      (clautolisp.autolisp-builtins-core::builtin-clal-binding
       (clautolisp.autolisp-runtime:make-autolisp-string "C-x C-f")
       (clautolisp.autolisp-runtime:make-autolisp-string "sedit load"))
      (clautolisp.autolisp-builtins-core::builtin-clal-remove-binding
       (clautolisp.autolisp-runtime:make-autolisp-string "C-x C-f")))
    (setf calls (nreverse calls))
    (is (eq :bind (first (first calls))))
    (is (equal "C-x C-f" (second (first calls))))            ; key -> CL string
    (is (equal "sedit load"                                  ; command forwarded
               (clautolisp.autolisp-runtime:autolisp-string-value (third (first calls)))))
    (is (eq :unbind (first (second calls))))
    (is (equal "C-x C-f" (second (second calls))))))

(test clal-binding-is-a-no-op-without-a-ui
  ;; No debugger UI loaded (hook nil) -> the builtins are harmless no-ops.
  (let ((clautolisp.autolisp-runtime:*ui-binding-hook* nil))
    (is (null (clautolisp.autolisp-builtins-core::builtin-clal-binding
               (clautolisp.autolisp-runtime:make-autolisp-string "z")
               (clautolisp.autolisp-runtime:make-autolisp-string "continue"))))
    (is (null (clautolisp.autolisp-builtins-core::builtin-clal-binding-lookup
               (clautolisp.autolisp-runtime:make-autolisp-string "z"))))))

;;; --- opaque lisp-object handles + clal frame/window/face builtins ------

(test opaque-lisp-object-reports-its-type-and-prints-unreadably
  (clautolisp.autolisp-runtime:reset-lisp-object-wrappers)
  (let* ((obj (list :a :b))
         (w (clautolisp.autolisp-runtime:wrap-lisp-object obj "WINDOW" (lambda () "sedit"))))
    (is (clautolisp.autolisp-runtime:lisp-object-p w))
    (is (clautolisp.autolisp-runtime:lisp-object-p w "WINDOW"))
    (is (not (clautolisp.autolisp-runtime:lisp-object-p w "FRAME")))
    ;; (type handle) -> WINDOW
    (is (string= "WINDOW" (clautolisp.autolisp-runtime:autolisp-symbol-name
                           (clautolisp.autolisp-runtime:autolisp-type w))))
    (is (search "#<WINDOW \"sedit\"" (prin1-to-string w)))
    ;; interned: same object -> EQ handle; unwrap round-trips
    (is (eq w (clautolisp.autolisp-runtime:wrap-lisp-object obj "WINDOW")))
    (is (eq obj (clautolisp.autolisp-runtime:unwrap-lisp-object w "WINDOW")))))

(test clal-object-builtins-forward-to-the-ui-object-hook
  (let ((calls '()))
    (let ((clautolisp.autolisp-runtime:*ui-object-hook*
            (lambda (op &rest args) (push (cons op args) calls) op)))
      (clautolisp.autolisp-builtins-core::builtin-clal-make-window
       (list (cons (clautolisp.autolisp-runtime:make-autolisp-string "name")
                   (clautolisp.autolisp-runtime:make-autolisp-string "sedit"))))
      (clautolisp.autolisp-builtins-core::builtin-clal-frame-list)
      (clautolisp.autolisp-builtins-core::builtin-clal-define-face
       (clautolisp.autolisp-runtime:make-autolisp-string "warn")))
    (setf calls (nreverse calls))
    (is (eq :make-window (first (first calls))))
    (is (eq :frame-list (first (second calls))))
    (is (eq :define-face (first (third calls))))))

(test clal-object-builtins-are-no-ops-without-a-ui
  (let ((clautolisp.autolisp-runtime:*ui-object-hook* nil))
    (is (null (clautolisp.autolisp-builtins-core::builtin-clal-make-window nil)))
    (is (null (clautolisp.autolisp-builtins-core::builtin-clal-frame-list)))))

(test clal-call-with-temp-window-forwards-to-hook
  (let ((calls '()))
    (let ((clautolisp.autolisp-runtime:*ui-object-hook*
            (lambda (op &rest args) (push (cons op args) calls) :ok)))
      (is (eq :ok (clautolisp.autolisp-builtins-core::builtin-clal-call-with-temp-window
                   nil (clautolisp.autolisp-runtime:make-autolisp-string "fn")))))
    (is (eq :with-temp-window (car (first calls))))))

(test clal-window-op-builtins-forward-to-the-hook
  (let ((calls '()))
    (let ((clautolisp.autolisp-runtime:*ui-object-hook*
            (lambda (op &rest args) (push (cons op args) calls) op)))
      (clautolisp.autolisp-builtins-core::builtin-clal-clear-window)
      (clautolisp.autolisp-builtins-core::builtin-clal-move-cursor-to 2 3)
      (clautolisp.autolisp-builtins-core::builtin-clal-window-put
       0 0 (clautolisp.autolisp-runtime:make-autolisp-string "x")))
    (setf calls (nreverse calls))
    (is (eq :clear-window (first (first calls))))
    (is (eq :move-cursor-to (first (second calls))))
    (is (equal '(2 3) (subseq (rest (second calls)) 0 2)))   ; row col (+ nil window)
    (is (eq :window-put (first (third calls))))))
