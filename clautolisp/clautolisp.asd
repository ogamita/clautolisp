(asdf:defsystem "clautolisp"
  :description "Aggregate clautolisp implementation systems."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host"
               "clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-dcl"
               "clautolisp/autolisp-file-compat")
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-reader"
  :description "AutoLISP reader subsystem for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("uiop")
  :serial t
  :components
  ((:file "autolisp-reader/source/package")
   (:file "autolisp-reader/source/model")
   (:file "autolisp-reader/source/dialect")
   (:file "autolisp-reader/source/input")
   (:file "autolisp-reader/source/tokenizer")
   (:file "autolisp-reader/source/parser")
   (:file "autolisp-reader/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-reader/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-runtime"
  :description "Core AutoLISP runtime object model for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader" "uiop")
  :serial t
  :components
  ((:file "autolisp-runtime/source/package")
   (:file "autolisp-runtime/source/model")
   (:file "autolisp-runtime/source/api")
   (:file "autolisp-runtime/source/ontology"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-runtime/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-host"
  :description "Host Abstraction Layer (HAL) and NullHost backend for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime")
  :serial t
  :components
  ((:file "autolisp-host/source/package")
   (:file "autolisp-host/source/protocol")
   (:file "autolisp-host/source/null-host"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-host/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-mock-host"
  :description "In-memory deterministic CAD-database backend (MockHost) for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-host" "clautolisp/autolisp-runtime")
  :serial t
  :components
  ((:file "autolisp-mock-host/source/package")
   (:file "autolisp-mock-host/source/model")
   (:file "autolisp-mock-host/source/sysvars")
   (:file "autolisp-mock-host/source/api")
   (:file "autolisp-mock-host/source/entity-api")
   (:file "autolisp-mock-host/source/selection-api")
   (:file "autolisp-mock-host/source/table-api")
   (:file "autolisp-mock-host/source/sysvar-api")
   (:file "autolisp-mock-host/source/prompt-api")
   (:file "autolisp-mock-host/source/com-progids")
   (:file "autolisp-mock-host/source/vlax-api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-mock-host/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-dcl"
  :description "Dialog Control Language (DCL) implementation for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime")
  :serial t
  :components
  ((:file "autolisp-dcl/source/package")
   (:file "autolisp-dcl/source/model")
   (:file "autolisp-dcl/source/parser")
   (:file "autolisp-dcl/source/runtime")
   (:file "autolisp-dcl/source/terminal"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-dcl/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-builtins-core"
  :description "Initial core builtin registry for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-dcl"
               "uiop")
  :serial t
  :components
  ((:file "autolisp-builtins-core/source/package")
   (:file "autolisp-builtins-core/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-builtins-core/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-file-compat"
  :description "Compatibility-audit harness for AutoLISP file and stream behavior."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core"
               "uiop")
  :serial t
  :components
  ((:file "autolisp-file-compat/source/package")
   (:file "autolisp-file-compat/source/model")
   (:file "autolisp-file-compat/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-file-compat/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/read-autolisp"
  :description "Command-line reader validation tool for AutoLISP source."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader" "uiop")
  :serial t
  :components
  ((:file "autolisp-reader/tools/read-autolisp/source/package")
   (:file "autolisp-reader/tools/read-autolisp/source/main")))

(asdf:defsystem "clautolisp/clautolisp-tool"
  :description "Standalone AutoLISP evaluator built on top of the clautolisp runtime."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host"
               "clautolisp/autolisp-builtins-core"
               "uiop")
  :serial t
  :components
  ((:file "tools/clautolisp/source/package")
   (:file "tools/clautolisp/source/version")
   (:file "tools/clautolisp/source/main")))

(asdf:defsystem "clautolisp/run-file-compat"
  :description "Command-line compatibility runner for file scenarios."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-file-compat" "uiop")
  :serial t
  :components
  ((:file "autolisp-file-compat/tools/run-file-compat/source/package")
   (:file "autolisp-file-compat/tools/run-file-compat/source/main")))

(asdf:defsystem "clautolisp/autolisp-reader/tests"
  :description "Tests for the clautolisp AutoLISP reader subsystem."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader" "fiveam")
  :serial t
  :components
  ((:file "autolisp-reader/tests/package")
   (:file "autolisp-reader/tests/test-harness")
   (:file "autolisp-reader/tests/tokenizer-tests")
   (:file "autolisp-reader/tests/parser-tests")
   (:file "autolisp-reader/tests/dialect-tests")
   (:file "autolisp-reader/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-host/tests"
  :description "Tests for the clautolisp Host Abstraction Layer."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-host" "fiveam")
  :serial t
  :components
  ((:file "autolisp-host/tests/package")
   (:file "autolisp-host/tests/test-harness")
   (:file "autolisp-host/tests/null-host-tests")
   (:file "autolisp-host/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-host.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-mock-host/tests"
  :description "Tests for the clautolisp MockHost data carriers."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-mock-host" "fiveam")
  :serial t
  :components
  ((:file "autolisp-mock-host/tests/package")
   (:file "autolisp-mock-host/tests/test-harness")
   (:file "autolisp-mock-host/tests/model-tests")
   (:file "autolisp-mock-host/tests/entity-api-tests")
   (:file "autolisp-mock-host/tests/selection-tests")
   (:file "autolisp-mock-host/tests/prompt-tests")
   (:file "autolisp-mock-host/tests/vlax-tests")
   (:file "autolisp-mock-host/tests/reactor-tests")
   (:file "autolisp-mock-host/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-mock-host.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-dcl/tests"
  :description "Tests for the clautolisp DCL subsystem."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-dcl" "fiveam")
  :serial t
  :components
  ((:file "autolisp-dcl/tests/package")
   (:file "autolisp-dcl/tests/test-harness")
   (:file "autolisp-dcl/tests/parser-tests")
   (:file "autolisp-dcl/tests/runtime-tests")
   (:file "autolisp-dcl/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-dcl.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-runtime/tests"
  :description "Tests for the clautolisp AutoLISP runtime object model."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime" "fiveam")
  :serial t
  :components
  ((:file "autolisp-runtime/tests/package")
   (:file "autolisp-runtime/tests/test-harness")
   (:file "autolisp-runtime/tests/model-tests")
   (:file "autolisp-runtime/tests/evaluator-tests")
   (:file "autolisp-runtime/tests/ontology-tests")
   (:file "autolisp-runtime/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-runtime.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-builtins-core/tests"
  :description "Tests for the initial clautolisp core builtins."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-mock-host"
               "fiveam")
  :serial t
  :components
  ((:file "autolisp-builtins-core/tests/package")
   (:file "autolisp-builtins-core/tests/test-harness")
   (:file "autolisp-builtins-core/tests/builtin-tests")
   (:file "autolisp-builtins-core/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-builtins-core.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-file-compat/tests"
  :description "Tests for the clautolisp file compatibility harness."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-file-compat" "fiveam")
  :serial t
  :components
  ((:file "autolisp-file-compat/tests/package")
   (:file "autolisp-file-compat/tests/test-harness")
   (:file "autolisp-file-compat/tests/api-tests")
   (:file "autolisp-file-compat/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-file-compat.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/tests"
  :description "Aggregate tests for the clautolisp subproject."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader/tests"
               "clautolisp/autolisp-runtime/tests"
               "clautolisp/autolisp-host/tests"
               "clautolisp/autolisp-mock-host/tests"
               "clautolisp/autolisp-dcl/tests"
               "clautolisp/autolisp-builtins-core/tests"
               "clautolisp/autolisp-file-compat/tests")
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (progn
                           (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-runtime.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-host.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-mock-host.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-dcl.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-builtins-core.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-file-compat.tests
                                             :run-all-tests))))
