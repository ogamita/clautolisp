(in-package #:autolisp-front-end.tests)

(in-suite autolisp-front-end-suite)

;;;; The engine's console must never block it
;;;; (alfe-accoreconsole-console-pipe-not-drained).
;;;;
;;;; The CAD backends used to launch the engine with :OUTPUT :STREAM
;;;; :ERROR-OUTPUT :STREAM and read those pipes only after the process had
;;;; exited. accoreconsole echoes its whole command line to that console, so a
;;;; long run filled the pipe and blocked on its next write until --timeout.
;;;;
;;;; These tests run a REAL child process -- the host Lisp -- through
;;;; START-ENGINE's own launch keywords: it writes 1 MiB to its standard output
;;;; and 1 MiB to its standard error, far past any pipe buffer, and only THEN
;;;; does its job (signal the mock CAD to publish READY, or exit with a
;;;; diagnostic). With an undrained pipe the child blocks in the middle of that
;;;; output and the READY wait times out: the test FAILS after its 30 s
;;;; timeout instead of hanging the suite.
;;;;
;;;; Uses the mock CAD runtime of backend-cad-tests.lisp
;;;; (SPAWN-MOCK-CAD-RUNTIME, FIND-PROTOCOL-SESSION-IN-WORKDIR).

(defparameter +console-flood-lines+ 1024
  "Lines of 1023 characters plus a newline the flooding child writes to EACH
of its standard output and standard error: 1 MiB per stream.")

(defun %host-lisp-argv (form)
  "An argv that runs FORM (a string) in a fresh process of the host Lisp, or
NIL when this implementation is not one we know how to re-launch."
  #+sbcl (list (uiop:native-namestring sb-ext:*runtime-pathname*)
               "--core" (uiop:native-namestring sb-ext:*core-pathname*)
               "--noinform" "--no-sysinit" "--no-userinit" "--non-interactive"
               "--eval" form)
  #+ccl (list (uiop:native-namestring (ccl::kernel-path))
              "--image-name" (uiop:native-namestring ccl:*heap-image-name*)
              "--no-init" "--quiet" "--batch"
              "--eval" form
              "--eval" "(ccl:quit 0)")
  #-(or sbcl ccl) (progn form nil))

(defun %exit-form (code)
  #+sbcl (format nil "(sb-ext:exit :code ~D)" code)
  #+ccl (format nil "(ccl:quit ~D)" code)
  #-(or sbcl ccl) (progn code "nil"))

(defun %console-flood-form (go-path &key exit-code (marker ""))
  "The child's program: flood both console streams, write MARKER on standard
error, then either exit with EXIT-CODE, or create GO-PATH and idle (the engine
is `up'; the test's shutdown kills it)."
  (format nil "(progn
  (let ((line (make-string 1023 :initial-element #\\x)))
    (dotimes (i ~D)
      (write-line line *standard-output*)
      (write-line line *error-output*)))
  (write-line ~S *error-output*)
  (finish-output *standard-output*)
  (finish-output *error-output*)
  ~A)"
          +console-flood-lines+
          marker
          (if exit-code
              (%exit-form exit-code)
              (format nil "(progn (with-open-file (o ~S :direction :output :if-exists :supersede) (write-line \"go\" o)) (loop repeat 1200 do (sleep 0.1)))"
                      (uiop:native-namestring go-path)))))

(defun %flooding-launcher (workdir child-form-fn state)
  "A launcher for START-ENGINE's :LAUNCHER. It ignores the CAD argv and runs
the host Lisp on (FUNCALL CHILD-FORM-FN GO-PATH) with EXACTLY the keywords
START-ENGINE passes -- the launch path under test. A watcher thread waits for
the child's GO file and only then starts the mock CAD runtime, so READY can
appear only once the child got through its flood. STATE is a one-element list
whose CAR is a plist; :PROCESS, :WATCHER, :MOCK are recorded there and :STOP
read."
  (let ((go (merge-pathnames "child-go.txt" workdir)))
    (lambda (argv &rest keys)
      (declare (ignore argv))
      (let ((info (apply #'uiop:launch-program
                         (%host-lisp-argv (funcall child-form-fn go))
                         keys)))
        (setf (getf (car state) :process) info)
        (setf (getf (car state) :watcher)
              (bordeaux-threads:make-thread
               (lambda ()
                 (loop with deadline = (+ (get-internal-real-time)
                                          (* 120 internal-time-units-per-second))
                       until (or (getf (car state) :stop)
                                 (> (get-internal-real-time) deadline))
                       do (when (probe-file go)
                            (setf (getf (car state) :mock)
                                  (spawn-mock-cad-runtime
                                   (find-protocol-session-in-workdir workdir)
                                   :cycles 1))
                            (return))
                          (sleep 0.05)))
               :name "console-flood watcher"))
        info))))

(defun %finish-flood (state workdir)
  "Stop everything %FLOODING-LAUNCHER started: the child, the watcher, the mock."
  (setf (getf (car state) :stop) t)
  (let ((info (getf (car state) :process)))
    (when info (alfe.backend.cad-common:kill-engine-process info)))
  (let ((watcher (getf (car state) :watcher)))
    (when watcher (ignore-errors (bordeaux-threads:join-thread watcher))))
  (let ((mock (getf (car state) :mock)))
    (when mock
      (ignore-errors
       (%finish-mock-cad mock (find-protocol-session-in-workdir workdir))))))

(defun %flood-file-size (path)
  (with-open-file (in path :direction :input :element-type '(unsigned-byte 8)
                           :if-does-not-exist nil)
    (if in (file-length in) 0)))

(defun %flood-workdir (tag)
  (uiop:ensure-directory-pathname
   (merge-pathnames (format nil "alfe-test-flood-~A-~D/" tag (random 999999))
                    (uiop:temporary-directory))))

(defun %run-flood-session (backend workdir start-keys)
  "Start BACKEND on a flooding child, run one eval, shut down. Returns
(VALUES STATE-AT-READY EVAL-STATUS CONDITION-OR-NIL)."
  (let ((state (list nil)))
    (unwind-protect
         (handler-case
             (let ((session (apply #'alfe.backend:start-engine
                                   backend workdir
                                   :dialect :strict :host :mock :mock-input nil
                                   :bootstrap-phase :full :interactive-p nil
                                   :mode :batch
                                   :launcher (%flooding-launcher
                                              workdir
                                              (lambda (go) (%console-flood-form go))
                                              state)
                                   :wait-for-ready t
                                   start-keys)))
               (let ((ready (alfe.backend:session-state session))
                     (result (let ((*standard-output* (make-string-output-stream))
                                   (*error-output* (make-string-output-stream)))
                               (alfe.backend:eval-plan
                                session
                                (list (alfe.backend:action-eval "(princ 7)")
                                      (alfe.backend:action-quit))))))
                 (alfe.backend:shutdown session)
                 (values ready (alfe.backend:eval-result-status result) nil)))
           (error (condition) (values nil nil condition)))
      (%finish-flood state workdir))))

(defun %start-flood-that-exits (backend workdir exit-code marker start-keys)
  "Start BACKEND on a child that floods its console, writes MARKER on standard
error and exits EXIT-CODE before READY. Returns the bootstrap condition, or
NIL when START-ENGINE returned."
  (let ((state (list nil))
        ;; The READY-abort warning quotes the 4000-character tail of the
        ;; flood; keep it out of the suite's output.
        (alfe.logging:*current-level* :error))
    (unwind-protect
         (handler-case
             (progn
               (apply #'alfe.backend:start-engine
                      backend workdir
                      :dialect :strict :host :mock :mock-input nil
                      :bootstrap-phase :full :interactive-p nil
                      :mode :batch
                      :launcher (%flooding-launcher
                                 workdir
                                 (lambda (go)
                                   (%console-flood-form go :exit-code exit-code
                                                           :marker marker))
                                 state)
                      :wait-for-ready t
                      start-keys)
               nil)
           (alfe.error:backend-bootstrap-error (condition) condition))
      (%finish-flood state workdir))))

(defun %flooded-stream-kept-p (workdir name)
  (>= (%flood-file-size (merge-pathnames name workdir))
      (* 1024 +console-flood-lines+)))

(test autocad-batch-console-flood-does-not-block-the-engine
  "An accoreconsole stand-in that writes 1 MiB to each console stream before
it can publish READY reaches READY and runs a request, and its whole console is
kept in the workdir."
  (let ((workdir (%flood-workdir "acad")))
    (if (null (%host-lisp-argv "nil"))
        (pass "no way to re-launch this Lisp as a child")
        (unwind-protect
             (progn
               (ensure-directories-exist workdir)
               (setf *mock-cad-condition* nil)
               (multiple-value-bind (ready status condition)
                   (%run-flood-session
                    (alfe.backend.autocad:make-autocad-backend
                     :accoreconsole-path "/usr/bin/true")
                    workdir
                    ;; --timeout bounds READY: a blocked child fails the test
                    ;; in 30 s instead of hanging the suite.
                    (list :cli-options (alfe.cli:make-cli-options :timeout 30)))
                 (is (null condition)
                     "the engine did not get through its console output: ~A~A"
                     condition (%mock-cad-failure-note))
                 (is (eq :ready ready))
                 (is (eq :success status) "eval status ~S~A" status
                     (%mock-cad-failure-note)))
               (is (%flooded-stream-kept-p workdir "engine-console-stdout.txt")
                   "the engine's standard output was not kept in the workdir")
               (is (%flooded-stream-kept-p workdir "engine-console-stderr.txt")
                   "the engine's standard error was not kept in the workdir"))
          (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore)))))

(test bricscad-console-flood-does-not-block-the-engine
  "The BricsCAD launch path (bricscad, cscript, osascript) redirects the
console the same way: 1 MiB per stream before READY does not block it."
  (let ((workdir (%flood-workdir "bcad")))
    (if (null (%host-lisp-argv "nil"))
        (pass "no way to re-launch this Lisp as a child")
        (unwind-protect
             (progn
               (ensure-directories-exist workdir)
               (setf *mock-cad-condition* nil)
               (multiple-value-bind (ready status condition)
                   (%run-flood-session
                    (alfe.backend.bricscad:make-bricscad-backend
                     :executable-path "/usr/bin/true" :variant :batch)
                    workdir
                    (list :cli-options (alfe.cli:make-cli-options :timeout 30)
                          :ready-timeout 30))
                 (is (null condition)
                     "the engine did not get through its console output: ~A~A"
                     condition (%mock-cad-failure-note))
                 (is (eq :ready ready))
                 (is (eq :success status) "eval status ~S~A" status
                     (%mock-cad-failure-note)))
               (is (%flooded-stream-kept-p workdir "engine-console-stdout.txt")
                   "the launcher's standard output was not kept in the workdir")
               (is (%flooded-stream-kept-p workdir "engine-console-stderr.txt")
                   "the launcher's standard error was not kept in the workdir"))
          (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore)))))

(test autocad-batch-console-flood-keeps-exit-diagnostics
  "An engine that floods its console and then dies before READY is reported as
having exited -- not as a READY timeout, which is what a child blocked on a
full pipe produced -- with its exit code and the end of its standard error,
which the diagnostics quoted from the pipes before."
  (let ((workdir (%flood-workdir "acad-exit")))
    (if (null (%host-lisp-argv "nil"))
        (pass "no way to re-launch this Lisp as a child")
        (unwind-protect
             (progn
               (ensure-directories-exist workdir)
               (let ((condition (%start-flood-that-exits
                                 (alfe.backend.autocad:make-autocad-backend
                                  :accoreconsole-path "/usr/bin/true")
                                 workdir 7 "fatal cfg lock"
                                 (list :ready-timeout 30))))
                 (is (not (null condition)))
                 (when condition
                   (is (eq :process-exited-before-ready
                           (alfe.error:backend-error-code condition))
                       "got ~S: ~A" (alfe.error:backend-error-code condition)
                       (alfe.error:backend-error-message condition))
                   (is (search "fatal cfg lock"
                               (alfe.error:backend-error-message condition)))
                   (is (eql 7 (getf (alfe.error:backend-error-details condition)
                                    :exit-code))))))
          (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore)))))

(test bricscad-console-flood-keeps-launcher-failure-details
  "The BricsCAD READY wait aborts on a launcher that exits non-zero and quotes
the tail of what it wrote -- now read from the captured console files."
  (let ((workdir (%flood-workdir "bcad-exit")))
    (if (null (%host-lisp-argv "nil"))
        (pass "no way to re-launch this Lisp as a child")
        (unwind-protect
             (progn
               (ensure-directories-exist workdir)
               (let ((condition (%start-flood-that-exits
                                 (alfe.backend.bricscad:make-bricscad-backend
                                  :executable-path "/usr/bin/true" :variant :batch)
                                 workdir 3 "osascript: not allowed"
                                 (list :ready-timeout 30))))
                 (is (not (null condition)))
                 (when condition
                   (is (eq :launcher-failed (alfe.error:backend-error-code condition))
                       "got ~S: ~A" (alfe.error:backend-error-code condition)
                       (alfe.error:backend-error-message condition))
                   (let ((message (alfe.error:backend-error-message condition)))
                     (is (search "launcher exited with code 3" message))
                     (is (search "osascript: not allowed" message))))))
          (uiop:delete-directory-tree workdir :validate t :if-does-not-exist :ignore)))))
