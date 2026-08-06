(in-package #:clautolisp.autolisp-cli.tests)

(in-suite autolisp-cli-suite)

;;;; CLI-launch unit tests (autolisp-cli-tests-missing.issue).
;;;;
;;;; The autolisp-cli system installs the launch-time *AUTOLISP-…*
;;;; transmit bindings and stamps a handful of host sysvars from them
;;;; (engine identity, TEMPPREFIX, launch codepage). Before this suite
;;;; existed those helpers were only exercised end-to-end by binary
;;;; runs. Here we drive them directly against a fresh MockHost.

;;; --- Engine identity stamping -----------------------------------
;;;
;;; The mock host's sysvar catalogue is generated from BricsCAD data,
;;; so PROGRAM / VENDORNAME / PLATFORM / ACADVER would masquerade as
;;; Bricsys unless APPLY-CLAUTOLISP-HOST-IDENTITY overwrites them.

(test identity-stamping-overwrites-program-vendor-platform
  (let ((context (setup-mock-evaluation-context)))
    (clautolisp.autolisp-cli::apply-clautolisp-host-identity
     context "1.7.13" "CLAUTOLISP")
    ;; frontend name is downcased for PROGRAM.
    (is (string= "clautolisp" (mock-getvar context "PROGRAM")))
    (is (string= "clautolisp" (mock-getvar context "PRODUCT")))
    (is (string= "clautolisp" (mock-getvar context "VENDORNAME")))
    (is (string= "clautolisp" (mock-getvar context "PLATFORM")))
    (is (string= "1.7.13" (mock-getvar context "ACADVER")))))

(test identity-stamping-blank-version-leaves-acadver-untouched
  ;; An empty version string must not clobber ACADVER with "".
  (let* ((context (setup-mock-evaluation-context))
         (before (mock-getvar context "ACADVER")))
    (clautolisp.autolisp-cli::apply-clautolisp-host-identity
     context "" "CLAUTOLISP")
    (is (equal before (mock-getvar context "ACADVER")))
    ;; …the rest of the identity is still stamped.
    (is (string= "clautolisp" (mock-getvar context "PROGRAM")))))

;;; --- TEMPPREFIX resolution --------------------------------------
;;;
;;; Resolution order at launch: vl-registry -> TMPDIR/TEMP/TMP env ->
;;; platform default. A value already stored in the registry wins over
;;; the environment; the resolved value is normalised to a forward-slash
;;; directory ending in a slash. The registry store is pointed at a
;;; throwaway temp file so the test never touches the user's real store.

(defmacro with-hermetic-registry (() &body body)
  "Run BODY with the mock vl-registry backed by a fresh, empty temp
sexp file (UNIX backend), so registry reads/writes stay hermetic."
  (let ((path (gensym "REGPATH")))
    `(let* ((,path (uiop:merge-pathnames*
                    (format nil "clautolisp-cli-test-registry-~36R.sexp"
                            (random (expt 36 8)))
                    (uiop:temporary-directory)))
            (clautolisp.cador::*vl-registry-backend* :unix)
            (clautolisp.cador::*mock-registry-path* ,path)
            (clautolisp.cador::*mock-registry* nil)
            (clautolisp.cador::*mock-registry-loaded-from* nil))
       (unwind-protect (progn ,@body)
         (ignore-errors (delete-file ,path))))))

(test tempprefix-registry-value-wins-and-is-normalised
  (with-hermetic-registry ()
    (let* ((context (setup-mock-evaluation-context))
           (host (clautolisp.autolisp-runtime:current-evaluation-host context)))
      ;; Pre-seed the registry with a stored preference (no trailing slash).
      (clautolisp.autolisp-host:host-registry-write
       host
       clautolisp.autolisp-cli::+tempprefix-registry-key+
       clautolisp.autolisp-cli::+tempprefix-registry-value+
       "/my/scratch")
      (clautolisp.autolisp-cli::apply-tempprefix-default context)
      ;; Normalised: trailing slash appended.
      (is (string= "/my/scratch/" (mock-getvar context "TEMPPREFIX"))))))

(test tempprefix-resolves-non-empty-when-registry-empty
  (with-hermetic-registry ()
    (let ((context (setup-mock-evaluation-context)))
      ;; No stored value -> falls through to TMPDIR/TEMP/TMP or the
      ;; platform default; either way TEMPPREFIX must end up non-empty
      ;; and slash-terminated (never the catalogue's "" placeholder).
      (clautolisp.autolisp-cli::apply-tempprefix-default context)
      (let ((value (mock-getvar context "TEMPPREFIX")))
        (is (stringp value))
        (is (plusp (length value)))
        (is (char= #\/ (char value (1- (length value)))))))))

(test tempprefix-normalise-appends-slash-and-forward-slashes
  ;; %NORMALIZE-TEMP-PREFIX: backslashes -> forward slashes, and a
  ;; trailing slash is guaranteed.
  (is (string= "/foo/"
               (clautolisp.autolisp-cli::%normalize-temp-prefix "/foo")))
  (is (string= "/foo/"
               (clautolisp.autolisp-cli::%normalize-temp-prefix "/foo/")))
  (is (string= "C:/Temp/"
               (clautolisp.autolisp-cli::%normalize-temp-prefix "C:\\Temp\\"))))

;;; --- Option value parsers ---------------------------------------

(test parse-host-accepts-cador-nihil-and-aliases
  (is (eql :cador (parse-host "cador" "--host")))
  (is (eql :nihil (parse-host "nihil" "--host")))
  ;; deprecated aliases: mock->cador, null/none->nihil
  (is (eql :cador (parse-host "mock" "--host")))
  (is (eql :null (parse-host "null" "--host")))
  (is (eql :null (parse-host "none" "--host"))))

(test parse-host-rejects-unknown
  (signals cli-usage-error (parse-host "bogus" "--host")))

(test parse-dialect-accepts-known-and-keywordises
  (is (eql :strict (parse-dialect "strict" "--dialect")))
  (is (eql :clautolisp (parse-dialect "clautolisp" "--dialect")))
  ;; legacy enumerated vendor keywords still parse
  (is (eql :autocad-2026 (parse-dialect "autocad-2026" "--dialect")))
  (is (eql :bricscad-v26 (parse-dialect "bricscad-v26" "--dialect")))
  (is (eql :autocad (parse-dialect "autocad" "--dialect"))))

(test parse-dialect-accepts-platform-version-spellings
  ;; dialect-platform-version-axis: platform + version facets keywordise
  ;; verbatim (resolved to a descriptor downstream by find-autolisp-dialect).
  (is (eql :autocad-mac      (parse-dialect "autocad-mac" "--dialect")))
  (is (eql :autocad-2022     (parse-dialect "autocad-2022" "--dialect")))
  (is (eql :autocad-mac-2027 (parse-dialect "autocad-mac-2027" "--dialect")))
  (is (eql :bricscad-mac     (parse-dialect "bricscad-mac" "--dialect")))
  (is (eql :bricscad-linux   (parse-dialect "bricscad-linux" "--dialect")))
  (is (eql :autocad-2027     (parse-dialect "autocad-2027" "--dialect"))))

(test parse-dialect-rejects-unknown
  (signals cli-usage-error (parse-dialect "klingon" "--dialect"))
  ;; a product with an unparseable suffix is still rejected
  (signals cli-usage-error (parse-dialect "autocad-nonsense" "--dialect")))

(test parse-timeout-positive-integer-only
  (is (= 30 (parse-timeout "30" "--timeout")))
  (signals cli-usage-error (parse-timeout "0" "--timeout"))
  (signals cli-usage-error (parse-timeout "-5" "--timeout"))
  (signals cli-usage-error (parse-timeout "abc" "--timeout")))
