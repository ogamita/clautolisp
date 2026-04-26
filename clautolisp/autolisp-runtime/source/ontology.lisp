(in-package #:clautolisp.autolisp-runtime)

;;;; Host-object ontology, lifecycle states, and reactor event channel.
;;;;
;;;; Phase 14a + 14b of the implementation roadmap. Mirrors the
;;;; design document (clautolisp/documentation/design.org) and the
;;;; normative section in autolisp-spec chapter 21
;;;; ("Host Object Ontology and Lifecycles").
;;;;
;;;; This module owns:
;;;;
;;;;   - the lifecycle-state vocabulary
;;;;   - the `reactor` struct
;;;;   - the public event-emission helpers (signal-document-event,
;;;;     signal-application-event)
;;;;   - the per-document and per-application reactor registries
;;;;     (the slots themselves live on document-namespace and
;;;;     runtime-session in model.lisp)
;;;;   - persistence of reactors against the document's named-object
;;;;     dictionary (Phase 14b)
;;;;
;;;; Backends call signal-document-event / signal-application-event
;;;; whenever a host-observable transition occurs. Reactor builtins
;;;; (vlr-*-reactor / vlr-add / vlr-remove / vlr-pers / ...) live in
;;;; autolisp-builtins-core and consume this surface.

;;; --- Reactor data model -----------------------------------------

(defstruct reactor
  "AutoLISP-visible reactor. KIND is the reactor-type keyword
(:object, :acdb, :command, :sysvar, ...). SCOPE is :document or
:application — matched against where the registry slot lives.
CALLBACKS maps reaction-name keyword to an AutoLISP callable
(typically an autolisp-symbol; persistent reactors require a
symbol so they round-trip across snapshot/restore). OWNERS is
the user-supplied list of objects (entity ENAMEs, dictionary
keys, etc.) — only object-/entity-style reactors filter on it."
  (id           (gensym "VLR-") :type t)
  (kind         :object :type keyword)
  (scope        :document :type keyword)
  (callbacks    (make-hash-table :test #'eq))
  (owners       '() :type list)
  (data         nil)
  (active-p     t :type boolean)
  (persistent-p nil :type boolean)
  (notification :all-documents :type keyword)
  (document     nil))

;;; --- Reactor-type metadata --------------------------------------
;;
;; Each entry: keyword -> (scope . canonical-reactor-type-name).
;; Used by signal-* helpers to dispatch and by the vlr-* builtin
;; family to validate constructor arguments.

(defparameter *reactor-type-table*
  '((:acdb           :document     "VLR-Acdb-Reactor")
    (:command        :document     "VLR-Command-Reactor")
    (:deepclone      :document     "VLR-DeepClone-Reactor")
    (:document       :document     "VLR-Document-Reactor")
    (:dwg            :document     "VLR-DWG-Reactor")
    (:dxf            :document     "VLR-DXF-Reactor")
    (:insert         :document     "VLR-Insert-Reactor")
    (:mouse          :document     "VLR-Mouse-Reactor")
    (:object         :document     "VLR-Object-Reactor")
    (:sysvar         :document     "VLR-SysVar-Reactor")
    (:toolbar        :document     "VLR-Toolbar-Reactor")
    (:undo           :document     "VLR-Undo-Reactor")
    (:wblock         :document     "VLR-Wblock-Reactor")
    (:window         :document     "VLR-Window-Reactor")
    (:xref           :document     "VLR-Xref-Reactor")
    (:docmanager     :application  "VLR-DocManager-Reactor")
    (:editor         :application  "VLR-Editor-Reactor")
    (:linker         :application  "VLR-Linker-Reactor")
    (:lisp           :application  "VLR-Lisp-Reactor")
    (:miscellaneous  :application  "VLR-Miscellaneous-Reactor"))
  "Canonical reactor-type registry. Each row is
(KIND-KEYWORD SCOPE TYPE-NAME-STRING).")

(defun reactor-type-scope (kind)
  (or (second (assoc kind *reactor-type-table*))
      (signal-autolisp-runtime-error
       :unknown-reactor-type
       "Unknown reactor type ~S; expected one of ~S."
       kind (mapcar #'first *reactor-type-table*))))

(defun reactor-type-name (kind)
  (or (third (assoc kind *reactor-type-table*))
      (signal-autolisp-runtime-error
       :unknown-reactor-type
       "Unknown reactor type ~S." kind)))

(defun reactor-type-keywords ()
  (mapcar #'first *reactor-type-table*))

;;; --- Re-entry depth limit ---------------------------------------

(defparameter *reactor-recursion-cap* 16)
(defvar *reactor-recursion-depth* 0)

;;; --- Internal: registry access ---------------------------------

(defun document-reactor-registry (document)
  (clautolisp.autolisp-runtime.internal::document-namespace-reactors document))

(defun session-reactor-registry (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-application-reactors session))

(defun add-reactor-to-document (document reactor)
  (setf (gethash (reactor-id reactor) (document-reactor-registry document)) reactor)
  (setf (reactor-document reactor) document)
  reactor)

(defun add-reactor-to-session (session reactor)
  (setf (gethash (reactor-id reactor) (session-reactor-registry session)) reactor)
  reactor)

(defun remove-reactor-from-document (document reactor)
  (remhash (reactor-id reactor) (document-reactor-registry document))
  reactor)

(defun remove-reactor-from-session (session reactor)
  (remhash (reactor-id reactor) (session-reactor-registry session))
  reactor)

(defun all-document-reactors (document)
  (let ((result '()))
    (maphash (lambda (id reactor) (declare (ignore id)) (push reactor result))
             (document-reactor-registry document))
    result))

(defun all-application-reactors (session)
  (let ((result '()))
    (maphash (lambda (id reactor) (declare (ignore id)) (push reactor result))
             (session-reactor-registry session))
    result))

(defun all-session-reactors (session)
  (let ((acc (all-application-reactors session)))
    (maphash (lambda (name document)
               (declare (ignore name))
               (dolist (reactor (all-document-reactors document))
                 (push reactor acc)))
             (clautolisp.autolisp-runtime.internal::runtime-session-document-namespaces
              session))
    acc))

;;; --- Event-trace helper (for tests) ----------------------------

(defun trace-event (session record)
  ;; The trace slot holds either nil (no trace bound) or a one-cell
  ;; mutable container whose CAR is the running records list. We use
  ;; this two-state shape so that trace-event can distinguish "trace
  ;; active but empty" from "no trace bound" without conflating with
  ;; the empty-list sentinel.
  (let ((trace
         (clautolisp.autolisp-runtime.internal::runtime-session-event-trace session)))
    (when trace
      (setf (car trace) (cons record (car trace))))))

(defun runtime-session-event-trace (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-event-trace session))

(defun set-runtime-session-event-trace (session value)
  (setf (clautolisp.autolisp-runtime.internal::runtime-session-event-trace session)
        value))

(defmacro with-event-trace ((trace-var session) &body body)
  "Capture every signal-*-event call made within BODY into
TRACE-VAR (a list of records, oldest-first). Resets the session's
event-trace slot afterwards."
  (let ((session-sym (gensym "SESSION"))
        (prior-sym (gensym "PRIOR")))
    `(let* ((,session-sym ,session)
            (,prior-sym (runtime-session-event-trace ,session-sym)))
       (set-runtime-session-event-trace ,session-sym '())
       (unwind-protect
            (multiple-value-prog1
                (progn ,@body)
              (let ((,trace-var
                     (reverse (runtime-session-event-trace ,session-sym))))
                (declare (ignorable ,trace-var))
                ,@body
                ,trace-var))
         (set-runtime-session-event-trace ,session-sym ,prior-sym)))))

;; (with-event-trace TRACE-VAR re-evaluates BODY; we want a single
;; evaluation. Provide the simpler `call-with-event-trace` instead
;; and let tests use it directly.)

(defun call-with-event-trace (session thunk)
  "Execute THUNK with SESSION's event-trace slot bound to a fresh
collector. Returns the list of trace records (oldest-first).
Restores the prior trace slot on unwind."
  (let* ((prior (runtime-session-event-trace session))
         (collector (cons nil nil)))
    (set-runtime-session-event-trace session collector)
    (unwind-protect
         (progn
           (funcall thunk)
           (reverse (car collector)))
      (set-runtime-session-event-trace session prior))))

;;; --- Public emission API ---------------------------------------

(defun signal-document-event (document kind reaction-name args)
  "Notify reactors subscribed to KIND on DOCUMENT that
REACTION-NAME just fired with ARGS. The dispatch loop consults
the reactor's CALLBACKS table for an entry under REACTION-NAME;
nothing happens for reactors that do not subscribe to that name."
  (let* ((session (find-document-session document))
         (record (list :document
                       (and document (document-namespace-name document))
                       kind reaction-name args)))
    (cond
      (session (trace-event session record))
      ;; If we cannot resolve the document to a session (e.g.
      ;; tests that constructed an isolated session without
      ;; binding the active evaluation context), trace into the
      ;; default-evaluation-context's session if one is bound.
      ((let* ((default (default-evaluation-context))
              (default-session
                (and default (evaluation-context-session default))))
         (when default-session (trace-event default-session record)))))
    (when document
      (dispatch-reactors (all-document-reactors document)
                         kind reaction-name args
                         :document document))
    nil))

(defun signal-application-event (session kind reaction-name args)
  "Notify reactors subscribed to KIND on SESSION that
REACTION-NAME just fired with ARGS."
  (let ((record (list :application nil kind reaction-name args)))
    (trace-event session record))
  (when session
    (dispatch-reactors (all-application-reactors session)
                       kind reaction-name args
                       :session session))
  nil)

(defun find-document-session (document)
  "Return the session owning DOCUMENT, or nil if it cannot be
resolved. Uses the back-pointer installed by make-runtime-session
when the document was constructed; falls back to the active
evaluation context's session for documents that have no back-
pointer (e.g. constructed via internal::make-document-namespace
in tests)."
  (and document
       (or (clautolisp.autolisp-runtime.internal::document-namespace-session
            document)
           (let ((active
                  clautolisp.autolisp-runtime.internal::*active-evaluation-context*))
             (and active (evaluation-context-session active))))))

(defun dispatch-reactors (reactors kind reaction-name args &key document session)
  (let ((*reactor-recursion-depth* (1+ *reactor-recursion-depth*)))
    (when (> *reactor-recursion-depth* *reactor-recursion-cap*)
      (signal-autolisp-runtime-error
       :reactor-recursion-limit
       "Reactor dispatch exceeded the configured recursion cap (~D)."
       *reactor-recursion-cap*))
    (dolist (reactor reactors)
      (when (and (reactor-active-p reactor)
                 (eq (reactor-kind reactor) kind)
                 (gethash reaction-name (reactor-callbacks reactor))
                 (reactor-passes-notification-filter-p reactor document session))
        (invoke-reactor-callback reactor reaction-name args)))))

(defun reactor-passes-notification-filter-p (reactor document session)
  (declare (ignore session))
  (case (reactor-notification reactor)
    ((:current-document-only)
     (or (null document)
         (eq document (reactor-document reactor))))
    (otherwise t)))

(defun invoke-reactor-callback (reactor reaction-name args)
  (let* ((callback (gethash reaction-name (reactor-callbacks reactor)))
         (target (cond
                   ((typep callback 'autolisp-symbol)
                    (handler-case (resolve-autolisp-function-designator callback)
                      (autolisp-runtime-error () nil)))
                   ((or (typep callback 'autolisp-subr)
                        (typep callback 'autolisp-usubr))
                    callback)
                   (t nil))))
    (cond
      (target
       (handler-case
           (call-autolisp-function target reactor reaction-name args)
         (autolisp-runtime-error (condition)
           ;; Don't tear down the host on a single bad callback;
           ;; record and continue.
           (declare (ignore condition))
           nil)))
      (t
       ;; Symbol resolved to nothing — log via the prompt-output
       ;; stream if a host is reachable; otherwise silently drop.
       nil))))

;;; --- Convenience: lifecycle state mutators ----------------------

(defun set-document-state (document state)
  "Transition DOCUMENT to STATE and emit the canonical
*WillChange / *Changed reaction pair where the documented
mapping calls for it. Only the high-traffic transitions are
modelled here; per-event helpers may add more in later phases."
  (let ((old (document-namespace-state document)))
    (case state
      (:active
       (signal-document-event document :document :vlr-documentToBeActivated
                              (list document))
       (signal-application-event (find-document-session document)
                                 :docmanager :vlr-documentToBeActivated
                                 (list document))
       (setf (clautolisp.autolisp-runtime.internal::document-namespace-state document)
             state)
       (signal-document-event document :document :vlr-documentBecameCurrent
                              (list document))
       (signal-application-event (find-document-session document)
                                 :docmanager :vlr-documentBecameCurrent
                                 (list document)))
      (:inactive
       (signal-document-event document :document :vlr-documentToBeDeactivated
                              (list document))
       (setf (clautolisp.autolisp-runtime.internal::document-namespace-state document)
             state)
       (signal-document-event document :document :vlr-documentBecameNotCurrent
                              (list document)))
      (:closing
       (signal-document-event document :document :vlr-beginDocumentClose
                              (list document))
       (signal-application-event (find-document-session document)
                                 :docmanager :vlr-documentToBeDestroyed
                                 (list document))
       (setf (clautolisp.autolisp-runtime.internal::document-namespace-state document)
             state))
      (:closed
       (setf (clautolisp.autolisp-runtime.internal::document-namespace-state document)
             state)
       (signal-application-event (find-document-session document)
                                 :docmanager :vlr-documentDestroyed
                                 (list document)))
      (otherwise
       (setf (clautolisp.autolisp-runtime.internal::document-namespace-state document)
             state)))
    (values old state)))

(defun set-application-state (session state)
  (let ((old (clautolisp.autolisp-runtime.internal::runtime-session-application-state
              session)))
    (when (and (eq state :quitting) (not (eq old :quitting)))
      (signal-application-event session :editor :vlr-beginQuit (list session))
      (signal-application-event session :miscellaneous :vlr-beginQuit (list session)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-application-state
           session) state)
    (when (eq state :quit)
      (signal-application-event session :editor :vlr-endLogFile (list session)))
    (values old state)))

;;; --- Application / document state accessors ---------------------

(defun runtime-session-application-state (session)
  (clautolisp.autolisp-runtime.internal::runtime-session-application-state session))

(defun document-namespace-state (document)
  (clautolisp.autolisp-runtime.internal::document-namespace-state document))

;;; --- Persistent-reactor index ----------------------------------

(defun document-namespace-persistent-reactor-index (document)
  (clautolisp.autolisp-runtime.internal::document-namespace-persistent-reactor-index document))
