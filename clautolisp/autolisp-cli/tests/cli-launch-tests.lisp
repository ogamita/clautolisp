(in-package #:clautolisp.autolisp-cli.tests)

(in-suite autolisp-cli-suite)

;;;; CLI-launch unit tests (autolisp-cli-tests-missing.issue).
;;;;
;;;; The autolisp-cli system installs the launch-time *AUTOLISP-…*
;;;; transmit bindings and stamps a handful of host sysvars from them
;;;; (engine identity, TEMPPREFIX, launch codepage). Before this suite
;;;; existed those helpers were only exercised end-to-end by binary
;;;; runs. Here we drive them directly against a fresh cador.

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
            (clautolisp.cador::*cador-registry-path* ,path)
            (clautolisp.cador::*cador-registry* nil)
            (clautolisp.cador::*cador-registry-loaded-from* nil))
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

(test parse-host-accepts-cador-cadtui-nihil-and-aliases
  (is (eql :cador (parse-host "cador" "--host")))
  (is (eql :cadtui (parse-host "cadtui" "--host")))
  (is (eql :nihil (parse-host "nihil" "--host")))
  ;; deprecated aliases: mock->cador, null/none->nihil
  (is (eql :cador (parse-host "mock" "--host")))
  (is (eql :null (parse-host "null" "--host")))
  (is (eql :null (parse-host "none" "--host"))))

(test parse-host-rejects-unknown
  (signals cli-usage-error (parse-host "bogus" "--host")))

(test print-hosts-lists-the-backends
  (let ((text (with-output-to-string (s)
                (clautolisp.autolisp-cli:print-hosts :stream s))))
    (is (search "cador" text))
    (is (search "cadtui" text))
    (is (search "nihil" text))
    ;; the deprecated aliases are noted, not silently dropped.
    (is (search "mock" text))))

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

;;; --- encoding-name resolution -----------------------------------

(test resolve-encoding-name-accepts-every-mac-roman-spelling
  ;; -e / -E must accept the same spellings the language accepts on
  ;; (open … "macroman") and (load … "macroman"), and must hand the
  ;; implementation the keyword it registers — SBCL knows :MAC-ROMAN
  ;; but not :MACROMAN, CCL knows both. Before macroman-encoding-name
  ;; `-e macroman' was a usage error on SBCL and fine on CCL.
  (dolist (spelling '("mac-roman" "MACROMAN" "mac_roman" "MAC_ROMAN"
                      "macintosh" "cp10000"))
    (multiple-value-bind (canonical keyword)
        (clautolisp.autolisp-cli:resolve-encoding-name spelling "-e")
      (is (string= "MAC-ROMAN" canonical)
          "RESOLVE-ENCODING-NAME(~S) canonical name" spelling)
      (is (eq :mac-roman keyword)
          "RESOLVE-ENCODING-NAME(~S) keyword" spelling)))
  ;; The line-terminator suffix still composes with it.
  (multiple-value-bind (canonical keyword)
      (clautolisp.autolisp-cli:resolve-encoding-name "macroman-mac" "-e")
    (is (string= "MAC-ROMAN-mac" canonical))
    (is (equal '(:mac-roman :newline :cr) keyword)))
  ;; …and a genuine typo is still a usage error.
  (signals cli-usage-error
    (clautolisp.autolisp-cli:resolve-encoding-name "mac-romain" "-e")))

(test parse-dcl-mode-accepts-ncurses
  "--dcl ncurses (and the `curses' spelling) select the full-screen renderer,
alongside tui/gui/auto; a typo is a usage error (dcl-ncurses-renderer.issue)."
  (is (eq :ncurses (clautolisp.autolisp-cli:parse-dcl-mode "ncurses" "--dcl")))
  (is (eq :ncurses (clautolisp.autolisp-cli:parse-dcl-mode "curses" "--dcl")))
  (is (eq :tui (clautolisp.autolisp-cli:parse-dcl-mode "tui" "--dcl")))
  (is (eq :gui (clautolisp.autolisp-cli:parse-dcl-mode "gui" "--dcl")))
  (is (eq :auto (clautolisp.autolisp-cli:parse-dcl-mode "auto" "--dcl")))
  (signals cli-usage-error
    (clautolisp.autolisp-cli:parse-dcl-mode "nope" "--dcl")))

;;; --- front-end bindings (alfe-clautolisp-backend-semantic-parity) ---
;;;
;;; alfe --backend subprocess hands the child engine the *AUTOLISP-...*
;;; bindings it resolved, through --front-end-bindings FILE, so user code sees
;;; the same values as under the in-process engine. The file must carry every
;;; value kind a binding can hold back unchanged: strings (non-ASCII, quotes,
;;; backslashes, newlines -- *AUTOLISP-HELP* has them all), symbols, integers,
;;; NIL and nested lists (*AUTOLISP-ACTIONS*).

(test front-end-bindings-file-round-trips-every-value-kind
  (let* ((text (format nil "caf~C \"quoted\" back\\slash~%second line"
                       (code-char 233)))
         (bindings
           (list (list "*AUTOLISP-VERSION*" (clautolisp.autolisp-runtime:make-autolisp-string "9.9.9"))
                 (list "*AUTOLISP-FRONTEND*" (clautolisp.autolisp-runtime:intern-autolisp-symbol "ALFE"))
                 (list "*AUTOLISP-TIMEOUT*" 42)
                 (list "*AUTOLISP-MAIN*" nil)
                 (list "*AUTOLISP-HELP*" (clautolisp.autolisp-runtime:make-autolisp-string text))
                 (list "*AUTOLISP-ACTIONS*"
                       (list (list (clautolisp.autolisp-runtime:intern-autolisp-symbol "EVAL")
                                   (clautolisp.autolisp-runtime:make-autolisp-string "(+ 1 2)"))))
                 (list "*AUTOLISP-PAIR*"
                       (cons 1 (clautolisp.autolisp-runtime:intern-autolisp-symbol "T")))))
         (path (uiop:tmpize-pathname
                (merge-pathnames "front-end-bindings-test.sexp"
                                 (uiop:temporary-directory)))))
    (unwind-protect
         (progn
           (clautolisp.autolisp-cli:write-transmit-bindings-file path bindings)
           (let ((back (clautolisp.autolisp-cli:read-transmit-bindings-file path)))
             (is (equal (mapcar #'first bindings) (mapcar #'first back)))
             (flet ((value (name) (second (assoc name back :test #'string=))))
               (is (string= "9.9.9" (clautolisp.autolisp-runtime:autolisp-string-value
                                     (value "*AUTOLISP-VERSION*"))))
               (is (eq (clautolisp.autolisp-runtime:intern-autolisp-symbol "ALFE")
                       (value "*AUTOLISP-FRONTEND*")))
               (is (eql 42 (value "*AUTOLISP-TIMEOUT*")))
               (is (null (value "*AUTOLISP-MAIN*")))
               (is (string= text (clautolisp.autolisp-runtime:autolisp-string-value
                                  (value "*AUTOLISP-HELP*"))))
               (let ((action (first (value "*AUTOLISP-ACTIONS*"))))
                 (is (eq (clautolisp.autolisp-runtime:intern-autolisp-symbol "EVAL")
                         (first action)))
                 (is (string= "(+ 1 2)" (clautolisp.autolisp-runtime:autolisp-string-value
                                         (second action)))))
               (is (eql 1 (car (value "*AUTOLISP-PAIR*"))))
               (is (eq (clautolisp.autolisp-runtime:intern-autolisp-symbol "T")
                       (cdr (value "*AUTOLISP-PAIR*")))))))
      (ignore-errors (delete-file path)))))

(test front-end-bindings-file-unreadable-is-a-noinput-cli-error
  ;; The file is the option's input: missing is EX_NOINPUT, malformed
  ;; EX_DATAERR (sysexits-exit-statuses.issue).
  (is (eql clautolisp.sysexits:+ex-noinput+
           (handler-case
               (progn (clautolisp.autolisp-cli:read-transmit-bindings-file
                       "/nonexistent/front-end-bindings.sexp")
                      :no-error)
             (clautolisp.autolisp-cli:cli-error (c)
               (clautolisp.autolisp-cli:cli-error-status c)))))
  (let ((path (uiop:tmpize-pathname
               (merge-pathnames "front-end-bindings-bad.sexp"
                                (uiop:temporary-directory)))))
    (unwind-protect
         (progn
           (with-open-file (out path :direction :output :if-exists :supersede)
             (write-line "(:not-the-bindings 1 ())" out))
           (is (eql clautolisp.sysexits:+ex-dataerr+
                    (handler-case
                        (progn (clautolisp.autolisp-cli:read-transmit-bindings-file path)
                               :no-error)
                      (clautolisp.autolisp-cli:cli-error (c)
                        (clautolisp.autolisp-cli:cli-error-status c))))))
      (ignore-errors (delete-file path)))))

;;; --- action boundaries (alfe-clautolisp-backend-semantic-parity) -------
;;;
;;; --front-end-action-boundaries DIR: the child engine publishes a marker
;;; before and after each action and waits for the front end's reply, so
;;; alfe's per-action plug-in hooks run between two actions of ONE run.

(defun %fresh-boundary-directory ()
  (let ((directory (merge-pathnames
                    (format nil "action-boundaries-test-~36R/"
                            (random (expt 36 10) (make-random-state t)))
                    (uiop:temporary-directory))))
    (ensure-directories-exist directory)
    directory))

(test action-boundary-marker-round-trips
  (let ((directory (%fresh-boundary-directory)))
    (unwind-protect
         (let ((marker (clautolisp.autolisp-cli:write-action-boundary
                        directory 3 :post :kind :expression
                        ;; a base-string, which *PRINT-READABLY* would write
                        ;; in SBCL's own #A syntax
                        :value (coerce "\"caf\"" 'base-string)
                        :status 5)))
           (is (equal (namestring marker)
                      (namestring (clautolisp.autolisp-cli:action-boundary-pathname
                                   directory 3 :post))))
           (is (string= "0003-post" (pathname-name marker)))
           (is (equal '(:index 3 :phase :post :kind :expression :value "\"caf\"" :status 5)
                      (clautolisp.autolisp-cli:read-action-boundary marker)))
           (is (not (search "#A" (uiop:read-file-string marker)))))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))))

(test action-boundary-report-waits-for-the-reply
  (let ((directory (%fresh-boundary-directory)))
    (unwind-protect
         (progn
           ;; The reply is already there: the child goes on at once.
           (clautolisp.autolisp-cli:acknowledge-action-boundary directory 1 :pre)
           (is (eq t (clautolisp.autolisp-cli:report-action-boundary
                      directory 1 :pre :kind :file)))
           (is (probe-file (clautolisp.autolisp-cli:action-boundary-pathname
                            directory 1 :pre))))
      (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore))
    ;; The front end is gone (its directory with it): the child stops waiting.
    (is (null (clautolisp.autolisp-cli:wait-for-action-boundary-reply
               (merge-pathnames "gone/" directory) 1 :pre)))))

(test action-boundaries-off-run-the-action-plain
  (is (eql 42 (clautolisp.autolisp-cli:call-at-action-boundaries
               nil 1 :expression nil (lambda () 42)))))
