(in-package #:clautolisp.autolisp-cli)

;;;; Control-C (SIGINT), portably across the host Lisps the programs ship on.
;;;;
;;;; The clautolisp program applies --on-interrupt / *CLAL-ON-INTERRUPT* at a
;;;; Control-C, and alfe does too for its in-process engine, or hands the
;;;; signal to its clautolisp child. Both need the same primitive: run a
;;;; function in a chosen Lisp thread when the process receives SIGINT, at a
;;;; point where returning from it resumes what was interrupted -- and NEVER
;;;; land in the host Lisp's own break loop, which an AutoLISP user must not
;;;; meet (AGENTS.md).
;;;;
;;;; The host Lisps deliver SIGINT differently:
;;;;
;;;;  - SBCL (POSIX): a Lisp-level signal handler (SB-SYS:ENABLE-INTERRUPT),
;;;;    run in whichever thread the kernel picked; it forwards to the target
;;;;    thread with SB-THREAD:INTERRUPT-THREAD. Absent from the win32 build
;;;;    (SB-UNIX:SIGINT does not exist there), which keeps its console
;;;;    behaviour.
;;;;  - CCL: the kernel only sets a flag; the housekeeping thread then calls
;;;;    FORCE-BREAK-IN-LISTENER on the "interactive abort process", which
;;;;    process-interrupts that thread into CBREAK-LOOP with an
;;;;    INTERRUPT-SIGNAL-CONDITION. CBREAK-LOOP calls CCL:*BREAK-HOOK* first,
;;;;    inside a CONTINUE restart: a hook that invokes CONTINUE returns from
;;;;    the interrupt and the program resumes, without the break loop. That is
;;;;    the hook installed here; CCL::*SELECT-INTERACTIVE-PROCESS-HOOK* names
;;;;    the thread to interrupt. Before clautolisp 2.2.218 none of this was
;;;;    done on CCL, and a Control-C under --on-interrupt quit / ignore / debug
;;;;    alike dropped the user into CCL's `1 >' break loop.
;;;;  - anything else: no handler; the native behaviour stays.

#+(and sbcl (not win32))
(defvar *sbcl-sigint-handlers* '()
  "The SIGINT handlers INSTALL-SIGINT-HANDLER installed and that are still in
force, most recent first (see RESTORE-SIGINT-HANDLER).")

(defun %current-host-thread ()
  #+sbcl sb-thread:*current-thread*
  #+ccl ccl:*current-process*
  #-(or sbcl ccl) nil)

(defun install-sigint-handler (function &key (thread (%current-host-thread)) urgent)
  "Arrange for FUNCTION (no arguments) to run in THREAD (default: the calling
thread) when the process receives SIGINT; returning from FUNCTION resumes the
interrupted computation. URGENT, when given, is called first, where the signal
is received (SBCL: the signal handler; CCL: the interrupted thread): a true
value means it took care of the signal (typically by exiting) and FUNCTION is
not called -- this is how a second Control-C exits while the first one's
debugger is still up. Returns a token for RESTORE-SIGINT-HANDLER, or NIL where
the host Lisp keeps its native behaviour."
  (declare (ignorable function thread urgent))
  #+(and sbcl (not win32))
  (let ((handler (lambda (signal info context)
                   (declare (ignore signal info context))
                   (unless (and urgent (funcall urgent))
                     (sb-thread:interrupt-thread thread function)))))
    (sb-sys:enable-interrupt sb-unix:sigint handler)
    (push handler *sbcl-sigint-handlers*)
    (list :sbcl handler))
  #+ccl
  (let ((old-hook ccl:*break-hook*)
        (old-select ccl::*select-interactive-process-hook*))
    (labels ((hook (condition hook)
               (declare (ignore hook))
               (when (typep condition 'ccl:interrupt-signal-condition)
                 ;; CBREAK-LOOP binds *BREAK-HOOK* to NIL around this call: put
                 ;; it back for the duration, so a SECOND Control-C (while the
                 ;; first one's debugger is up) comes here too, not to the
                 ;; break loop.
                 (let ((ccl:*break-hook* #'hook))
                   (unless (and urgent (funcall urgent))
                     (funcall function)))
                 ;; Return from the interrupt: the program resumes.
                 (let ((restart (find-restart 'continue)))
                   (when restart (invoke-restart restart))))))
      (setf ccl::*select-interactive-process-hook* (lambda () thread)
            ccl:*break-hook* #'hook)
      (list :ccl old-hook old-select)))
  #-(or (and sbcl (not win32)) ccl)
  nil)

(defun restore-sigint-handler (token)
  "Undo the INSTALL-SIGINT-HANDLER that returned TOKEN (NIL: nothing to undo)."
  (when token
    (ecase (first token)
      #+(and sbcl (not win32))
      (:sbcl
       ;; SB-SYS:ENABLE-INTERRUPT does not return the handler it replaces, so
       ;; the ones installed here are stacked: restoring one reinstates the
       ;; one below it, or SBCL's own (SB-UNIX::SIGINT-HANDLER, which signals
       ;; SB-SYS:INTERACTIVE-INTERRUPT).
       (setf *sbcl-sigint-handlers* (remove (second token) *sbcl-sigint-handlers*))
       (sb-sys:enable-interrupt sb-unix:sigint
                                (or (first *sbcl-sigint-handlers*)
                                    (let ((default (find-symbol "SIGINT-HANDLER" "SB-UNIX")))
                                      (if (and default (fboundp default))
                                          (fdefinition default)
                                          :default)))))
      #+ccl
      (:ccl (setf ccl:*break-hook* (second token)
                  ccl::*select-interactive-process-hook* (third token)))))
  nil)

(defun call-with-sigint-handler (function thunk &key urgent)
  "Call THUNK with FUNCTION as the SIGINT handler of the calling thread (see
INSTALL-SIGINT-HANDLER), restoring the previous handler however THUNK exits."
  (let ((token (install-sigint-handler function :urgent urgent)))
    (unwind-protect (funcall thunk)
      (restore-sigint-handler token))))

(defun abrupt-exit (code)
  "Exit the process NOW with status CODE: flush the standard streams, then end
without unwinding any thread or running exit hooks -- for a second Control-C,
when the user wants out and something may be blocked."
  (ignore-errors (finish-output *standard-output*))
  (ignore-errors (finish-output *error-output*))
  #+sbcl (sb-ext:exit :code code :abort t)
  #-sbcl (cffi:foreign-funcall "_exit" :int code :void))

(defun forward-sigint (pid)
  "Pass a Control-C on to the child process PID when the terminal did not
already deliver it: a child in its own process group (SBCL's RUN-PROGRAM puts
one there when its input is not the terminal) never sees the keyboard's
SIGINT, a child sharing ours already did -- sending it a second one would read
as a second Control-C. Returns T when the signal was sent. A no-op on
MS-Windows, where the console delivers Control-C to every attached process."
  (unless (uiop:os-windows-p)
    (let ((group (cffi:foreign-funcall "getpgid" :int pid :int))
          (ours (cffi:foreign-funcall "getpgrp" :int)))
      (when (and (plusp group) (/= group ours))
        (zerop (cffi:foreign-funcall "kill" :int pid :int 2 :int))))))
