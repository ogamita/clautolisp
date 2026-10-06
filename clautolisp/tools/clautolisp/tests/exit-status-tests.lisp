;;;; clautolisp/tools/clautolisp/tests/exit-status-tests.lisp
;;;;
;;;; The process exit statuses (sysexits-exit-statuses.issue): each failure
;;;; the program can meet maps to its <sysexits.h> code through the shared
;;;; table, CLAUTOLISP.AUTOLISP-CLI:ENGINE-EXIT-STATUS -- the one alfe's
;;;; in-process engine uses too. MAIN itself exits the process, so these
;;;; tests drive the pieces MAIN is made of (the action runner, the option
;;;; parser, the drawing opener) and map the condition each one signals; the
;;;; built executable is exercised by the alfe conformance corpus.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %exit-status-context ()
  "A fresh context with the core builtins and no host, reading sources as
UTF-8. Call it inside WITH-ISOLATED-BUILTIN-HOOKS."
  (let ((context (clautolisp.autolisp-runtime:make-default-runtime-context)))
    (clautolisp.tools.clautolisp::setup-context context nil)
    (clautolisp.tools.clautolisp::set-default-source-encoding context :utf-8)
    context))

(defmacro with-isolated-builtin-hooks (&body body)
  "Run BODY with the process-wide hooks INSTALL-CORE-BUILTINS sets rebound,
so that installing the builtins here does not leak into the suites that run
later: the cador suite runs after this one and expects COM points as plain
lists, which is what it gets until the builtins' wrap hooks are installed
(install-core-builtins-leaks-com-hooks-across-suites.issue)."
  `(let ((clautolisp.autolisp-builtins-core::*com-loaded-p*
           clautolisp.autolisp-builtins-core::*com-loaded-p*)
         (clautolisp.autolisp-runtime:*resolve-unbound-function-hook*
           clautolisp.autolisp-runtime:*resolve-unbound-function-hook*)
         (clautolisp.autolisp-runtime:*vlax-collection-items-hook*
           clautolisp.autolisp-runtime:*vlax-collection-items-hook*)
         (clautolisp.autolisp-runtime:*com-point-wrap-hook*
           clautolisp.autolisp-runtime:*com-point-wrap-hook*)
         (clautolisp.autolisp-runtime:*com-point-unwrap-hook*
           clautolisp.autolisp-runtime:*com-point-unwrap-hook*)
         (clautolisp.autolisp-runtime:*com-objects-wrap-hook*
           clautolisp.autolisp-runtime:*com-objects-wrap-hook*))
     ,@body))

(defun %status-of-action (action)
  "Run ACTION (:FILE . PATH) / (:EXPRESSION . TEXT) the way RUN-WITH-INPUT
does and return (values STATUS CONDITION REPORT): the exit status the
condition it signalled maps to (0 when none), the condition, and the
engine's report of it."
  (with-isolated-builtin-hooks
   (let ((context (%exit-status-context)))
    (handler-case
        (progn
          (clautolisp.tools.clautolisp::eval-action-in-context
           context action (clautolisp.tools.clautolisp::keyword->dialect :strict))
          (values 0 nil ""))
      (clautolisp.autolisp-runtime:autolisp-termination (condition)
        (values (clautolisp.autolisp-cli:engine-exit-status condition) condition ""))
      (error (condition)
        (values (clautolisp.autolisp-cli:engine-exit-status condition)
                condition
                (with-output-to-string (out)
                  (clautolisp.autolisp-cli:report-engine-error
                   condition :stream out))))))))

(defun %exit-status-fixture (name octets)
  "Write OCTETS (a list of bytes) to a fresh temporary file; return its path."
  (let ((path (uiop:tmpize-pathname
               (merge-pathnames name (uiop:temporary-directory)))))
    (with-open-file (out path :direction :output :if-exists :supersede
                              :element-type '(unsigned-byte 8))
      (write-sequence (coerce octets '(vector (unsigned-byte 8))) out))
    path))

(defun %ascii-octets (string)
  (map 'list #'char-code string))

(test exit-status-missing-load-file-is-noinput
  "-l FILE that does not exist: EX_NOINPUT (66)."
  (is (= clautolisp.sysexits:+ex-noinput+
         (%status-of-action '(:file . "/nonexistent/sysexits-missing.lsp")))))

(test exit-status-unreadable-load-file-is-noinput
  "-l FILE that exists but cannot be read (mode 000): EX_NOINPUT (66).
POSIX only (chmod); skipped when the file stays readable anyway (root)."
  (unless (uiop:os-windows-p)
    (let ((path (%exit-status-fixture "sysexits-noperm.lsp"
                                      (%ascii-octets "(princ 1)"))))
      (unwind-protect
           (progn
             (uiop:run-program (list "chmod" "000" (namestring path)))
             (if (ignore-errors (with-open-file (in path) (read-char in nil)) t)
                 (is (probe-file path) "running as root: mode 000 still readable")
                 (is (= clautolisp.sysexits:+ex-noinput+
                        (%status-of-action (cons :file (namestring path)))))))
        (ignore-errors (uiop:run-program (list "chmod" "600" (namestring path))))
        (ignore-errors (delete-file path))))))

(test exit-status-load-file-the-reader-refuses-is-dataerr
  "-l FILE with an unbalanced parenthesis: EX_DATAERR (65), reported as a
read error with its place, not as the host Lisp's printed structure."
  (let ((path (%exit-status-fixture
               "sysexits-unbalanced.lsp"
               (%ascii-octets (format nil "(princ \"a\")~%(defun f (~%")))))
    (unwind-protect
         (multiple-value-bind (status condition report)
             (%status-of-action (cons :file (namestring path)))
           (declare (ignore condition))
           (is (= clautolisp.sysexits:+ex-dataerr+ status))
           (is (search "read error" report) "report: ~S" report)
           (is (not (search "#S(" report)) "report: ~S" report))
      (ignore-errors (delete-file path)))))

(test exit-status-load-file-not-in-its-encoding-is-dataerr
  "-l FILE whose bytes are not valid UTF-8, read as UTF-8: EX_DATAERR (65)."
  (let ((path (%exit-status-fixture
               "sysexits-badenc.lsp"
               (append (%ascii-octets "(princ \"") '(255 254 128)
                       (%ascii-octets "\")")))))
    (unwind-protect
         (multiple-value-bind (status condition report)
             (%status-of-action (cons :file (namestring path)))
           (declare (ignore condition))
           ;; An implementation that substitutes a replacement character
           ;; instead of signalling reads the file: then the run succeeds.
           (is (member status (list clautolisp.sysexits:+ex-dataerr+ 0))
               "status ~S" status)
           ;; Reported with the file and the encoding, not the host's
           ;; stream object.
           (when (eql status clautolisp.sysexits:+ex-dataerr+)
             (is (search "read error" report) "report: ~S" report)
             (is (search "sysexits-badenc" report) "report: ~S" report)
             (is (not (search "#<" report)) "report: ~S" report)))
      (ignore-errors (delete-file path)))))

(test exit-status-expression-the-reader-refuses-is-dataerr
  "-x with an unbalanced parenthesis, or a stray closing one: EX_DATAERR."
  (dolist (text '("(" ")" "(princ \"a"))
    (multiple-value-bind (status condition report)
        (%status-of-action (cons :expression text))
      (declare (ignore condition))
      (is (= clautolisp.sysexits:+ex-dataerr+ status) "-x ~S: ~S" text status)
      (is (search "<-x>:1:" report) "-x ~S: ~S" text report))))

(test exit-status-runtime-error-is-one-and-quit-passes-through
  "A runtime error in the user's program is 1 -- not a sysexits code -- and
(quit N) / (exit N) is N, unchanged."
  (is (= clautolisp.sysexits:+exit-autolisp-error+
         (%status-of-action '(:expression . "(/ 1 0)"))))
  (let ((clautolisp.autolisp-runtime:*clal-on-quit* :quit))
    (is (= 7 (%status-of-action '(:expression . "(quit 7)"))))
    (is (= 0 (%status-of-action '(:expression . "(+ 1 2)"))))))

(test exit-status-usage-errors-are-usage
  "An unknown option, a missing argument, a bad option value: EX_USAGE (64)."
  (dolist (argv '(("--no-such-option") ("-l") ("--dialect" "nonsense")))
    (handler-case
        (progn (clautolisp.tools.clautolisp::parse-arguments argv)
               (is nil "~S was accepted" argv))
      (clautolisp.autolisp-cli:cli-error (condition)
        (is (= clautolisp.sysexits:+ex-usage+
               (clautolisp.autolisp-cli:cli-error-status condition))
            "~S: ~S" argv condition)
        (is (= clautolisp.sysexits:+ex-usage+
               (clautolisp.autolisp-cli:engine-exit-status condition)))))))

(defun %drawing-error-status (host path)
  (handler-case
      (progn (clautolisp.tools.clautolisp::open-drawing-argument host path)
             nil)
    (clautolisp.autolisp-cli:cli-error (condition)
      (clautolisp.autolisp-cli:cli-error-status condition))))

(test exit-status-drawing-argument
  "--dwg: a missing drawing is EX_NOINPUT (66), a file that is not a drawing
EX_DATAERR (65), and a host without drawings makes the option a usage error
(EX_USAGE, 64)."
  (is (= clautolisp.sysexits:+ex-noinput+
         (%drawing-error-status (clautolisp.cador:make-cador)
                                "/nonexistent/sysexits-none.dxf")))
  (is (= clautolisp.sysexits:+ex-usage+
         (%drawing-error-status (make-instance 'clautolisp.autolisp-host:nihil)
                                "a.dxf")))
  (let ((path (%exit-status-fixture "sysexits-garbage.dxf"
                                    (%ascii-octets "this is not a drawing"))))
    (unwind-protect
         (is (= clautolisp.sysexits:+ex-dataerr+
                (%drawing-error-status (clautolisp.cador:make-cador)
                                       (namestring path))))
      (ignore-errors (delete-file path)))))

(test exit-status-internal-and-io-errors
  "An error that is the program's own fault is EX_SOFTWARE (70); another
stream error EX_IOERR (74)."
  (is (= clautolisp.sysexits:+ex-software+
         (clautolisp.autolisp-cli:engine-exit-status
          (make-condition 'simple-error :format-control "internal"))))
  (is (= clautolisp.sysexits:+ex-ioerr+
         (clautolisp.autolisp-cli:engine-exit-status
          (make-condition 'stream-error :stream *standard-output*)))))
