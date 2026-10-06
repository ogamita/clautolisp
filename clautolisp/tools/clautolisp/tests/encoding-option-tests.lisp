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

(test econsole-folds-into-the-tools-terminal
  ;; clautolisp's console is in-process: the same stream as its terminal, so
  ;; an explicit -Econsole[-in|-out] plans the terminal when no -Eterminal is
  ;; given; an explicit -Eterminal wins; -Econsole wins over the bare -E.
  (flet ((keys (plan) (mapcar #'first plan))
         (ext (plan key) (fourth (assoc key plan))))
    (let ((plan (clautolisp.autolisp-cli:terminal-encoding-plan
                 (%enc-options "-Econsole-in" "ISO-8859-1"))))
      (is (equal '(:input) (keys plan)))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "ISO-8859-1")
                 (ext plan :input))))
    (let ((plan (clautolisp.autolisp-cli:terminal-encoding-plan
                 (%enc-options "-Econsole" "ISO-8859-1" "-Eterminal-out" "UTF-8"))))
      (is (equal '(:output :error :input) (keys plan)))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "UTF-8") (ext plan :output)))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "ISO-8859-1") (ext plan :input))))
    (let ((plan (clautolisp.autolisp-cli:terminal-encoding-plan
                 (%enc-options "-E" "UTF-8" "-Econsole-out" "ISO-8859-1"))))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "ISO-8859-1") (ext plan :output)))
      (is (equal (clautolisp.autolisp-cli:encoding-keyword "UTF-8") (ext plan :input))))
    ;; without the fold (a CAD's console device) -Econsole plans nothing
    (is (null (clautolisp.autolisp-cli:terminal-encoding-plan
               (%enc-options "-Econsole" "ISO-8859-1") :fold-console nil)))))

(test efile-directions-are-resolved
  (let ((o (%enc-options "-Efile" "UTF-8" "-Efile-write" "ISO-8859-1")))
    (is (equal "UTF-8" (clautolisp.autolisp-cli:cli-situation-encoding o "file" "read")))
    (is (equal "ISO-8859-1" (clautolisp.autolisp-cli:cli-situation-encoding o "file" "write")))))
