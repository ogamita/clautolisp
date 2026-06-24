;;;; autolisp-front-end/source/backend-echo.lisp
;;;;
;;;; The `echo` backend is the test-only mock specified by
;;;; ../issues/open/alfe-backend-interface.issue (section "Mock
;;;; backend"). It implements every generic on ALFE.BACKEND:BACKEND
;;;; with a scripted answer table, letting alfe.cli tests drive an
;;;; end-to-end action plan without depending on a real evaluator.
;;;;
;;;; Behaviour:
;;;;
;;;;   - DETECT always succeeds — the echo backend is always
;;;;     "available" (it is registered explicitly, never via the
;;;;     default-resolver).
;;;;   - START-ENGINE returns a fresh ECHO-SESSION whose initial
;;;;     output buffers are empty and whose state is :ready.
;;;;   - EVAL-PLAN walks the action list and emits a deterministic
;;;;     answer per action kind:
;;;;        (:eval EXPR)       → "EXPR" echoed back, value = EXPR
;;;;        (:eval "(+ 1 2)")  → special case: value = "3" (the spec
;;;;                              asks for the smoke test to assert
;;;;                              this exact behaviour).
;;;;        (:load PATH-PLIST) → "loaded PATH", value = "T"
;;;;        (:main FN)         → "main FN", value = "T"
;;;;        (:interactive)     → echoes "(interactive)" and stops
;;;;        (:quit)            → returns with status :success
;;;;     Captured stdout is the concatenation of those echoes.
;;;;   - SHUTDOWN flips the state to :stopped, idempotent.
;;;;
;;;; The backend is registered eagerly on load so tests can
;;;; (find-backend :echo) without an explicit setup step.

(defpackage #:alfe.backend.echo
  (:use #:cl)
  (:import-from #:alfe.backend
                #:backend
                #:backend-name
                #:detect
                #:prepare-workdir
                #:start-engine
                #:eval-plan
                #:read-output
                #:send-input
                #:request-control
                #:shutdown
                #:cleanup-workdir
                #:session
                #:session-backend
                #:session-workdir
                #:session-dialect
                #:session-state
                #:session-state-set
                #:make-session
                #:action-kind
                #:action-payload
                #:make-eval-result
                #:register-backend)
  (:import-from #:alfe.error
                #:backend-protocol-error)
  (:export #:echo-backend
           #:make-echo-backend
           #:echo-session
           #:echo-session-output
           #:echo-session-input))

(in-package #:alfe.backend.echo)

(defclass echo-backend (backend)
  ()
  (:default-initargs
   :name :echo
   :display-name "echo (test mock)")
  (:documentation
   "Always-available mock backend used by alfe-front-end's own test
suite. Never wired into the CLI's default-resolver."))

(defun make-echo-backend ()
  (make-instance 'echo-backend))

(defstruct (echo-session
            (:include session)
            (:constructor %make-echo-session))
  "Session subclass that records the textual answers EVAL-PLAN
emitted and any input pushed via SEND-INPUT, so tests can inspect
both after the fact."
  (output       (make-string-output-stream))
  (error-output (make-string-output-stream))
  (input        (make-array 0 :element-type 't
                              :adjustable t :fill-pointer 0)))

(defmethod detect ((backend echo-backend) &key)
  ;; Always available.
  backend)

(defmethod prepare-workdir ((backend echo-backend) workdir-root &key)
  ;; The echo backend does not need an on-disk workdir; tests pass NIL.
  workdir-root)

(defmethod start-engine ((backend echo-backend) workdir
                         &key dialect host mock-input bootstrap-phase
                              interactive-p mode dwg
                              load-encoding io-encoding
                              cli-options version-text)
  (declare (ignore host mock-input bootstrap-phase interactive-p mode dwg
                   load-encoding io-encoding cli-options version-text))
  (let ((session (%make-echo-session :backend backend
                                     :workdir workdir
                                     :dialect dialect)))
    (session-state-set session :ready)
    session))

(defun render-eval-payload (payload)
  "Return (values echo-text value-string). The (+ 1 2) special case
exists so the acceptance criterion in alfe-backend-interface.issue
(echo backend computes 3) holds without dragging in a real evaluator."
  (let ((trimmed (string-trim '(#\Space #\Tab #\Newline) payload)))
    (cond
      ((string= trimmed "(+ 1 2)")
       (values "3" "3"))
      (t
       (values payload payload)))))

(defmethod eval-plan ((session echo-session) plan)
  (session-state-set session :running)
  ;; The backend contract is: write live to *STANDARD-OUTPUT* AND
  ;; capture a copy for diagnostic introspection. We use a broadcast
  ;; stream so every write fans out to both destinations. The capture
  ;; lives in the session struct so tests can inspect it after the
  ;; fact via EVAL-RESULT-OUTPUT or READ-OUTPUT.
  (let* ((output-capture (echo-session-output session))
         (error-capture  (echo-session-error-output session))
         (live-stdout    (make-broadcast-stream *standard-output* output-capture))
         (live-stderr    (make-broadcast-stream *error-output*    error-capture))
         (final-value nil)
         (status :success))
    (let ((*standard-output* live-stdout)
          (*error-output*    live-stderr))
      (dolist (action plan)
        (let ((kind (action-kind action))
              (payload (action-payload action)))
          (ecase kind
            (:load
             (let ((path (getf payload :path)))
               (format t "loaded ~A~%" path)
               (setf final-value "T")))
            (:eval
             (multiple-value-bind (text value)
                 (render-eval-payload payload)
               (format t "~A~%" text)
               (setf final-value value)))
            (:main
             (format t "main ~A~%" payload)
             (setf final-value "T"))
            (:interactive
             (format t "(interactive)~%")
             (setf final-value nil))
            (:quit
             (return))))))
    (session-state-set session :done)
    (make-eval-result
     :status status
     :value final-value
     :output (get-output-stream-string output-capture)
     :error-output (get-output-stream-string error-capture))))

(defmethod read-output ((session echo-session) &key timeout)
  (declare (ignore timeout))
  (values (get-output-stream-string (echo-session-output session))
          (get-output-stream-string (echo-session-error-output session))))

(defmethod send-input ((session echo-session) text)
  (vector-push-extend text (echo-session-input session))
  text)

(defmethod request-control ((session echo-session) command)
  (case command
    (:ping       :pong)
    (:shutdown   (shutdown session) :stopped)
    (:interrupt  (session-state-set session :stopping) :interrupted)
    (otherwise
     (error 'backend-protocol-error
            :backend :echo
            :code :unknown-control
            :message (format nil "Unknown control command ~S" command)
            :details (list :command command)))))

(defmethod shutdown ((session echo-session) &key reason)
  (declare (ignore reason))
  (unless (eq (session-state session) :stopped)
    (session-state-set session :stopped))
  session)

(defmethod cleanup-workdir ((backend echo-backend) workdir &key keep-p)
  (declare (ignore workdir keep-p))
  nil)

;;; Register on load so (alfe.backend:find-backend :echo) works
;;; without an explicit init call from tests.
(register-backend :echo (make-echo-backend))
