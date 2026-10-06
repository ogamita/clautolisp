;;;; clautolisp/tools/clautolisp/tests/interrupt-tests.lisp
;;;;
;;;; --on-interrupt / *CLAL-ON-INTERRUPT*: a REAL SIGINT, sent to this very
;;;; process, must reach HANDLE-INTERRUPT in the thread that installed the
;;;; handler -- on SBCL through its signal handler, on CCL through
;;;; CCL:*BREAK-HOOK* (debugger-public-interface-and-on-error.issue: until
;;;; clautolisp 2.2.218 CCL had no handler, and a Control-C dropped the user
;;;; into CCL's own `1 >' break loop under every policy). Run by both
;;;; `make test-sbcl' and `make test-ccl'. The shipped executables are driven
;;;; by tools/clautolisp/tests/shipped-interrupt-test.sh.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %sigint-supported-p ()
  "True where the program installs a SIGINT handler (not on MS-Windows)."
  (and (not (uiop:os-windows-p))
       #+(or sbcl ccl) t
       #-(or sbcl ccl) nil))

(defun %send-sigint-to-self ()
  (cffi:foreign-funcall "kill"
                        :int (cffi:foreign-funcall "getpid" :int)
                        :int 2
                        :int))

(defun %set-live-interrupt-policy (name)
  "Set the AutoLISP *CLAL-ON-INTERRUPT* (which HANDLE-INTERRUPT reads LIVE,
overriding the runtime variable) to the symbol NAME."
  (clautolisp.autolisp-runtime:set-autolisp-symbol-value
   (clautolisp.autolisp-runtime:intern-autolisp-symbol "*CLAL-ON-INTERRUPT*")
   (clautolisp.autolisp-runtime:intern-autolisp-symbol name)))

(defun %wait-until (predicate &key (seconds 10))
  "Poll PREDICATE every 50 ms (interruptibly: the SIGINT is handled at such a
point) until it is true or SECONDS pass; return its last value."
  (loop with deadline = (+ (get-internal-real-time)
                           (* seconds internal-time-units-per-second))
        for value = (funcall predicate)
        until (or value (> (get-internal-real-time) deadline))
        do (sleep 0.05)
        finally (return value)))

(test sigint-under-debug-policy-breaks-into-the-debugger
  "A SIGINT under the DEBUG policy, with a debug session active, enters the
debugger through *DEBUG-BREAK-HOOK* in the installing thread, then resumes
this computation (no host break loop, no exit)."
  (if (not (%sigint-supported-p))
      (is (not (%sigint-supported-p)) "no SIGINT handler on this platform")
      (let* ((seen nil)
             (thread-seen nil)
             (me #+sbcl sb-thread:*current-thread* #+ccl ccl:*current-process*)
             (clautolisp.autolisp-runtime:*clal-on-interrupt* :debug)
             (clautolisp.autolisp-runtime:*debugging* t)
             (clautolisp.autolisp-runtime:*debug-break-hook*
               (lambda (message)
                 (setf thread-seen #+sbcl sb-thread:*current-thread*
                                   #+ccl ccl:*current-process*
                       seen message))))
        (%set-live-interrupt-policy "DEBUG")
        (let ((installed (clautolisp.tools.clautolisp:install-interrupt-handler)))
          (unwind-protect
               (progn
                 (is (eq t installed))
                 (%send-sigint-to-self)
                 (%wait-until (lambda () seen))
                 (is (equal "interrupt (Control-C)" seen))
                 (is (eq me thread-seen)
                     "the debugger was entered in another thread"))
            (clautolisp.tools.clautolisp:restore-interrupt-handler))))))

(test sigint-under-ignore-policy-resumes
  "A SIGINT under the IGNORE policy is handled (no host break loop, no exit,
no debugger) and the interrupted computation carries on."
  (if (not (%sigint-supported-p))
      (is (not (%sigint-supported-p)) "no SIGINT handler on this platform")
      (let* ((breaks 0)
             (clautolisp.autolisp-runtime:*clal-on-interrupt* :ignore)
             (clautolisp.autolisp-runtime:*debugging* t)
             (clautolisp.autolisp-runtime:*debug-break-hook*
               (lambda (message)
                 (declare (ignore message))
                 (incf breaks))))
        (%set-live-interrupt-policy "IGNORE")
        (clautolisp.tools.clautolisp:install-interrupt-handler)
        (unwind-protect
             (progn
               (%send-sigint-to-self)
               ;; Give the signal time to be delivered and handled: this wait
               ;; is the interrupted computation, and it must run to its end.
               (%wait-until (lambda () nil) :seconds 2)
               (is (zerop breaks) "the IGNORE policy entered the debugger"))
          (clautolisp.tools.clautolisp:restore-interrupt-handler)
          (%set-live-interrupt-policy "DEBUG")))))

(test sigint-handler-is-restored
  "RESTORE-INTERRUPT-HANDLER leaves no handler of ours installed, and
installing again works (an embedding program -- alfe's in-process engine --
installs it per run)."
  (if (not (%sigint-supported-p))
      (is (not (%sigint-supported-p)) "no SIGINT handler on this platform")
      (progn
        (is (eq t (clautolisp.tools.clautolisp:install-interrupt-handler)))
        (clautolisp.tools.clautolisp:restore-interrupt-handler)
        (is (null clautolisp.tools.clautolisp::*interrupt-handler-token*))
        #+ccl (is (null ccl:*break-hook*))
        (is (eq t (clautolisp.tools.clautolisp:install-interrupt-handler)))
        (clautolisp.tools.clautolisp:restore-interrupt-handler))))
