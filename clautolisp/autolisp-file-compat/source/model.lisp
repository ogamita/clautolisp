(in-package #:clautolisp.autolisp-file-compat)

(defstruct file-compat-scenario
  (name "" :type string)
  (description "" :type string)
  (kind :roundtrip :type keyword)
  root
  (relative-path "" :type string)
  (classification :portable :type keyword)
  (tags '() :type list)
  (external-format :default)
  (newline-mode :lf)
  (setup-files '() :type list)
  current-directory
  (support-paths '() :type list)
  (trusted-paths '() :type list)
  builtin-name
  (arguments '() :type list)
  (steps '() :type list)
  result-ref
  expected-value
  artifact-relative-path
  expected-artifact-exists-p
  input-text
  input-bytes
  expected-text
  (expected-lines '() :type list)
  expected-bytes)

(defstruct file-compat-artifact
  path
  bytes
  text
  (lines '() :type list))

(defstruct file-compat-check
  (name "" :type string)
  (passed-p nil :type boolean)
  (message "" :type string))

(defstruct file-compat-report
  scenario
  (runner :local :type keyword)
  (checks '() :type list)
  artifact)

(defstruct file-compat-summary
  (total-scenarios 0 :type integer)
  (passed-scenarios 0 :type integer)
  (failed-scenarios 0 :type integer)
  (total-checks 0 :type integer)
  (passed-checks 0 :type integer)
  (failed-checks 0 :type integer))
