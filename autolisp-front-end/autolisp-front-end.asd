;;;; autolisp-front-end/autolisp-front-end.asd
;;;;
;;;; ASDF wrapper for the `alfe` (AutoLISP Front-End) subproject:
;;;; a Common Lisp rewrite of the historical bash `autolisp-script`
;;;; on top of the clautolisp/autolisp-* modules. See
;;;; documentation/alfe--specifications.org for the canonical spec
;;;; and ../issues/open/alfe.plan for the implementation plan.
;;;;
;;;; The system decomposition mirrors the alfe-skeleton.issue ticket:
;;;;
;;;;   autolisp-front-end                  aggregate, depends on every
;;;;                                       subsystem below
;;;;   autolisp-front-end/core             error / logging / workdir /
;;;;                                       backend interface / cli
;;;;   autolisp-front-end/backend-clautolisp  Phase 1, stub for now
;;;;   autolisp-front-end/file-protocol    Phase 2, stub for now
;;;;   autolisp-front-end/backend-bricscad Phase 3, stub for now
;;;;   autolisp-front-end/backend-autocad  Phase 3, stub for now
;;;;   autolisp-front-end/alfe-tool        the alfe executable build
;;;;   autolisp-front-end/tests            FiveAM tests (smoke + future)
;;;;
;;;; The Phase 2-3 stubs exist so the aggregate system loads cleanly
;;;; on a fresh checkout; later tickets fill them in.

(asdf:defsystem "autolisp-front-end"
  :description "alfe — single CLI front-end driving clautolisp (in-process or subprocess) and CAD-resident AutoLISP REPLs via a file-IPC protocol."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end/core"
               "autolisp-front-end/backend-clautolisp"
               "autolisp-front-end/file-protocol"
               "autolisp-front-end/backend-bricscad"
               "autolisp-front-end/backend-autocad")
  ;; Test-op on the aggregate delegates to the /tests system, which
  ;; carries the perform method that actually invokes run-all-tests.
  ;; Keep this side clean (no second :perform) so the suite isn't
  ;; double-executed.
  :in-order-to ((asdf:test-op
                 (asdf:test-op "autolisp-front-end/tests"))))

(asdf:defsystem "autolisp-front-end/core"
  :description "alfe core: error hierarchy, logging, workdir helpers, abstract backend protocol, CLI dispatch."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host"
               "uiop")
  :serial t
  :components
  ((:file "source/error")
   (:file "source/logging")
   (:file "source/workdir")
   (:file "source/backend")
   (:file "source/backend-echo")
   (:file "source/cli")))

(asdf:defsystem "autolisp-front-end/backend-clautolisp"
  :description "alfe backend driving clautolisp in-process or as a subprocess."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end/core"
               "trivial-gray-streams")
  :serial t
  :components
  ((:file "source/backend-clautolisp")))

(asdf:defsystem "autolisp-front-end/file-protocol"
  :description "alfe file-IPC protocol driver shared by the CAD backends (Phase 2, stub)."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end/core")
  :serial t
  :components
  ((:file "source/file-protocol-stub")))

(asdf:defsystem "autolisp-front-end/backend-bricscad"
  :description "alfe backend driving BricsCAD via the file-IPC protocol (Phase 3, stub)."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end/core"
               "autolisp-front-end/file-protocol")
  :serial t
  :components
  ((:file "source/backend-bricscad-stub")))

(asdf:defsystem "autolisp-front-end/backend-autocad"
  :description "alfe backend driving AutoCAD via the file-IPC protocol (Phase 3, stub)."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end/core"
               "autolisp-front-end/file-protocol")
  :serial t
  :components
  ((:file "source/backend-autocad-stub")))

(asdf:defsystem "autolisp-front-end/alfe-tool"
  :description "Standalone alfe executable built on top of the front-end core."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end")
  :serial t
  :components
  ((:file "tools/alfe/source/package")
   (:file "tools/alfe/source/version")
   (:file "tools/alfe/source/main")))

(asdf:defsystem "autolisp-front-end/tests"
  :description "FiveAM tests for the alfe front-end (smoke + per-ticket suites)."
  :author "Pascal J. Bourguignon"
  :license "AGPL-3.0"
  :depends-on ("autolisp-front-end" "fiveam")
  :serial t
  :components
  ((:file "tests/package")
   (:file "tests/test-harness")
   (:file "tests/smoke-tests")
   (:file "tests/backend-tests")
   (:file "tests/cli-tests")
   (:file "tests/backend-clautolisp-tests")
   (:file "tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :autolisp-front-end.tests
                                           :run-all-tests)))
