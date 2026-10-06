;;;; clautolisp/tools/clautolisp/tests/encoding-option-tests.lisp
;;;;
;;;; The -E<situation> family as the clautolisp tool parses it
;;;; (encoding-situations-cli-options, section 6): the bare -E reaches the
;;;; situations the downstream reads, a specific option wins over it, an
;;;; unknown situation names the valid ones, -Eterminal plans the tool's own
;;;; streams.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %enc-options (&rest arguments)
  (clautolisp.tools.clautolisp::parse-arguments (append arguments '("-x" "1"))))

(test bare-e-reaches-source-and-terminal
  (let ((o (%enc-options "-E" "ISO-8859-1")))
    (is (equal "ISO-8859-1" (clautolisp.autolisp-cli:cli-options-load-encoding o)))
    (is (equal "ISO-8859-1" (clautolisp.autolisp-cli:cli-options-io-encoding o)))))

(test specific-encoding-wins-over-the-bare-e-in-any-order
  (dolist (args '(("-E" "ISO-8859-1" "-Esource" "UTF-8")
                  ("-Esource" "UTF-8" "-E" "ISO-8859-1")))
    (let ((o (apply #'%enc-options args)))
      (is (equal "UTF-8" (clautolisp.autolisp-cli:cli-options-load-encoding o)))
      (is (equal "ISO-8859-1" (clautolisp.autolisp-cli:cli-options-io-encoding o))))))

(test unknown-encoding-situation-lists-the-situations
  (let ((message (handler-case (progn (%enc-options "-Efoo" "UTF-8") nil)
                   (clautolisp.autolisp-cli:cli-usage-error (c) (princ-to-string c)))))
    (is (stringp message))
    (is (search "source" message))
    (is (search "terminal" message))))

(test eterminal-plans-the-tools-own-streams
  (let ((plan (clautolisp.autolisp-cli:terminal-encoding-plan
               (%enc-options "-Eterminal-out" "UTF-8"))))
    (is (equal '(:output :error) (mapcar #'first plan)))
    (is (null (clautolisp.autolisp-cli:terminal-encoding-plan (%enc-options))))))

(test efile-directions-are-resolved
  (let ((o (%enc-options "-Efile" "UTF-8" "-Efile-write" "ISO-8859-1")))
    (is (equal "UTF-8" (clautolisp.autolisp-cli:cli-situation-encoding o "file" "read")))
    (is (equal "ISO-8859-1" (clautolisp.autolisp-cli:cli-situation-encoding o "file" "write")))))
