(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Phase 14b: end-to-end reactor dispatch through MockHost ----

(test cador-entmake-fires-acdb-objectappended
  (let* ((mock (make-cador))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let ((records (clautolisp.autolisp-runtime:call-with-event-trace
                    session
                    (lambda ()
                      (host-entmake mock (list (cons 0 "LINE")
                                                (cons 8 "0")
                                                (cons 10 '(0 0 0))
                                                (cons 11 '(1 1 0))))))))
      (is (find :vlr-objectappended records :key #'fourth)))))

(test cador-entmod-fires-objectmodified
  (let* ((mock (make-cador))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let* ((data (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                                          (cons 10 '(0 0 0)) (cons 11 '(1 1 0)))))
           (ename (cdr (first data)))
           (records (clautolisp.autolisp-runtime:call-with-event-trace
                     session
                     (lambda ()
                       (host-entmod mock
                                     (cons (cons -1 ename)
                                           (list (cons 0 "LINE")
                                                 (cons 8 "Modified"))))))))
      (is (find :vlr-objectmodified records :key #'fourth))
      (is (find :vlr-modified records :key #'fourth)))))

(test cador-setvar-fires-sysvar-events
  (let* ((mock (make-cador))
         (session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:default-evaluation-context))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let ((records (clautolisp.autolisp-runtime:call-with-event-trace
                    session
                    (lambda ()
                      (host-setvar mock "CMDECHO" 0)))))
      (is (find :vlr-sysvarwillchange records :key #'fourth))
      (is (find :vlr-sysvarchanged records :key #'fourth)))))

(test reactor-fires-on-cador-mutation
  ;; Register an acdb reactor on the active document, mutate an
  ;; entity through MockHost, assert the reactor's callback ran.
  (let* ((mock (make-cador))
         (context (clautolisp.autolisp-runtime:default-evaluation-context))
         (session (clautolisp.autolisp-runtime:evaluation-context-session context))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (fired-events '())
         (callback (clautolisp.autolisp-runtime:make-autolisp-subr
                    "ON-MOD"
                    (lambda (reactor reaction-name args)
                      (declare (ignore reactor args))
                      (push reaction-name fired-events)))))
    (clautolisp.autolisp-runtime:set-runtime-session-host session mock)
    (let ((reactor (clautolisp.autolisp-runtime:make-reactor :kind :acdb)))
      (setf (gethash :vlr-objectappended
                     (clautolisp.autolisp-runtime:reactor-callbacks reactor))
            callback)
      (setf (gethash :vlr-objectmodified
                     (clautolisp.autolisp-runtime:reactor-callbacks reactor))
            callback)
      (clautolisp.autolisp-runtime:add-reactor-to-document document reactor))
    (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           context))
      (let* ((data (host-entmake mock (list (cons 0 "LINE") (cons 8 "0")
                                            (cons 10 '(0 0 0)) (cons 11 '(1 1 0)))))
             (ename (cdr (first data))))
        (host-entmod mock
                      (cons (cons -1 ename)
                            (list (cons 0 "LINE") (cons 8 "L1"))))))
    (is (member :vlr-objectappended fired-events))
    (is (member :vlr-objectmodified fired-events))))
