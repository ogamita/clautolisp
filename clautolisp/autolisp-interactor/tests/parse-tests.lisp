;;;; The command-line parser: token classification, strings, syntax errors.

(in-package #:clautolisp.interactor.tests)

(in-suite interactor-suite)

(test parse-classifies-idents-integers-floats-and-tokens
  (is (equal '((ident . "break") (integer . "42"))
             (parse-command "break 42")))
  (is (equal '((ident . "list") (ident . "source"))
             (parse-command "list source")))
  (is (equal '((ident . "b") (token . "source.lsp:33"))
             (parse-command "b source.lsp:33")))
  (is (equal '((ident . "set") (ident . "width") (float . "72.5"))
             (parse-command "set width 72.5")))
  (is (equal '((ident . "skip") (integer . "-3") (float . "+1.5e2"))
             (parse-command "skip -3 +1.5e2"))))

(test parse-preserves-case-and-skips-whitespace
  (is (equal '((ident . "Print") (token . "*X*"))
             (parse-command "  Print   *X* "))))

(test parse-starts-where-asked
  ;; the comma-command reader parses from after the comma
  (is (equal '((ident . "abort")) (parse-command ",abort" :start 1)))
  (is (equal '((ident . "b") (token . "foo.lisp:42"))
             (parse-command ",b foo.lisp:42" :start 1))))

(test parse-decodes-strings
  (is (equal '((ident . "b") (string . "/A vilainous/path with spaces/or \\ backslashes/in/it.lsp:143"))
             (parse-command "b \"/A vilainous/path with spaces/or \\\\ backslashes/in/it.lsp:143\"")))
  (is (equal '((ident . "say") (string . "he\"llo"))
             (parse-command "say \"he\\\"llo\""))))

(test parse-accepts-punctuation-and-signed-command-names
  ;; the navigators' keys: `.', `>>', `+3' name commands; only a string cannot
  (is (equal '((token . ">>")) (parse-command ">>")))
  (is (equal '((token . ".") (ident . "foo")) (parse-command ". foo")))
  (is (equal '((integer . "+3")) (parse-command "+3"))))

(test parse-signals-command-syntax-errors
  (signals command-syntax-error (parse-command "say \"unterminated"))
  (signals command-syntax-error (parse-command "say \"bad escape \\n\""))
  (signals command-syntax-error (parse-command "say \"gl\"ued"))
  ;; a string cannot name a command
  (signals command-syntax-error (parse-command "\"break\" 42")))

(test lenient-parse-degrades-malformed-strings-to-tokens
  ;; a raw argument embedding a Lisp form still reads (the readers' mode)
  (is (equal '((ident . "condition") (integer . "3")
               (token . "(equal") (ident . "s") (token . "\"a") (token . "b\")"))
             (parse-command "condition 3 (equal s \"a  b\")" :lenient t)))
  ;; but a string can still not start a command
  (signals command-syntax-error (parse-command "\"break\" 42" :lenient t)))

(test parse-reports-position
  (let ((err (handler-case (progn (parse-command "say \"oops") nil)
               (command-syntax-error (e) e))))
    (is (not (null err)))
    (is (equal "say \"oops" (command-syntax-error-command err)))
    (is (= 4 (command-syntax-error-position err)))))
