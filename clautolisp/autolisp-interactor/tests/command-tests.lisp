;;;; Command dictionaries: registration, the §0 naming rule, aliases, lookup.

(in-package #:clautolisp.interactor.tests)

(in-suite interactor-suite)

(test bind-registers-key-and-phrase
  (let ((d (make-command-dictionary "test")))
    (bind-command d '(lb list breakpoints) '() "List." (constantly :lb))
    (is (eq (find-command d "lb") (find-command d "list breakpoints")))
    (is (equal "List." (command-docstring (find-command d "lb"))))
    (is (null (find-command d "list")))))

(test naming-rule-enforced-for-word-named-commands
  (let ((d (make-command-dictionary "test")))
    (signals error (bind-command d '(x continue) '() "bad" (constantly t)))
    ;; punctuation keys are exempt
    (bind-command d '(|.| definition) '() "ok" (constantly t))
    (is (not (null (find-command d "."))))))

(test rebinding-a-token-clashes
  (let ((d (make-command-dictionary "test")))
    (bind-command d '(b break) '() "Break." (constantly t))
    (signals error (bind-command d '(b back) '() "dup" (constantly t)))))

(test unbind-removes-key-and-phrase
  (let ((d (make-command-dictionary "test")))
    (bind-command d '(q quit) '() "Quit." (constantly t))
    (is (unbind-command d "quit"))
    (is (null (find-command d "q")))
    (is (null (find-command d "quit")))))

(test aliases-share-the-command
  (let ((d (make-command-dictionary "test")))
    (let ((cmd (bind-command d '(j jump) '(target) "Jump." (constantly t))))
      (bind-command-alias d ",jump" "jump")
      (is (eq cmd (find-command d ",jump")))
      (signals error (bind-command-alias d "j" cmd))       ; token taken
      (signals error (bind-command-alias d "zz" "nosuch")))))

(test lookup-walks-the-stack-innermost-first
  (let ((inner (make-command-dictionary "inner"))
        (outer (make-command-dictionary "outer")))
    (bind-command outer '(b break) '() "outer b." (constantly :outer))
    (bind-command outer '(c continue) '() "outer c." (constantly :outer))
    (bind-command inner '(b bind) '() "inner b." (constantly :inner))
    (multiple-value-bind (cmd dict) (lookup-command "b" (list inner outer))
      (is (eq dict inner))
      (is (eq :inner (funcall (command-function cmd)))))
    (multiple-value-bind (cmd dict) (lookup-command "c" (list inner outer))
      (is (eq dict outer))
      (is (eq :outer (funcall (command-function cmd)))))))

(test arity-and-raw-argument-declaration
  (let ((d (make-command-dictionary "test")))
    (let ((plain (bind-command d '(z zar) '(count name) "Zar." (constantly t)))
          (raw   (bind-command d '(e echo) '(&whole arg) "Echo." #'identity))
          (rest  (bind-command d '(m more) '(x &rest xs) "More." (constantly t))))
      (is (= 2 (command-arity plain)))
      (is (not (command-raw-argument-p plain)))
      (is (equal '(count name) (command-required-parameters plain)))
      (is (command-raw-argument-p raw))
      (is (equal '() (command-required-parameters raw)))
      (is (equal '(x) (command-required-parameters rest))))))

(test dictionary-commands-enumerates-each-command-once
  (let ((d (make-command-dictionary "test")))
    (bind-command d '(q quit) '() "Quit." (constantly t))
    (bind-command d '(h help) '() "Help." (constantly t))
    (bind-command-alias d "?" "help")
    (is (equal '("h" "q") (mapcar #'command-key (dictionary-commands d))))))
