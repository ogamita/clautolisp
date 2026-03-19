(asdf:defsystem "clautolisp"
  :description "Aggregate clautolisp implementation systems."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader")
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
   (:file "autolisp-reader/source/input")
   (:file "autolisp-reader/source/tokenizer")
   (:file "autolisp-reader/source/parser")
   (:file "autolisp-reader/source/api"))
  :in-order-to ((asdf:test-op
                 (asdf:test-op "clautolisp/autolisp-reader/tests")))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         :success))

(asdf:defsystem "clautolisp/autolisp-reader/tests"
  :description "Tests for the clautolisp AutoLISP reader subsystem."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader")
  :serial t
  :components
  ((:file "autolisp-reader/tests/package")
   (:file "autolisp-reader/tests/test-harness")
   (:file "autolisp-reader/tests/tokenizer-tests")
   (:file "autolisp-reader/tests/parser-tests")
   (:file "autolisp-reader/tests/run"))
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                           :run-all-tests)))

(asdf:defsystem "clautolisp/tests"
  :description "Aggregate tests for the clautolisp subproject."
  :author "Codex"
  :license "AGPL-3.0"
  :depends-on ("clautolisp/autolisp-reader/tests")
  :perform (asdf:test-op (op system)
                         (declare (ignore op system))
                         (uiop:symbol-call :clautolisp.autolisp-reader.tests
                                           :run-all-tests)))
