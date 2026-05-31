(in-package #:clautolisp.debug)

;;;; AutoLISP error integration (spec §10). The session entries install a
;;;; HANDLER-BIND for autolisp-runtime-error around the application. A
;;;; handler-bind handler runs BEFORE the stack unwinds, so DEBUG-HANDLE-
;;;; ERROR can snapshot the live environment at the error point and offer
;;;; the §10.1 resolutions. Errors caught by an inner vl-catch-all-apply
;;;; never reach this handler (its handler-case transfers control first),
;;;; which is exactly the §10.1 unhandled / §10.2 caught split.

(defparameter *break-on-caught-error* nil
  "When non-nil, the session also breaks on errors caught by
vl-catch-all-apply (spec §10.2), via the runtime caught-error hook. Off by
default — only unhandled errors break into the debugger.")

(defun debug-handle-error (ti condition reason)
  "Handle an AutoLISP error during a debug session. REASON is
:unhandled-error (from the session handler-bind) or :caught-error (from
the vl-catch-all hook). Builds a snapshot at the erroring form, dispatches
to *debug-hit-handler*, and carries out the resolution it returns:

  :continue / :continue-with-error / NIL   decline → let it propagate to
                                            the user's *error* (§10.1)
  :abort                                    unwind cleanly to the session
  (:continue-with-return VALUE)             supply VALUE for the innermost
                                            instrumented form (§10.1)

A decline returns normally so the condition keeps propagating."
  (let* ((pp (thread-debug-info-current-pp ti))
         (fid (if pp (car pp) 0))
         (form-id (if pp (cdr pp) 0))
         (metadata (metadata-for-function-id fid))
         (hit (make-hit :thread-info ti :fid fid :form-id form-id :when :error
                        :stop-reason reason :metadata metadata
                        :source-position (and metadata (form-id-position metadata form-id))
                        :condition condition
                        :error-message (autolisp-runtime-error-message condition)
                        :errno (ignore-errors (autolisp-errno))
                        :snapshot (build-snapshot ti fid form-id :error metadata))))
    (apply-error-directive (funcall *debug-hit-handler* hit))))

(defun apply-error-directive (directive)
  (cond
    ((or (null directive) (eq directive :continue) (eq directive :continue-with-error))
     nil)                                       ; decline → propagate to *error*
    ((eq directive :abort)
     (throw 'clal-abort :aborted))              ; unwind to the session catch
    ((and (consp directive) (eq (first directive) :continue-with-return))
     ;; Return a value for the innermost instrumented form (§10.1). Safe
     ;; only for form-internal errors; if no instrumented form encloses
     ;; the error there is no restart and we decline.
     (let ((restart (find-restart 'clal-poll-return)))
       (when restart
         (invoke-restart restart (coerce-from-cl (second directive))))))
    (t nil)))

(defun call-with-error-integration (ti thunk break-on-caught)
  "Run THUNK with the §10 error handlers installed for TI: a HANDLER-BIND
that breaks on unhandled errors, a CATCH for :abort, and (when
BREAK-ON-CAUGHT) the runtime caught-error hook. Returns THUNK's value, or
:ABORTED if the user aborted."
  (let ((clautolisp.autolisp-runtime:*autolisp-caught-error-hook*
          (when break-on-caught
            (lambda (condition) (debug-handle-error ti condition :caught-error)))))
    (catch 'clal-abort
      (handler-bind ((clautolisp.autolisp-runtime:autolisp-runtime-error
                       (lambda (condition)
                         (debug-handle-error ti condition :unhandled-error))))
        (funcall thunk)))))
