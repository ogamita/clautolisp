(in-package #:clautolisp.autolisp-runtime.tests)

(in-suite autolisp-runtime-suite)

;;;; cador-2 multidocument conformance probes E1 / E2.
;;;;
;;;; E1 (symbol identity across namespaces, analysis doc E1 / D2 §I.4): symbols
;;;; are interned session-wide into ONE table (the symbol OBJECT is shared
;;;; everywhere), but each document namespace holds its OWN value cell, so the
;;;; same name has independent values per document and switching documents
;;;; switches which value is seen.
;;;;
;;;; E2 (blackboard copy-versus-share, analysis doc E2 / D2 §I.5): the
;;;; blackboard SHARES by identity — vl-bb-set stores the object and vl-bb-ref
;;;; returns the same object, across documents, with no copy.
;;;;
;;;; These are pure runtime properties (per-document namespaces + the one
;;;; per-session blackboard); cador holds drawings, not lisp namespaces, so the
;;;; probes live here and run deterministically under the shipped image. C3
;;;; (the blackboard must reject functions) is a separate, not-yet-implemented
;;;; code change and is intentionally NOT asserted here.
;;;;
;;;; %make-doc-context and %with-fresh-active-context are defined in
;;;; scheduler-tests.lisp (same package/suite, loaded first by the :serial
;;;; test system).

;;; --- E1: symbol identity + per-document value cells ---------------

(test e1-symbol-object-is-process-global
  ;; The symbol OBJECT is interned session-wide: the same name is the same
  ;; object everywhere (D2 §I.4 "global interning").
  (is (eq (intern-autolisp-symbol "E1-X") (intern-autolisp-symbol "E1-X"))))

(test e1-symbol-value-is-per-document
  ;; Each document namespace holds its own value cell for a symbol, so the same
  ;; name carries independent values in two documents.
  (let ((ns-a (make-document-namespace :name "E1-A"))
        (ns-b (make-document-namespace :name "E1-B"))
        (x    (intern-autolisp-symbol "E1-VAR"))
        (va   (intern-autolisp-symbol "E1-VAL-A"))
        (vb   (intern-autolisp-symbol "E1-VAL-B")))
    (document-namespace-set ns-a x va)
    (document-namespace-set ns-b x vb)
    (is (eq va (document-namespace-ref ns-a x)))
    (is (eq vb (document-namespace-ref ns-b x)))
    (is (not (eq (document-namespace-ref ns-a x)
                 (document-namespace-ref ns-b x))))))

(test e1-switching-document-switches-the-visible-value
  ;; Through the real switch path (scheduler-activate sets the active context):
  ;; the value a bare symbol resolves to follows the current document.
  (%with-fresh-active-context
    (let* ((session (make-runtime-session))
           (sched   (make-document-scheduler))
           (a (%make-doc-context session "E1S-A" "E1S-A"))
           (b (%make-doc-context session "E1S-B" "E1S-B"))
           (x  (intern-autolisp-symbol "E1S-VAR"))
           (va (intern-autolisp-symbol "E1S-VA"))
           (vb (intern-autolisp-symbol "E1S-VB")))
      (scheduler-register-context sched a)
      (scheduler-register-context sched b)
      (scheduler-activate sched a)
      (set-variable x va)                 ; no explicit context -> current (A)
      (scheduler-activate sched b)
      (set-variable x vb)
      (is (eq vb (lookup-variable x)))     ; B sees vb
      (scheduler-activate sched a)
      (is (eq va (lookup-variable x))))))   ; A still sees va

(test e1-symbol-identity-through-the-blackboard
  ;; A1 (§III): the blackboard round-trips the symbol OBJECT across documents,
  ;; confirming global interning. (eq (vl-bb-ref 'probe) 'my-symbol) across docs.
  (let* ((session (make-runtime-session))
         (ns-a (make-document-namespace :name "A1-A"))
         (ns-b (make-document-namespace :name "A1-B"))
         (ctx-a (make-evaluation-context :session session
                                         :current-document ns-a
                                         :current-namespace ns-a))
         (ctx-b (make-evaluation-context :session session
                                         :current-document ns-b
                                         :current-namespace ns-b))
         (probe (intern-autolisp-symbol "A1-PROBE"))
         (my    (intern-autolisp-symbol "A1-MY-SYMBOL")))
    (blackboard-set probe my ctx-a)
    (is (eq my (blackboard-ref probe ctx-b)))))

;;; --- E2: the blackboard shares by identity ------------------------

(test e2-blackboard-shares-by-identity-across-documents
  ;; vl-bb-set stores the object; vl-bb-ref returns the SAME object from another
  ;; document; no copy. (eq l (vl-bb-ref 'probe)) is t.
  (let* ((session (make-runtime-session))
         (ns-a (make-document-namespace :name "E2-A"))
         (ns-b (make-document-namespace :name "E2-B"))
         (ctx-a (make-evaluation-context :session session
                                         :current-document ns-a
                                         :current-namespace ns-a))
         (ctx-b (make-evaluation-context :session session
                                         :current-document ns-b
                                         :current-namespace ns-b))
         (probe (intern-autolisp-symbol "E2-PROBE"))
         (l     (list 1 2 3)))
    (blackboard-set probe l ctx-a)
    (is (eq l (blackboard-ref probe ctx-b)))    ; B reads the same object
    (is (eq l (blackboard-ref probe ctx-a)))))  ; A still the same object
