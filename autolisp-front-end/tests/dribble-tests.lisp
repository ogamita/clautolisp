;;;; alfe's dribble (alfe-dribble.issue): the FORMAT is the contract, because a
;;;; transcript is read beside clautolisp's own and diffed against it. These
;;;; tests pin the header, the tagging, the interleaving rule and the append
;;;; semantics, and the pass-through that keeps the clautolisp backend's
;;;; recording the engine's own.

(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

(defmacro %with-dribble ((path &key (backend :bricscad)
                                    (alfe-version "9.9.9")
                                    (cad-version "bricscad-v25"))
                         &body body)
  "Record into a fresh temporary file, bind PATH to it, and clean up. Each test
gets its own file, so nothing depends on test order."
  `(let ((,path (merge-pathnames (format nil "alfe-dribble-~D.log" (random 999999))
                                 (uiop:temporary-directory))))
     (unwind-protect
          (progn
            (alfe.dribble:start-dribble :file ,path :backend ,backend
                                        :alfe-version ,alfe-version
                                        :cad-version ,cad-version)
            ,@body)
       (ignore-errors (alfe.dribble:stop-dribble))
       (ignore-errors (delete-file ,path)))))

(defun %dribble-lines (path)
  (with-open-file (in path :external-format :utf-8)
    (loop for line = (read-line in nil nil) while line collect line)))

(test alfe-dribble-header-carries-both-versions
  "The header names alfe AND the engine -- two versions, unlike clautolisp's
one, because a transcript of a CAD session is only interpretable with both."
  (%with-dribble (path)
    (alfe.dribble:stop-dribble)
    (is (equal '(";; H: alfe 9.9.9 bricscad bricscad-v25") (%dribble-lines path)))))

(test alfe-dribble-header-says-unknown-rather-than-waiting
  "When alfe does not know the CAD's version yet -- the engine has not answered,
and may never -- the header says so instead of being withheld: a transcript that
appeared only after a successful start would be missing the failed starts."
  (%with-dribble (path :cad-version nil)
    (alfe.dribble:stop-dribble)
    (is (equal '(";; H: alfe 9.9.9 bricscad unknown") (%dribble-lines path)))))

(test alfe-dribble-tags-input-output-and-errors
  "Input raw and unprefixed; output `;; O: '; error output `;; E: '; a condition
`;; C: ' -- the format clautolisp writes."
  (%with-dribble (path)
    (alfe.dribble:record-input "(princ 1)")
    (alfe.dribble:record-output (format nil "1~%"))
    (alfe.dribble:record-error-output (format nil "a warning~%"))
    (alfe.dribble:record-condition "DIVISION-BY-ZERO: Division by zero in /.")
    (alfe.dribble:stop-dribble)
    (is (equal (list ";; H: alfe 9.9.9 bricscad bricscad-v25"
                     "(princ 1)"
                     ";; O: 1"
                     ";; E: a warning"
                     ";; C: DIVISION-BY-ZERO: Division by zero in /.")
               (%dribble-lines path)))))

(test alfe-dribble-splits-a-chunk-into-lines
  "alfe drains CHUNKS, not characters, so a multi-line chunk becomes one tagged
line per line -- never one line carrying an embedded newline."
  (%with-dribble (path)
    (alfe.dribble:record-output (format nil "one~%two~%three~%"))
    (alfe.dribble:stop-dribble)
    (is (equal (list ";; H: alfe 9.9.9 bricscad bricscad-v25"
                     ";; O: one" ";; O: two" ";; O: three")
               (%dribble-lines path)))))

(test alfe-dribble-completes-a-partial-line-from-the-next-chunk
  "A chunk not ending in a newline leaves the line OPEN; the next chunk of the
same tag continues it. Draining a file in two reads must not split a line in
two."
  (%with-dribble (path)
    (alfe.dribble:record-output "half")
    (alfe.dribble:record-output (format nil "-and-half~%"))
    (alfe.dribble:stop-dribble)
    (is (equal (list ";; H: alfe 9.9.9 bricscad bricscad-v25" ";; O: half-and-half")
               (%dribble-lines path)))))

(test alfe-dribble-interleaving-terminates-the-open-line
  "The interleaving rule: when another tag must write while a line is open, the
open line is terminated first, so no line carries two tags' text. Here stderr
arrives mid-line, and the partial stdout is emitted as its own `;; O: ' line --
kept, not dropped: alfe sees no prompts, so a partial line is genuine output."
  (%with-dribble (path)
    (alfe.dribble:record-output "no newline yet")
    (alfe.dribble:record-error-output (format nil "urgent~%"))
    (alfe.dribble:stop-dribble)
    (is (equal (list ";; H: alfe 9.9.9 bricscad bricscad-v25"
                     ";; O: no newline yet"
                     ";; E: urgent")
               (%dribble-lines path)))))

(test alfe-dribble-stop-flushes-an-unterminated-line
  "A session ending on output without a trailing newline keeps that output: the
clautolisp side drops such a line only when it is PROMPT text, and a CAD engine
driven through files writes no prompts at alfe."
  (%with-dribble (path)
    (alfe.dribble:record-output "trailing")
    (alfe.dribble:stop-dribble)
    (is (equal (list ";; H: alfe 9.9.9 bricscad bricscad-v25" ";; O: trailing")
               (%dribble-lines path)))))

(test alfe-dribble-appends-to-an-existing-file
  "A day's sessions accumulate: the second recording appends, so both headers
and both transcripts are in the file."
  (let ((path (merge-pathnames (format nil "alfe-dribble-append-~D.log" (random 999999))
                              (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (alfe.dribble:start-dribble :file path :backend :autocad
                                       :alfe-version "1.0" :cad-version "acad-2022")
           (alfe.dribble:record-input "(first)")
           (alfe.dribble:stop-dribble)
           (alfe.dribble:start-dribble :file path :backend :autocad
                                       :alfe-version "1.0" :cad-version "acad-2022")
           (alfe.dribble:record-input "(second)")
           (alfe.dribble:stop-dribble)
           (is (equal (list ";; H: alfe 1.0 autocad acad-2022" "(first)"
                            ";; H: alfe 1.0 autocad acad-2022" "(second)")
                      (%dribble-lines path))))
      (ignore-errors (delete-file path)))))

(test alfe-dribble-records-nothing-when-inactive
  "Every recorder is a no-op when no dribble is running: the CAD driver calls
them unconditionally, so this is what keeps a session without --dribble free of
both cost and side effects."
  (is (null (alfe.dribble:dribble-active-p)))
  (alfe.dribble:record-input "(ignored)")
  (alfe.dribble:record-output "ignored")
  (alfe.dribble:record-error-output "ignored")
  (alfe.dribble:record-condition "ignored")
  (is (null (alfe.dribble:dribble-active-p)))
  (is (null alfe.dribble:*dribble-path*)))

(test alfe-dribble-default-path-is-per-backend-and-timestamped
  "$XDG_STATE_HOME/alfe/dribbles/<backend>/<timestamp>.log. The per-backend
directory is alfe's own: one machine drives several engines, and a listing that
mixed them would hide the difference the transcript is kept for."
  (let ((path (namestring (alfe.dribble:default-dribble-path :autocad))))
    (is (search "alfe/dribbles/autocad/" path))
    (is (search ".log" path))
    ;; YYYYMMDDTHHMMSS: the T is what distinguishes it from a date alone, and
    ;; two runs in one second would otherwise collide.
    (is (find #\T (file-namestring path)))
    (is (>= (length (file-namestring path)) (length "20260927T000000.log")))))

(test alfe-dribble-default-path-sits-under-the-state-home
  "The default file is under $XDG_STATE_HOME, or ~/.local/state when that is
unset -- the specification's default, not a home-directory dotfile."
  (let ((path (namestring (alfe.dribble:default-dribble-path :bricscad)))
        (state-home (namestring (alfe.dribble::%state-home))))
    (is (eql 0 (search state-home path))
        "~S must start with the state home ~S" path state-home)
    ;; And that state home is the specified one: the variable when set,
    ;; ~/.local/state otherwise.
    (let ((env (uiop:getenv "XDG_STATE_HOME")))
      (if (and env (plusp (length env)))
          (is (eql 0 (search (namestring (uiop:ensure-directory-pathname env))
                             state-home)))
          (is (search ".local/state/" state-home))))))

;;; --- the clautolisp backend is FORWARDED, not recorded here ----------

(test alfe-dribble-is-forwarded-to-the-spawned-clautolisp
  "pjb's split: the engine records its own REPL, so alfe passes the request into
the argv (as it already does for -Esource) and records nothing itself. A bare
--dribble forwards bare; --dribble=FILE forwards the file; the interactor filter
goes with it, because interactors are exactly what the engine has and alfe's CAD
path has not."
  (flet ((flags (dribble interactors)
           (let ((session (alfe.backend.clautolisp::%make-subprocess-session
                           :dribble dribble :dribble-interactors interactors)))
             (alfe.backend.clautolisp::%dribble-cli-flags session))))
    (is (null (flags nil nil)) "no --dribble, nothing forwarded")
    (is (equal '("--dribble") (flags t nil)))
    (is (equal '("--dribble=/tmp/t.log") (flags "/tmp/t.log" nil)))
    (is (equal '("--dribble" "--dribble-interactors=t") (flags t :all)))
    (is (equal '("--dribble" "--dribble-interactors=AUTOLISP,ALDO")
               (flags t '("AUTOLISP" "ALDO"))))
    ;; The filter alone configures a recording that is not happening.
    (is (null (flags nil :all))
        "--dribble-interactors without --dribble forwards nothing")))

(test alfe-dribble-records-a-whole-mock-cad-session
  "END TO END, the acceptance criterion: drive the mock CAD through
DRIVE-PROTOCOL-ACTIONS with a dribble running, and the transcript shows the form
alfe SENT (raw) and the engine's echo (`;; O: '), in order. This is the path a
real BricsCAD session takes -- the recorder is called from the driver's
send-action and drain-live, not from the test."
  (let ((workdir (uiop:ensure-directory-pathname
                  (merge-pathnames (format nil "alfe-dribble-e2e-~D/" (random 999999))
                                   (uiop:temporary-directory))))
        (log (merge-pathnames (format nil "alfe-dribble-e2e-~D.log" (random 999999))
                              (uiop:temporary-directory))))
    (unwind-protect
        (progn
          (ensure-directories-exist workdir)
          (setf *mock-cad-condition* nil)
          (let* ((protocol (alfe.protocol.file:init-session workdir))
                 (cad (spawn-mock-cad-runtime protocol :cycles 1))
                 (plan (list (alfe.backend:action-eval "(princ 42)")
                             (alfe.backend:action-quit))))
            (alfe.protocol.file:wait-for-status-prefix protocol "READY" :timeout 15)
            (alfe.dribble:start-dribble :file log :backend :bricscad
                                        :alfe-version "9.9.9"
                                        :cad-version "bricscad-v25")
            (unwind-protect
                 (let ((*standard-output* (make-string-output-stream))
                       (*error-output*    (make-string-output-stream)))
                   (let ((result (alfe.backend.cad-common:drive-protocol-actions
                                  protocol plan)))
                     (is (eq :success (alfe.backend:eval-result-status result))
                         "got ~S~A" (alfe.backend:eval-result-status result)
                         (%mock-cad-failure-note))))
              (alfe.dribble:stop-dribble))
            (%finish-mock-cad cad protocol)
            (let ((lines (%dribble-lines log)))
              (is (equal ";; H: alfe 9.9.9 bricscad bricscad-v25" (first lines)))
              ;; the form alfe sent, raw and unprefixed
              (is (member "(princ 42)" lines :test #'equal)
                  "the sent form must be recorded raw; got ~S" lines)
              ;; the mock echoes the payload back, so it arrives as output
              (is (find-if (lambda (line)
                             (and (eql 0 (search ";; O: " line))
                                  (search "(princ 42)" line)))
                           lines)
                  "the engine's echo must be recorded as output; got ~S" lines)
              ;; input comes before the output it produced
              (is (< (position "(princ 42)" lines :test #'equal)
                     (or (position-if (lambda (line) (eql 0 (search ";; O: " line)))
                                      lines)
                         most-positive-fixnum))))))
      (ignore-errors (delete-file log))
      (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore))))

(test alfe-dribble-says-so-when-the-in-process-engine-cannot-record
  "--dribble with the IN-PROCESS clautolisp engine records nothing, because the
recording is clautolisp's own REPL tee and only the clautolisp PROGRAM attaches
it (*DRIBBLE-HOOK*). alfe says that, and names the two ways to get a transcript.
Silence would be the one unacceptable answer: a user who asked for a record must
not discover its absence by looking for the file."
  (let* ((options (parse-arguments '("--dribble" "-x" "(+ 1 2)")))
         (text (with-output-to-string (err)
                 (let ((*error-output* err))
                   (is (alfe.backend.clautolisp::%warn-direct-dribble-unavailable
                        options))))))
    (is (search "--dribble records nothing" text))
    (is (search "--backend subprocess" text)
        "the warning must name the way to get the engine's own transcript")
    (is (search "--autocad" text)
        "and say that the CAD backends do record"))
  ;; Without --dribble it says nothing at all.
  (let* ((options (parse-arguments '("-x" "(+ 1 2)")))
         (text (with-output-to-string (err)
                 (let ((*error-output* err))
                   (is (null (alfe.backend.clautolisp::%warn-direct-dribble-unavailable
                              options)))))))
    (is (zerop (length text)))))
