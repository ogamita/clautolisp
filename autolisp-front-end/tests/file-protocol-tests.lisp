(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; FiveAM tests for alfe.protocol.file (Phase 2).
;;;;
;;;; The acceptance criteria from
;;;; ../../issues/open/alfe-file-protocol.issue:
;;;;
;;;;   - session bring-up produces the protocol/ layout the spec
;;;;     documents (filenames, initial contents).
;;;;   - a mock CAD test scripts the full lifecycle
;;;;     (BOOTING → READY 0 → RUNNING 1 → DONE 1 OK → STOPPING →
;;;;     STOPPED) and asserts every transition.
;;;;   - atomic-write tests do not flake under load.
;;;;   - line-to-form reader produces a balanced form for the spec's
;;;;     "Cas d'usage visés".
;;;;
;;;; Threading: we use bordeaux-threads to drive the mock CAD in a
;;;; background thread, and to scale the atomic-write contention test
;;;; up to N concurrent writers. bordeaux-threads is in the test
;;;; system's :depends-on so the package is loaded before these tests
;;;; are read.

;;; --- helpers --------------------------------------------------------

(defun make-test-workdir (prefix)
  "Construct a fresh per-test workdir under the system temp dir.
Tests clean up after themselves via DELETE-WORKDIR; we deliberately
keep the workdir on test failure to ease debugging."
  (let* ((stem (format nil "alfe-protocol-~A-~D-~D/"
                       prefix (alfe.workdir::current-pid) (random 1000000)))
         (path (merge-pathnames stem (uiop:temporary-directory))))
    (ensure-directories-exist path)
    path))

(defun delete-workdir (workdir)
  (when (uiop:directory-exists-p workdir)
    (uiop:delete-directory-tree workdir :validate t
                                        :if-does-not-exist :ignore)))

;;; --- session bring-up ----------------------------------------------

(test protocol-init-session-creates-layout
  "INIT-SESSION lays down WORKDIR/protocol/ with the spec's slot
inventory; stdout.txt and stderr.txt are pre-created (empty), the
other channels are absent until a publication happens, and
status.txt opens with `BOOTING`."
  (let ((workdir (make-test-workdir "init")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          (is (uiop:directory-exists-p
               (alfe.protocol.file:protocol-session-protocol-dir session)))
          (is (probe-file
               (alfe.protocol.file:protocol-session-status-path session)))
          (is (probe-file
               (alfe.protocol.file:protocol-session-stdout-path session)))
          (is (probe-file
               (alfe.protocol.file:protocol-session-stderr-path session)))
          ;; stdin and control are absent until first publication.
          (is (not (probe-file
                    (alfe.protocol.file:protocol-session-stdin-path session))))
          (is (not (probe-file
                    (alfe.protocol.file:protocol-session-control-path session))))
          (is (string= "BOOTING"
                       (alfe.protocol.file:read-current-status session))))
      (delete-workdir workdir))))

;;; --- vendored runtime LSP integrity ---------------------------------

(defun %count-chars (path char)
  (let ((count 0))
    (with-open-file (in path :element-type 'character
                             :external-format :utf-8)
      (loop for ch = (read-char in nil :eof)
            until (eq ch :eof)
            when (eql ch char) do (incf count)))
    count))

(test vendored-runtime-lsp-paren-balance
  "The vendored autolisp-remote-io.lsp + autolisp-bootstrap.lsp are
loaded verbatim into the CAD; an unmatched paren in either file
makes BricsCAD's LOAD bail out with `extra right parenthesis on
input' or `unexpected end of input', cascading into
`server-loop CAUGHT error' at the protocol level. A previous edit
to the runtime's success branch (DONE N OK fix) shipped with an
extra trailing `)' and broke the production run; this test pins the
invariant so it doesn't happen again."
  (dolist (basename '("autolisp-remote-io.lsp" "autolisp-bootstrap.lsp"))
    (let* ((path (asdf:system-relative-pathname
                  "autolisp-front-end/backend-cad-common"
                  (concatenate 'string "source/runtime/" basename)))
           (opens (%count-chars path #\())
           (closes (%count-chars path #\))))
      (is (= opens closes)
          "vendored ~A: ~D opens vs ~D closes (delta ~D)"
          basename opens closes (- opens closes)))))

;;; --- atomic write --------------------------------------------------

(test protocol-write-atomic-file-roundtrips
  "A bare WRITE-ATOMIC-FILE call leaves the target file with the
written content plus a trailing newline (default policy)."
  (let* ((workdir (make-test-workdir "atomic"))
         (target (merge-pathnames "value.txt" workdir)))
    (unwind-protect
        (progn
          (alfe.protocol.file:write-atomic-file target "hello")
          (is (string= (format nil "hello~%")
                       (alfe.protocol.file:read-file-as-string target))))
      (delete-workdir workdir))))

(test protocol-write-atomic-file-overwrites
  "Repeated writes through WRITE-ATOMIC-FILE leave only the latest
content visible; the temp file is renamed atomically each time."
  (let* ((workdir (make-test-workdir "atomic-overwrite"))
         (target (merge-pathnames "value.txt" workdir)))
    (unwind-protect
        (progn
          (alfe.protocol.file:write-atomic-file target "first")
          (alfe.protocol.file:write-atomic-file target "second")
          (alfe.protocol.file:write-atomic-file target "third")
          (is (string= (format nil "third~%")
                       (alfe.protocol.file:read-file-as-string target))))
      (delete-workdir workdir))))

(test protocol-write-atomic-file-contention
  "N=16 concurrent writers publishing distinct integers all complete
without errors; the final file content is one of the published
values (atomic rename = last-write-wins, never a torn read). The
test asserts that EVERY observation during the race read a fully-
formed value, never a partial one."
  (let* ((workdir (make-test-workdir "contention"))
         (target (merge-pathnames "value.txt" workdir))
         (n-writers 16)
         (writes-per-writer 50)
         (allowed-values (loop for i below (* n-writers writes-per-writer)
                               collect (format nil "value-~D" i)))
         (observed-corruptions nil)
         (thread-errors nil)
         (mutex (bordeaux-threads:make-lock)))
    (flet ((record-thread-error (label condition)
             ;; Mutex-guarded so 16 writers' caught errors don't
             ;; clobber each other on push.
             (bordeaux-threads:with-lock-held (mutex)
               (push (list :label label :error (format nil "~A" condition))
                     thread-errors))))
      (unwind-protect
        (let (threads)
          ;; Pre-fill so the reader doesn't see a missing file.
          (alfe.protocol.file:write-atomic-file target "seed")
          ;; Reader thread: continuously read the target and verify
          ;; it's one of the allowed values (or "seed", or "value-..."
          ;; with trailing newline). Any other shape is corruption.
          ;;
          ;; The HANDLER-CASE wrapping the body is the
          ;; non-interactive-CCL guard: on SBCL an uncaught thread
          ;; condition is just dropped, but CCL prompts on the
          ;; nonexistent terminal ('requires access to Shared
          ;; Terminal Input … Type (:y N)' — Job 14519641143 hung
          ;; on this for ~15 minutes). Catch and record instead.
          (let ((reader
                  (bordeaux-threads:make-thread
                   (lambda ()
                     (handler-case
                         (loop for ch from 0 below 1000
                               for content = (alfe.protocol.file:read-file-as-string target)
                               do (let ((trimmed (string-right-trim
                                                  '(#\Newline #\Space) content)))
                                    (unless (or (string= trimmed "seed")
                                                (and (> (length trimmed) 6)
                                                     (string= "value-" trimmed
                                                              :end2 6)))
                                      (bordeaux-threads:with-lock-held (mutex)
                                        (push (list :corruption-at ch :content trimmed)
                                              observed-corruptions)))))
                       (error (c) (record-thread-error "reader" c))))
                   :name "atomic-write-reader")))
            (dotimes (writer-id n-writers)
              ;; Bind WRITER-ID afresh per iteration. DOTIMES under
              ;; SBCL reuses the same variable cell across iterations;
              ;; without this LET, every spawned thread closes over the
              ;; *final* value of writer-id (n-writers), so the test
              ;; ends up publishing values outside the expected range.
              (let ((id writer-id))
                (push
                 (bordeaux-threads:make-thread
                  (lambda ()
                    (handler-case
                        (dotimes (n writes-per-writer)
                          (alfe.protocol.file:write-atomic-file
                           target
                           (format nil "value-~D"
                                   (+ (* id writes-per-writer) n))))
                      (error (c) (record-thread-error
                                  (format nil "writer-~D" id) c))))
                  :name (format nil "atomic-writer-~D" id))
                 threads)))
            (dolist (thread threads)
              (bordeaux-threads:join-thread thread))
            ;; Stop the reader (it self-stops after 1000 reads, but
            ;; just in case).
            (handler-case (bordeaux-threads:join-thread reader)
              (error () nil))
            (is (null thread-errors)
                "Threads raised uncaught errors: ~S" thread-errors)
            (is (null observed-corruptions)
                "Saw torn writes: ~S" observed-corruptions)
            ;; Final state is one of the published values or the seed.
            (let* ((final (string-right-trim
                           '(#\Newline #\Space)
                           (alfe.protocol.file:read-file-as-string target))))
              (is (or (string= final "seed")
                      (find final allowed-values :test #'string=))
                  "Final content ~S is not one of the published values" final))))
      (delete-workdir workdir)))))

;;; --- status polling ------------------------------------------------

(test protocol-wait-for-status-matches
  "WAIT-FOR-STATUS returns truthy when status.txt's current line is
exactly the expected string, before the timeout fires."
  (let ((workdir (make-test-workdir "wait-exact")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          ;; INIT-SESSION publishes BOOTING; wait should return T
          ;; immediately.
          (multiple-value-bind (ok elapsed last)
              (alfe.protocol.file:wait-for-status session "BOOTING"
                                                   :timeout 1)
            (declare (ignore elapsed))
            (is (not (null ok)))
            (is (string= "BOOTING" last))))
      (delete-workdir workdir))))

(test protocol-wait-for-status-times-out
  "When the expected status never arrives, WAIT-FOR-STATUS returns
NIL and surfaces the last-seen status for diagnostic purposes —
without throwing a Lisp condition."
  (let ((workdir (make-test-workdir "wait-timeout")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          (multiple-value-bind (ok elapsed last)
              (alfe.protocol.file:wait-for-status session "READY 0"
                                                   :timeout 0.3)
            (declare (ignore elapsed))
            (is (null ok))
            (is (string= "BOOTING" last))))
      (delete-workdir workdir))))

(test protocol-wait-for-status-prefix-matches-parameterised
  "WAIT-FOR-STATUS-PREFIX matches `READY 0` / `RUNNING 7` / `DONE 7
OK` etc. by leading prefix, since the counter suffix is set by the
runtime and not known a priori."
  (let ((workdir (make-test-workdir "wait-prefix")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          (alfe.protocol.file:write-atomic-file
           (alfe.protocol.file:protocol-session-status-path session)
           "READY 42")
          (multiple-value-bind (ok elapsed last)
              (alfe.protocol.file:wait-for-status-prefix
               session "READY" :timeout 1)
            (declare (ignore elapsed))
            (is (not (null ok)))
            (is (string= "READY 42" last))))
      (delete-workdir workdir))))

;;; --- output draining -----------------------------------------------

(test protocol-drain-stdout-incremental
  "DRAIN-STDOUT returns only the *new* text since the previous call,
advancing the session's offset; consecutive drains compose to the
full file contents."
  (let ((workdir (make-test-workdir "drain")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-stdout-path session)))
          ;; First write: 3 lines.
          (with-open-file (out path :direction :output :if-exists :append
                                    :external-format :utf-8)
            (format out "alpha~%beta~%gamma~%"))
          (let ((batch1 (alfe.protocol.file:drain-stdout session)))
            (is (string= (format nil "alpha~%beta~%gamma~%") batch1)))
          ;; Second drain after no writes: empty.
          (is (string= "" (alfe.protocol.file:drain-stdout session)))
          ;; Append a 4th line; drain returns only that one.
          (with-open-file (out path :direction :output :if-exists :append
                                    :external-format :utf-8)
            (format out "delta~%"))
          (let ((batch2 (alfe.protocol.file:drain-stdout session)))
            (is (string= (format nil "delta~%") batch2))))
      (delete-workdir workdir))))

(test protocol-drain-debug-log-incremental
  "DRAIN-DEBUG-LOG behaves like DRAIN-STDOUT but reads from the CAD-
side debug log (workdir/logs/debug.log). Returns \"\" when the file is
absent (the runtime hasn't published anything yet), the new bytes once
the file appears, and \"\" again on a no-change drain. The session's
DEBUG-LOG-PATH is set by INIT-SESSION even though the file isn't
created eagerly."
  (let ((workdir (make-test-workdir "drain-debug")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-debug-log-path session)))
          (is (not (null path)))
          ;; File does not exist yet — drain is a cheap no-op.
          (is (string= "" (alfe.protocol.file:drain-debug-log session)))
          ;; Create the file with two lines.
          (ensure-directories-exist path)
          (with-open-file (out path :direction :output :if-exists :supersede
                                    :if-does-not-exist :create
                                    :external-format :utf-8)
            (format out "[CAD] hello~%[CAD] entering loop~%"))
          (let ((batch (alfe.protocol.file:drain-debug-log session)))
            (is (search "[CAD] hello" batch))
            (is (search "[CAD] entering loop" batch)))
          ;; No new bytes: empty drain.
          (is (string= "" (alfe.protocol.file:drain-debug-log session)))
          ;; Append a third line; drain returns only that.
          (with-open-file (out path :direction :output :if-exists :append
                                    :external-format :utf-8)
            (format out "[CAD] crash~%"))
          (let ((batch (alfe.protocol.file:drain-debug-log session)))
            (is (search "[CAD] crash" batch))
            (is (not (search "[CAD] hello" batch)))))
      (delete-workdir workdir))))

(test protocol-stream-debug-log-to-logger-counts-lines
  "STREAM-DEBUG-LOG-TO-LOGGER drains and returns the number of non-
empty lines surfaced through the alfe logger. The actual log emission
is exercised in practice by the polling helpers."
  (let ((workdir (make-test-workdir "stream-debug")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-debug-log-path session)))
          ;; Nothing on disk: 0 lines streamed.
          (is (zerop (alfe.protocol.file:stream-debug-log-to-logger session)))
          ;; Write three CAD lines.
          (ensure-directories-exist path)
          (with-open-file (out path :direction :output :if-exists :supersede
                                    :if-does-not-exist :create
                                    :external-format :utf-8)
            (format out "[CAD] one~%[CAD] two~%[CAD] three~%"))
          (is (= 3 (alfe.protocol.file:stream-debug-log-to-logger session)))
          ;; Second call streams 0 (offset advanced past the previous tail).
          (is (zerop (alfe.protocol.file:stream-debug-log-to-logger session))))
      (delete-workdir workdir))))

(test protocol-drain-stdout-survives-utf8
  "A drain that lands across multi-byte boundaries does not split a
character (the runtime appends line-at-a-time, so this is structurally
safe; we still test the path explicitly)."
  (let ((workdir (make-test-workdir "drain-utf8")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-stdout-path session)))
          (with-open-file (out path :direction :output :if-exists :append
                                    :external-format :utf-8)
            (format out "caf~A~%" (code-char 233))) ; "café"
          (let ((batch (alfe.protocol.file:drain-stdout session)))
            (is (search (string (code-char 233)) batch))))
      (delete-workdir workdir))))

;;; --- line-to-form reader -------------------------------------------

(test protocol-read-balanced-form-single-atom
  "A single atom (the spec's `42` example) returns balanced on the
first line."
  (let* ((source-lines '("42"))
         (idx 0))
    (multiple-value-bind (text eof)
        (alfe.protocol.file:read-balanced-form-from-lines
         (lambda ()
           (and (< idx (length source-lines))
                (prog1 (nth idx source-lines) (incf idx)))))
      (is (null eof))
      (is (string= "42" text)))))

(test protocol-read-balanced-form-multi-line
  "A multi-line list — open paren on line 1, close paren on line 3 —
accumulates until balanced. Mirrors the spec's `Cas d'usage:
interactive read` example."
  (let* ((source-lines (list "(+" "  1" "  2)"))
         (idx 0))
    (multiple-value-bind (text eof)
        (alfe.protocol.file:read-balanced-form-from-lines
         (lambda ()
           (and (< idx (length source-lines))
                (prog1 (nth idx source-lines) (incf idx)))))
      (is (null eof))
      (is (search "(+" text))
      (is (search "2)" text)))))

(test protocol-read-balanced-form-on-eof
  "An empty line-source returns (values nil t) — the EOF marker the
caller uses to break its outer loop."
  (multiple-value-bind (text eof)
      (alfe.protocol.file:read-balanced-form-from-lines
       (lambda () nil))
    (is (null text))
    (is (not (null eof)))))

;;; --- control commands ----------------------------------------------

(test protocol-send-control-validates-command
  "SEND-CONTROL refuses anything outside :ping / :shutdown /
:interrupt with a structured BACKEND-PROTOCOL-ERROR."
  (let ((workdir (make-test-workdir "control-validate")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          (signals alfe.error:backend-protocol-error
            (alfe.protocol.file:send-control session :no-such-command)))
      (delete-workdir workdir))))

(test protocol-send-control-publishes
  "SEND-CONTROL atomically publishes the documented uppercase text
for the recognised keywords."
  (let ((workdir (make-test-workdir "control-publish")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-control-path session)))
          (alfe.protocol.file:send-control session :ping)
          (is (string= (format nil "PING~%")
                       (alfe.protocol.file:read-file-as-string path)))
          ;; Simulate the runtime consuming the file before the next send.
          (delete-file path)
          (alfe.protocol.file:send-control session :shutdown)
          (is (string= (format nil "SHUTDOWN~%")
                       (alfe.protocol.file:read-file-as-string path))))
      (delete-workdir workdir))))

(test protocol-send-stdin-waits-for-prior-consumption
  "When stdin.txt is still occupied by an earlier publication, the
sender blocks until it's freed (the runtime consumed it). We
simulate the runtime by deleting the file from a background thread
after a short delay; SEND-STDIN should succeed within the timeout."
  (let ((workdir (make-test-workdir "stdin-wait")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-stdin-path session)))
          (alfe.protocol.file:write-atomic-file path "(first)")
          ;; Background "runtime" consumes after a short delay.
          (let ((consumer
                  (bordeaux-threads:make-thread
                   (lambda ()
                     (sleep 0.1)
                     (when (probe-file path) (delete-file path))))))
            (alfe.protocol.file:send-stdin session "(second)" :wait-timeout 2)
            (bordeaux-threads:join-thread consumer))
          (is (string= (format nil "(second)~%")
                       (alfe.protocol.file:read-file-as-string path))))
      (delete-workdir workdir))))

;;; --- run-common.lsp emitter ----------------------------------------

(test protocol-emit-run-common-lsp-contains-globals
  "The emitter writes a syntactically-acceptable AutoLISP file that
sets every documented *AUTOLISP-* and *AUTOLISP_* global, in both
hyphen and underscore spellings, so the upstream runtime (which
expects underscore) and the spec (which documents hyphen) both
work without us forking the runtime."
  (let ((workdir (make-test-workdir "emit-lsp")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:emit-run-common-lsp session)))
          (is (probe-file path))
          (let ((content (alfe.protocol.file:read-file-as-string path)))
            ;; Hyphen variants
            (is (search "*AUTOLISP-PROTOCOL-STATUSFILE*" content))
            (is (search "*AUTOLISP-PROTOCOL-STDINFILE*" content))
            (is (search "*AUTOLISP-PROTOCOL-DIR*" content))
            (is (search "*AUTOLISP-DEBUG*" content))
            ;; The run-common.lsp protocol generation moved from
            ;; *AUTOLISP-VERSION* to *AUTOLISP-RUNCOMMON-VERSION*
            ;; so the CLI-derived *AUTOLISP-VERSION* (alfe build
            ;; version string from transmit-options.issue) can
            ;; occupy its canonical name without colliding.
            (is (search "*AUTOLISP-RUNCOMMON-VERSION*" content))
            ;; Underscore variants (what the actual runtime reads)
            (is (search "*AUTOLISP_PROTOCOL_STATUSFILE*" content))
            (is (search "*AUTOLISP_PROTOCOL_STDINFILE*" content))
            (is (search "*AUTOLISP_PROTOCOL_DIR*" content))
            (is (search "*AUTOLISP_DEBUG*" content))
            (is (search "*AUTOLISP_RUNCOMMON_VERSION*" content))))
      (delete-workdir workdir))))

(test protocol-emit-run-common-lsp-installs-variadic-shadows
  "The emitted run-common.lsp contains the alfe-host-supports-rest-p
probe and the variadic shadow definitions for princ/print/prin1/
prompt that fire when the probe succeeds. This replaces the
walk-rewriting normalize approach with a native-arity shadow that
preserves the user's reader-built cons cells — same fix scope as
1.1.10, but at the source rather than papering over normalize.

The shadows must use `(& args)' (clautolisp's spelling) so they
work on the mock-host and AutoCAD-like hosts; BricsCAD V26
canonicalises both `&' and `&REST' through the same parser path
(per Bricsys support confirmation). Either spelling reaches the
defun-time validator."
  ;; The bridge block (which carries the variadic shadows) is
  ;; emitted only when BOTH the bootstrap and the runtime LSP are
  ;; staged — emit-run-common-lsp gates the bridge inside the
  ;; runtime-staged branch (so a session that intentionally
  ;; doesn't load the protocol runtime, e.g. an ad-hoc script run,
  ;; doesn't get the bridge either). Stage both before checking.
  (let* ((workdir (make-test-workdir "emit-variadic"))
         (fake-boot (merge-pathnames "fake-bootstrap.lsp" workdir))
         (fake-rt   (merge-pathnames "fake-runtime.lsp" workdir)))
    (unwind-protect
        (progn
          (with-open-file (out fake-boot :direction :output
                                         :if-exists :supersede
                                         :if-does-not-exist :create
                                         :external-format :utf-8)
            (format out ";; fake bootstrap~%(setq fake-boot t)~%"))
          (with-open-file (out fake-rt :direction :output
                                       :if-exists :supersede
                                       :if-does-not-exist :create
                                       :external-format :utf-8)
            (format out ";; fake runtime~%(setq fake-rt t)~%"))
          (let* ((session (alfe.protocol.file:init-session
                           workdir
                           :bootstrap-lsp-source fake-boot
                           :runtime-lsp-source fake-rt))
                 (_ (alfe.protocol.file:stage-bootstrap-lsp session))
                 (__ (alfe.protocol.file:stage-runtime-lsp session))
                 (path (alfe.protocol.file:emit-run-common-lsp session)))
            (declare (ignore _ __))
            (is (probe-file path))
            (let ((content (alfe.protocol.file:read-file-as-string path)))
              ;; The host-capability probe.
              (is (search "(defun alfe-host-supports-rest-p" content))
              (is (search "__alfe-amp-rest-probe" content))
              ;; The variadic shadows installed under the YES branch.
              (is (search "(defun princ (& args)" content))
              (is (search "(defun print (& args)" content))
              (is (search "(defun prin1 (& args)" content))
              (is (search "(defun prompt (& args)" content))
              ;; The no-op normalize override that's the whole
              ;; point — with variadic shadows in place, walking
              ;; the form is unnecessary. Identity-fn preserves
              ;; cons-cell identity.
              (is (search "(defun autolisp-normalize-princ-call (form) form)"
                          content))
              ;; The fallback debug log for hosts that lack &rest.
              (is (search "host lacks &rest" content)))))
      (delete-workdir workdir))))

(test protocol-stage-bootstrap-lsp-copies-into-runtime-subdir
  "STAGE-BOOTSTRAP-LSP copies the BOOTSTRAP-LSP-SOURCE file to
workdir/runtime/autolisp-bootstrap.lsp and records the staged path
on the session, mirroring STAGE-RUNTIME-LSP. With no source set the
function is a no-op."
  (let ((workdir (make-test-workdir "stage-bootstrap")))
    (unwind-protect
        (let ((src (merge-pathnames "fake-bootstrap.lsp" workdir)))
          ;; Create a fake source file we can stage.
          (with-open-file (out src :direction :output :if-exists :supersede
                                   :if-does-not-exist :create
                                   :external-format :utf-8)
            (format out ";; fake bootstrap~%(setq fake-bootstrap-loaded t)~%"))
          ;; Without :bootstrap-lsp-source the stage is a no-op.
          (let ((session (alfe.protocol.file:init-session workdir)))
            (is (null (alfe.protocol.file:stage-bootstrap-lsp session)))
            (is (null (alfe.protocol.file:protocol-session-bootstrap-lsp-staged
                       session))))
          ;; With the source set it copies + records.
          (let* ((session (alfe.protocol.file:init-session
                          workdir :bootstrap-lsp-source src))
                 (staged (alfe.protocol.file:stage-bootstrap-lsp session)))
            (is (not (null staged)))
            (is (probe-file staged))
            (is (search "autolisp-bootstrap.lsp" (namestring staged)))
            (is (eq staged
                    (alfe.protocol.file:protocol-session-bootstrap-lsp-staged
                     session)))
            ;; Content should round-trip verbatim.
            (let ((content (alfe.protocol.file:read-file-as-string staged)))
              (is (search "fake-bootstrap-loaded" content)))))
      (delete-workdir workdir))))

(test protocol-emit-run-common-lsp-loads-bootstrap-before-runtime
  "When both autolisp-bootstrap.lsp and autolisp-remote-io.lsp are
staged, the emitted run-common.lsp issues a (load ...) for the
bootstrap *before* the runtime — order matters because the runtime's
server loop calls into helpers defined in the bootstrap."
  (let ((workdir (make-test-workdir "emit-load-order")))
    (unwind-protect
        (let* ((bootstrap-src (merge-pathnames "fake-bootstrap.lsp" workdir))
               (runtime-src   (merge-pathnames "fake-runtime.lsp" workdir)))
          (with-open-file (out bootstrap-src :direction :output
                                             :if-exists :supersede
                                             :if-does-not-exist :create
                                             :external-format :utf-8)
            (write-string ";; fake bootstrap" out))
          (with-open-file (out runtime-src :direction :output
                                           :if-exists :supersede
                                           :if-does-not-exist :create
                                           :external-format :utf-8)
            (write-string ";; fake runtime" out))
          (let* ((session (alfe.protocol.file:init-session
                          workdir
                          :bootstrap-lsp-source bootstrap-src
                          :runtime-lsp-source runtime-src)))
            (alfe.protocol.file:stage-bootstrap-lsp session)
            (alfe.protocol.file:stage-runtime-lsp session)
            (let* ((path (alfe.protocol.file:emit-run-common-lsp session))
                   (content (alfe.protocol.file:read-file-as-string path))
                   ;; Search for the LOAD invocations specifically — the
                   ;; runtime path also appears earlier in the file as
                   ;; the value of the *AUTOLISP-PROTOCOL-RUNTIMEFILE*
                   ;; setq, so a plain filename search would find that
                   ;; first.
                   (bootstrap-load-pos
                    (search "loading bootstrap:" content))
                   (runtime-load-pos
                    (search "loading runtime:" content)))
              (is (integerp bootstrap-load-pos))
              (is (integerp runtime-load-pos))
              ;; Bootstrap must load BEFORE the runtime.
              (is (< bootstrap-load-pos runtime-load-pos))
              ;; And the server-loop call follows both.
              (let ((loop-pos (search "(vl-catch-all-apply 'autolisp-protocol-server-loop"
                                      content)))
                (is (integerp loop-pos))
                (is (< runtime-load-pos loop-pos))))))
      (delete-workdir workdir))))

(test cad-common-discover-bootstrap-lsp-finds-vendored
  "DISCOVER-BOOTSTRAP-LSP resolves the in-tree autolisp-bootstrap.lsp
via ASDF's system registry. When the vendored copy isn't on disk (a
stripped install) the test exits cleanly without an assertion — FiveAM
counts that as a pass."
  (let ((path (alfe.backend.cad-common:discover-bootstrap-lsp)))
    (when path
      (is (not (null (probe-file path))))
      (is (integerp (search "autolisp-bootstrap.lsp" path))))))

;;; --- heartbeat -----------------------------------------------------

(test protocol-read-heartbeat-empty-returns-nil
  "When the runtime has not yet published a heartbeat, READ-HEARTBEAT
returns NIL — *not* an error. The spec calls heartbeat publication
optional."
  (let ((workdir (make-test-workdir "heartbeat-empty")))
    (unwind-protect
        (let ((session (alfe.protocol.file:init-session workdir)))
          (is (null (alfe.protocol.file:read-heartbeat session))))
      (delete-workdir workdir))))

(test protocol-read-heartbeat-last-line
  "READ-HEARTBEAT returns the last non-empty line of heartbeat.txt
when the runtime has published one or more timestamps."
  (let ((workdir (make-test-workdir "heartbeat-line")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (path (alfe.protocol.file:protocol-session-heartbeat-path session)))
          (with-open-file (out path :direction :output :if-exists :supersede
                                    :if-does-not-exist :create
                                    :external-format :utf-8)
            (format out "2026-01-01T00:00:00~%2026-05-23T12:34:56~%"))
          (is (string= "2026-05-23T12:34:56"
                       (alfe.protocol.file:read-heartbeat session))))
      (delete-workdir workdir))))

;;; --- end-to-end mock CAD -------------------------------------------

(defun mock-cad-runtime (session
                         &key (initial-ready-delay 0.05)
                              (running-delay 0.05)
                              (done-delay 0.05))
  "A tiny CAD-side runtime emulator. Runs the documented state
machine — BOOTING (already published by INIT-SESSION) → READY 0 →
RUNNING 1 → DONE 1 OK → READY 1 → STOPPING → STOPPED — pausing the
configured delay between transitions so the alfe side has time to
observe each one.

When stdin.txt arrives between READY 0 and RUNNING 1, the runtime
treats its content as the request body, writes the body verbatim
to stdout.txt (so the test can verify the round-trip), and deletes
stdin.txt (destructive consumption per the spec)."
  (alfe.protocol.file:write-atomic-file
   (alfe.protocol.file:protocol-session-status-path session)
   "READY 0")
  (sleep initial-ready-delay)
  ;; Wait briefly for a request on stdin.txt
  (let ((stdin-path (alfe.protocol.file:protocol-session-stdin-path session))
        (request nil)
        (deadline (+ (get-internal-real-time)
                     (* 2 internal-time-units-per-second))))
    (loop until (probe-file stdin-path)
          when (> (get-internal-real-time) deadline)
            do (return)
          do (sleep 0.02))
    (when (probe-file stdin-path)
      (setf request (alfe.protocol.file:read-file-as-string stdin-path))
      (delete-file stdin-path))
    (alfe.protocol.file:write-atomic-file
     (alfe.protocol.file:protocol-session-status-path session)
     "RUNNING 1")
    (sleep running-delay)
    ;; Echo the request to stdout.
    (when request
      (with-open-file (out (alfe.protocol.file:protocol-session-stdout-path session)
                           :direction :output :if-exists :append
                           :external-format :utf-8)
        (write-string request out)))
    (alfe.protocol.file:write-atomic-file
     (alfe.protocol.file:protocol-session-status-path session)
     "DONE 1 OK")
    (sleep done-delay)
    (alfe.protocol.file:write-atomic-file
     (alfe.protocol.file:protocol-session-status-path session)
     "READY 1")
    ;; Wait for SHUTDOWN.
    (let ((control-path (alfe.protocol.file:protocol-session-control-path session))
          (deadline (+ (get-internal-real-time)
                       (* 2 internal-time-units-per-second))))
      (loop until (let ((text (alfe.protocol.file:read-file-as-string control-path)))
                    (search "SHUTDOWN" text))
            when (> (get-internal-real-time) deadline)
              do (return)
            do (sleep 0.02))
      (when (probe-file control-path) (delete-file control-path)))
    (alfe.protocol.file:write-atomic-file
     (alfe.protocol.file:protocol-session-status-path session)
     "STOPPING")
    ;; Hold STOPPING longer than the polling primitive's initial
    ;; back-off (*poll-initial-ms* = 50 ms) so the alfe-side
    ;; WAIT-FOR-STATUS has a window to observe it. A real CAD
    ;; shutdown takes much longer than this; the inflated delay is
    ;; only there for the test's sake.
    (sleep 0.2)
    (alfe.protocol.file:write-atomic-file
     (alfe.protocol.file:protocol-session-status-path session)
     "STOPPED")))

(test protocol-mock-cad-full-lifecycle
  "End-to-end: the mock CAD runs the documented state machine in a
background thread; alfe waits for each transition with the
documented poll primitives and sends a request + shutdown. Every
transition must be observed within the timeout."
  (let ((workdir (make-test-workdir "mock-cad")))
    (unwind-protect
        (let* ((session (alfe.protocol.file:init-session workdir))
               (cad-thread
                 (bordeaux-threads:make-thread
                  (lambda () (mock-cad-runtime session))
                  :name "mock-cad-runtime")))
          ;; BOOTING is already published; first observable transition
          ;; is READY 0.
          (is (alfe.protocol.file:wait-for-status-prefix
               session "READY" :timeout 2))
          ;; Issue a request.
          (alfe.protocol.file:send-stdin session "(+ 1 2)")
          ;; Wait for the runtime to start, finish, and re-publish READY.
          (is (alfe.protocol.file:wait-for-status-prefix
               session "RUNNING" :timeout 2))
          (is (alfe.protocol.file:wait-for-status-prefix
               session "DONE" :timeout 2))
          (multiple-value-bind (ok elapsed last)
              (alfe.protocol.file:wait-for-status session "READY 1"
                                                   :timeout 2)
            (declare (ignore elapsed))
            (is (not (null ok)))
            (is (string= "READY 1" last)))
          ;; Now we can drain stdout and find the echoed request.
          (let ((stdout (alfe.protocol.file:drain-stdout session)))
            (is (search "(+ 1 2)" stdout)))
          ;; Request shutdown and assert the runtime walks the rest of
          ;; the state machine.
          (alfe.protocol.file:send-control session :shutdown)
          (is (alfe.protocol.file:wait-for-status
               session "STOPPING" :timeout 2))
          (is (alfe.protocol.file:wait-for-status
               session "STOPPED" :timeout 2))
          (bordeaux-threads:join-thread cad-thread))
      (delete-workdir workdir))))
