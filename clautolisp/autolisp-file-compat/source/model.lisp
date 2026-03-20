(in-package #:clautolisp.autolisp-file-compat)

(defstruct file-compat-scenario
  (name "" :type string)
  (description "" :type string)
  root
  (relative-path "" :type string)
  (external-format :default)
  (newline-mode :lf)
  input-text
  input-bytes
  expected-text
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
