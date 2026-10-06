(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for the clautolisp backend (Phase 1).
;;;;
;;;; Acceptance criteria from
;;;; ../../issues/open/alfe-backend-clautolisp.issue:
;;;;
;;;;   - alfe --clautolisp -x '(+ 1 2)' → 3, exit 0
;;;;   - alfe --clautolisp -l fixture.lsp runs the file
;;;;   - --main C:MAIN calls the entry point
;;;;   - encoding round-trips for utf-8 / iso-8859-1 / windows-1252
;;;;
;;;; The subprocess variant is exercised only when clautolisp-sbcl is
;;;; built and present on disk — the test detects that and skips
;;;; otherwise, so a fresh checkout's `make test` doesn't depend on
;;;; the binary's existence.

(defun make-fresh-clautolisp-backend (&optional (variant :direct))
  "Construct a fresh clautolisp backend instance for tests. Avoids
the shared registry entry so tests can't accidentally mutate each
other's session state."
  (alfe.backend.clautolisp:make-clautolisp-backend :variant variant))

(defun start-clautolisp-direct-session (&key (dialect :strict) (host :cador))
  "Common test scaffolding: spin up a fresh in-process session with
no workdir (we exercise the captured-output path)."
  (let ((backend (make-fresh-clautolisp-backend :direct)))
    (alfe.backend:start-engine backend nil
                               :dialect dialect
                               :host host
                               :mock-input nil
                               :bootstrap-phase :full
                               :interactive-p nil)))

(test clautolisp-backend-start-classifies-the-run-frame
  "THE REGRESSION (windows-msys-paths-in-autolisp-load-alfe.issue).

Starting the engine anchors it to the live process in TWO ways: the
cwd, and the path RUN FRAME. alfe's backend copied the first half out
of the clautolisp tool's startup and not the second, so
*RUN-ENVIRONMENT* stayed the BUILD frame. On a mingw-SBCL-under-MSYS2
host the build frame carries the native drive-style override, so an
MSYS2 path mapped to nothing and `alfe --clautolisp' answered
LOAD-FILE-NOT-FOUND for a /c/Users/... path that `clautolisp' opened
fine.

This host is not Windows, so the two frames are the SAME identity
environment here and no value comparison could see the bug. What CAN
be seen is whether the backend classified the run frame AT ALL: the
slot is set to a sentinel first, and starting must replace it. That is
exactly the step alfe was skipping."
  (let ((sentinel (list :not-a-real-environment)))
    (setf clautolisp.pathname-mapping:*run-environment* sentinel)
    (start-clautolisp-direct-session)
    (is (not (eq sentinel clautolisp.pathname-mapping:*run-environment*))
        "alfe started the engine without classifying the run frame — an ~
MSYS2 /c/... path will not map")
    ;; and it is a real descriptor, not merely something else
    (is (not (null clautolisp.pathname-mapping:*run-environment*)))))

(test clautolisp-backend-is-registered
  "The clautolisp backend self-registers on load under :clautolisp,
so the CLI default-resolver finds it without an explicit init call."
  (let ((backend (alfe.backend:find-backend :clautolisp)))
    (is (not (null backend)))
    (is (eq :clautolisp (alfe.backend:backend-name backend)))))

(test clautolisp-direct-detect-always-succeeds
  "DETECT on the direct variant is unconditional — the engine *is*
the host Lisp."
  (let ((backend (make-fresh-clautolisp-backend :direct)))
    (is (eq backend (alfe.backend:detect backend)))))

(test clautolisp-direct-eval-plus-1-2-prints-three
  "Headline acceptance: -x '(+ 1 2)' evaluates to 3 in the direct
variant, status :success, and the value is \"3\". The backend itself
does not print the value — the CLI layer does (cf. the matching
CLI-RUN-CLAUTOLISP-* test). Here we only assert the value the
backend hands back."
  (let* ((session (start-clautolisp-direct-session))
         (plan    (list (alfe.backend:action-eval "(+ 1 2)")
                        (alfe.backend:action-quit)))
         (result  (alfe.backend:eval-plan session plan)))
    (is (eq :success (alfe.backend:eval-result-status result)))
    (is (string= "3" (alfe.backend:eval-result-value result)))
    (alfe.backend:shutdown session)))

(test clautolisp-direct-eval-multiple-forms
  "An action plan with several :eval actions runs them in order
against a single shared evaluation context — setq in one form,
visible in the next."
  (let* ((session (start-clautolisp-direct-session))
         (plan    (list (alfe.backend:action-eval "(setq x 7)")
                        (alfe.backend:action-eval "(+ x 1)")
                        (alfe.backend:action-quit)))
         (result  (alfe.backend:eval-plan session plan)))
    (is (eq :success (alfe.backend:eval-result-status result)))
    (is (string= "8" (alfe.backend:eval-result-value result)))
    (alfe.backend:shutdown session)))

(defun make-temp-fixture-path (prefix &optional (type "lsp"))
  "Build an absolute pathname inside the system temp directory for a
test fixture file. We construct the path by hand (rather than via
uiop:with-temporary-file) because the fixture has to outlive the
let* binding that builds it — load actions read it back later."
  (let* ((name (format nil "~A~D-~D.~A"
                       prefix (alfe.workdir::current-pid) (random 1000000) type)))
    (namestring (merge-pathnames name (uiop:temporary-directory)))))

(test clautolisp-direct-load-evaluates-file-and-side-effects
  "A :load action reads + evaluates the file in the shared context;
side effects (here, setq) survive into a subsequent :eval action."
  (let ((path (make-temp-fixture-path "alfe-test-load-")))
    (unwind-protect
        (progn
          (with-open-file (out path :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create
                                    :external-format :utf-8)
            (format out "(setq z 41)~%(setq z (+ z 1))~%"))
          (let* ((session (start-clautolisp-direct-session))
                 (plan (list (alfe.backend:action-load path)
                             (alfe.backend:action-eval "z")
                             (alfe.backend:action-quit)))
                 (result (alfe.backend:eval-plan session plan)))
            (is (eq :success (alfe.backend:eval-result-status result)))
            (is (string= "42" (alfe.backend:eval-result-value result)))
            (alfe.backend:shutdown session)))
      (when (probe-file path) (delete-file path)))))

(test clautolisp-direct-open-resolves-relative-path-against-cwd
  "Regression (cad-open-relative-path-not-resolved-vs-cwd.issue): a relative
path handed to OPEN resolves against the LIVE process cwd, not the image
build directory. The runtime's *autolisp-current-directory* is
DEFPARAMETER'd at build time; START-ENGINE re-reads getcwd so (open \"rel\"
...) opens a file under the caller's cwd, matching BricsCAD/AutoCAD. A
relative name with no matching file still returns nil."
  (let* ((dir (uiop:ensure-directory-pathname
               (merge-pathnames
                (format nil "alfe-test-relopen-~D-~D/"
                        (alfe.workdir::current-pid) (random 1000000))
                (uiop:temporary-directory))))
         (rel "fixture-rel.prj")
         (file (merge-pathnames rel dir)))
    (unwind-protect
        (progn
          (ensure-directories-exist dir)
          (with-open-file (out file :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create
                                    :external-format :utf-8)
            (write-line "(project fixture)" out))
          (uiop:with-current-directory (dir)
            ;; Relative name that exists -> opens (1).
            (let* ((session (start-clautolisp-direct-session))
                   (plan (list (alfe.backend:action-eval
                                (format nil "(if (open ~S \"r\") 1 0)" rel))
                               (alfe.backend:action-quit)))
                   (result (alfe.backend:eval-plan session plan)))
              (is (eq :success (alfe.backend:eval-result-status result)))
              (is (string= "1" (alfe.backend:eval-result-value result))
                  "relative OPEN should resolve against cwd; got ~S"
                  (alfe.backend:eval-result-value result))
              (alfe.backend:shutdown session))
            ;; Relative name that does not exist -> still nil (0).
            (let* ((session (start-clautolisp-direct-session))
                   (plan (list (alfe.backend:action-eval
                                "(if (open \"nope-missing.prj\" \"r\") 1 0)")
                               (alfe.backend:action-quit)))
                   (result (alfe.backend:eval-plan session plan)))
              (is (string= "0" (alfe.backend:eval-result-value result)))
              (alfe.backend:shutdown session))))
      (ignore-errors
        (uiop:delete-directory-tree dir :validate t
                                        :if-does-not-exist :ignore)))))

(test clautolisp-direct-main-calls-named-entry-point
  "(action-main \"FN\") looks up FN in the runtime and calls it as
the entry point. Result is the function's return value."
  (let* ((session (start-clautolisp-direct-session))
         (plan    (list (alfe.backend:action-eval "(defun the-entry () 100)")
                        (alfe.backend:action-main "THE-ENTRY")
                        (alfe.backend:action-quit)))
         (result  (alfe.backend:eval-plan session plan)))
    (is (eq :success (alfe.backend:eval-result-status result)))
    (is (string= "100" (alfe.backend:eval-result-value result)))
    (alfe.backend:shutdown session)))

(test clautolisp-direct-main-unknown-function-fails
  "Asking --main FN for a nonexistent FN surfaces BACKEND-EVAL-ERROR
and the result reports :failed."
  (let* ((session (start-clautolisp-direct-session))
         (plan    (list (alfe.backend:action-main "NO-SUCH-FUNCTION")
                        (alfe.backend:action-quit)))
         (result  (alfe.backend:eval-plan session plan)))
    (is (eq :failed (alfe.backend:eval-result-status result)))
    (alfe.backend:shutdown session)))

(test clautolisp-direct-runtime-error-is-failed-not-aborted
  "An AutoLISP runtime error during EVAL-PLAN sets STATUS to :failed
(matches exit code 1)."
  (let* ((session (start-clautolisp-direct-session))
         (plan    (list (alfe.backend:action-eval "(/ 1 0)")
                        (alfe.backend:action-quit)))
         (result  (alfe.backend:eval-plan session plan)))
    (is (eq :failed (alfe.backend:eval-result-status result)))
    (alfe.backend:shutdown session)))

(test clautolisp-direct-shutdown-is-idempotent
  "Two SHUTDOWN calls are fine; state is :stopped after the first."
  (let ((session (start-clautolisp-direct-session)))
    (alfe.backend:shutdown session)
    (is (eq :stopped (alfe.backend:session-state session)))
    (alfe.backend:shutdown session)
    (is (eq :stopped (alfe.backend:session-state session)))))

;;; --- encoding round-trips -------------------------------------------
;;;
;;; The spec calls out utf-8, iso-8859-1, and windows-1252 with LF/CRLF/CR
;;; line endings. We exercise the three encodings × LF + CRLF here
;;; (CR-only line endings are rare in modern AutoLISP source; the
;;; spec marks them as a stretch goal).

;;; The encoding tests below write fixtures byte-by-byte so we don't
;;; have to drag babel into the test deps. For ASCII payloads — the
;;; common case for AutoLISP source — every encoding produces the
;;; same bytes; we use distinguishing high-bit bytes per encoding to
;;; verify the load path honours the hint.

(defun write-bytes (path bytes)
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :element-type '(unsigned-byte 8))
    (write-sequence (coerce bytes '(simple-array (unsigned-byte 8) (*))) out)))

(defun ascii-bytes-for (string)
  "Encode an ASCII STRING as a list of byte codes. Signals if any
character is non-ASCII — keeps the test fixtures auditable."
  (loop for ch across string
        do (assert (< (char-code ch) 128))
        collect (char-code ch)))

(defun fixture-bytes (line-ending body-bytes-or-string)
  "Render BODY-BYTES-OR-STRING — an ASCII string or a list of
already-encoded bytes — followed by LINE-ENDING (:lf, :crlf, or :cr)."
  (let ((body (if (stringp body-bytes-or-string)
                  (ascii-bytes-for body-bytes-or-string)
                  body-bytes-or-string)))
    (append body (ecase line-ending
                   (:lf   (list 10))
                   (:crlf (list 13 10))
                   (:cr   (list 13))))))

(defun try-encoding-round-trip (encoding line-ending)
  "Write a fixture file using ENCODING + LINE-ENDING that sets
MESSAGE to \"ok\", load it through the alfe clautolisp backend with
the matching --encoding hint, and assert the value round-trips."
  (let ((path (make-temp-fixture-path
               (format nil "alfe-enc-~(~A~)-" encoding))))
    (unwind-protect
        (progn
          ;; The payload is pure ASCII so every encoding's
          ;; byte-sequence is identical; the round-trip really
          ;; verifies the load path doesn't choke on the hint and
          ;; that line-ending normalisation behaves.
          (write-bytes path (fixture-bytes line-ending "(setq message \"ok\")"))
          (let* ((session (start-clautolisp-direct-session))
                 (plan (list (alfe.backend:action-load
                              path :encoding (case encoding
                                               (:utf-8 "utf-8")
                                               (:iso-8859-1 "iso-8859-1")
                                               (:windows-1252 "windows-1252")))
                             (alfe.backend:action-eval "message")
                             (alfe.backend:action-quit)))
                 (result (alfe.backend:eval-plan session plan)))
            (prog1 (eq :success (alfe.backend:eval-result-status result))
              (alfe.backend:shutdown session))))
      (when (probe-file path) (delete-file path)))))

(test clautolisp-direct-encoding-keyword-helper
  "Internal ENCODING-KEYWORD maps the documented encoding strings to
the right Lisp external-format keywords (now delegated to the
shared clautolisp.autolisp-cli registry)."
  (is (eq :utf-8 (alfe.backend.clautolisp::encoding-keyword "utf-8")))
  (is (eq :utf-8 (alfe.backend.clautolisp::encoding-keyword "UTF-8")))
  (is (eq :iso-8859-1 (alfe.backend.clautolisp::encoding-keyword "iso-8859-1")))
  (is (eq :iso-8859-1 (alfe.backend.clautolisp::encoding-keyword "latin-1")))
  (is (eq :windows-1252 (alfe.backend.clautolisp::encoding-keyword "cp1252")))
  (is (eq :windows-1252 (alfe.backend.clautolisp::encoding-keyword "windows-1252")))
  ;; US-ASCII via every documented alias.
  (is (eq :us-ascii (alfe.backend.clautolisp::encoding-keyword "us-ascii")))
  (is (eq :us-ascii (alfe.backend.clautolisp::encoding-keyword "ascii"))))

(test clautolisp-direct-encoding-typo-rejected
  "A clearly-malformed encoding name (e.g. `uft-8') signals a
cli-usage-error from the shared validator rather than passing
through to OPEN and surfacing as an opaque external-format error
later. Plausibly-named-but-unknown encodings are still forwarded
to the implementation."
  (signals clautolisp.autolisp-cli:cli-usage-error
    (alfe.backend.clautolisp::encoding-keyword "8859"))
  (signals clautolisp.autolisp-cli:cli-usage-error
    (alfe.backend.clautolisp::encoding-keyword "/etc/passwd")))

(test clautolisp-direct-encoding-utf8-lf
  "UTF-8 source with LF line endings round-trips through -l."
  (is (try-encoding-round-trip :utf-8 :lf)))

(test clautolisp-direct-encoding-utf8-crlf
  "UTF-8 source with CRLF line endings round-trips through -l."
  (is (try-encoding-round-trip :utf-8 :crlf)))

(test clautolisp-direct-encoding-iso-8859-1
  "ISO-8859-1 source round-trips through -l with -e iso-8859-1."
  (is (try-encoding-round-trip :iso-8859-1 :lf)))

(test clautolisp-direct-encoding-windows-1252
  "windows-1252 (cp1252) source round-trips through -l with the
matching encoding hint."
  (is (try-encoding-round-trip :windows-1252 :lf)))

;;; --- CLI integration -----------------------------------------------

(test cli-run-clautolisp-x-plus-1-2-prints-three
  "End-to-end: alfe -x '(print (+ 1 2))' against the real clautolisp
backend prints \"3\" on stdout and exits 0.

Per the alfe spec (\"Action output semantics\"), `-x EXPR' does NOT
auto-print the value — the user must (print …) explicitly. So the
headline acceptance criterion is now `-x '(print (+ 1 2))' → 3' (was
`-x '(+ 1 2)' → 3' in versions before the spec clarification).

`--no-init' is needed to avoid the user's ~/.autolisp init file
which on the test host triggers an unrelated alref.lsp encoding
error; the test wants to exercise the action plan in isolation."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout))
             (alfe.cli:run '("--no-init" "--clautolisp"
                             "-x" "(print (+ 1 2))")
                           :version "0.0.2"))))
    (is (= 0 exit-code))
    (is (search "3" (get-output-stream-string stdout)))))

(test cli-run-clautolisp-x-bare-expr-does-not-auto-print
  "Companion to cli-run-clautolisp-x-plus-1-2-prints-three: a bare
`-x EXPR' without an explicit (print …) MUST NOT auto-print the
value. alfe does not echo eval-result-value at end-of-plan — that
behaviour is reserved for the interactive REPL."
  (let* ((stdout (make-string-output-stream))
         (exit-code
           (let ((*standard-output* stdout))
             (alfe.cli:run '("--no-init" "--clautolisp"
                             "-x" "(+ 1 2)")
                           :version "0.0.2"))))
    (is (= 0 exit-code))
    (is (not (search "3" (get-output-stream-string stdout))))))

;;; --- subprocess variant (conditional) -------------------------------

(defun subprocess-binary-available-p ()
  "True iff a clautolisp-sbcl binary the subprocess variant can
spawn exists at one of the documented search paths."
  (let ((backend (make-fresh-clautolisp-backend :subprocess)))
    (handler-case
        (progn (alfe.backend:detect backend) t)
      (alfe.error:backend-not-available () nil))))

(test clautolisp-subprocess-detect-finds-binary-when-built
  "When clautolisp-sbcl is on disk the subprocess variant detects it;
when not, DETECT signals BACKEND-NOT-AVAILABLE."
  (if (subprocess-binary-available-p)
      (let ((backend (make-fresh-clautolisp-backend :subprocess)))
        (is (eq backend (alfe.backend:detect backend))))
      ;; Without the binary, the subprocess variant must refuse to
      ;; start — but it must refuse with a structured error, not a
      ;; raw lisp condition.
      (signals alfe.error:backend-not-available
        (alfe.backend:detect (make-fresh-clautolisp-backend :subprocess)))))

;;; --- installed engine discovery (alfe-installed-subprocess-binary-
;;; not-discovered) ----------------------------------------------------
;;;
;;; The running alfe executable, the OS, the processor, the environment
;;; and $PATH are all injected, so a pretend installation is enough: no
;;; image is dumped, and the host's own layout does not matter.

(defun %disc-candidates (&key (env "") (exe nil) (os :linux)
                              (machine "X86-64") (checkout nil) (path ""))
  (alfe.backend.clautolisp::candidate-clautolisp-binaries
   :env env :exe exe :os os :machine machine :checkout checkout :path path))

(defun %disc-scratch-root (label)
  "A fresh scratch directory whose name contains a space."
  (uiop:ensure-directory-pathname
   (format nil "~Aalfe ~A ~D-~D/"
           (namestring (uiop:temporary-directory))
           label (get-universal-time) (random 1000000))))

(defun %disc-touch (path)
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output :if-exists :supersede
                            :if-does-not-exist :create)
    (write-line "#!/bin/sh" out))
  path)

(test clautolisp-installed-engine-linux-x86-64
  "Installed on Linux x86-64: the clautolisp-sbcl beside the running
alfe-sbcl, without suffix, comes first -- before $PATH and
/usr/local/bin -- and the prefix may contain spaces."
  (let* ((dir "/opt/my tools/libexec/clautolisp/binaries/linux/x86-64/")
         (cands (%disc-candidates
                 :exe (pathname (concatenate 'string dir "alfe-sbcl")))))
    (is (equal (concatenate 'string dir "clautolisp-sbcl") (first cands)))
    (is (equal "/usr/local/bin/clautolisp-sbcl" (car (last cands))))
    ;; the PREFIX/libexec/... candidate IS the sibling here: listed once
    (is (= 2 (length cands)) "candidates: ~S" cands)
    (is (notany (lambda (c) (search ".exe" c)) cands))))

(test clautolisp-installed-engine-bin-layout-adds-libexec
  "alfe-sbcl in PREFIX/bin (the autolisp-front-end `make install'
layout): its sibling, then PREFIX/libexec/clautolisp/binaries/OS/CPU/,
OS and CPU named as dispatch.sh names them (darwin, arm64)."
  (let ((cands (%disc-candidates :exe #P"/opt/pre fix/bin/alfe-sbcl"
                                 :os :macos :machine "ARM64")))
    (is (equal '("/opt/pre fix/bin/clautolisp-sbcl"
                 "/opt/pre fix/libexec/clautolisp/binaries/darwin/arm64/clautolisp-sbcl"
                 "/usr/local/bin/clautolisp-sbcl")
               cands))))

(test clautolisp-installed-engine-windows-x86-64
  "Installed on MS-Windows x86-64: clautolisp-sbcl.exe beside
alfe-sbcl.exe; no /usr/local/bin fallback there. The CPU names are the
ones dispatch.sh/dispatch.cmd use."
  (let* ((exe (make-pathname
               :directory '(:absolute "RunForestRun" "outils" "local" "libexec"
                            "clautolisp" "binaries" "windows" "x86-64")
               :name "alfe-sbcl" :type "exe"))
         (cands (%disc-candidates :exe exe :os :windows :machine "X86-64")))
    (is (= 1 (length cands)) "candidates: ~S" cands)
    (let ((p (pathname (first cands))))
      (is (equal "clautolisp-sbcl" (pathname-name p)))
      (is (equal "exe" (pathname-type p)))
      (is (equal (pathname-directory exe) (pathname-directory p))))
    (is (equal "x86-64"
               (alfe.backend.clautolisp::distribution-arch-name "AMD64")))
    (is (equal "x86-64"
               (alfe.backend.clautolisp::distribution-arch-name "x86_64")))
    (is (equal "arm64"
               (alfe.backend.clautolisp::distribution-arch-name "aarch64")))))

(test clautolisp-installed-engine-not-claimed-by-a-development-image
  "A development image runs as sbcl/ccl: its directory says nothing
about where the engine is, so nothing is proposed from it."
  (is (equal '("/usr/local/bin/clautolisp-sbcl")
             (%disc-candidates :exe #P"/usr/local/bin/sbcl")))
  (is (equal '("/usr/local/bin/clautolisp-sbcl") (%disc-candidates :exe nil))))

(test clautolisp-stale-checkout-path-is-ignored-when-absent
  "The checkout path captured at compile time is tried only when the
file exists; a vanished build tree neither shadows the installed engine
nor appears in the diagnostic. When it does exist, it comes after the
installed engine."
  (let* ((root (%disc-scratch-root "checkout"))
         (stale (namestring (merge-pathnames "gone/clautolisp-sbcl" root)))
         (present (namestring (merge-pathnames "build/clautolisp-sbcl" root)))
         (exe #P"/opt/pre fix/libexec/clautolisp/binaries/linux/x86-64/alfe-sbcl"))
    (unwind-protect
         (progn
           (%disc-touch present)
           (let ((cands (%disc-candidates :exe exe :checkout stale)))
             (is (not (member stale cands :test #'equal)) "candidates: ~S" cands))
           (let ((cands (%disc-candidates :exe exe :checkout present)))
             (is (equal "/opt/pre fix/libexec/clautolisp/binaries/linux/x86-64/clautolisp-sbcl"
                        (first cands)))
             (is (equal present (second cands)) "candidates: ~S" cands)))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(test clautolisp-env-override-wins
  "$ALFE_CLAUTOLISP_BIN, when set, is the first candidate, before the
installed engine; empty means unset."
  (let ((exe #P"/opt/p/libexec/clautolisp/binaries/linux/x86-64/alfe-sbcl"))
    (is (equal "/elsewhere/my-clautolisp"
               (first (%disc-candidates :env "/elsewhere/my-clautolisp" :exe exe))))
    (is (equal "/opt/p/libexec/clautolisp/binaries/linux/x86-64/clautolisp-sbcl"
               (first (%disc-candidates :env "" :exe exe))))
    (is (equal "/opt/p/libexec/clautolisp/binaries/linux/x86-64/clautolisp-sbcl"
               (first (%disc-candidates :env nil :exe exe))))))

(test clautolisp-path-walk-uses-the-platform-separator
  "$PATH is split on `;' on MS-Windows (where `:' follows every drive
letter) and on `:' elsewhere; the engine is looked for under its
platform name."
  (let* ((root (%disc-scratch-root "path"))
         (bin (merge-pathnames "b i n/" root)))
    (unwind-protect
         (progn
           (%disc-touch (merge-pathnames "clautolisp-sbcl" bin))
           (%disc-touch (merge-pathnames "clautolisp-sbcl.exe" bin))
           (is (equal (namestring (merge-pathnames "clautolisp-sbcl" bin))
                      (first (%disc-candidates
                              :path (format nil "/nonexistent:~A" (namestring bin))))))
           (is (equal (namestring (merge-pathnames "clautolisp-sbcl.exe" bin))
                      (first (%disc-candidates
                              :os :windows
                              :path (format nil "/nonexistent;~A" (namestring bin)))))))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(test clautolisp-no-subprocess-binary-diagnostic-lists-candidates
  "NO-SUBPROCESS-BINARY names every candidate tried, the installed ones
included, so an incomplete installation says where it looked."
  (let* ((cands (%disc-candidates :exe #P"/opt/pre fix/bin/alfe-sbcl"))
         (message (alfe.backend.clautolisp::no-subprocess-binary-message cands)))
    (is (= 3 (length cands)))
    (dolist (c cands)
      (is (search c message) "~S missing from ~S" c message))
    (is (search "ALFE_CLAUTOLISP_BIN" message))))

(test clautolisp-detect-finds-the-installed-engine
  "End to end through DETECT: an installation under a prefix with a
space, the running alfe placed in it, $ALFE_CLAUTOLISP_BIN unset: the
subprocess variant finds the engine shipped beside it -- and names it
among the candidates when it is missing."
  (let* ((root (%disc-scratch-root "detect"))
         (dir (merge-pathnames "pre fix/libexec/clautolisp/binaries/linux/x86-64/"
                               root))
         (exe (merge-pathnames "alfe-sbcl" dir))
         (engine (merge-pathnames "clautolisp-sbcl" dir))
         (saved (uiop:getenv "ALFE_CLAUTOLISP_BIN")))
    (unwind-protect
         (let ((alfe.backend.cad-common:*executable-pathname-function*
                 (lambda () exe))
               (alfe.backend.cad-common:*host-os-override* :linux)
               (alfe.backend.clautolisp::*checkout-sibling-clautolisp* nil))
           (setf (uiop:getenv "ALFE_CLAUTOLISP_BIN") "")
           (ensure-directories-exist dir)
           ;; Missing: the diagnostic names the installed candidate. (A
           ;; clautolisp-sbcl on this host's $PATH would be found instead.)
           (let ((condition
                   (handler-case
                       (progn (alfe.backend:detect
                               (make-fresh-clautolisp-backend :subprocess))
                              nil)
                     (alfe.error:backend-not-available (c) c))))
             (when condition
               (is (search (namestring engine) (princ-to-string condition))
                   "~A" condition)))
           (%disc-touch engine)
           (let ((backend (make-fresh-clautolisp-backend :subprocess)))
             (alfe.backend:detect backend)
             (is (equal (namestring (truename engine))
                        (alfe.backend.clautolisp::clautolisp-backend-executable-path
                         backend)))))
      (setf (uiop:getenv "ALFE_CLAUTOLISP_BIN") (or saved ""))
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(test clautolisp-subprocess-eval-parity-with-direct
  "Acceptance: --backend subprocess -x '(+ 1 2)' produces the same
final value as the direct variant. Skipped when clautolisp-sbcl
isn't on disk (a fresh checkout's `make test` runs before
`make build-clautolisp-sbcl`)."
  (cond
    ((not (subprocess-binary-available-p))
     ;; FiveAM has no first-class :skip, so we record a passing
     ;; assertion explaining the skip. The point of this test is to
     ;; surface a regression once the binary IS built — when it
     ;; isn't, we just note we didn't run.
     (is (not (subprocess-binary-available-p))
         "clautolisp-sbcl not present; subprocess parity test skipped."))
    (t
     (let* ((backend (alfe.backend:detect
                      (make-fresh-clautolisp-backend :subprocess)))
            (session (alfe.backend:start-engine backend nil
                                                :dialect :strict
                                                :host :cador
                                                :mock-input nil
                                                :bootstrap-phase :full
                                                :interactive-p nil))
            (plan (list (alfe.backend:action-eval "(+ 1 2)")
                        (alfe.backend:action-quit)))
            ;; Don't echo to live stdout during this test -- otherwise the
            ;; FiveAM trace gets polluted -- but KEEP what was said: a failure
            ;; here used to report only that the status was not :SUCCESS, and
            ;; the loaded Windows runner gave no other clue
            ;; (mock-cad-protocol-tests-flake-on-native-windows).
            (out (make-string-output-stream))
            (err (make-string-output-stream))
            (result
              (let ((*standard-output* out)
                    (*error-output*    err))
                (alfe.backend:eval-plan session plan))))
       (is (eq :success (alfe.backend:eval-result-status result))
           "got ~S; output ~S; stdout ~S; stderr ~S"
           (alfe.backend:eval-result-status result)
           (alfe.backend:eval-result-output result)
           (get-output-stream-string out)
           (get-output-stream-string err))
       (alfe.backend:shutdown session)))))

;;; --- --host: transmitted to clautolisp by its own names -------------

(test clautolisp-subprocess-passes-the-host-on-by-its-own-name
  "The subprocess variant hands --host to the clautolisp executable as
cador, cadtui or nihil — the names clautolisp has — cador when there is none."
  (dolist (spec '((:cador "cador") (:cadtui "cadtui") (:nihil "nihil") (nil "cador")))
    (destructuring-bind (host name) spec
      (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                       :variant :subprocess
                       :executable-path "/x/clautolisp-sbcl"))
             (session (alfe.backend.clautolisp::%make-subprocess-session
                       :backend backend :dialect :strict :host host))
             (argv (alfe.backend.clautolisp::build-subprocess-argv
                    session (list (alfe.backend:action-eval "(+ 1 2)")))))
        (is (equal name (nth (1+ (position "--host" argv :test #'string=)) argv))
            "host ~S is passed as ~S" host name)))))

(test clautolisp-subprocess-forwards-the-situation-encodings
  "The subprocess variant forwards the file / terminal / log situations to the
spawned clautolisp as -Efile-read / -Efile-write / -Eterminal-in /
-Eterminal-out / -Elog (only those requested), next to -Esource; an explicit
-Econsole reaches the child folded into the terminal pair (the engine's console
is its terminal), and console / cadstdio are never forwarded as such."
  (labels ((argv-for (args)
             (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                              :variant :subprocess
                              :executable-path "/x/clautolisp-sbcl"))
                    (keys (alfe.cli:situation-engine-keywords
                           (alfe.cli:parse-arguments args)
                           :console-is-terminal-p t))
                    (session (alfe.backend.clautolisp::%make-subprocess-session
                              :backend backend :dialect :strict :host :cador
                              :load-encoding (getf keys :source-encoding)
                              :file-read-encoding (getf keys :file-read-encoding)
                              :file-write-encoding (getf keys :file-write-encoding)
                              :terminal-in-encoding (getf keys :terminal-in-encoding)
                              :terminal-out-encoding (getf keys :terminal-out-encoding)
                              :log-encoding (getf keys :log-encoding))))
               (alfe.backend.clautolisp::build-subprocess-argv
                session (list (alfe.backend:action-eval "(+ 1 2)")))))
           (value (argv option)
             (let ((p (position option argv :test #'string=)))
               (and p (nth (1+ p) argv)))))
    ;; nothing requested: no encoding option at all
    (let ((argv (argv-for '("-x" "1"))))
      (is (notany (lambda (a) (and (> (length a) 2) (string= "-E" a :end2 2))) argv)
          "argv ~S" argv))
    ;; each situation, its own option
    (let ((argv (argv-for '("-Efile-read" "cp1252" "-Efile-write" "utf-8"
                            "-Eterminal-out" "latin-1" "-Elog" "us-ascii"))))
      (is (equal "WINDOWS-1252" (value argv "-Efile-read")))
      (is (equal "UTF-8" (value argv "-Efile-write")))
      (is (equal "ISO-8859-1" (value argv "-Eterminal-out")))
      (is (null (value argv "-Eterminal-in")))
      (is (equal "US-ASCII" (value argv "-Elog")))
      (is (null (value argv "-Esource")))
      ;; before the action flags, so in effect from the first -x
      (is (< (position "-Efile-read" argv :test #'string=)
             (position "-x" argv :test #'string=))))
    ;; the bare -E: source, file, terminal and log; never console / cadstdio
    (let ((argv (argv-for '("-E" "UTF-8"))))
      (dolist (option '("-Esource" "-Efile-read" "-Efile-write"
                        "-Eterminal-in" "-Eterminal-out" "-Elog"))
        (is (equal "UTF-8" (value argv option)) "~A in ~S" option argv))
      (is (notany (lambda (a) (or (search "-Econsole" a) (search "-Ecadstdio" a))) argv)))
    ;; -Econsole folds into the terminal pair
    (let ((argv (argv-for '("-Econsole-in" "cp1252"))))
      (is (equal "WINDOWS-1252" (value argv "-Eterminal-in")))
      (is (null (value argv "-Eterminal-out")))
      (is (notany (lambda (a) (search "-Econsole" a)) argv)))
    ;; the captured pipe is decoded in the forwarded terminal-out encoding
    (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                     :variant :subprocess :executable-path "/x/clautolisp-sbcl"))
           (session (alfe.backend.clautolisp::%make-subprocess-session
                     :backend backend :dialect :strict
                     :terminal-out-encoding "WINDOWS-1252")))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "WINDOWS-1252")
                 (alfe.backend.clautolisp::%subprocess-capture-external-format session)))
      (is (null (alfe.backend.clautolisp::%subprocess-capture-external-format
                 (alfe.backend.clautolisp::%make-subprocess-session
                  :backend backend :dialect :strict)))))))

(defun cadtui-binary-available-p ()
  "True iff a clautolisp-sbcl the subprocess variant can spawn exists AND
knows the cadtui host (an old build does not)."
  (let ((backend (make-fresh-clautolisp-backend :subprocess)))
    (handler-case
        (progn
          (alfe.backend:detect backend)
          (let ((hosts (uiop:run-program
                        (list (alfe.backend.clautolisp::clautolisp-backend-executable-path
                               backend)
                              "--list-hosts")
                        :output :string :ignore-error-status t)))
            (and (search "cadtui" hosts) t)))
      (error () nil))))

(test clautolisp-runs-the-cadtui-host-through-the-subprocess-variant
  "alfe --clautolisp --host cadtui (no --backend): the run is the clautolisp
executable's, with the cadtui host — *AUTOLISP-HOST* says so. Skipped when no
clautolisp-sbcl that has cadtui is installed."
  (if (not (cadtui-binary-available-p))
      (is (not (cadtui-binary-available-p))
          "no clautolisp-sbcl with cadtui here; end-to-end test skipped")
      (let* ((out (make-string-output-stream))
             (err (make-string-output-stream))
             (code (let ((*standard-output* out) (*error-output* err))
                     (run '("--no-init" "--no-plugins" "--clautolisp" "--host" "cadtui"
                            "-x" "(princ *autolisp-host*)")
                          :version "9.9.9"))))
        (is (= 0 code) "stderr: ~A" (get-output-stream-string err))
        (is (search "CADTUI" (get-output-stream-string out))))))

;;; --- semantic parity of the two variants ---------------------------
;;;
;;; alfe-clautolisp-backend-semantic-parity.issue: `--backend direct' and
;;; `--backend subprocess' are transports for the same engine. Two checks:
;;;
;;;  1. the option CONTRACT (alfe.backend.clautolisp:*clautolisp-option-
;;;     contract*) classifies exactly the options alfe's parser accepts --
;;;     a new option cannot be added without deciding how both variants
;;;     consume it;
;;;  2. a TABLE of runs, each executed once per variant through alfe's own
;;;     entry point, whose stdout, stderr, exit status and file side effects
;;;     must be identical.

(defun %alfe-accepted-long-options ()
  "Every long option alfe's parser accepts (core options, no plug-ins)."
  (remove-duplicates
   (loop for spec in (append alfe.cli::*alfe-option-specs*
                             clautolisp.autolisp-cli:*common-option-specs*)
         append (clautolisp.autolisp-cli:option-spec-longs spec))
   :test #'string=))

(test clautolisp-option-contract-classifies-every-accepted-option
  "Every option alfe accepts has ONE entry in the clautolisp option contract,
and the contract names no option alfe no longer accepts."
  (let ((accepted (%alfe-accepted-long-options))
        (classified (mapcar #'first
                            alfe.backend.clautolisp:*clautolisp-option-contract*)))
    (is (null (set-difference accepted classified :test #'string=))
        "options accepted by alfe but missing from the clautolisp contract: ~S"
        (set-difference accepted classified :test #'string=))
    (is (null (set-difference classified accepted :test #'string=))
        "options in the clautolisp contract that alfe does not accept: ~S"
        (set-difference classified accepted :test #'string=))
    (is (= (length classified)
           (length (remove-duplicates classified :test #'string=)))
        "an option is classified twice")
    (is (every (lambda (entry)
                 (member (second entry)
                         '(:front-end :engine :no-effect :program :divergent)))
               alfe.backend.clautolisp:*clautolisp-option-contract*))))

(test clautolisp-option-contract-says-how-the-child-receives-each-option
  "Every option the engine consumes says, with :FORWARD, how the subprocess
variant hands it to the child -- argv-fragment functions, :PLAN or
:ENVIRONMENT -- and the options alfe consumes itself, or nobody does, forward
nothing. BUILD-SUBPROCESS-ARGV is derived from these entries."
  (dolist (entry alfe.backend.clautolisp:*clautolisp-option-contract*)
    (destructuring-bind (name disposition how &key forward) entry
      (declare (ignore how))
      (if (member disposition '(:engine :program))
          (is (or (member forward '(:plan :environment))
                  (and (consp forward)
                       (every (lambda (fn) (and (symbolp fn) (fboundp fn))) forward)))
              "~A (~S) has no usable :forward: ~S" name disposition forward)
          (is (null forward) "~A (~S) forwards ~S" name disposition forward)))))

(test clautolisp-subprocess-argv-is-derived-from-the-contract
  "With every forwarded slot set, the child's argv carries each option once,
before the actions, and the -E family only once though many contract entries
name it."
  (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                   :variant :subprocess :executable-path "/x/clautolisp-sbcl"))
         (session (alfe.backend.clautolisp::%make-subprocess-session
                   :backend backend :dialect :lax :host :nihil
                   :dwg "/d/a.dwg" :load-encoding "utf-8"
                   :file-read-encoding "iso-8859-1" :log-encoding "utf-8"
                   :dribble "/tmp/d.log" :dribble-interactors :all
                   :dcl :tui))
         (argv (alfe.backend.clautolisp::build-subprocess-argv
                session (list (alfe.backend:action-eval "(princ)")))))
    (flet ((after (option)
             (second (member option argv :test #'equal)))
           (occurrences (option)
             (count option argv :test #'equal)))
      (is (equal "/x/clautolisp-sbcl" (first argv)))
      (is (equal "lax" (after "--dialect")))
      (is (equal "nihil" (after "--host")))
      (is (equal "/d/a.dwg" (after "--dwg")))
      (is (equal "utf-8" (after "-Esource")))
      (is (equal "iso-8859-1" (after "-Efile-read")))
      (is (equal "utf-8" (after "-Elog")))
      (is (equal "tui" (after "--dcl")))
      (is (member "--dribble=/tmp/d.log" argv :test #'equal))
      (is (member "--dribble-interactors=t" argv :test #'equal))
      (dolist (option '("--dialect" "--host" "--dwg" "-Esource" "-Efile-read"
                        "-Elog" "--dcl" "--dribble=/tmp/d.log" "-x"))
        (is (= 1 (occurrences option)) "~A occurs ~D times in ~S"
            option (occurrences option) argv))
      (is (equal '("-x" "(princ)") (last argv 2))))
    ;; the defaults forward nothing optional
    (let ((argv (alfe.backend.clautolisp::build-subprocess-argv
                 (alfe.backend.clautolisp::%make-subprocess-session
                  :backend backend :dialect nil :dcl :auto)
                 nil)))
      (is (equal '("/x/clautolisp-sbcl" "--quiet" "--no-init"
                   "--dialect" "strict" "--host" "cador")
                 argv)
          "~S" argv))))

(defun %parity-fixture (name content &key (external-format :utf-8))
  "Write CONTENT to a fresh temporary file named after NAME; return its
namestring."
  (let ((path (uiop:tmpize-pathname
               (merge-pathnames name (uiop:temporary-directory)))))
    (with-open-file (out path :direction :output :if-exists :supersede
                              :external-format external-format)
      (write-string content out))
    (namestring path)))

(defun %run-alfe-variant (variant arguments &key input)
  "Run alfe in-process as `alfe --no-init --no-plugins --clautolisp --backend
VARIANT ARGUMENTS...' (VARIANT :DEFAULT: no --backend at all), reading INPUT
(a string, else an empty stream) as its standard input. Returns (:EXIT code
:STDOUT text :STDERR text)."
  (let* ((out (make-string-output-stream))
         (err (make-string-output-stream))
         (code (let ((*standard-output* out)
                     (*error-output* err)
                     (*standard-input* (make-string-input-stream (or input ""))))
                 (alfe.cli:run (append (list "--no-init" "--no-plugins"
                                             "--clautolisp")
                                       (unless (eq variant :default)
                                         (list "--backend" (string-downcase variant)))
                                       arguments)
                               :version "9.9.9"))))
    (list :exit code
          :stdout (get-output-stream-string out)
          :stderr (get-output-stream-string err))))

(defun %file-octets-or-nil (path)
  (when (probe-file path)
    (with-open-file (in path :element-type '(unsigned-byte 8))
      (let ((octets (make-array (file-length in) :element-type '(unsigned-byte 8))))
        (read-sequence octets in)
        (coerce octets 'list)))))

(defun %parity-scenarios ()
  "The parity table: (NAME ARGUMENTS &key SIDE-EFFECT EXPECT-FILE EXPECT-STDOUT
EXPECT-EXIT LENIENT INPUT VARIANTS).
SIDE-EFFECT names a file the run writes, compared octet for octet; EXPECT-FILE
says what it must hold: a list of octets, a string it must contain, or :ABSENT.
EXPECT-EXIT, when given, is the exit status both runs must have (the
sysexits table, sysexits-exit-statuses.issue).
INPUT is the run's standard input. VARIANTS are the two runs compared, by
default (:DIRECT :SUBPROCESS); a run that needs the clautolisp PROGRAM (a REPL,
--dribble, --dcl ncurses/gui) compares the default -- no --backend -- with
--backend subprocess, --backend direct being a usage error for it.
EXPECT-STDOUT, when given, must be a substring of both outputs (so a table
entry also says what the run is FOR, not only that the two runs agree).
LENIENT compares stderr only for a successful run: the DWG codec's error
names the native library candidates, which may legitimately differ."
  (let* ((nl (string #\Newline))
         (e-acute (string (code-char 233)))
         (loaded (%parity-fixture
                  "parity-load.lsp"
                  (concatenate 'string
                               "(defun c:hello () (princ \"hello\"))" nl
                               "(princ (list 'loaded (= *autolisp-load-pathname* nil)))" nl)))
         (latin1 (%parity-fixture
                  "parity-latin1.lsp"
                  (concatenate 'string "(princ (strlen \"" e-acute "t" e-acute "\"))" nl)
                  :external-format :latin-1))
         (unbalanced (%parity-fixture
                      "parity-unbalanced.lsp"
                      (concatenate 'string "(princ \"a\")" nl "(defun f (" nl)))
         (written (namestring
                   (uiop:tmpize-pathname
                    (merge-pathnames "parity-written.txt" (uiop:temporary-directory)))))
         (dxf (namestring
               (asdf:system-relative-pathname
                "clautolisp/drawing" "drawing/template/empty-drawing.dxf")))
         (dwg (namestring
               (asdf:system-relative-pathname
                "autolisp-front-end" "source/empty.dwg")))
         (dribble-file (namestring
                        (uiop:tmpize-pathname
                         (merge-pathnames "parity-dribble.log"
                                          (uiop:temporary-directory)))))
         (dcl (%parity-fixture
               "parity.dcl"
               (concatenate 'string
                            "parity : dialog { label = \"Parity\"; ok_only; }" nl))))
    `(("host cador"
       ("--host" "cador" "-x" "(princ (list *autolisp-host* (getvar \"PROGRAM\")))")
       :expect-stdout "alfe")
      ("host nihil"
       ("--host" "nihil" "-x" "(princ 'ok)")
       :expect-stdout "OK")
      ("dialect"
       ("--dialect" "autocad-2022" "-x" "(princ *autolisp-dialect*)")
       :expect-stdout "AUTOCAD-2022")
      ("lax"
       ("--lax" "-x" "(princ *autolisp-dialect*)")
       :expect-stdout "LAX")
      ("front-end bindings"
       ("-x" "(princ (list *autolisp-frontend* *autolisp-backend* *autolisp-version* *autolisp-expression* *autolisp-actions* *autolisp-quiet* *autolisp-no-init*))")
       :expect-stdout "ALFE")
      ("quiet, timeout, mode, no-color"
       ("--quiet" "--timeout" "7" "--mode" "batch" "--no-color"
        "-x" "(princ (list *autolisp-quiet* *autolisp-timeout* *autolisp-mode* *autolisp-no-color*))")
       :expect-stdout "7")
      ("load then eval"
       ("-l" ,loaded "-x" "(c:hello)")
       :expect-stdout "hello")
      ("main"
       ("-l" ,loaded "--main" "c:hello")
       :expect-stdout "hello")
      ("main undefined" ("--main" "no-such-function"))
      ("runtime error stops the plan"
       ("-x" "(princ \"a\")" "-x" "(car 1)" "-x" "(princ \"b\")")
       :expect-exit 1)
      ("exit status" ("-x" "(princ \"a\")" "-x" "(exit 3)") :expect-exit 3)
      ("recorded status" ("-x" "(autolisp-set-status 5)") :expect-exit 5)
      ("missing load file" ("-l" "/nonexistent/parity-missing.lsp")
       :expect-exit ,clautolisp.sysexits:+ex-noinput+)
      ("load file the reader refuses" ("-l" ,unbalanced)
       :expect-exit ,clautolisp.sysexits:+ex-dataerr+)
      ("load file not in the source encoding" ("-Esource" "utf-8" "-l" ,latin1)
       :expect-exit ,clautolisp.sysexits:+ex-dataerr+)
      ("expression the reader refuses" ("-x" "(princ")
       :expect-exit ,clautolisp.sysexits:+ex-dataerr+)
      ("unknown option" ("--no-such-option")
       :expect-exit ,clautolisp.sysexits:+ex-usage+)
      ("source encoding"
       ("-Esource" "iso-8859-1" "-l" ,latin1)
       :expect-stdout "3")
      ("file-write encoding"
       ("-Efile-write" "iso-8859-1"
        "-x" ,(format nil "(setq f (open ~S \"w\")) (write-line ~S f) (close f)"
                      written e-acute))
       :side-effect ,written :expect-file (233 10))
      ("drawing dxf"
       ("--host" "cador" "--dwg" ,dxf "-x" "(princ (getvar \"DWGNAME\"))")
       :expect-stdout "empty-drawing.dxf")
      ("drawing missing"
       ("--host" "cador" "--dwg" "/nonexistent/parity-missing.dwg" "-x" "(princ 1)")
       :expect-exit ,clautolisp.sysexits:+ex-noinput+)
      ("drawing dwg"
       ("--host" "cador" "--dwg" ,dwg "-x" "(princ (getvar \"DWGNAME\"))")
       :lenient t)
      ;; The clautolisp program's own machinery (the REPL, the recorder, the
      ;; DCL renderer selection): the default and --backend subprocess.
      ("interactive"
       ("-i")
       :input ,(concatenate 'string "(princ 42)" nl)
       :variants (:default :subprocess)
       :expect-stdout "_$ 4242")
      ("no action is a REPL"
       ()
       :input ,(concatenate 'string "(princ 'bare)" nl)
       :variants (:default :subprocess)
       :expect-stdout "BARE")
      ("actions then REPL"
       ("-l" ,loaded "-x" "(setq parity-a 7)" "-i")
       :input ,(concatenate 'string "(c:hello)" nl "(princ parity-a)" nl)
       :variants (:default :subprocess)
       :expect-stdout "hello")
      ("REPL runtime error"
       ("-i")
       :input ,(concatenate 'string "(car 1)" nl "(princ 'after)" nl)
       :variants (:default :subprocess)
       :expect-stdout "AFTER")
      ("dribble of a REPL"
       (,(format nil "--dribble=~A" dribble-file) "-i")
       :input ,(concatenate 'string "(princ 42)" nl)
       :variants (:default :subprocess)
       :side-effect ,dribble-file
       :expect-file ,(concatenate 'string "(princ 42)" nl ";; O: 4242"))
      ("dribble of a batch run"
       (,(format nil "--dribble=~A" dribble-file) "-x" "(princ 1)")
       :variants (:default :subprocess)
       :side-effect ,dribble-file
       :expect-file :absent
       :expect-stdout "1")
      ("dcl tui"
       ("--dcl" "tui"
        "-x" ,(format nil "(setq id (load_dialog ~S)) (princ (numberp id)) (princ (new_dialog \"parity\" id)) (unload_dialog id)"
                      dcl))
       :expect-stdout "TT")
      ("dcl default"
       ("-x" ,(format nil "(setq id (load_dialog ~S)) (princ (numberp id)) (unload_dialog id)"
                      dcl))
       :expect-stdout "T")
      ;; The line renderer reads the user's answer on standard input: the
      ;; child reads alfe's, as the in-process engine does.
      ("dcl dialog answered on standard input"
       ("--dcl" "tui"
        "-x" ,(format nil "(setq id (load_dialog ~S)) (new_dialog \"parity\" id) (princ (list 'result (start_dialog))) (unload_dialog id)"
                      dcl))
       :input ,(concatenate 'string "accept" nl)
       :expect-stdout "(RESULT 1)")
      ;; The debugger options (debugger-public-interface-and-on-error.issue):
      ;; the ones a batch run can show without a terminal. --on-error debug,
      ;; --debugger-ui and the aldb transports talk to the user; they are
      ;; covered by CLAUTOLISP-DIRECT-ON-ERROR-DEBUG-STOPS-IN-ALDO, the
      ;; forwarding test, and the shell demonstration of the ticket.
      ("on-error quit"
       ("--on-error" "quit" "-x" "(princ \"a\")" "-x" "(/ 1 0)" "-x" "(princ \"after\")")
       :expect-stdout "a")
      ("on-error ignore"
       ("--on-error" "ignore" "-x" "(princ \"a\")" "-x" "(/ 1 0)" "-x" "(princ \"after\")")
       :expect-stdout "a")
      ("debugger policies"
       ("--on-error" "ignore" "--on-interrupt" "quit" "--on-quit" "quit"
        "-x" "(princ (list *clal-on-error* *clal-on-interrupt* *clal-on-quit*))")
       :expect-stdout "(IGNORE QUIT QUIT)")
      ("debugger policy defaults"
       ("-x" "(princ (list *clal-on-error* *clal-on-interrupt* *clal-on-quit*))")
       :expect-stdout "(QUIT DEBUG QUIT)"))))

(defun %parity-file-matches-p (octets expect)
  "True when the side-effect file's OCTETS (NIL: no file) are what EXPECT says:
a list of octets, a string it contains (UTF-8), or :ABSENT."
  (cond ((eq expect :absent) (null octets))
        ((stringp expect)
         (and octets
              (search expect (babel:octets-to-string
                              (coerce octets '(vector (unsigned-byte 8)))
                              :encoding :utf-8))
              t))
        (t (equal expect octets))))

(test clautolisp-backend-variants-are-semantically-identical
  "Every row of the parity table gives the same stdout, stderr, exit status
and file side effects under its two variants (--backend direct and --backend
subprocess, or the default and --backend subprocess for a run that is the
clautolisp program's). Skipped when no clautolisp-sbcl is built (the
subprocess variant needs it)."
  (if (not (subprocess-binary-available-p))
      (is (not (subprocess-binary-available-p))
          "clautolisp-sbcl not present; parity table skipped.")
      (dolist (row (%parity-scenarios))
        (destructuring-bind (name arguments &key side-effect expect-file expect-stdout
                                                 expect-exit
                                                 lenient input
                                                 (variants '(:direct :subprocess)))
            row
          (flet ((run-one (variant)
                   (when side-effect (ignore-errors (delete-file side-effect)))
                   (let ((result (%run-alfe-variant variant arguments :input input)))
                     (append result
                             (list :side-effect
                                   (and side-effect
                                        (%file-octets-or-nil side-effect)))))))
            (destructuring-bind (first-variant second-variant) variants
              (let ((first (run-one first-variant))
                    (second (run-one second-variant)))
                (is (eql (getf first :exit) (getf second :exit))
                    "~A: exit ~S (~(~A~)) vs ~S (~(~A~)); stderr ~S vs ~S"
                    name (getf first :exit) first-variant
                    (getf second :exit) second-variant
                    (getf first :stderr) (getf second :stderr))
                (is (string= (getf first :stdout) (getf second :stdout))
                    "~A: stdout ~S (~(~A~)) vs ~S (~(~A~))"
                    name (getf first :stdout) first-variant
                    (getf second :stdout) second-variant)
                (unless (and lenient (not (eql 0 (getf first :exit))))
                  (is (string= (getf first :stderr) (getf second :stderr))
                      "~A: stderr ~S (~(~A~)) vs ~S (~(~A~))"
                      name (getf first :stderr) first-variant
                      (getf second :stderr) second-variant))
                (when side-effect
                  (is (equal (getf first :side-effect) (getf second :side-effect))
                      "~A: file ~S (~(~A~)) vs ~S (~(~A~))"
                      name (getf first :side-effect) first-variant
                      (getf second :side-effect) second-variant)
                  (is (%parity-file-matches-p (getf first :side-effect) expect-file)
                      "~A: wrote ~S, expected ~S" name (getf first :side-effect)
                      expect-file)
                  (ignore-errors (delete-file side-effect)))
                (when expect-exit
                  (is (eql expect-exit (getf first :exit))
                      "~A: exit ~S, expected ~S; stderr ~S"
                      name (getf first :exit) expect-exit (getf first :stderr)))
                (when expect-stdout
                  (is (search expect-stdout (getf first :stdout))
                      "~A: expected ~S in ~S" name expect-stdout
                      (getf first :stdout))))))))))

(test clautolisp-program-runs-refuse-the-direct-variant
  "A run that is the clautolisp program's (a REPL, --dribble, --dcl ncurses)
cannot be honoured in-process: --backend direct is a usage error (EX_USAGE),
reported before any engine starts, rather than a different behaviour."
  (dolist (arguments '(("-i") ()
                       ("--dribble=/tmp/alfe-parity-refused.log" "-x" "(princ 1)")
                       ("--dcl" "ncurses" "-x" "(princ 1)")))
    (let ((result (%run-alfe-variant :direct arguments)))
      (is (eql clautolisp.sysexits:+ex-usage+ (getf result :exit)) "~S: ~S" arguments result)
      (is (search "--backend direct" (getf result :stderr)) "~S: ~S" arguments result)
      (is (zerop (length (getf result :stdout))) "~S: ~S" arguments result))))

(test clautolisp-terminal-encoding-resolves-identically-for-both-variants
  "-Eterminal-out: the direct variant re-encodes alfe's own streams, the
subprocess variant forwards it to the child and decodes the capture with it.
Both come from the same resolved value. (Driving the streams themselves needs
a real terminal file descriptor, so this compares the resolved configuration.)"
  (let* ((options (alfe.cli:parse-arguments
                   '("--clautolisp" "-Eterminal-out" "iso-8859-1" "-x" "(princ)")))
         (keywords (alfe.cli:situation-engine-keywords options
                                                        :console-is-terminal-p t))
         (plan (alfe.cli:terminal-encoding-plan options))
         (backend (alfe.backend.clautolisp:make-clautolisp-backend
                   :variant :subprocess :executable-path "/x/clautolisp-sbcl"))
         (session (alfe.backend.clautolisp::%make-subprocess-session
                   :backend backend :dialect :strict
                   :terminal-out-encoding (getf keywords :terminal-out-encoding)))
         (argv (alfe.backend.clautolisp::build-subprocess-argv session nil)))
    (is (getf keywords :terminal-out-encoding))
    ;; direct: alfe's stdout is re-encoded with it
    (is (find :output plan :key #'first))
    ;; subprocess: forwarded verbatim, and the capture is decoded with it
    (let ((tail (member "-Eterminal-out" argv :test #'equal)))
      (is (equal (getf keywords :terminal-out-encoding) (second tail))))
    (is (alfe.backend.clautolisp::%subprocess-capture-external-format session))))

(test clautolisp-subprocess-forwards-the-front-end-bindings
  "The subprocess variant passes --front-end-bindings FILE only when it has
bindings to forward, before the actions."
  (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                   :variant :subprocess :executable-path "/x/clautolisp-sbcl"))
         (session (alfe.backend.clautolisp::%make-subprocess-session
                   :backend backend :dialect :strict))
         (plan (list (alfe.backend:action-eval "(princ)"))))
    (is (not (member "--front-end-bindings"
                     (alfe.backend.clautolisp::build-subprocess-argv session plan)
                     :test #'equal)))
    (let* ((argv (alfe.backend.clautolisp::build-subprocess-argv
                  session plan :front-end-bindings-file "/tmp/fe.sexp"))
           (tail (member "--front-end-bindings" argv :test #'equal)))
      (is (equal "/tmp/fe.sexp" (second tail)))
      (is (< (position "--front-end-bindings" argv :test #'equal)
             (position "-x" argv :test #'equal))))))

;;; --- the debugger options (debugger-public-interface-and-on-error.issue) --
;;;
;;; alfe shares the clautolisp program's debugger options (pjb, 2026-10-06):
;;; same spelling and parsing (the shared specs), same meaning in both
;;; variants, and refused by the CAD backends, which have no aldo.

(defun %run-alfe-argv (arguments &key (input ""))
  "Run alfe in-process as `alfe --no-init --no-plugins ARGUMENTS...', with
INPUT on its standard input. Returns (:EXIT code :STDOUT text :STDERR text)."
  (let* ((out (make-string-output-stream))
         (err (make-string-output-stream))
         (code (let ((*standard-output* out)
                     (*error-output* err)
                     (*standard-input* (make-string-input-stream input)))
                 (alfe.cli:run (append (list "--no-init" "--no-plugins") arguments)
                               :version "9.9.9"))))
    (list :exit code
          :stdout (get-output-stream-string out)
          :stderr (get-output-stream-string err))))

(test clautolisp-direct-on-error-debug-stops-in-aldo
  "--on-error debug under the in-process engine stops in aldo at the error,
as the clautolisp program does: the dumb UI talks on alfe's streams, `q'
aborts the program (the next action does not run) and the run exits 0."
  (let* ((result (%run-alfe-argv
                  '("--clautolisp" "--backend" "direct"
                    "--on-error" "debug" "--debugger-ui" "dumb"
                    "-x" "(princ \"before\")" "-x" "(/ 1 0)" "-x" "(princ \"after-marker\")")
                  :input (format nil "q~%")))
         (stdout (getf result :stdout)))
    (is (eql 0 (getf result :exit)) "exit ~S, stderr ~S"
        (getf result :exit) (getf result :stderr))
    (is (search "DBG>" stdout) "no debugger prompt in ~S" stdout)
    (is (search "before" stdout))
    (is (not (search "after-marker" stdout)))))

(test clautolisp-direct-debugger-continue-reports-the-error
  "Continuing from the error stop lets the error take its course: reported
in the engine's words, exit 1 -- the clautolisp program's outcome."
  (let ((result (%run-alfe-argv
                 '("--clautolisp" "--backend" "direct"
                   "--on-error" "debug" "--debugger-ui" "dumb"
                   "-x" "(/ 1 0)")
                 :input (format nil "c~%"))))
    (is (eql 1 (getf result :exit)))
    (is (search "DIVISION-BY-ZERO" (getf result :stderr)))))

(test clautolisp-subprocess-forwards-the-debugger-options
  "The subprocess variant forwards the debugger options the user gave,
spelled so that the child's parser reads back the same values, before the
actions; and says when they arm a debug session (the child then gets alfe's
terminal)."
  (let* ((options (alfe.cli:parse-arguments
                   '("--clautolisp" "--on-error" "debug" "--on-interrupt" "ignore"
                     "--on-quit" "debug" "--debugger-ui" "ncurses"
                     "--aldb-listen" "[::1]:4301" "-x" "(princ)")))
         (arguments (clautolisp.autolisp-cli:debugger-option-arguments options)))
    (is (equal '("--on-error" "debug" "--on-interrupt" "ignore" "--on-quit" "debug"
                 "--debugger-ui" "ncurses" "--aldb-listen" "[::1]:4301")
               arguments))
    (is (eq t (clautolisp.autolisp-cli:debugger-session-requested-p options)))
    (let ((child (clautolisp.tools.clautolisp::parse-arguments
                  (append arguments '("-x" "1")))))
      (is (eq :debug (clautolisp.autolisp-cli:cli-options-on-error child)))
      (is (eq :ignore (clautolisp.autolisp-cli:cli-options-on-interrupt child)))
      (is (eq :debug (clautolisp.autolisp-cli:cli-options-on-quit child)))
      (is (eq :ncurses (clautolisp.autolisp-cli:cli-options-user-interface child)))
      (is (equal "::1" (clautolisp.autolisp-cli:cli-options-aldb-address child)))
      (is (eql 4301 (clautolisp.autolisp-cli:cli-options-aldb-port child))))
    (let* ((backend (alfe.backend.clautolisp:make-clautolisp-backend
                     :variant :subprocess :executable-path "/x/clautolisp-sbcl"))
           (session (alfe.backend.clautolisp::%make-subprocess-session
                     :backend backend :dialect :strict
                     :debugger-arguments arguments :debugger-session-p t))
           (argv (alfe.backend.clautolisp::build-subprocess-argv
                  session (list (alfe.backend:action-eval "(princ)")))))
      (is (search arguments argv :test #'equal))
      (is (< (position "--on-error" argv :test #'equal)
             (position "-x" argv :test #'equal))))))

(test clautolisp-debugger-options-forwarded-only-when-given
  "Nothing is forwarded when no debugger option was given (the child applies
its own defaults, as the direct variant does), and only a debugging request
gives the child the terminal: --on-error quit or --on-interrupt ignore do not."
  (let ((none (alfe.cli:parse-arguments '("--clautolisp" "-x" "(princ)")))
        (quiet (alfe.cli:parse-arguments
                '("--clautolisp" "--on-error" "quit" "--on-interrupt" "ignore"
                  "-x" "(princ)")))
        (stdio (alfe.cli:parse-arguments
                '("--clautolisp" "--aldb-stdio" "-x" "(princ)"))))
    (is (null (clautolisp.autolisp-cli:debugger-option-arguments none)))
    (is (null (clautolisp.autolisp-cli:debugger-session-requested-p none)))
    (is (equal '("--on-error" "quit" "--on-interrupt" "ignore")
               (clautolisp.autolisp-cli:debugger-option-arguments quiet)))
    (is (null (clautolisp.autolisp-cli:debugger-session-requested-p quiet)))
    (is (equal '("--aldb-stdio")
               (clautolisp.autolisp-cli:debugger-option-arguments stdio)))
    (is (eq t (clautolisp.autolisp-cli:debugger-session-requested-p stdio)))))

(test alfe-aldb-stdio-excludes-interactive-as-clautolisp-does
  "--aldb-stdio with --interactive (or --aldb-listen) is the same usage error
in alfe as in the clautolisp program."
  (let ((with-i (%run-alfe-argv '("--clautolisp" "--aldb-stdio" "-i")))
        (with-listen (%run-alfe-argv '("--clautolisp" "--aldb-stdio"
                                       "--aldb-listen" "4301" "-x" "1"))))
    (is (eql clautolisp.sysexits:+ex-usage+ (getf with-i :exit)))
    (is (search "mutually exclusive" (getf with-i :stderr)))
    (is (eql clautolisp.sysexits:+ex-usage+ (getf with-listen :exit)))
    (is (search "mutually exclusive" (getf with-listen :stderr)))))

(test cad-backends-refuse-the-aldo-options
  "--autocad / --bricscad refuse --on-interrupt, --on-quit, --debugger-ui,
--aldb-listen and --aldb-stdio with a usage error (EX_USAGE 64) -- never ignore
them -- dry run included; --on-error stays accepted (it also governs alfe's
own unexpected conditions)."
  (dolist (backend '("--bricscad" "--autocad"))
    (dolist (option '(("--on-interrupt" "quit") ("--on-quit" "debug")
                      ("--debugger-ui" "dumb") ("--aldb-listen" "4301")
                      ("--aldb-stdio")))
      (let ((result (%run-alfe-argv
                     (append (list backend "--dry-run") option
                             (list "-x" "(princ 1)")))))
        (is (eql clautolisp.sysexits:+ex-usage+ (getf result :exit)) "~A ~A: exit ~S"
            backend (first option) (getf result :exit))
        (is (search "aldo" (getf result :stderr)) "~A ~A: stderr ~S"
            backend (first option) (getf result :stderr))
        (is (search (first option) (getf result :stderr)))))
    (let ((result (%run-alfe-argv (list backend "--dry-run" "--on-error" "debug"
                                        "-x" "(princ 1)"))))
      (is (eql 0 (getf result :exit)) "~A --on-error: exit ~S, stderr ~S"
          backend (getf result :exit) (getf result :stderr)))))
