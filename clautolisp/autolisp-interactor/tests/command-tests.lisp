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

;;; --- typed command arguments -------------------------------------------

(test typed-parameters-register-and-describe
  (let ((d (make-command-dictionary "test")))
    (let ((cmd (bind-command d '(z zar) '((count integer) name &rest (forms sexp))
                             "Zar." (constantly t))))
      (is (= 3 (command-arity cmd)))
      (is (not (command-raw-argument-p cmd)))
      ;; the required specs keep the sublists whole …
      (is (equal '((count integer) name) (command-required-parameters cmd)))
      ;; … and the parameter accessors take them apart
      (is (eq 'count (command-parameter-name '(count integer))))
      (is (eq 'integer (command-parameter-type '(count integer))))
      (is (eq 'name (command-parameter-name 'name)))
      (is (eq 'string (command-parameter-type 'name))))))

(test invalid-lambda-lists-are-rejected-at-registration
  (let ((d (make-command-dictionary "test")))
    ;; unknown parameter type
    (signals error (bind-command d '(b bad) '((x frobnicate)) "bad" (constantly t)))
    ;; malformed sublist
    (signals error (bind-command d '(w worse) '((x integer extra)) "bad" (constantly t)))
    ;; &whole is exactly (&whole VAR) — no typed entries, nothing else
    (signals error (bind-command d '(m mixed) '(&whole (x integer)) "bad" (constantly t)))
    (signals error (bind-command d '(a also) '(&whole x (y integer)) "bad" (constantly t)))
    ;; the naming rule is still enforced alongside
    (signals error (bind-command d '(x continue) '((count integer)) "bad" (constantly t)))))

(test convert-command-argument-converts-per-type
  (let* ((d (make-command-dictionary "test"))
         (cmd (bind-command d '(z zar) '((count integer)) "Zar." (constantly t))))
    (is (= 42 (convert-command-argument cmd '(count integer) "42")))
    (is (= -7 (convert-command-argument cmd '(count integer) "-7")))
    (is (= 1.5 (convert-command-argument cmd '(ratio float) "1.5")))
    (is (= 3 (convert-command-argument cmd '(ratio float) "3")))  ; a CL real
    (is (equal "foo-1" (convert-command-argument cmd '(name ident) "foo-1")))
    (is (equal "a b" (convert-command-argument cmd '(text string) "a b")))
    (let ((*package* (find-package '#:clautolisp.interactor.tests)))
      (is (equal '(list 1 2) (convert-command-argument cmd '(form sexp) "(list 1 2)"))))
    ;; a bare symbol means STRING; NIL (a missing argument) stays NIL
    (is (equal "42" (convert-command-argument cmd 'count "42")))
    (is (null (convert-command-argument cmd '(count integer) nil)))))

(test convert-command-argument-reports-mismatches
  (let* ((d (make-command-dictionary "test"))
         (cmd (bind-command d '(z zar) '((count integer)) "Zar." (constantly t))))
    (signals command-argument-error (convert-command-argument cmd '(count integer) "x"))
    (signals command-argument-error (convert-command-argument cmd '(count integer) "1.5"))
    (signals command-argument-error (convert-command-argument cmd '(ratio float) "abc"))
    (signals command-argument-error (convert-command-argument cmd '(name ident) "3d"))
    (signals command-argument-error (convert-command-argument cmd '(form sexp) "(unbalanced"))
    ;; *read-eval* is disabled for SEXP / FLOAT conversions
    (signals command-argument-error
      (convert-command-argument cmd '(form sexp) "#.(error \"boom\")"))
    ;; the report is the spec'd sentence, on the long name
    (handler-case (convert-command-argument cmd '(count integer) "x")
      (command-argument-error (err)
        (is (equal "the zar command needs a integer for count, got \"x\""
                   (princ-to-string err)))))))

(test dictionary-commands-enumerates-each-command-once
  (let ((d (make-command-dictionary "test")))
    (bind-command d '(q quit) '() "Quit." (constantly t))
    (bind-command d '(h help) '() "Help." (constantly t))
    (bind-command-alias d "?" "help")
    (is (equal '("h" "q") (mapcar #'command-key (dictionary-commands d))))))
