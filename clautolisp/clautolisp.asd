(asdf:defsystem "clautolisp"
  :description "Aggregate clautolisp implementation systems."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-source-map"
               "clautolisp/autolisp-runtime"
               "clautolisp/drawing"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host"
               "clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-cli"
               "clautolisp/autolisp-dcl"
               "clautolisp/autolisp-file-compat"
               "clautolisp/autolisp-init-files"
               "clautolisp/autolisp-debug"
               "clautolisp/autolisp-inspect"
               "clautolisp/autolisp-debug-ui"
               "clautolisp/autolisp-debug-ui-dumb"
               "clautolisp/autolisp-debug-ui-tui"
               "clautolisp/autolisp-debug-ui-ncurses")
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

(asdf:defsystem "clautolisp/autolisp-source-map"
  :description "Source-position map carrying reader positions into the runtime (debugger §3)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader")
  :serial t
  :components
  ((:file "autolisp-source-map/source/package")
   (:file "autolisp-source-map/source/source-map"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-source-map/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-runtime"
  :description "Core AutoLISP runtime object model for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader" "clautolisp/autolisp-source-map" "uiop")
  :serial t
  :components
  ((:file "autolisp-runtime/source/package")
   (:file "autolisp-runtime/source/model")
   (:file "autolisp-runtime/source/terminal-color")
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

(asdf:defsystem "clautolisp/drawing"
  :description "The drawing value object: a first-class, backend-independent CAD drawing database (Phase 17a)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime")
  :serial t
  :components
  ((:file "drawing/source/package")
   (:file "drawing/source/model")
   (:file "drawing/source/conditions")
   (:file "drawing/source/api")
   (:file "drawing/source/persistence")
   (:file "drawing/source/dxf"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/drawing/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/drawing-dwg"
  :description "DWG codec backed by the vendored libredwg via a CFFI'd C shim (Phase 17e). Optional: NOT part of the core clautolisp aggregate; requires the libredwg shim built (make build-libredwg) and CFFI."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/drawing" "cffi" "uiop")
  :serial t
  :components
  ((:file "drawing-dwg/source/package")
   (:file "drawing-dwg/source/bindings")
   (:file "drawing-dwg/source/codec"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/drawing-dwg/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/drawing-dwg/tests"
  :description "Tests for the clautolisp DWG codec (libredwg)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/drawing-dwg" "fiveam")
  :serial t
  :components
  ((:file "drawing-dwg/tests/package")
   (:file "drawing-dwg/tests/test-harness")
   (:file "drawing-dwg/tests/dwg-tests")
   (:file "drawing-dwg/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.drawing.dwg.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-mock-host"
  :description "In-memory deterministic CAD-database backend (MockHost) for clautolisp."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-host" "clautolisp/autolisp-runtime"
               "clautolisp/drawing")
  :serial t
  :components
  ((:file "autolisp-mock-host/source/package")
   (:file "autolisp-mock-host/source/model")
   (:file "autolisp-mock-host/source/sysvar-catalogue")
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
   (:file "autolisp-dcl/source/sexp-wire")
   (:file "autolisp-dcl/source/subprocess-renderer")
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
   (:file "autolisp-builtins-core/source/secureload")
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
   (:file "autolisp-reader/tools/read-autolisp/source/version")
   (:file "autolisp-reader/tools/read-autolisp/source/main")))

(asdf:defsystem "clautolisp/autolisp-cli"
  :description "Shared CLI option parser + *AUTOLISP-…* variable installer for clautolisp and alfe."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime"
               "clautolisp/autolisp-host"
               ;; for APPLY-DIALECT-TRUST-SYSVAR-DEFAULTS, the launch-time
               ;; dialect-dependent SECURELOAD / TRUSTEDPATHS overlay.
               "clautolisp/autolisp-builtins-core")
  :serial t
  :components
  ((:file "autolisp-cli/source/package")
   (:file "autolisp-cli/source/conditions")
   (:file "autolisp-cli/source/encoding")
   (:file "autolisp-cli/source/options")
   (:file "autolisp-cli/source/spec")
   (:file "autolisp-cli/source/parser")
   (:file "autolisp-cli/source/transmit"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-cli/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/clautolisp-tool"
  :description "Standalone AutoLISP evaluator built on top of the clautolisp runtime."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-host"
               "clautolisp/autolisp-mock-host"
               "clautolisp/autolisp-builtins-core"
               "clautolisp/autolisp-cli"
               "clautolisp/autolisp-dcl"
               "clautolisp/autolisp-init-files"
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

(asdf:defsystem "clautolisp/drawing/tests"
  :description "Tests for the clautolisp drawing CL API (Phase 17b)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/drawing" "fiveam")
  :serial t
  :components
  ((:file "drawing/tests/package")
   (:file "drawing/tests/test-harness")
   (:file "drawing/tests/api-tests")
   (:file "drawing/tests/persistence-tests")
   (:file "drawing/tests/dxf-tests")
   (:file "drawing/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.drawing.tests
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
   (:file "autolisp-mock-host/tests/sysvar-catalogue-tests")
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
   (:file "autolisp-dcl/tests/sexp-wire-tests")
   (:file "autolisp-dcl/tests/subprocess-renderer-tests")
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
   (:file "autolisp-builtins-core/tests/errno-coupling-tests")
   (:file "autolisp-builtins-core/tests/clal-extensions-tests")
   (:file "autolisp-builtins-core/tests/secureload-dialect-tests")
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

(asdf:defsystem "clautolisp/autolisp-init-files"
  :description "User init-file discovery (~/.clautolisp / ~/.alfe / ~/.autolisp + their .config/ siblings) shared by clautolisp and alfe."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("uiop")
  :serial t
  :components
  ((:file "autolisp-init-files/source/package")
   (:file "autolisp-init-files/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-init-files/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-init-files/tests"
  :description "FiveAM tests for clautolisp.autolisp-init-files."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-init-files" "fiveam")
  :serial t
  :components
  ((:file "autolisp-init-files/tests/package")
   (:file "autolisp-init-files/tests/api-tests")
   (:file "autolisp-init-files/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-init-files.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-debug"
  :description "Clautolisp debugger engine: instrumentation, poll points, breakpoints (debugger Phase 1)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime"
               "clautolisp/autolisp-source-map"
               "bordeaux-threads")
  :serial t
  :components
  ((:file "autolisp-debug/source/package")
   (:file "autolisp-debug/source/metadata")
   (:file "autolisp-debug/source/breakpoints")
   (:file "autolisp-debug/source/snapshot")
   (:file "autolisp-debug/source/stepping")
   (:file "autolisp-debug/source/poll")
   (:file "autolisp-debug/source/error")
   (:file "autolisp-debug/source/instrument")
   (:file "autolisp-debug/source/session"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-inspect"
  :description "AutoLISP value inspector (debugger Part IV): pages, accessors, navigation, path expressions, workspace."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime")
  :serial t
  :components
  ((:file "autolisp-inspect/source/package")
   (:file "autolisp-inspect/source/workspace")
   (:file "autolisp-inspect/source/page")
   (:file "autolisp-inspect/source/session"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-inspect/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-inspect/tests"
  :description "FiveAM tests for the clautolisp inspector."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-inspect" "clautolisp/autolisp-runtime" "fiveam")
  :serial t
  :components
  ((:file "autolisp-inspect/tests/package")
   (:file "autolisp-inspect/tests/inspect-tests")
   (:file "autolisp-inspect/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.inspect.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-debug-ui"
  :description "Debugger UI protocol + session lifecycle (debugger §17, §21–§24)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-runtime"
               "clautolisp/autolisp-debug"
               "clautolisp/autolisp-inspect"
               "clautolisp/autolisp-source-map")
  :serial t
  :components
  ((:file "autolisp-debug-ui/source/package")
   (:file "autolisp-debug-ui/source/protocol")
   (:file "autolisp-debug-ui/source/session")
   (:file "autolisp-debug-ui/source/settings")
   (:file "autolisp-debug-ui/source/decorations"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug-ui-dumb/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-debug-ui-dumb"
  :description "Dumb-terminal debugger UI (debugger §18)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui")
  :serial t
  :components
  ((:file "autolisp-debug-ui-dumb/source/package")
   (:file "autolisp-debug-ui-dumb/source/dumb-ui"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug-ui-dumb/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-debug-ui-dumb/tests"
  :description "FiveAM tests for the dumb-terminal debugger UI + UI protocol."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui-dumb" "fiveam")
  :serial t
  :components
  ((:file "autolisp-debug-ui-dumb/tests/package")
   (:file "autolisp-debug-ui-dumb/tests/dumb-ui-tests")
   (:file "autolisp-debug-ui-dumb/tests/settings-tests")
   (:file "autolisp-debug-ui-dumb/tests/decorations-tests")
   (:file "autolisp-debug-ui-dumb/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.ui.dumb.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-source-map/tests"
  :description "FiveAM tests for clautolisp.source."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-source-map" "clautolisp/autolisp-runtime" "fiveam")
  :serial t
  :components
  ((:file "autolisp-source-map/tests/package")
   (:file "autolisp-source-map/tests/source-map-tests")
   (:file "autolisp-source-map/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.source.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-debug/tests"
  :description "FiveAM tests for the clautolisp debugger engine."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug"
               "clautolisp/autolisp-source-map"
               "clautolisp/autolisp-runtime"
               "clautolisp/autolisp-builtins-core"
               "fiveam")
  :serial t
  :components
  ((:file "autolisp-debug/tests/package")
   (:file "autolisp-debug/tests/test-harness")
   (:file "autolisp-debug/tests/instrument-tests")
   (:file "autolisp-debug/tests/breakpoint-tests")
   (:file "autolisp-debug/tests/snapshot-tests")
   (:file "autolisp-debug/tests/stepping-tests")
   (:file "autolisp-debug/tests/error-tests")
   (:file "autolisp-debug/tests/session-tests")
   (:file "autolisp-debug/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.debug.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-debug-ui-tui"
  :description "Thin terminal-UI abstraction + mock backend for the ncurses debugger UI (debugger §19.3)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ()
  :serial t
  :components
  ((:file "autolisp-debug-ui-tui/source/package")
   (:file "autolisp-debug-ui-tui/source/tui"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug-ui-ncurses/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-debug-ui-ncurses"
  :description "Four-pane ncurses debugger UI on the tui abstraction (debugger §19)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui"
               "clautolisp/autolisp-debug-ui-tui")
  :serial t
  :components
  ((:file "autolisp-debug-ui-ncurses/source/package")
   (:file "autolisp-debug-ui-ncurses/source/ncurses-ui"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug-ui-ncurses/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-debug-ui-ncurses/tests"
  :description "FiveAM tests for the tui abstraction + ncurses UI (via the mock screen)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui-ncurses" "fiveam")
  :serial t
  :components
  ((:file "autolisp-debug-ui-ncurses/tests/package")
   (:file "autolisp-debug-ui-ncurses/tests/tui-tests")
   (:file "autolisp-debug-ui-ncurses/tests/ncurses-tests")
   (:file "autolisp-debug-ui-ncurses/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.ui.ncurses.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/autolisp-debug-ui-emacs"
  :description "Emacs (aldb) debugger UI: S-expression RPC shim implementing the UI protocol (debugger §20)."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui")
  :serial t
  :components
  ((:file "autolisp-debug-ui-emacs/source/package")
   (:file "autolisp-debug-ui-emacs/source/emacs-ui"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-debug-ui-emacs/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-debug-ui-emacs/tests"
  :description "FiveAM tests for the Emacs (aldb) RPC shim, over string streams."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-debug-ui-emacs" "fiveam")
  :serial t
  :components
  ((:file "autolisp-debug-ui-emacs/tests/package")
   (:file "autolisp-debug-ui-emacs/tests/emacs-ui-tests")
   (:file "autolisp-debug-ui-emacs/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.ui.emacs.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/tests"
  :description "Aggregate tests for the clautolisp subproject."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader/tests"
               "clautolisp/autolisp-source-map/tests"
               "clautolisp/autolisp-runtime/tests"
               "clautolisp/drawing/tests"
               "clautolisp/autolisp-host/tests"
               "clautolisp/autolisp-mock-host/tests"
               "clautolisp/autolisp-dcl/tests"
               "clautolisp/autolisp-builtins-core/tests"
               "clautolisp/autolisp-file-compat/tests"
               "clautolisp/autolisp-init-files/tests"
               "clautolisp/autolisp-debug/tests"
               "clautolisp/autolisp-inspect/tests"
               "clautolisp/autolisp-debug-ui-dumb/tests"
               "clautolisp/autolisp-debug-ui-ncurses/tests"
               "clautolisp/autolisp-debug-ui-emacs/tests")
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (progn
                           (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-runtime.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.drawing.tests
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
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.autolisp-init-files.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.source.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.debug.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.inspect.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.ui.dumb.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.ui.ncurses.tests
                                             :run-all-tests)
                           (uiop:symbol-call :clautolisp.ui.emacs.tests
                                             :run-all-tests))))
