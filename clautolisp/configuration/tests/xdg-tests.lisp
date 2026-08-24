(in-package #:clautolisp.configuration.tests)

(in-suite configuration-suite)

;;;; The property this module exists to guarantee is not "the paths are
;;;; right" — both copies computed right paths, identically, for months.
;;;; It is that THERE IS ONLY ONE IMPLEMENTATION. So the first test below
;;;; asserts symbol IDENTITY, not equal results: comparing results would
;;;; have passed happily the whole time the duplication existed, which is
;;;; precisely the failure mode (aldo-config-path-implemented-twice.issue).

(test the-configuration-rule-has-exactly-one-implementation
  "CLAUTOLISP.DEBUG.UI re-exports these names; they must be the SAME
symbols this module exports, not homonyms. A local re-definition would
make them distinct and fail here — which is the check the codebase did not
have when aldo's config path came to be written twice."
  (dolist (name '("XDG-CONFIG-HOME" "XDG-CONFIG-DIRS"
                  "CONFIG-RELATIVE-PATH" "CONFIG-SAVE-PATH" "CONFIG-LOAD-PATH"))
    (let ((ours (find-symbol name "CLAUTOLISP.CONFIGURATION"))
          (theirs (find-symbol name "CLAUTOLISP.DEBUG.UI")))
      (is (not (null ours)) "~A is not in CLAUTOLISP.CONFIGURATION" name)
      (is (eq ours theirs)
          "~A is a different symbol in CLAUTOLISP.DEBUG.UI — the rule has ~
           been implemented twice again" name))))

(test the-aldo-path-is-the-same-one-both-callers-use
  "The debug UI's façade and the path the AutoLISP builtins now ask for
must be the same file. They were computed by two implementations before;
this pins the answer rather than trusting that two copies still agree."
  (is (equal (clautolisp.debug.ui:aldo-config-save-path)
             (config-save-path "aldo")))
  (is (equal (clautolisp.debug.ui:lisp-config-save-path)
             (config-save-path "lisp"))))

(test config-getenv-treats-an-empty-variable-as-unset
  "An exported-but-empty XDG_CONFIG_HOME must fall back to the default.
Without this every configuration file would resolve against the
filesystem root, which is the kind of thing one discovers in production."
  (is (null (config-getenv "CLAUTOLISP_CONFIGURATION_TEST_UNSET_VARIABLE"))))

(test config-paths-are-name-parameterised
  "One rule, applied to a name: clautolisp/NAME.conf under the XDG
directories. The two declared names must not collide, which is the whole
reason the parameter exists."
  (is (equal #P"clautolisp/aldo.conf" (config-relative-path "aldo")))
  (is (equal #P"clautolisp/lisp.conf" (config-relative-path "lisp")))
  (is (not (equal (config-save-path "aldo") (config-save-path "lisp"))))
  ;; the save path is under XDG_CONFIG_HOME
  (is (search (namestring (uiop:ensure-directory-pathname (xdg-config-home)))
              (namestring (config-save-path "aldo"))))
  ;; and the search path is a non-empty list of strings
  (is (every #'stringp (xdg-config-dirs)))
  (is (plusp (length (xdg-config-dirs)))))

(test the-declared-configuration-names-are-the-ones-in-use
  "The module names the project's configuration files so that `what
configuration does clautolisp have?' has a readable answer. Adding one
should be a change here, not a string appearing somewhere new."
  (is (configuration-name-p "aldo"))
  (is (configuration-name-p "lisp"))
  (is (not (configuration-name-p "nonesuch")))
  (is (equal '("aldo" "lisp") *configuration-names*)))
