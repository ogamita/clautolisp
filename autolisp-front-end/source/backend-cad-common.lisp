;;;; autolisp-front-end/source/backend-cad-common.lisp
;;;;
;;;; Shared helpers used by both CAD backends (BricsCAD + AutoCAD).
;;;; Specified implicitly by alfe-backend-bricscad.issue and
;;;; alfe-backend-autocad.issue — both tickets share the same
;;;; protocol-driven shape, so the common bits live here to keep
;;;; the per-backend files focused on platform specifics.

(defpackage #:alfe.backend.cad-common
  (:use #:cl)
  (:import-from #:alfe.error
                #:backend-not-available
                #:backend-bootstrap-error
                #:backend-protocol-error
                #:backend-eval-error)
  (:import-from #:alfe.backend
                #:make-eval-result)
  (:import-from #:alfe.logging
                #:log-debug
                #:log-verbose
                #:log-warn)
  (:export ;; OS detection
           #:host-os
           #:*host-os-override*
           #:macos-p
           #:linux-p
           #:windows-p
           ;; binary discovery
           #:env-binary
           #:first-existing
           #:windows-program-files-roots
           #:windows-glob-existing-files
           #:vbs-escape
           #:applescript-escape
           ;; runtime LSP discovery
           #:discover-runtime-lsp
           #:discover-bootstrap-lsp
           #:require-runtime-assets
           #:installation-prefixes
           #:alfe-executable-p
           #:asset-search-candidates
           #:*executable-pathname-function*
           #:*vendored-asset-system*
           #:*runtime-lsp-fallback-paths*
           #:*bootstrap-lsp-fallback-paths*
           ;; protocol-driven eval-plan
           #:drive-protocol-actions
           ;; launcher liveness during the READY wait
           #:launcher-exit-code
           #:launcher-alive-or-clean-p
           #:launcher-state-description
           #:engine-never-started-p
           #:ready-timeout-diagnosis
           #:launcher-failure-details
           #:kill-engine-process
           #:cad-argument-path
           ;; the engine's console, captured to files (never an undrained pipe)
           #:console-capture
           #:console-capture-p
           #:make-console-capture
           #:console-capture-stdout-path
           #:console-capture-stderr-path
           #:console-capture-launch-keys
           #:console-capture-text
           #:process-console-text
           ;; plug-in support: launcher script slots, launch options
           #:expand-plugin-slots
           #:launcher-lines
           #:call-launcher
           ;; CAD program discovery + denotation (backend selection)
           #:cad-program
           #:cad-program-kind
           #:cad-program-version
           #:cad-program-locale
           #:cad-program-path
           #:cad-program-denotation
           #:discover-cad-programs
           #:autocad-release-in-path
           #:print-cad-programs
           #:resolve-cad-denotation
           ;; -Efile forwarded to the CAD's own OPEN
           #:cad-file-encoding-plan
           #:cad-open-write-ccs
           ;; the CAD's own command-history log (--cad-log, -Elog)
           #:cad-log-files
           #:cad-log-decode-encoding
           #:decode-cad-log-octets
           #:collect-cad-log))

(in-package #:alfe.backend.cad-common)

;;; --- OS detection -------------------------------------------------

(defvar *host-os-override* nil
  "When non-NIL, forces HOST-OS to return this keyword (:macos / :linux /
:windows) instead of the compile-time detection. Its only purpose is to
let tests exercise a platform-specific launch path — e.g. the Windows
`/Automation' batch argv (alfe-bricscad-batch-hidden-ui) — from a host of
a different OS. NIL in production; never bound outside the test suite.")

(defun host-os ()
  "Return one of :macos :linux :windows :unknown. The detection only
looks at compile-time *features*; UIOP exposes a similar helper but
its name differs across versions, and we don't need uiop's full
matrix here. *HOST-OS-OVERRIDE*, when set, wins (tests only)."
  (or *host-os-override*
      (cond
        #+darwin                   ((or :macos))
        #+(and unix (not darwin))  ((or :linux))
        #+(or win32 windows mswindows)
                                   ((or :windows))
        (t                          :unknown))))

(defun macos-p ()   (eq (host-os) :macos))
(defun linux-p ()   (eq (host-os) :linux))
(defun windows-p () (eq (host-os) :windows))

;;; --- binary discovery helpers ------------------------------------

(defun env-binary (name)
  "Return the env-var value as a string if it's set, exists on disk,
and is executable. Returns NIL otherwise. Used by every backend's
DETECT for its primary `$<BACKEND>_EXE` override."
  (let ((value (uiop:getenv name)))
    (when (and value
               (plusp (length value))
               (probe-file value))
      value)))

(defun first-existing (candidates)
  "Return the first candidate path that exists on disk, or NIL when
none do. CANDIDATES may contain NIL entries (the caller often
splices optional env-var values); those are skipped silently."
  (dolist (candidate candidates)
    (when (and candidate
               (probe-file candidate))
      (return-from first-existing (namestring (truename candidate)))))
  nil)

(defparameter *windows-program-files-env-vars*
  '("ProgramW6432" "ProgramFiles" "ProgramFiles(x86)")
  "Environment variables that typically point at Windows program-
installation roots. The order prefers the native 64-bit tree, then
the generic tree, then the 32-bit compatibility tree.")

(defun windows-program-files-roots ()
  "Return the distinct existing Program Files roots advertised by the
current environment. The result is a list of directory pathnames in
search order, suitable for MERGE-PATHNAMES-based globbing on native
Windows Lisp images."
  (let ((seen (make-hash-table :test #'equal))
        (roots '()))
    (dolist (name *windows-program-files-env-vars* (nreverse roots))
      (let ((value (uiop:getenv name)))
        (when (and value (plusp (length value)))
          (let* ((root (ignore-errors
                         (uiop:ensure-directory-pathname
                          (uiop:parse-native-namestring value))))
                 (namestring (and root (probe-file root)
                                  (namestring (truename root)))))
            (when (and namestring
                       (not (gethash namestring seen)))
              (setf (gethash namestring seen) t)
              (push (uiop:ensure-directory-pathname namestring) roots))))))))

(defun windows-glob-existing-files (relative-globs &key
                                                    (roots
                                                      (windows-program-files-roots)))
  "Expand each RELATIVE-GLOBS pattern under every directory in ROOTS
and return the existing matches as absolute namestrings. RELATIVE-GLOBS
uses forward-slash separators and may contain `*' wildcards in any
path segment, which keeps the callers readable on both native Windows
and MSYS/MinGW-hosted Lisp images."
  (loop for root in roots
        append (loop for relative-glob in relative-globs
                     append (mapcar #'namestring
                                    (directory
                                     (merge-pathnames relative-glob root))))))

;;; --- string escapers for emitted bridge scripts ------------------

(defun vbs-escape (string)
  "Escape STRING for inclusion in a VBScript double-quoted literal.
Per the spec's escape_vbs_string helper: double internal quotes,
leave backslashes alone (Windows paths embed them verbatim)."
  (with-output-to-string (out)
    (loop for ch across string
          do (case ch
               (#\" (write-string "\"\"" out))
               (t   (write-char ch out))))))

(defun applescript-escape (string)
  "Escape STRING for inclusion in an AppleScript double-quoted
literal. AppleScript uses backslash escapes — backslash and double
quote both have to be escaped."
  (with-output-to-string (out)
    (loop for ch across string
          do (case ch
               (#\\ (write-string "\\\\" out))
               (#\" (write-string "\\\"" out))
               (t   (write-char ch out))))))

;;; --- runtime LSP discovery ---------------------------------------
;;;
;;; The CAD-side bootstrap involves two .lsp files, loaded in order:
;;;
;;;   1. autolisp-bootstrap.lsp  — the ~67 autolisp-* helper defuns
;;;                                 (autolisp-eval-request-form,
;;;                                  autolisp-log-err, autolisp-set-
;;;                                  status, …) ported verbatim from
;;;                                 the legacy bash wrapper.
;;;   2. autolisp-remote-io.lsp  — the file-IPC server loop, which
;;;                                 calls into the helpers from (1).
;;;
;;; Both files are shared by every CAD backend. They ship vendored under
;;; source/runtime/, `make install' copies them to
;;; <PREFIX>/share/alfe/runtime/, and $ALFE_BOOTSTRAP_LSP /
;;; $ALFE_RUNTIME_LSP override both. ASSET-SEARCH-CANDIDATES below is the
;;; one statement of the search order.

(defparameter *runtime-lsp-fallback-paths*
  '("/opt/local/share/alfe/runtime/autolisp-remote-io.lsp"
    "/usr/local/share/alfe/runtime/autolisp-remote-io.lsp"
    "/usr/share/alfe/runtime/autolisp-remote-io.lsp"
    "~/works/sncf-reseau/src/outils-autolisp/autolisp-script/runtime/autolisp-remote-io.lsp")
  "Fallback locations consulted when $ALFE_RUNTIME_LSP is unset and
the vendored copy is missing. The last entry points at the legacy
SNCF tree so developers with that checkout keep working without
configuration.")

(defparameter *bootstrap-lsp-fallback-paths*
  '("/opt/local/share/alfe/runtime/autolisp-bootstrap.lsp"
    "/usr/local/share/alfe/runtime/autolisp-bootstrap.lsp"
    "/usr/share/alfe/runtime/autolisp-bootstrap.lsp")
  "Fallback locations for autolisp-bootstrap.lsp when $ALFE_BOOTSTRAP_LSP
is unset and the vendored copy is missing. The legacy SNCF tree does
NOT ship this file standalone — the bash wrapper inlines its content
into the generated run-common.lsp at run time — so there is no
SNCF-tree fallback here (only the vendored copy + install prefixes).")

;;; --- the installation prefix of the RUNNING executable ------------
;;;
;;; An installed alfe is a dumped image: the ASDF source location it was
;;; built from need not exist on the machine it runs on, and the fixed
;;; prefixes above do not name an arbitrary Windows install. The copies
;;; `make install' puts under <PREFIX>/share/alfe/runtime/ are found from
;;; where the executable itself lives (alfe-installed-runtime-prefix-
;;; discovery.issue) -- never from the current directory, and never from
;;; the build location.

(defun executable-pathname ()
  "The truename of the running executable, or NIL when it cannot be
determined. Symlinks are resolved, so a bin/alfe link finds the tree it
points into. The implementation-specific part is this one form."
  (ignore-errors
   (let ((path #+sbcl sb-ext:*runtime-pathname*
               #+ccl (ccl::kernel-path)
               #-(or sbcl ccl) nil))
     (when path
       (truename path)))))

(defvar *executable-pathname-function* 'executable-pathname
  "Function of no argument returning the running executable's pathname.
A variable so the tests can place a pretend executable in a pretend
installation; production never rebinds it.")

(defun alfe-executable-p (exe)
  "True when EXE is an alfe program: alfe, alfe-sbcl, alfe-ccl, with or
without .exe. A development image runs as `sbcl' or `ccl', whose own
prefix (/usr, /usr/local) says nothing about where alfe's assets are --
and must not shadow the source tree's copies; the fixed fallbacks still
cover a system-wide install."
  (let ((name (and exe (pathname-name exe))))
    (and (stringp name)
         (or (string-equal name "alfe")
             (and (> (length name) 5)
                  (string-equal "alfe-" name :end2 5))))))

(defun %components-equal (a b)
  (and (= (length a) (length b))
       (every (lambda (x y) (and (stringp x) (stringp y) (string-equal x y)))
              a b)))

(defun installation-prefixes (&optional
                                (exe (funcall *executable-pathname-function*)))
  "The installation prefixes EXE can belong to, most specific first, as
directory pathnames. The prefix is only known at run time -- a release
is staged, zipped, and unpacked under any path -- and alfe's binary sits
in one of two places in it:

  <PREFIX>/libexec/.../alfe-<lisp>[.exe]
      below libexec, per platform and processor
      (libexec/clautolisp/binaries/<os>/<arch>/ today), reached through
      the bin/alfe[.cmd] trampoline, which does not pass the prefix on
  <PREFIX>/bin/alfe-<lisp>[.exe]
      the autolisp-front-end `make install' layout

Components compare case-insensitively: on Windows LIBEXEC and libexec
are the same directory. NIL when EXE is not an alfe executable."
  (when (alfe-executable-p exe)
    (let* ((dir (pathname-directory exe))
           (n (length dir))
           (prefixes '()))
      (flet ((prefix (drop)
               (make-pathname :directory (subseq dir 0 (- n drop))
                              :name nil :type nil :version nil
                              :defaults exe)))
        ;; Anywhere below a libexec directory: the prefix is its parent.
        ;; The deepest libexec wins, so a prefix that itself contains a
        ;; libexec component (/opt/libexec/x/libexec/...) still resolves.
        (let ((pos (position-if (lambda (c)
                                  (and (stringp c) (string-equal c "libexec")))
                                dir :from-end t)))
          (when (and pos (> pos 0) (< pos (1- n)))
            (push (prefix (- n pos)) prefixes)))
        (when (and (> n 1)
                   (stringp (car (last dir)))
                   (string-equal (car (last dir)) "bin"))
          (push (prefix 1) prefixes)))
      (nreverse prefixes))))

(defun installed-asset-paths (basename)
  "<PREFIX>/share/alfe/runtime/BASENAME for every prefix the running
executable can belong to."
  (mapcar (lambda (prefix)
            (merge-pathnames
             (make-pathname :directory '(:relative "share" "alfe" "runtime")
                            :name (pathname-name basename)
                            :type (pathname-type basename))
             prefix))
          (installation-prefixes)))

(defvar *vendored-asset-system* "autolisp-front-end/backend-cad-common"
  "The ASDF system whose source tree holds source/runtime/. A variable so
the tests can make the source tree unavailable, as it is to an
installed executable on another machine.")

(defun asset-search-candidates (env-name basename fallback-paths)
  "Every place an asset is looked for, in precedence order, as a list of
(ORIGIN PATH), PATH a namestring:

  1. :environment  $ENV-NAME, when set and non-empty
  2. :installed    <PREFIX>/share/alfe/runtime/, from the executable
  3. :vendored     source/runtime/ in the ASDF source tree
  4. :fallback     the fixed FALLBACK-PATHS

This is also what a missing-asset error reports, so it lists candidates
that do not exist."
  (let ((env (uiop:getenv env-name))
        (vendored (ignore-errors
                   (asdf:system-relative-pathname
                    *vendored-asset-system*
                    (concatenate 'string "source/runtime/" basename)))))
    (append
     (when (and env (plusp (length env)))
       (list (list :environment env)))
     (mapcar (lambda (p) (list :installed (uiop:native-namestring p)))
             (installed-asset-paths basename))
     (when vendored
       (list (list :vendored (uiop:native-namestring vendored))))
     (mapcar (lambda (p) (list :fallback (uiop:native-namestring p)))
             fallback-paths))))

(defun %resolve-asset (env-name basename fallback-paths)
  "The first existing file among ASSET-SEARCH-CANDIDATES, as an absolute
namestring, or NIL. An $ENV-NAME naming no file is passed over, as it
always was."
  (loop for (nil path) in (asset-search-candidates env-name basename
                                                   fallback-paths)
        for found = (ignore-errors (probe-file path))
        when (and found (pathname-name found))
          do (return (namestring found))))

(defun discover-runtime-lsp ()
  "Resolve the CAD-side runtime LSP path (autolisp-remote-io.lsp):
$ALFE_RUNTIME_LSP, then the running alfe's installation prefix, then the
vendored source/runtime/ copy, then the fixed fallbacks -- see
ASSET-SEARCH-CANDIDATES. Returns an absolute namestring, or NIL."
  (%resolve-asset "ALFE_RUNTIME_LSP" "autolisp-remote-io.lsp"
                  *runtime-lsp-fallback-paths*))

(defun discover-bootstrap-lsp ()
  "Resolve the CAD-side bootstrap LSP path (autolisp-bootstrap.lsp),
which defines the autolisp-* helpers the runtime's server loop calls.
Same order as DISCOVER-RUNTIME-LSP. Returns an absolute namestring, or
NIL."
  (%resolve-asset "ALFE_BOOTSTRAP_LSP" "autolisp-bootstrap.lsp"
                  *bootstrap-lsp-fallback-paths*))

(defun require-runtime-assets (backend)
  "Resolve both CAD-side assets, or signal BACKEND-BOOTSTRAP-ERROR (code
:RUNTIME-ASSET-MISSING) naming each missing one and every path searched
for it. Returns (values RUNTIME-PATH BOOTSTRAP-PATH).

Called BEFORE anything is launched. A CAD started without them boots and
never reaches READY; the whole READY timeout (120 s on the Windows
runner) used to be spent waiting for a runtime that was never staged."
  (let ((runtime (discover-runtime-lsp))
        (bootstrap (discover-bootstrap-lsp))
        (missing '()))
    (unless bootstrap
      (push (list "autolisp-bootstrap.lsp" "ALFE_BOOTSTRAP_LSP"
                  (asset-search-candidates "ALFE_BOOTSTRAP_LSP"
                                           "autolisp-bootstrap.lsp"
                                           *bootstrap-lsp-fallback-paths*))
            missing))
    (unless runtime
      (push (list "autolisp-remote-io.lsp" "ALFE_RUNTIME_LSP"
                  (asset-search-candidates "ALFE_RUNTIME_LSP"
                                           "autolisp-remote-io.lsp"
                                           *runtime-lsp-fallback-paths*))
            missing))
    (when missing
      (setf missing (nreverse missing))
      (error 'backend-bootstrap-error
             :backend backend
             :code :runtime-asset-missing
             :message
             (format nil "~A not launched: required CAD runtime file~P not found.~
~:{~%  ~A (set $~A to override); searched:~:{~%    ~(~11A~) ~A~}~}~
~%  running executable: ~A"
                     backend (length missing)
                     missing
                     (or (funcall *executable-pathname-function*) "unknown"))
             :details (list :missing missing)))
    (values runtime bootstrap)))

;;; --- protocol-driven eval-plan ------------------------------------

(defparameter *interactive-prompt-primary*    "alfe> "
  "Prompt issued before reading a fresh top-level form in the
CAD-backed interactive REPL.")

(defparameter *interactive-prompt-continuation* "    > "
  "Continuation prompt issued when the form on the wire is not yet
balanced and the user must keep typing.")

(defparameter *interactive-quit-tokens*
  '(":quit" ":q" ":exit" "(quit)" "(exit)")
  "Lines (after trimming) that terminate the CAD-backed interactive
REPL on the alfe side without bothering to send another request.
Anything else is forwarded to the runtime verbatim. Note that the
runtime *itself* still honours (quit)/(exit) — sending those forms
through stdin.txt drives the same code path as :quit control; this
list is just a UX convenience so users can type the familiar tokens
and have the loop terminate cleanly without waiting for the runtime
round-trip.")

;;; --- G3b: transcode a codepage -l source to UTF-8+BOM for the CAD --------
;;;
;;; A CAD host cannot load a raw single-byte-codepage source portably: (load)
;;; has NO encoding argument -- it detects a UTF-8/UTF-16 BOM, else decodes with
;;; the READ-ONLY SYSCODEPAGE (macOS = MAC_ROMAN, Windows = its ANSI cp). So a
;;; cp1252 é (0xE9) native-loaded on macOS BricsCAD becomes È, and (chr 233) is
;;; no longer = the file char (cad-chr-vs-loaded-encoding). When -Esource names
;;; a codepage, alfe decodes the file with it and stages a UTF-8-WITH-BOM copy,
;;; which every platform's (load) detects (via the BOM) and decodes correctly.
;;; Unicode / unset encodings pass through unchanged. (A refinement, not needed
;;; for correctness: skip the copy when -Esource already equals the host
;;; SYSCODEPAGE -- the raw file would then load right too.)

(defun %source-encoding->babel (encoding)
  "Map a -Esource ENCODING designator to a BABEL encoding keyword, or NIL when it
is nil / :auto / a Unicode codec the CAD reads via its own BOM (no transcode
needed). babel gives the SAME codec set on SBCL and CCL, so every named codepage
is handled, not just the built-in cp1252 cascade."
  (let ((kw (ignore-errors (clautolisp.autolisp-cli:encoding-keyword encoding))))
    (case kw
      ((nil :auto :utf-8 :utf8 :utf-16 :utf-16le :utf-16be :utf16le :utf16be) nil)
      ;; babel spells the Windows codepages :cp125X, not :windows-125X.
      (:windows-1250 :cp1250) (:windows-1251 :cp1251) (:windows-1252 :cp1252)
      (:windows-1253 :cp1253) (:windows-1254 :cp1254) (:windows-1255 :cp1255)
      (:windows-1256 :cp1256) (:windows-1257 :cp1257) (:windows-1258 :cp1258)
      (t kw))))                          ; :iso-8859-*, :koi8-*, :cp125X, … pass through

(defun %read-file-octets (path)
  (with-open-file (in path :direction :input :element-type '(unsigned-byte 8))
    (let ((v (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (read-sequence v in)
      v)))

(defun stage-source-as-utf8-bom (protocol-session path encoding &optional product)
  "Resolve PATH against alfe's invocation directory.  If ENCODING is a
non-Unicode codepage, decode that absolute source with babel and write a
copy into the workdir the CAD's native load reads right, returning the copy's
path for the CAD to (load); otherwise return the absolute source path itself.

The copy is UTF-8 with a BOM -- except for PRODUCT :AUTOCAD, where it is
windows-1252 without a BOM whenever the text fits: AutoCAD 2022 at LISPSYS 0
IGNORES a BOM and reads the UTF-8 bytes as cp1252 (two characters for each
accented one), and at LISPSYS 1 / 2 it reads a file that is not valid UTF-8 as
cp1252 -- so cp1252 reads right at every level (E1, job 16931781178,
encoding-situations-cli-options). Text cp1252 cannot hold keeps UTF-8 + BOM
(right at LISPSYS 1 / 2 only).

The absolutisation is required even without transcoding: CAD batch processes
run from the generated workdir, not necessarily from alfe's current directory,
so forwarding a relative -l pathname verbatim makes the CAD look in the wrong
directory."
  (let* ((absolute-path (namestring
                         (uiop:ensure-absolute-pathname path (uiop:getcwd))))
         (babel-enc (%source-encoding->babel encoding)))
    (if (null babel-enc)
      absolute-path
      (let* ((text (babel:octets-to-string (%read-file-octets absolute-path)
                                           :encoding babel-enc :errorp nil))
             (staged (merge-pathnames
                      (format nil "esrc-~A" (file-namestring (pathname path)))
                      (uiop:ensure-directory-pathname
                       (alfe.protocol.file:protocol-session-workdir
                        protocol-session)))))
        (let ((cp1252 (and (eq product :autocad)
                           (ignore-errors (babel:string-to-octets text :encoding :cp1252
                                                                       :errorp t)))))
          (if cp1252
              (with-open-file (out staged :direction :output :element-type '(unsigned-byte 8)
                                          :if-exists :supersede :if-does-not-exist :create)
                (write-sequence cp1252 out))
              (with-open-file (out staged :direction :output :external-format :utf-8
                                          :if-exists :supersede :if-does-not-exist :create)
                (write-char (code-char #xFEFF) out)   ; UTF-8 BOM -> EF BB BF
                (write-string text out)))
          (log-debug "cad-common: staged ~A ~A -> ~A (from ~A source)"
                     (if cp1252 "cp1252" "UTF-8+BOM")
                     (file-namestring (pathname absolute-path))
                     (file-namestring staged) encoding))
        (namestring (truename staged))))))

;;; --- launcher liveness during the READY wait -------------------------
;;;
;;; alfe-bricscad-automation-macos: a launcher that dies before the engine
;;; publishes READY used to be invisible — the READY wait simply ran out its
;;; whole timeout (240 s on the macOS probe) and reported a bare READY-TIMEOUT
;;; with an empty status.txt, which says nothing about WHY. The launcher's own
;;; exit code and stderr held the answer and were discarded.
;;;
;;; The subtlety is that a launcher exiting is NOT itself a failure. In
;;; automation mode the launcher is a driver, not the engine: osascript
;;; returns as soon as it has typed its keystrokes, and cscript returns once it
;;; has dispatched the COM SendCommand — both long before the CAD has loaded
;;; run-common.lsp and published READY. Only a NON-ZERO exit proves the launch
;;; failed. So we abort early on a non-zero exit and keep waiting on a clean
;;; one, which leaves the batch path (where the process IS the CAD) unchanged
;;; in every case that used to work.

(defun launcher-exit-code (process-info)
  "The exit code of PROCESS-INFO if it has terminated, else NIL. Never
blocks: UIOP:WAIT-PROCESS returns immediately (and caches) once the
process is gone."
  (when (and process-info
             (not (ignore-errors (uiop:process-alive-p process-info))))
    (ignore-errors (uiop:wait-process process-info))))

(defun launcher-alive-or-clean-p (process-info)
  "Predicate for WAIT-FOR-STATUS-PREFIX's :ALIVE-P. True while the
launcher is running, and true after it exits 0 (a driver that has done
its job); false only once it has exited NON-ZERO, which aborts the wait
immediately instead of burning the rest of the timeout."
  (let ((code (launcher-exit-code process-info)))
    (or (null code) (eql code 0))))

(defun engine-never-started-p (last-status)
  "True when the engine has published no transition at all: LAST-STATUS is
empty or still the BOOTING that INIT-SESSION wrote before the CAD was launched.

This is the discriminator the READY-timeout message was missing. `Timed out,
launcher still running' reads identically for a CAD that is merely slow and for
one sitting on a modal dialog nobody can answer, and telling those apart took
three wrong hypotheses once (cad-runner-wedged-by-modal-dialog). A CAD that has
moved to RUNNING and stopped is a different problem from one that never loaded
run-common.lsp at all."
  (let ((status (string-trim '(#\Space #\Tab #\Newline #\Return)
                             (or last-status ""))))
    (or (zerop (length status))
        (and (>= (length status) 7)
             (string-equal "BOOTING" status :end2 7)))))

(defun ready-timeout-diagnosis (exit-code last-status)
  "The phrase appended to a READY-timeout message, from the launcher's EXIT-CODE
\(NIL while it is alive) and the LAST-STATUS the protocol saw.

Pure, so the wording is testable without launching anything. Three cases, and
the third is the one this exists for:

- the launcher EXITED -- its code is the fact that matters, and
  LAUNCHER-FAILURE-DETAILS already reports a non-zero one with its output;
- it is alive and the engine HAS moved (RUNNING, DONE, ...) -- then it started
  fine and stalled later, which is not a launch problem at all;
- it is alive and the engine NEVER MOVED off BOOTING -- it was started and has
  produced nothing. On Windows that is usually a startup dialog waiting for
  input, and under a hidden main frame (/Automation) the dialog is invisible as
  well as unanswerable: BricsCAD asks which drawing and which profile to use
  when given neither. On macOS the same shape comes from the Accessibility
  prompt that blocks the first `keystroke' from an un-permitted osascript.
  Naming the likely cause here is the whole point -- it is what would have
  pointed at the real one in a single read."
  (cond
    (exit-code (format nil "launcher exited with code ~A" exit-code))
    ((engine-never-started-p last-status)
     "launcher still running but the engine never moved past BOOTING -- it was \
started and has produced nothing; on Windows this is usually a startup dialog \
waiting for input (BricsCAD asks which drawing and which profile when given \
neither, and under a hidden main frame the dialog is invisible as well as \
unanswerable), on macOS an Accessibility prompt blocking osascript")
    (t "launcher still running")))

(defun launcher-state-description (process-info &optional last-status)
  "A short phrase describing the launcher's state, for the READY-timeout
message. A launcher that finished cleanly and a launcher that is STUCK
produce identical protocol symptoms — status.txt frozen at BOOTING,
empty channels — and the one thing that tells them apart is whether the
process is still there. On macOS the stuck case is real and common: the
first `keystroke' from an un-permitted process raises a system
Accessibility prompt, and osascript blocks on that modal until someone
answers it.

LAST-STATUS, when given, sharpens it further — see READY-TIMEOUT-DIAGNOSIS."
  (when process-info
    (ready-timeout-diagnosis (launcher-exit-code process-info) last-status)))

(defun launcher-failure-details (process-info &key (limit 4000) capture)
  "When PROCESS-INFO exited non-zero, return a string with its exit code
and whatever it wrote to stderr/stdout (truncated to LIMIT characters);
NIL while it is alive or when it exited 0.

The text comes from CAPTURE, the CONSOLE-CAPTURE the launch redirected the
process's output into (see MAKE-CONSOLE-CAPTURE), and from the process's own
pipes only when a launcher returned some anyway (PROCESS-CONSOLE-TEXT). It is
read only once the process is known to be dead."
  (let ((code (launcher-exit-code process-info)))
    (when (and code (not (eql code 0)))
      (flet ((tail (which)
               (let ((text (string-right-trim
                            '(#\Newline #\Return)
                            (or (ignore-errors
                                 (process-console-text process-info which
                                                       :capture capture
                                                       :strip-nul nil))
                                ""))))
                 (if (> (length text) limit)
                     (subseq text (- (length text) limit))
                     text))))
        (let ((err (tail :stderr))
              (out (tail :stdout)))
          (format nil "launcher exited with code ~A~@[; stderr: ~A~]~@[; stdout: ~A~]"
                  code
                  (when (plusp (length err)) (string-trim '(#\Newline #\Space) err))
                  (when (plusp (length out)) (string-trim '(#\Newline #\Space) out))))))))

(defun cad-argument-path (path)
  "The text to hand an EXTERNAL CAD process for PATH.

A STRING is passed through UNTOUCHED. It already names a file under the
CAD's rules -- a --dwg argument, $AUTOLISP_BRICSCAD_TEMPLATE -- and this
Lisp has no business reinterpreting it. Calling NAMESTRING on it did
exactly that: NAMESTRING of a string first PARSES it as a pathname of
the Lisp alfe happens to be running on, and the two implementations
disagree. On a Unix host SBCL renders \"C:/t.dwt\" back unchanged; CCL
escapes the colon and produced \"C\\\\:/t.dwt\", which then went to
BricsCAD (alfe-bricscad-template-path-escaped-on-ccl.issue).

A PATHNAME object -- the per-run workdir's run.scr, a bridge script --
belongs to THIS host, so it IS rendered here, but with
UIOP:NATIVE-NAMESTRING: the operating system's spelling, with none of
the Lisp's namestring escapes, because the reader is a separate program
and not this Lisp. On SBCL that is the same string NAMESTRING gives for
an ordinary path."
  (etypecase path
    (string path)
    (pathname (uiop:native-namestring path))))

(defun kill-engine-process (info &key (timeout 6))
  "Best-effort terminate the launched engine within TIMEOUT seconds, NEVER
blocking indefinitely.

`uiop:wait-process' can hang on Windows when the engine (a GUI CAD) is
slow to die, or when a child of it shares the handles — that would freeze
alfe in shutdown and hang the whole job. So this terminates, then POLLS
`process-alive-p' up to TIMEOUT, force-killing (:urgent) if it outlives
that, and never issues an unbounded wait. On exit the OS reaps it.

This lived in the BricsCAD backend, which is where the hazard was first
paid for. It is not BricsCAD-specific — AutoCAD spawns a GUI process the
same way — and having only one backend own the careful version is exactly
how the other one kept the unbounded `wait-process' that this docstring
warns about. Shared here so both use it."
  (when info
    (ignore-errors
     (when (uiop:process-alive-p info) (uiop:terminate-process info)))
    (let ((start (get-internal-real-time)))
      (loop while (and (ignore-errors (uiop:process-alive-p info))
                       (< (/ (float (- (get-internal-real-time) start))
                             internal-time-units-per-second)
                          timeout))
            do (sleep 0.2)))
    (ignore-errors
     (when (uiop:process-alive-p info)
       (uiop:terminate-process info :urgent t)
       ;; :urgent is SIGKILL, which the kernel delivers ASYNCHRONOUSLY: the
       ;; process is doomed but not necessarily REAPED the instant
       ;; terminate-process returns, so process-alive-p can still read true
       ;; for a short window — wider on a loaded machine. A caller that
       ;; checks liveness right after we return (and our own contract —
       ;; "the process is gone when this returns") then sees a survivor
       ;; that is already dying. Poll briefly for the death we just caused,
       ;; still BOUNDED (SIGKILL cannot be trapped, so this resolves in
       ;; milliseconds; the cap only guards a pathological D-state child)
       ;; and never an unbounded wait-process
       ;; (timing-flakes-in-process-and-socket-tests).
       (let ((kstart (get-internal-real-time)))
         (loop while (and (ignore-errors (uiop:process-alive-p info))
                          (< (/ (float (- (get-internal-real-time) kstart))
                                internal-time-units-per-second)
                             2))
               do (sleep 0.02))))))
  nil)

;;; --- the engine's console: captured to files, never an undrained pipe ---
;;;
;;; alfe used to start the CAD (accoreconsole, bricscad, and the cscript /
;;; osascript launchers) with :OUTPUT :STREAM :ERROR-OUTPUT :STREAM and read
;;; those pipes only once the process had EXITED, for the diagnostics. Nothing
;;; read them while it ran -- the payload travels through the file protocol --
;;; so once the operating system's pipe buffer was full (a few KB to 64 KB)
;;; the engine's next console write blocked for ever. accoreconsole echoes its
;;; whole command line to that console, in UTF-16LE, so a long chatty --mode
;;; batch run hung part-way, at no particular command, until --timeout
;;; (alfe-accoreconsole-console-pipe-not-drained.issue).
;;;
;;; The console now goes to two files in the run's workdir. A file never fills,
;;; so the engine can never block on it; reading it cannot block either, even
;;; when a grandchild (the bricscad.exe a launcher started) still holds the
;;; handle, which reading a pipe to its end-of-file would; it needs no thread,
;;; so it is the same on SBCL and CCL, Windows and POSIX; and --keep leaves the
;;; console in the workdir for a post-mortem. It is the shape the clautolisp
;;; child already had (%RUN-ENGINE-CHILD in backend-clautolisp.lisp).

(defstruct (console-capture (:constructor %make-console-capture))
  "Where a launched engine's standard output and error output go, and the
external format to read them back with."
  (stdout-path nil)
  (stderr-path nil)
  (external-format :iso-8859-1))

(defun make-console-capture (workdir &key (name "engine-console")
                                          (external-format :iso-8859-1))
  "A CONSOLE-CAPTURE into WORKDIR/NAME-stdout.txt and WORKDIR/NAME-stderr.txt.
EXTERNAL-FORMAT is how CONSOLE-CAPTURE-TEXT decodes them (the default is a
total decoder that never signals)."
  (let ((dir (uiop:ensure-directory-pathname workdir)))
    (%make-console-capture
     :stdout-path (merge-pathnames (format nil "~A-stdout.txt" name) dir)
     :stderr-path (merge-pathnames (format nil "~A-stderr.txt" name) dir)
     :external-format (or external-format :iso-8859-1))))

(defun console-capture-launch-keys (capture)
  "The UIOP:LAUNCH-PROGRAM keywords that send the process's standard output
and error output to CAPTURE's files (each truncated first)."
  (list :output (console-capture-stdout-path capture)
        :if-output-exists :supersede
        :error-output (console-capture-stderr-path capture)
        :if-error-output-exists :supersede))

(defun %read-stream-text (stream strip-nul)
  (with-output-to-string (out)
    (loop for ch = (read-char stream nil nil)
          while ch
          unless (and strip-nul (char= ch (code-char 0)))
            do (write-char ch out))))

(defun console-capture-text (capture which &key (strip-nul t))
  "What the engine wrote to WHICH (:STDOUT or :STDERR) of CAPTURE, as a string;
\"\" when there is nothing. Decoded with CAPTURE's external format, falling
back to ISO-8859-1 (which never signals) when that fails. STRIP-NUL removes
the NULs of a UTF-16LE console read byte-wise (accoreconsole). Never blocks:
it reads a file, never a pipe."
  (let ((path (and capture
                   (ecase which
                     (:stdout (console-capture-stdout-path capture))
                     (:stderr (console-capture-stderr-path capture))))))
    (flet ((read-as (format)
             (with-open-file (in path :direction :input
                                      :if-does-not-exist nil
                                      :external-format format)
               (if in (%read-stream-text in strip-nul) ""))))
      (or (and path
               (or (ignore-errors (read-as (console-capture-external-format capture)))
                   (ignore-errors (read-as :iso-8859-1))))
          ""))))

(defun process-console-text (process-info which &key capture (strip-nul t))
  "Everything PROCESS-INFO wrote to WHICH (:STDOUT or :STDERR): the text of
CAPTURE's file, then whatever its pipe still holds when the launcher returned
one (a test launcher may). Call it only once the process is dead -- reading a
live pipe to its end would wait for the process."
  (let ((stream (and process-info
                     (ignore-errors
                      (ecase which
                        (:stdout (uiop:process-info-output process-info))
                        (:stderr (uiop:process-info-error-output process-info)))))))
    (concatenate 'string
                 (console-capture-text capture which :strip-nul strip-nul)
                 (or (and (streamp stream)
                          (open-stream-p stream)
                          (input-stream-p stream)
                          (ignore-errors (%read-stream-text stream strip-nul)))
                     ""))))

;;; --- plug-in support ---------------------------------------------------
;;;
;;; The launcher scripts alfe writes for the CAD (run.scr, the VBScript
;;; bridges) have named slots that plug-ins fill through the hook
;;; :launcher-lines (see the spec chapter "Plug-ins"), and the spawn takes
;;; the working directory and environment a plug-in asks for through the
;;; hook :launch-options. With no active plug-in every function here is the
;;; identity on what it is given.

(defun launcher-lines (slot kind variant)
  "The lines the active plug-ins put in SLOT of a launcher script of KIND
(:scr or :vbs) for VARIANT (:batch or :automation)."
  (alfe.plugin:run-hook :launcher-lines slot :kind kind :variant variant))

(defun expand-plugin-slots (template variant)
  "TEMPLATE with each of its two VBScript plug-in slot lines,
${PLUGIN_AFTER_APP} and ${PLUGIN_BEFORE_LOAD}, replaced by the lines the
active plug-ins provide for it, or removed with its newline when there are
none — so a run with no plug-in emits the template byte for byte."
  (let ((out template))
    (loop for (placeholder slot) in '(("${PLUGIN_AFTER_APP}"   :after-app)
                                      ("${PLUGIN_BEFORE_LOAD}" :before-load))
          do (let ((lines (launcher-lines slot :vbs variant)))
               ;; A string replaces the placeholder; NIL removes it, and with
               ;; it the newline of the line it stood alone on.
               (setf out (uiop:frob-substrings
                          out
                          (list (if lines
                                    placeholder
                                    (format nil "~A~%" placeholder)))
                          (and lines (format nil "~{~A~^~%~}" lines))))))
    out))

(defun %call-with-environment (environment thunk)
  "Call THUNK with the (NAME . VALUE) pairs of ENVIRONMENT set in the
process environment, restoring the previous values afterwards. A NIL VALUE
sets the variable to the empty string (the portable form of \"unset\")."
  (let ((previous (mapcar (lambda (pair) (cons (car pair) (uiop:getenv (car pair))))
                          environment)))
    (unwind-protect
         (progn
           (dolist (pair environment)
             (setf (uiop:getenv (car pair)) (or (cdr pair) "")))
           (funcall thunk))
      (dolist (pair previous)
        (setf (uiop:getenv (car pair)) (or (cdr pair) ""))))))

(defun call-launcher (launcher argv launch-options &rest keys)
  "Call LAUNCHER as (LAUNCHER ARGV . KEYS), adding :DIRECTORY and applying
the :ENVIRONMENT that LAUNCH-OPTIONS, the result of the :launch-options
hook, carries. The mock launchers of the test suite ignore extra keys."
  (let ((directory (getf launch-options :directory))
        (environment (getf launch-options :environment)))
    (flet ((launch ()
             (apply launcher argv
                    (append (when directory (list :directory directory)) keys))))
      (if environment
          (%call-with-environment environment #'launch)
          (launch)))))

(defun drive-protocol-actions (protocol-session plan
                               &key
                                 (request-timeout 30)
                                 (keep-alive-while-running t)
                                 (process-info nil)
                                 (shutdown-timeout 10)
                                 (input-stream  *standard-input*)
                                 (output-stream *standard-output*)
                                 (error-stream  *error-output*)
                                 (staging-product nil))
  "Drive a PLAN of actions through a connected PROTOCOL-SESSION,
waiting for each transition to land. The CAD-side runtime is
expected to walk READY N → RUNNING N → DONE N {OK,FAIL,QUIT} per
the spec's main loop.

Returns an EVAL-RESULT with:
  - status: :success when every action saw `DONE N OK`,
            :failed on any `DONE N FAIL`,
            :aborted on a timeout.
  - output / error-output: the drained stdout.txt / stderr.txt
    captures (the full per-plan transcript — alfe writes them live
    to OUTPUT-STREAM / ERROR-STREAM as each action completes, and
    keeps a copy for the EVAL-RESULT).

Each round-trip waits for a *counter-specific* `DONE N` — generic
`DONE` would match the previous action's stale status the very tick
after send-stdin returns, dropping the new eval's output and any
error message before they could be drained. The counter is seeded
from the runtime's `READY N` (whatever the CAD published when it
became ready) and incremented locally on each send.

INPUT-STREAM/OUTPUT-STREAM/ERROR-STREAM are wired through to the
:interactive REPL loop; the CLI passes the live terminal streams,
tests can pass string streams to drive the REPL in-process.

REQUEST-TIMEOUT bounds how long each round-trip waits for its `DONE N'.
When KEEP-ALIVE-WHILE-RUNNING (the default) and PROCESS-INFO are given,
that budget only guards the READY->RUNNING handshake: once the runtime
publishes `RUNNING N' and the spawned process is alive, the wait is
extended so a legitimately long (eval ...) is not aborted on wall-clock
(alfe-request-timeout-aborts-long-eval). An explicit user `--timeout'
passes KEEP-ALIVE-WHILE-RUNNING NIL to restore a hard cap. PROCESS-INFO
(a UIOP process object) also lets a dead engine abort promptly."
  (let* ((status :success)
         (captured-stdout (make-string-output-stream))
         (captured-stderr (make-string-output-stream))
         ;; Liveness probe over the spawned CAD process, or NIL in tests /
         ;; when the caller has no handle. Consulted by wait-for-status-prefix
         ;; to distinguish "engine still computing" from "engine died".
         (alive-p (when process-info
                    (lambda () (uiop:process-alive-p process-info))))
         ;; The runtime publishes "READY N" at startup and then walks
         ;; N+1 on each request. We initialise from the currently-
         ;; observed status (typically "READY 0") so the first
         ;; send-action waits for "DONE 1".
         (request-counter (or (parse-trailing-positive-integer
                               (alfe.protocol.file:read-current-status
                                protocol-session))
                              0)))
    (labels
        ((apply-alfe-control (key value)
           "Apply one parsed `[ALFE-CONTROL] KEY=VALUE' sentinel."
           (cond
             ((string-equal key "DEBUG")
              (let ((on (or (string= value "1")
                            (string-equal value "T"))))
                (alfe.logging:set-level (if on :debug :info))))
             ((string-equal key "VERBOSE")
              (let ((on (or (string= value "1")
                            (string-equal value "T"))))
                ;; Don't downgrade from :debug -- VERBOSE=0 means
                ;; "stop verbose chatter", but if debug is also on
                ;; we want to stay at :debug.
                (cond
                  (on
                   (unless (eq alfe.logging:*current-level* :debug)
                     (alfe.logging:set-level :verbose)))
                  (t
                   (when (eq alfe.logging:*current-level* :verbose)
                     (alfe.logging:set-level :info))))))
             (t
              ;; Unknown control key. Log under :debug so the user can
              ;; diagnose typos, but don't fail the drain.
              (alfe.logging:log-debug
               "cad-common: unknown ALFE-CONTROL key ~S (value ~S)"
               key value))))
         (filter-alfe-control-lines (raw)
           "Walk RAW, identify any `[ALFE-CONTROL] KEY=VALUE' lines,
apply them as side effects, and return the chunk with those lines
stripped out. Non-sentinel lines pass through verbatim so the
terminal sees only what the user printed.

The sentinel format is one line per command:
  `[ALFE-CONTROL] KEY=VALUE'
Trailing newlines are preserved on non-sentinel lines so the caller
can write the result straight to OUTPUT-STREAM."
           (let ((accum (make-string-output-stream))
                 (start 0)
                 (sentinel "[ALFE-CONTROL] ")
                 (len (length raw)))
             (loop
               (let ((eol (position #\Newline raw :start start)))
                 (let* ((line-end (or eol len))
                        (line (subseq raw start line-end))
                        (trimmed (string-left-trim '(#\Space #\Tab) line)))
                   (cond
                     ((and (>= (length trimmed) (length sentinel))
                           (string= sentinel trimmed
                                    :end2 (length sentinel)))
                      ;; Sentinel hit -- parse + apply, don't echo.
                      (let* ((rest (subseq trimmed (length sentinel)))
                             (eq-pos (position #\= rest)))
                        (when eq-pos
                          (apply-alfe-control
                           (string-trim '(#\Space #\Tab)
                                        (subseq rest 0 eq-pos))
                           (string-trim '(#\Space #\Tab #\Return)
                                        (subseq rest (1+ eq-pos)))))))
                     (t
                      ;; Non-sentinel: copy through, preserving the
                      ;; newline if there was one.
                      (write-string line accum)
                      (when eol
                        (write-char #\Newline accum))))
                   (if eol
                       (setf start (1+ eol))
                       (return)))))
             (get-output-stream-string accum)))
         (drain-live ()
           "Drain stdout.txt + stderr.txt, append to the capture
streams, and echo to the live OUTPUT-STREAM / ERROR-STREAM so the
user sees CAD output AS each action completes (not deferred to
end-of-plan).

`[ALFE-CONTROL] KEY=VALUE' lines in stdout are intercepted here
(see filter-alfe-control-lines): they apply control side effects
inline -- chiefly toggling alfe.logging:*current-level* -- and are
stripped before the chunk reaches the terminal. Stderr is passed
through verbatim."
           (let ((out (alfe.protocol.file:drain-stdout protocol-session))
                 (err (alfe.protocol.file:drain-stderr protocol-session)))
             (when (plusp (length out))
               (let ((visible (filter-alfe-control-lines out)))
                 ;; Capture the full text (including sentinels) for
                 ;; the eval-result -- tests + diagnostics may want
                 ;; the unfiltered trace. The live stream only sees
                 ;; the filtered text.
                 (write-string out captured-stdout)
                 ;; The dribble records what the USER would have seen, so the
                 ;; FILTERED text: an [ALFE-CONTROL] line is alfe's own
                 ;; signalling, never engine output (alfe-dribble.issue).
                 (when (plusp (length visible))
                   (alfe.dribble:record-output visible)
                   (write-string visible output-stream)
                   (finish-output output-stream))))
             (when (plusp (length err))
               (write-string err captured-stderr)
               (alfe.dribble:record-error-output err)
               (write-string err error-stream)
               (finish-output error-stream))))
         (sync-verbosity-from-runtime ()
           "Re-read protocol/runtime-flags.txt and, if the CAD-side
runtime has toggled *AUTOLISP-DEBUG* / *AUTOLISP-VERBOSE*, mirror
the change into alfe.logging's *current-level* so the alfe-side
trace lines respect the runtime-side switch regardless of what the
--debug / --verbose CLI flag was at startup.

The mapping is `most-specific-wins': DEBUG=1 -> :DEBUG;
VERBOSE=1 -> :VERBOSE; both NIL -> :INFO. We never drop below
:INFO from here -- the CLI's --quiet (which sets :WARN) still
wins because runtime-flags only carries DEBUG/VERBOSE."
           (let ((flags (alfe.protocol.file:read-runtime-flags
                         protocol-session)))
             (when flags
               (let ((desired
                       (cond
                         ((getf flags :debug)   :debug)
                         ((getf flags :verbose) :verbose)
                         (t                     :info))))
                 (unless (eq desired alfe.logging:*current-level*)
                   ;; Only ever transition between debug/verbose/info
                   ;; based on the runtime flags; if the CLI elected
                   ;; :warn (--quiet alone) we leave that alone, the
                   ;; user opted out of debug/verbose chatter at the
                   ;; process level.
                   (unless (eq alfe.logging:*current-level* :warn)
                     (alfe.logging:set-level desired)))))))
         (wait-done ()
           "Wait for the runtime to publish `DONE <request-counter>'.
Sets STATUS based on the OK / FAIL / QUIT suffix. Drains stdout +
stderr right after the match so output reaches alfe before the
next round-trip starts. After draining we also mirror the current
runtime-side verbosity flags into alfe.logging so toggles a REPL
user makes via (setq *autolisp-debug* …) take effect on the next
trace line."
           (incf request-counter)
           (let ((target (format nil "~A ~D"
                                 alfe.protocol.file:+status-done-prefix+
                                 request-counter))
                 ;; RUNNING acknowledgement for this request. Supplied only
                 ;; when the caller opted into keep-alive; an explicit
                 ;; --timeout keeps this NIL so the wait is a hard cap.
                 (running-target
                   (when keep-alive-while-running
                     (format nil "~A ~D"
                             alfe.protocol.file:+status-running-prefix+
                             request-counter))))
             (multiple-value-bind (matched elapsed last)
                 (alfe.protocol.file:wait-for-status-prefix
                  protocol-session target
                  :timeout request-timeout
                  :running-prefix running-target
                  :alive-p alive-p)
               (declare (ignore elapsed))
               (drain-live)
               (sync-verbosity-from-runtime)
               (cond
                 ((not matched)
                  (setf status :aborted)
                  nil)
                 ((search " FAIL" last) (setf status :failed))
                 ((search " QUIT" last) nil)
                 (t nil)))))
         (send-action (form-text)
           "Atomically publish FORM-TEXT into stdin.txt, then wait
for the runtime to acknowledge `DONE <next-counter>'."
           ;; The form is this session's INPUT -- the nearest thing a
           ;; file-protocol conversation has to what a user typed -- and it is
           ;; recorded raw and unprefixed, as the format wants
           ;; (alfe-dribble.issue). Before sending, so the transcript reads in
           ;; the order it happened even when the engine answers instantly.
           (alfe.dribble:record-input form-text)
           (alfe.protocol.file:send-stdin protocol-session form-text)
           (wait-done))
         (interactive-loop ()
           "Read balanced forms from INPUT-STREAM, forward each to
the runtime via send-action, drain output, repeat until EOF or the
user types a quit token. Survives runtime errors: a `DONE N FAIL'
shows the error on stderr and the prompt comes back."
           (loop
             (drain-live)
             (write-string *interactive-prompt-primary* output-stream)
             (finish-output output-stream)
             (multiple-value-bind (text eof-p)
                 (alfe.protocol.file:read-balanced-form-from-lines
                  (lambda () (read-line input-stream nil nil))
                  :source-name "<alfe-repl>")
               (cond
                 (eof-p
                  (terpri output-stream)
                  (return))
                 ((or (null text) (zerop (length text)))
                  ;; Blank input — just re-prompt.
                  nil)
                 ((member (string-trim '(#\Space #\Tab #\Newline #\Return)
                                       text)
                          *interactive-quit-tokens* :test #'string-equal)
                  (return))
                 (t
                  ;; In a REPL we want to *see* the value the user just
                  ;; typed -- (+ 1 2) should echo 3 on the next line.
                  ;; The protocol only relays printer output (see the
                  ;; alfe spec's "Action output semantics" section),
                  ;; so wrap each form with (print …) on its way to the
                  ;; runtime. The bootstrap's `print' shadow routes the
                  ;; emitted text through *AUTOLISP_PROTOCOL_STDOUTFILE*,
                  ;; which the next drain-live picks up and writes to
                  ;; OUTPUT-STREAM. -x and -l, which are batch and do
                  ;; NOT auto-print, are unaffected -- they take the
                  ;; :load / :eval branches above and bypass this wrap.
                  (send-action (format nil "(print ~A)" text))
                  ;; A FAILED action in the REPL is recoverable: the
                  ;; runtime stays in the read loop, we surfaced the
                  ;; stderr via drain-live, just reset our local
                  ;; status so the next form gets a clean wait-done.
                  (when (eq status :failed)
                    (setf status :success))))))))
      (log-verbose "cad-common: driving ~D action~:P (request-timeout ~A s)"
                   (length plan) request-timeout)
      (log-debug "cad-common: starting from request-counter ~D"
                 request-counter)
      (dolist (action plan)
        (unless (eq status :success) (return))
        (log-debug "cad-common: action ~A payload ~S"
                   (alfe.backend:action-kind action)
                   (alfe.backend:action-payload action))
        (case (alfe.backend:action-kind action)
          (:load
           (let* ((payload (alfe.backend:action-payload action))
                  (path (getf payload :path))
                  (load-path (stage-source-as-utf8-bom
                              protocol-session path (getf payload :encoding)
                              staging-product)))
             (send-action (format nil "(load ~S)" load-path))))
          (:eval
           (send-action (alfe.backend:action-payload action)))
          (:main
           (send-action (format nil "(~A)" (alfe.backend:action-payload action))))
          (:interactive
           ;; The CAD-side runtime is already a read-eval loop on
           ;; stdin.txt; alfe just forwards the terminal. We surface
           ;; a one-line banner so the user knows they've crossed
           ;; into the live REPL, then turn the file-IPC loop into
           ;; an interactive one. Exiting the loop falls through to
           ;; the next action in the plan (typically :quit).
           (format output-stream
                   "alfe REPL on CAD backend. Type ~A or end-of-file (Ctrl-D) to exit.~%"
                   (car *interactive-quit-tokens*))
           (finish-output output-stream)
           (interactive-loop))
          (:quit
           (alfe.protocol.file:send-control protocol-session :shutdown)
           (multiple-value-bind (matched elapsed last)
               (alfe.protocol.file:wait-for-status
                protocol-session
                alfe.protocol.file:+status-stopped+
                :timeout shutdown-timeout)
             (declare (ignore elapsed last))
             (drain-live)
             (unless matched
               (setf status :aborted)))))))
    ;; Final drain — catches anything published between the last
    ;; wait-done's drain-live and now (e.g. a buffered newline).
    (let ((out (alfe.protocol.file:drain-stdout protocol-session))
          (err (alfe.protocol.file:drain-stderr protocol-session)))
      (when (plusp (length out))
        (write-string out captured-stdout)
        (write-string out output-stream))
      (when (plusp (length err))
        (write-string err captured-stderr)
        (write-string err error-stream)))
    (finish-output output-stream)
    (finish-output error-stream)
    (make-eval-result
     :status status
     :value nil       ; CAD backends don't surface a typed value
     :output (get-output-stream-string captured-stdout)
     :error-output (get-output-stream-string captured-stderr))))

(defun parse-trailing-positive-integer (string)
  "If STRING looks like `<word> <integer> ...' (e.g. \"READY 0\",
\"DONE 7 OK\"), return the integer. NIL when STRING is NIL or has no
integer in the second token slot. Used to seed the request-counter
in drive-protocol-actions from whatever READY N the runtime has
already published when we begin driving."
  (when (and string (plusp (length string)))
    (let* ((parts (uiop:split-string string :separator '(#\Space #\Tab))))
      (when (>= (length parts) 2)
        (ignore-errors (parse-integer (second parts)))))))

;;; --- CAD program discovery + denotation (alfe-backend-selection) ---
;;;
;;; A user may have several CAD versions/locales installed and want to pick
;;; one explicitly. DISCOVER-CAD-PROGRAMS enumerates them ALL (unlike the
;;; per-backend DISCOVER-*-BINARY which return only the best one), each with a
;;; canonical DENOTATION (acad-2026, bricscad-v26, bricscad-v25-fr_FR,
;;; accoreconsole-2022, clautolisp) the CLI can select by. This is the model
;;; behind --list-cad-programs; the selection wiring builds on it.

(defstruct (cad-program (:constructor %make-cad-program) (:copier nil))
  (kind       nil)   ; :acad :accoreconsole :bricscad :clautolisp
  (version    nil)   ; "2026" / "V26" / an alfe version / NIL
  (locale     nil)   ; "fr_FR" (BricsCAD/Windows) or NIL
  (path       nil)   ; executable namestring, or "(embedded)" for clautolisp
  (denotation nil))  ; canonical selector, e.g. "acad-2026"

;; -- version / locale extraction from an install path -----------------

(defun %find-autocad-year (path)
  "The first bare 20NN run in PATH (a namestring), or NIL. Bare = not a
digit on either side, so \"AutoCAD 2026\" yields \"2026\"."
  (loop for i from 0 to (max -1 (- (length path) 4))
        when (and (char= (char path i) #\2) (char= (char path (1+ i)) #\0)
                  (digit-char-p (char path (+ i 2))) (digit-char-p (char path (+ i 3)))
                  (or (zerop i) (not (digit-char-p (char path (1- i)))))
                  (or (>= (+ i 4) (length path)) (not (digit-char-p (char path (+ i 4))))))
          return (subseq path i (+ i 4))))

(defun autocad-release-in-path (path)
  "The AutoCAD product year named by PATH (\"2022\"), or NIL. The
install directory is where the release is written down, and the COM
ProgID resolution reads it from there
(alfe-autocad-cad-selection-ignores-com-progid)."
  (when path
    (%find-autocad-year (namestring path))))

(defun %find-bricscad-version (path)
  "The BricsCAD version token in PATH — \"V\" then digits (e.g. \"V26\"),
upper-cased; \"V26x64\" keeps only \"V26\". NIL when absent."
  (let ((u (string-upcase path)))
    (loop for i from 0 below (length u)
          when (and (char= (char u i) #\V)
                    (< (1+ i) (length u))
                    (digit-char-p (char u (1+ i)))
                    (or (zerop i) (not (alpha-char-p (char u (1- i))))))
            return (let ((j (1+ i)))
                     (loop while (and (< j (length u)) (digit-char-p (char u j))) do (incf j))
                     (concatenate 'string "V" (subseq u (1+ i) j))))))

(defun %find-locale (path)
  "A POSIX-ish locale token in PATH — ll_CC (two lower, '_', two upper, e.g.
\"fr_FR\") — or NIL."
  (loop for i from 0 to (max -1 (- (length path) 5))
        when (and (lower-case-p (char path i)) (lower-case-p (char path (1+ i)))
                  (char= (char path (+ i 2)) #\_)
                  (upper-case-p (char path (+ i 3))) (upper-case-p (char path (+ i 4)))
                  (or (zerop i) (not (alphanumericp (char path (1- i)))))
                  (or (>= (+ i 5) (length path)) (not (alphanumericp (char path (+ i 5))))))
          return (subseq path i (+ i 5))))

(defun %dwg-trueview-path-p (path)
  "True when PATH lies in a DWG TrueView install. The free, read-only DWG
TrueView viewer also ships accoreconsole.exe, but it is not AutoCAD: it
cannot create or modify entities, and its configuration file lives in
Program Files, so for a normal user it aborts on launch (\"configuration
file may be locked\"). It therefore gets its own denotation
(dwgtrueview-YYYY) so that accoreconsole / autocad never select it."
  (search "trueview" (string-downcase (namestring path))))

(defun %cad-denotation (kind version locale &key path)
  "Build the canonical denotation string from KIND + VERSION + LOCALE.
PATH is used to tell DWG TrueView's accoreconsole apart from AutoCAD's."
  (let ((base (ecase kind
                (:acad          (format nil "acad~@[-~A~]" version))
                (:accoreconsole (format nil "~:[accoreconsole~;dwgtrueview~]~@[-~A~]"
                                        (and path (%dwg-trueview-path-p path))
                                        version))
                (:bricscad      (format nil "bricscad~@[-~(~A~)~]" version))
                (:clautolisp    "clautolisp"))))
    (if (and (eq kind :bricscad) locale)
        (format nil "~A-~A" base locale)
        base)))

(defun %cad-program-from-path (kind path)
  "Parse a discovered executable PATH into a CAD-PROGRAM of KIND."
  (let* ((ns (namestring path))
         (version (case kind
                    ((:acad :accoreconsole) (%find-autocad-year ns))
                    (:bricscad              (%find-bricscad-version ns))))
         (locale (when (eq kind :bricscad) (%find-locale ns))))
    (%make-cad-program :kind kind :version version :locale locale :path ns
                       :denotation (%cad-denotation kind version locale :path ns))))

;; -- per-kind, per-OS enumeration -------------------------------------

(defun %glob (pattern) (mapcar #'namestring (directory pattern)))

(defun discover-acad-programs ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Autodesk/AutoCAD */acad.exe"))
             (%glob "/c/Program Files/Autodesk/AutoCAD */acad.exe")))
    ((macos-p)
     (%glob "/Applications/Autodesk/AutoCAD */AutoCAD *.app/Contents/MacOS/AutoCAD"))))

(defun discover-accoreconsole-programs ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Autodesk/*/accoreconsole.exe"))
             (%glob "/c/Program Files/Autodesk/*/accoreconsole.exe")))
    ((macos-p)
     (%glob "/Applications/Autodesk/AutoCAD */AutoCAD *.app/Contents/Helpers/AcCoreConsole.app/Contents/MacOS/AcCoreConsole"))))

(defun discover-bricscad-paths ()
  (cond
    ((windows-p)
     (append (windows-glob-existing-files '("Bricsys/*/bricscad.exe"))
             (%glob "/c/Program Files*/Bricsys/*/bricscad.exe")))
    ((macos-p) (%glob "/Applications/BricsCAD*.app/Contents/MacOS/bricscad"))
    ((linux-p) (%glob "/opt/bricsys/bricscad/V*/bricscad"))))

(defun %dedup-programs (programs)
  "Drop programs whose PATH we have already seen (the Windows globs overlap)."
  (let ((seen (make-hash-table :test #'equal)) (out '()))
    (dolist (p programs (nreverse out))
      (unless (gethash (cad-program-path p) seen)
        (setf (gethash (cad-program-path p) seen) t)
        (push p out)))))

(defun clautolisp-program ()
  "clautolisp is embedded in alfe (not forked), so it is always available."
  (%make-cad-program :kind :clautolisp :path "(embedded in alfe)"
                     :denotation "clautolisp"))

(defun discover-cad-programs ()
  "All CAD programs installed on this host, each as a CAD-PROGRAM with a
canonical denotation. clautolisp is always present (embedded)."
  (%dedup-programs
   (append (mapcar (lambda (p) (%cad-program-from-path :acad p))
                   (discover-acad-programs))
           (mapcar (lambda (p) (%cad-program-from-path :accoreconsole p))
                   (discover-accoreconsole-programs))
           (mapcar (lambda (p) (%cad-program-from-path :bricscad p))
                   (discover-bricscad-paths))
           (list (clautolisp-program)))))

(defun print-cad-programs (&optional (stream *standard-output*))
  "The --list-cad-programs output: DENOTATION then PATH, one per line."
  (let ((programs (discover-cad-programs)))
    (if programs
        (dolist (p programs)
          (format stream "~24A ~A~%" (cad-program-denotation p) (cad-program-path p)))
        (format stream "no CAD programs found (clautolisp is always available)~%"))
    (values)))

;;; --- denotation resolution (backend selection, increment 2) --------

(defun %prefix-p (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix string :end2 (length prefix))))

(defun %denotation-matches-p (query pd)
  "QUERY matches program-denotation PD when it is PD exactly, or a
segment-boundary prefix of it (so \"bricscad\" matches \"bricscad-v26\" and
\"bricscad-v25\" matches \"bricscad-v25-fr_FR\")."
  (or (string= query pd)
      (%prefix-p (concatenate 'string query "-") pd)))

(defun %cad-version-key (program)
  "A sortable integer for 'latest' selection: the AutoCAD year, or the
BricsCAD V-number; 0 when there is no version."
  (let ((v (cad-program-version program)))
    (cond
      ((null v) 0)
      ((and (plusp (length v)) (char-equal (char v 0) #\V))
       (or (parse-integer v :start 1 :junk-allowed t) 0))
      (t (or (parse-integer v :junk-allowed t) 0)))))

;; -- host locale preference (disambiguates same-version installs) -----

(defun %locale-from-lc-value (value)
  "The ll_CC core of a POSIX locale string, or NIL. \"fr_FR.UTF-8\" → \"fr_FR\";
\"C\" / \"POSIX\" / \"en\" → NIL."
  (when (and value (plusp (length value)))
    (let* ((end (or (position #\. value) (position #\@ value) (length value)))
           (base (subseq value 0 end)))
      (when (and (= (length base) 5) (char= (char base 2) #\_)) base))))

(defun %macos-apple-languages ()
  "The macOS AppleLanguages preference as ll_CC codes (\"en-FR\" → \"en_FR\"),
most-preferred first; NIL off macOS or on any failure (best-effort)."
  (when (macos-p)
    (let ((out (ignore-errors
                 (uiop:run-program '("defaults" "read" "-g" "AppleLanguages")
                                   :output :string :ignore-error-status t))))
      (when out
        (let ((result '()) (start 0))
          (loop
            (let ((open (position #\" out :start start)))
              (unless open (return))
              (let ((close (position #\" out :start (1+ open))))
                (unless close (return))
                (let ((tok (substitute #\_ #\- (subseq out (1+ open) close))))
                  (when (and (= (length tok) 5) (char= (char tok 2) #\_))
                    (push tok result)))
                (setf start (1+ close)))))
          (nreverse result))))))

(defun %host-preferred-locales ()
  "Ordered, de-duplicated ll_CC locales the host prefers — macOS
AppleLanguages first, then LC_ALL / LC_CTYPE / LANG — used to pick among
same-version BricsCAD installs of different localisations."
  (let ((acc '()))
    (dolist (loc (append (%macos-apple-languages)
                         (remove nil (mapcar (lambda (v) (%locale-from-lc-value (uiop:getenv v)))
                                             '("LC_ALL" "LC_CTYPE" "LANG")))))
      (pushnew loc acc :test #'string-equal))
    (nreverse acc)))

(defun %locale-rank (program preferred-locales)
  "PROGRAM's position in PREFERRED-LOCALES (earlier = better), or a large
number when it has no locale or none is preferred — so locale-less programs
keep their discovery order."
  (let ((loc (cad-program-locale program)))
    (or (and loc (position loc preferred-locales :test #'string-equal))
        most-positive-fixnum)))

(defun resolve-cad-denotation (denotation programs &key (mode :auto)
                                                        (preferred-locales
                                                         (%host-preferred-locales)))
  "Resolve DENOTATION (a string) against PROGRAMS to a single CAD-PROGRAM, or
NIL when nothing matches. Exact and segment-prefix matches are accepted; among
matches the LATEST version wins, and ties are broken by PREFERRED-LOCALES (the
host's locale preference) so several localised BricsCAD installs of the same
version pick the right one. The virtual =autocad[-VER]= maps to =acad= or
=accoreconsole= per MODE (=:batch= → accoreconsole, else acad), so
=--cad autocad-2022 --mode batch= selects accoreconsole-2022."
  (let* ((q0 (string-downcase (string-trim '(#\Space #\Tab) denotation)))
         (q (if (or (string= q0 "autocad") (%prefix-p "autocad-" q0))
                (concatenate 'string
                             (if (eq mode :batch) "accoreconsole" "acad")
                             (subseq q0 (length "autocad")))
                q0))
         (matches (remove-if-not
                   (lambda (p)
                     (%denotation-matches-p q (string-downcase (cad-program-denotation p))))
                   programs)))
    (when matches
      (let* ((top-version (reduce #'max matches :key #'%cad-version-key :initial-value -1))
             (top (remove-if-not (lambda (p) (= (%cad-version-key p) top-version)) matches)))
        (first (stable-sort (copy-list top) #'<
                            :key (lambda (p) (%locale-rank p preferred-locales))))))))

;;; --- -Efile forwarded to the CAD's own OPEN ------------------------
;;;
;;; encoding-situations-cli-options section 6 point 5. What the CADs' OPEN
;;; does with an encoding was MEASURED (probes/sources/probe-open-encoding.lsp,
;;; writing "A" e-acute "B"):
;;;
;;;   AutoCAD 2022 (LISPSYS 0)  write cp1252; ANY third argument is "too many
;;;                             arguments"; ",ccs=" accepted and ignored.
;;;                             Read decodes cp1252.
;;;   AutoCAD 2022 (LISPSYS 1/2) write cp1252 by default; (open f "w" "utf8")
;;;                             writes UTF-8 without a BOM, "utf8-bom" with
;;;                             one. Read decodes UTF-8, falling back to
;;;                             cp1252 (E1, job 16980926802). An append
;;;                             (open f "a" "utf8") adds UTF-8, and "utf8-bom"
;;;                             on a file that has its BOM adds no second one
;;;                             (sizes 4 -> 6 and 7 -> 9, job 16998925786).
;;;   BricsCAD V25 Windows      write cp1252; third argument accepted, no
;;;                             effect; "w,ccs=UTF-8" writes UTF-8 WITH a BOM,
;;;                             "w,ccs=UTF-16LE" UTF-16LE with a BOM. Read
;;;                             never decodes (raw octets, BOM skipped). An
;;;                             append "a,ccs=" adds no second BOM (UTF-8
;;;                             7 -> 9, UTF-16LE 8 -> 10), while a plain "a"
;;;                             on such a file appends cp1252 (7 -> 8): so
;;;                             ",ccs=" is forwarded on "a" too (job
;;;                             17027935338).
;;;   BricsCAD V26 macOS        writes UTF-8 without a BOM whatever the mode;
;;;                             read returns raw octets.
;;;
;;; So alfe can honour the WRITE direction in two cases: BricsCAD on Windows,
;;; UTF-8 or UTF-16LE, by appending ",ccs=" to the user's "w"/"a" mode; and
;;; AutoCAD, UTF-8, by passing "utf8" as OPEN's third argument to a plain "w"
;;; or "a" -- in the CAD, only when LISPSYS is 1 or 2 (it is read at start-up,
;;; alfe cannot know it beforehand). Both are done by alfe-open* in the
;;; bootstrap, on every action: in code loaded with alfe-load, and in every
;;; protocol request -- the -l file, -x, --main, the REPL -- whose OPEN calls
;;; the emitted autolisp-eval-request-source rewrites in the source text
;;; (alfe-efile-write-not-applied-to-l-file).
;;; Everything else is warned about, never silently dropped -- except a
;;; request for what the CAD does anyway.

(defun %squashed-encoding-name (name)
  "NAME (an encoding spelling) canonicalised through the CLI's alias table,
upcased, with every - and _ removed: utf-8 / UTF8 / utf_8 -> \"UTF8\",
cp1252 / windows-1252 -> \"WINDOWS1252\". A name the table rejects is squashed
as typed."
  (let ((canonical (or (ignore-errors
                        (clautolisp.autolisp-cli:canonical-encoding-name name))
                       name)))
    (remove-if (lambda (ch) (member ch '(#\- #\_)))
               (string-upcase canonical))))

(defun %file-encoding-kind (name)
  "Classify an encoding NAME as :UTF-8, :UTF-16LE, :CP1252, or :OTHER."
  (let ((squashed (%squashed-encoding-name name)))
    (cond ((string= squashed "UTF8") :utf-8)
          ((string= squashed "UTF16LE") :utf-16le)
          ((member squashed '("WINDOWS1252" "CP1252") :test #'string=) :cp1252)
          (t :other))))

(defun cad-file-encoding-plan (backend-name platform write-encoding read-encoding)
  "How the -Efile-write / -Efile-read encodings reach a CAD's own OPEN.
BACKEND-NAME is :BRICSCAD or :AUTOCAD, PLATFORM :WINDOWS / :MACOS (the CAD runs
on alfe's host), WRITE-ENCODING / READ-ENCODING the resolved situation values
(strings, or NIL when none was given).

Returns (values CCS WARNINGS ARG). CCS is the string alfe-open* appends as
\",ccs=CCS\" to a plain \"w\"/\"a\" OPEN mode -- \"UTF-8\" or \"UTF-16LE\",
only for BricsCAD on Windows -- or NIL. ARG is the third argument alfe-open*
passes to a plain \"w\" / \"a\" OPEN -- \"utf8\", only for AutoCAD, and applied
in the CAD only at LISPSYS 1 / 2 -- or NIL. WARNINGS is the list of texts to log: one
per request the CAD cannot honour, with the measured reason. A request for
what the CAD does anyway (cp1252 on Windows, UTF-8 on BricsCAD macOS, a cp1252
read on AutoCAD) is no warning."
  (let ((prefix (format nil "backend ~A: " (symbol-name backend-name)))
        (ccs nil)
        (arg nil)
        (warnings '()))
    (when write-encoding
      (let ((kind (%file-encoding-kind write-encoding)))
        (flet ((refuse (reason)
                 (push (format nil "~A-Efile-write ~A is not forwarded to the CAD's ~
OPEN: ~A." prefix write-encoding reason)
                       warnings)))
          (case backend-name
            (:bricscad
             (case platform
               (:windows
                (case kind
                  (:utf-8 (setf ccs "UTF-8"))
                  (:utf-16le (setf ccs "UTF-16LE"))
                  (:cp1252)
                  (t (refuse "BricsCAD on Windows honours only ,ccs=UTF-8 and ~
,ccs=UTF-16LE (measured, V25); files are written in cp1252"))))
               (:macos
                (unless (eq kind :utf-8)
                  (refuse "BricsCAD on macOS writes UTF-8 whatever the mode (measured, V26)")))
               (t (refuse (format nil "OPEN's encoding is unmeasured on ~(~A~)" platform)))))
            (:autocad
             (case kind
               ;; forwarded as "utf8"; the CAD side checks LISPSYS and warns
               ;; there when it is 0 (alfe-open* in the bootstrap)
               (:utf-8 (setf arg "utf8"))
               (:cp1252)
               (t (refuse "AutoCAD's OPEN takes only \"utf8\" / \"utf8-bom\" (at LISPSYS ~
1/2; none at 0, measured, AutoCAD 2022); files are written in cp1252"))))
            (t (refuse "this backend has no OPEN encoding forwarding"))))))
    (when (and read-encoding
               (not (and (eq backend-name :autocad)
                         (eq (%file-encoding-kind read-encoding) :cp1252))))
      (push (format nil "~A-Efile-read ~A is not forwarded: the CAD's OPEN reads ~
in its own default whatever it is asked (measured: AutoCAD 2022 reads cp1252 at ~
LISPSYS 0, UTF-8 falling back to cp1252 at LISPSYS 1/2; BricsCAD returns octets)."
                    prefix read-encoding)
            warnings))
    (values ccs (nreverse warnings) arg)))

(defvar *cad-file-encoding-warnings-given* '()
  "The CAD-FILE-ENCODING-PLAN warning texts already logged this run.")

(defun cad-open-write-ccs (backend-name cli-options &key (platform (host-os)))
  "Run CAD-FILE-ENCODING-PLAN on CLI-OPTIONS' -Efile-write / -Efile-read
(bare -E included, as the transmitted *AUTOLISP-FILE-*-ENCODING* are), log each
warning once per run, and return (values CCS ARG): the ccs string for
*ALFE-OPEN-WRITE-CCS* and the third argument for *ALFE-OPEN-WRITE-ARG* (each
or NIL)."
  (if (null cli-options)
      (values nil nil)
      (multiple-value-bind (ccs warnings arg)
          (cad-file-encoding-plan
           backend-name platform
           (clautolisp.autolisp-cli:cli-situation-encoding cli-options "file" "write")
           (clautolisp.autolisp-cli:cli-situation-encoding cli-options "file" "read"))
        (dolist (text warnings)
          (unless (member text *cad-file-encoding-warnings-given* :test #'string=)
            (push text *cad-file-encoding-warnings-given*)
            (log-warn "~A" text)))
        (when ccs
          (log-debug "backend ~A: OPEN \"w\"/\"a\" get ,ccs=~A" backend-name ccs))
        (when arg
          (log-debug "backend ~A: OPEN \"w\"/\"a\" get the third argument ~S at LISPSYS 1/2"
                     backend-name arg))
        (values ccs arg))))

;;; --- the CAD's own command-history log (--cad-log, -Elog) ------------
;;;
;;; encoding-situations-cli-options, the `log' situation. In the log and full
;;; bootstrap phases the CAD-side bootstrap points LOGFILEPATH at the workdir's
;;; logs/ directory and sets LOGFILEMODE to 1 (autolisp-log-setup), so the CAD
;;; writes its command-history log there, next to alfe's own debug.log; it is
;;; closed when the engine quits. --cad-log FILE has alfe read it once the
;;; engine is down and copy it, decoded, to FILE.
;;;
;;; How it is decoded, MEASURED:
;;;   AutoCAD 2022              windows-1252 (probe-logfile, MR !428: a PRINCed
;;;                             e-acute reads back 233);
;;;   BricsCAD V25 Windows      windows-1252, no BOM (2026-10-08, job
;;;                             16998925784: the raw log starts 0D 0A 2D, and
;;;                             "Depart" with e-acute is 44 E9 70 61 72 74);
;;;   BricsCAD V26 macOS        writes no log in batch mode (job 16998925783).
;;; So the default is: a BOM names the encoding (UTF-8, UTF-16LE); without one,
;;; windows-1252 on Windows -- both Windows CADs -- and the auto-detect cascade
;;; elsewhere (nothing measured there). An explicit -Elog
;;; overrides it; the bare -E does not reach the log, which the CAD writes in
;;; its own encoding whatever alfe is told.

(defun cad-log-files (workdir)
  "The CAD log files in WORKDIR's logs/ directory, oldest first (by write date,
then name), excluding alfe's own debug.log. NIL when there is none."
  (let* ((dir (merge-pathnames (make-pathname :directory '(:relative "logs"))
                               (uiop:ensure-directory-pathname workdir)))
         (files (remove-if (lambda (p)
                             (string-equal (file-namestring p) "debug.log"))
                           (and (probe-file dir) (uiop:directory-files dir)))))
    (stable-sort (sort (copy-list files) #'string< :key #'file-namestring)
                 #'< :key (lambda (p) (or (ignore-errors (file-write-date p)) 0)))))

(defun %strip-line-terminator-suffix (name)
  "NAME without a trailing line-ending variant (-dos, -unix, -mac, -crlf, -lf,
-cr): the log is decoded first and its line ends normalised afterwards."
  (let ((up (string-upcase name)))
    (dolist (suffix '("-CRLF" "-DOS" "-UNIX" "-MAC" "-LF" "-CR") name)
      (let ((n (length suffix)))
        (when (and (> (length up) n)
                   (string= suffix up :start2 (- (length up) n)))
          (return (subseq name 0 (- (length name) n))))))))

(defun cad-log-decode-encoding (bytes &key explicit (platform (host-os)))
  "The decoder keyword (as ALFE.PROTOCOL.FILE:DECODE-CONSOLE-OCTETS takes it) for
a CAD log whose content is BYTES: the EXPLICIT -Elog encoding when one was given
(a line-ending suffix ignored); else a BOM's (:UTF-8 / :UTF-16LE); else
:CP1252 on Windows and :AUTO elsewhere. A second value, when EXPLICIT names an
encoding the log decoder does not have, is the warning text (the log is then
decoded with :AUTO)."
  (flet ((starts-with (&rest octets)
           (and (>= (length bytes) (length octets))
                (every #'= octets (subseq bytes 0 (length octets))))))
    (cond
      (explicit
       (let ((kw (alfe.protocol.file::%canonical-console-encoding
                  (%strip-line-terminator-suffix explicit))))
         (if (and (eq kw :auto)
                  (not (string-equal (%strip-line-terminator-suffix explicit) "auto")))
             (values :auto
                     (format nil "-Elog ~A: the CAD log is decoded only as UTF-8, ~
UTF-16LE, ISO-8859-1, WINDOWS-1252 or US-ASCII; auto-detected instead." explicit))
             kw)))
      ((starts-with #xEF #xBB #xBF) :utf-8)
      ((starts-with #xFF #xFE) :utf-16le)
      ((eq platform :windows) :cp1252)
      (t :auto))))

(defun %lf-line-ends (text)
  "TEXT with every CR LF (and a lone CR) turned into LF."
  (with-output-to-string (out)
    (let ((n (length text)))
      (loop for i from 0 below n
            for ch = (char text i)
            do (cond ((char= ch #\Return)
                      (write-char #\Newline out)
                      (when (and (< (1+ i) n) (char= (char text (1+ i)) #\Newline))
                        (incf i)))
                     (t (write-char ch out)))))))

(defun decode-cad-log-octets (bytes &key explicit (platform (host-os)))
  "Decode a CAD log's BYTES (see CAD-LOG-DECODE-ENCODING) and normalise its line
ends to LF. A leading UTF-8 or UTF-16LE BOM is not part of the text. Returns
(values TEXT WARNING)."
  (multiple-value-bind (encoding warning)
      (cad-log-decode-encoding bytes :explicit explicit :platform platform)
    (let ((text (alfe.protocol.file:decode-console-octets bytes encoding)))
      (values (%lf-line-ends (string-left-trim (string (code-char #xFEFF)) text))
              warning))))

(defun %file-octet-vector (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let* ((buf (make-array (file-length in) :element-type '(unsigned-byte 8)))
           (got (read-sequence buf in)))
      (if (= got (length buf)) buf (subseq buf 0 got)))))

(defun collect-cad-log (backend-name workdir cli-options &key (platform (host-os)))
  "Read the CAD log files of WORKDIR (CAD-LOG-FILES) and decode each with the
explicit -Elog of CLI-OPTIONS, else the measured default
(CAD-LOG-DECODE-ENCODING). Returns (values ENTRIES STATUS): ENTRIES a list of
(NAME . TEXT); STATUS :COLLECTED, or :NONE when the CAD wrote no log. A file
that cannot be read is warned about and skipped."
  (let ((explicit (and cli-options
                       (clautolisp.autolisp-cli:cli-situation-encoding-explicit
                        cli-options "log")))
        (entries '())
        (warned nil))
    (dolist (path (cad-log-files workdir))
      (handler-case
          (multiple-value-bind (text warning)
              (decode-cad-log-octets (%file-octet-vector path)
                                     :explicit explicit :platform platform)
            (when (and warning (not warned))
              (setf warned t)
              (log-warn "backend ~A: ~A" backend-name warning))
            (push (cons (file-namestring path) text) entries))
        (error (e)
          (log-warn "backend ~A: the CAD log ~A cannot be read: ~A"
                    backend-name (file-namestring path) e))))
    (values (nreverse entries) (if entries :collected :none))))
