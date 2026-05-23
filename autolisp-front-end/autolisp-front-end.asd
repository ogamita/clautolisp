;;;; autolisp-front-end/autolisp-front-end.asd
;;;;
;;;; ASDF wrapper for the `alfe` (AutoLISP Front-End) subproject:
;;;; a Common Lisp rewrite of the historical bash `autolisp-script`
;;;; on top of the clautolisp/autolisp-* modules. See
;;;; documentation/alfe--specifications.org for the canonical spec.
;;;;
;;;; The system declarations below are scaffolding: source files are
;;;; added incrementally as the alfe-* tickets under
;;;; ../issues/open/ land. The skeleton system depends on the
;;;; clautolisp evaluator + reader + builtins so that the
;;;; clautolisp-direct backend can simply (in-package :alfe.backend.clautolisp)
;;;; and call the runtime APIs.

(asdf:defsystem "autolisp-front-end"
  :description "alfe — single CLI front-end driving clautolisp (in-process or subprocess) and CAD-resident AutoLISP REPLs via a file-IPC protocol."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host")
  :components
  ;; Stubs only — the per-area packages and source files are
  ;; introduced by the alfe-skeleton.issue, alfe-cli.issue, etc.
  ;; tickets. Listed here as a single placeholder pathname so the
  ;; system loads cleanly on a fresh checkout.
  ((:module "source"
    :components ())))
