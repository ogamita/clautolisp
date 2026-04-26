(asdf:defsystem "clautolisp"
  :description "Aggregate clautolisp implementation systems."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core"
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
   (:file "autolisp-runtime/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-runtime/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-builtins-core"
  :description "Initial core builtin registry for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime" "uiop")
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
               "clautolisp/autolisp-builtins-core"
               "uiop")
  :serial t
  :components
  ((:file "tools/clautolisp/source/package")
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
   (:file "autolisp-runtime/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-runtime.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-builtins-core/tests"
  :description "Tests for the initial clautolisp core builtins."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-builtins-core" "fiveam")
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
               "clautolisp/autolisp-builtins-core/tests"
               "clautolisp/autolisp-file-compat/tests")
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (progn
                           (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-runtime.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-builtins-core.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-file-compat.tests
                                             :run-all-tests))))
