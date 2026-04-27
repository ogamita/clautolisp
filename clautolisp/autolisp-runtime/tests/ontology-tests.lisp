(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;; --- Phase 14a: ontology + event channel --------------------------

(test runtime-session-defaults-application-state-to-running
  (let ((session (make-runtime-session)))
    (is (eq :running
            (clautolisp.autolisp-runtime:runtime-session-application-state session)))))

(test document-namespace-defaults-state-to-loaded
  (let ((document (make-document-namespace :name "T")))
    (is (eq :loaded
            (clautolisp.autolisp-runtime:document-namespace-state document)))))

(test set-document-state-emits-activate-event-pair
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (records (clautolisp.autolisp-runtime:call-with-event-trace
                   session
                   (lambda ()
                     (clautolisp.autolisp-runtime:set-document-state document :active)))))
    (is (find :vlr-documenttobeactivated records :key #'fourth))
    (is (find :vlr-documentbecamecurrent records :key #'fourth))
    (is (eq :active
            (clautolisp.autolisp-runtime:document-namespace-state document)))))

(test set-application-state-emits-quit-events
  (let* ((session (make-runtime-session))
         (records (clautolisp.autolisp-runtime:call-with-event-trace
                   session
                   (lambda ()
                     (clautolisp.autolisp-runtime:set-application-state
                      session :quitting)))))
    (is (find :vlr-beginquit records :key #'fourth))))

(test signal-document-event-records-into-trace-only-when-trace-bound
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session)))
    ;; No trace bound -> no error, no observable side-effect.
    (clautolisp.autolisp-runtime:signal-document-event
     document :acdb :vlr-objectmodified '(()))
    (is (null (clautolisp.autolisp-runtime:runtime-session-event-trace session)))
    ;; Trace bound -> records appended.
    (let ((records (clautolisp.autolisp-runtime:call-with-event-trace
                    session
                    (lambda ()
                      (clautolisp.autolisp-runtime:signal-document-event
                       document :acdb :vlr-objectmodified '(()))))))
      (is (= 1 (length records)))
      (is (eq :document (first (first records))))
      (is (eq :acdb (third (first records))))
      (is (eq :vlr-objectmodified (fourth (first records)))))))

;;; --- Phase 14b: reactor struct + dispatch -------------------------

(test reactor-struct-builds-with-default-slots
  (let ((reactor (clautolisp.autolisp-runtime:make-reactor)))
    (is (eq :object (clautolisp.autolisp-runtime:reactor-kind reactor)))
    (is (eq :document (clautolisp.autolisp-runtime:reactor-scope reactor)))
    (is (clautolisp.autolisp-runtime:reactor-active-p reactor))
    (is (eq :all-documents
            (clautolisp.autolisp-runtime:reactor-notification reactor)))))

(test add-reactor-to-document-and-back
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (reactor (clautolisp.autolisp-runtime:make-reactor :kind :acdb)))
    (clautolisp.autolisp-runtime:add-reactor-to-document document reactor)
    (is (member reactor
                (clautolisp.autolisp-runtime:all-document-reactors document)))
    (is (eq document (clautolisp.autolisp-runtime:reactor-document reactor)))
    (clautolisp.autolisp-runtime:remove-reactor-from-document document reactor)
    (is (null (clautolisp.autolisp-runtime:all-document-reactors document)))))

(test add-reactor-to-session-application-scope
  (let* ((session (make-runtime-session))
         (reactor (clautolisp.autolisp-runtime:make-reactor
                   :kind :docmanager :scope :application)))
    (clautolisp.autolisp-runtime:add-reactor-to-session session reactor)
    (is (member reactor
                (clautolisp.autolisp-runtime:all-application-reactors session)))))

(test signal-document-event-dispatches-matching-reactor
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (fired-with nil)
         (callback-fn (clautolisp.autolisp-runtime:make-autolisp-subr
                       "ON-MOD"
                       (lambda (reactor reaction-name args)
                         (declare (ignore reactor))
                         (setf fired-with (list reaction-name args)))))
         (reactor (clautolisp.autolisp-runtime:make-reactor :kind :acdb))
         (callbacks (clautolisp.autolisp-runtime:reactor-callbacks reactor)))
    (setf (gethash :vlr-objectmodified callbacks) callback-fn)
    (clautolisp.autolisp-runtime:add-reactor-to-document document reactor)
    (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           (clautolisp.autolisp-runtime:default-evaluation-context)))
      (clautolisp.autolisp-runtime:signal-document-event
       document :acdb :vlr-objectmodified '((modify-args))))
    (is (and fired-with
             (eq :vlr-objectmodified (first fired-with))))))

(test signal-document-event-skips-non-matching-kind
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (fired nil)
         (callback (clautolisp.autolisp-runtime:make-autolisp-subr
                    "ON" (lambda (r n a) (declare (ignore r n a)) (setf fired t))))
         (reactor (clautolisp.autolisp-runtime:make-reactor :kind :sysvar)))
    (setf (gethash :vlr-sysvarchanged
                   (clautolisp.autolisp-runtime:reactor-callbacks reactor))
          callback)
    (clautolisp.autolisp-runtime:add-reactor-to-document document reactor)
    ;; Send an :acdb event — the :sysvar reactor must not fire.
    (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           (clautolisp.autolisp-runtime:default-evaluation-context)))
      (clautolisp.autolisp-runtime:signal-document-event
       document :acdb :vlr-objectmodified '((args))))
    (is (null fired))))

(test inactive-reactor-does-not-fire
  (let* ((session (make-runtime-session))
         (document (clautolisp.autolisp-runtime:runtime-session-current-document
                    session))
         (fired nil)
         (callback (clautolisp.autolisp-runtime:make-autolisp-subr
                    "ON" (lambda (r n a) (declare (ignore r n a)) (setf fired t))))
         (reactor (clautolisp.autolisp-runtime:make-reactor :kind :acdb)))
    (setf (gethash :vlr-objectmodified
                   (clautolisp.autolisp-runtime:reactor-callbacks reactor))
          callback)
    (setf (clautolisp.autolisp-runtime:reactor-active-p reactor) nil)
    (clautolisp.autolisp-runtime:add-reactor-to-document document reactor)
    (let ((clautolisp.autolisp-runtime.internal::*active-evaluation-context*
           (clautolisp.autolisp-runtime:default-evaluation-context)))
      (clautolisp.autolisp-runtime:signal-document-event
       document :acdb :vlr-objectmodified '(())))
    (is (null fired))))
