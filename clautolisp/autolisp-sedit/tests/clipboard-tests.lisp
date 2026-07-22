;;;; clautolisp/autolisp-sedit/tests/clipboard-tests.lisp
;;;;
;;;; The clipboard (§5.4 + clipboard-interface.org): the provider protocol,
;;;; auto-selection + fallback, the text and node layers, secure paste, base64,
;;;; and the sedit-copy/cut/paste integration. Tests bind their own providers so
;;;; nothing touches a real system clipboard.

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

(defun make-mock-provider (&key (name :mock) (available t))
  "A provider backed by an in-process box. Returns (values PROVIDER BOX)."
  (let ((box (list nil)))
    (values (make-clipboard-provider name
              :available-p (constantly available)
              :put-text (lambda (s) (setf (car box) s) nil)
              :get-text (lambda () (car box)))
            box)))

;;; --- the provider protocol ------------------------------------------------

(test null-provider-is-a-noop
  (let ((p (make-null-provider)))
    (is (funcall (clipboard-provider-available-p p)))
    (is (null (funcall (clipboard-provider-put-text p) "x")))
    (is (null (funcall (clipboard-provider-get-text p))))))

(test mock-provider-round-trips-text
  (let ((*clipboard-provider* (make-mock-provider)))
    (is (clipboard-put-text "hello"))
    (is (equal "hello" (clipboard-get-text)))))

;;; --- selection + fallback (§Errors and fallback) --------------------------

(test auto-selection-picks-the-first-available-provider
  (let* ((unavail (make-clipboard-provider :nope :available-p (constantly nil)
                                                 :put-text (lambda (s) (declare (ignore s)))
                                                 :get-text (lambda () nil)))
         (yes (make-mock-provider :name :yes))
         (*clipboard-providers* (list unavail yes (make-null-provider)))
         (*clipboard-provider* nil))
    (reset-clipboard-selection)
    (is (eq :yes (clipboard-provider-name (active-provider))))))

(test forcing-a-provider-by-keyword
  (let ((*clipboard-providers* (list (make-mock-provider :name :one) (make-mock-provider :name :two)))
        (*clipboard-provider* :two))
    (is (eq :two (clipboard-provider-name (active-provider))))))

(test a-failing-provider-is-demoted-to-null-and-warns-once
  (let ((*clipboard-provider*
          (make-clipboard-provider :bad
            :available-p (constantly t)
            :put-text (lambda (s) (declare (ignore s)) (error "subprocess crashed"))
            :get-text (lambda () (error "subprocess crashed"))))
        (*clipboard-demoted* nil)
        (clautolisp.sedit::%demote-warned nil))
    (handler-bind ((warning #'muffle-warning))
      (is (null (clipboard-put-text "x")))        ; caught, demoted
      (is (not (null *clipboard-demoted*)))
      (is (null (clipboard-get-text))))))         ; now goes to :NULL, no re-signal

(test disabling-the-system-clipboard
  (let ((*clipboard-provider* (make-mock-provider))
        (*system-clipboard-enabled* nil))
    (is (null (clipboard-put-text "x")))          ; disabled: no-op
    (is (null (clipboard-get-text)))))

;;; --- the node / sexp layer (§Public API, §Sexp ↔ text) --------------------

(test copy-node-mirrors-source-text-and-paste-parses-it
  (multiple-value-bind (provider box) (make-mock-provider)
    (declare (ignore box))
    (let ((*clipboard-provider* provider))
      (clipboard-copy-node (parse-form "(defun foo (x) (+ x 1))"))
      (is (equal "(defun foo (x) (+ x 1))" (clipboard-get-text)))     ; foreign apps see source
      (is (equal '(:defun :foo (:x) (:+ :x 1))
                 (tree->sexp (clipboard-paste-node nil)))))))          ; parsed back

(test paste-falls-back-to-the-internal-clip-when-system-empty
  (let ((*clipboard-provider* :null))              ; get-text -> NIL
    (let ((fallback (sexp->tree '(a b))))
      (is (eq fallback (clipboard-paste-node fallback))))))

(test paste-of-non-lisp-text-becomes-a-string-atom
  (let ((*clipboard-provider* (make-mock-provider)))
    (clipboard-put-text "   ")                      ; only whitespace: no form
    (let ((node (clipboard-paste-node nil)))
      (is (atom-node-p node))
      (is (stringp (atom-node-value node))))))

(test paste-never-evaluates-foreign-read-macros
  ;; a malicious "#.(…)" on the clipboard must not run: the reader never evals
  (let ((*clipboard-provider* (make-mock-provider)))
    (clipboard-put-text "#.(error \"boom\")")
    ;; no error is signalled (no evaluation) and a plain node comes back
    (is (node-p (clipboard-paste-node nil)))))

(test clip-object-round-trip
  (let ((sexp-obj (node->clip-object (parse-form "(a b c)")))
        (com-obj (node->clip-object (make-comment-node ";; hi"))))
    (is (eq :sexp (first sexp-obj)))
    (is (eq :comment (first com-obj)))
    (is (equal '(:a :b :c) (tree->sexp (clip-object->node sexp-obj))))
    (is (equal ";; hi" (comment-node-text (clip-object->node com-obj))))))

;;; --- base64 (OSC 52 encoding) ---------------------------------------------

(test base64-encoding-matches-the-standard
  (flet ((b64 (s) (clautolisp.sedit::%base64 (clautolisp.sedit::%utf8-bytes s))))
    (is (equal "" (b64 "")))
    (is (equal "Zg==" (b64 "f")))
    (is (equal "Zm8=" (b64 "fo")))
    (is (equal "Zm9v" (b64 "foo")))
    (is (equal "aGVsbG8=" (b64 "hello")))))

;;; --- sedit-copy/cut/paste integrate with the system clipboard -------------

(test sedit-copy-then-paste-across-sessions-via-the-system-clipboard
  (let ((*clipboard-provider* (make-mock-provider)))
    ;; copy in one session (mirrors "a" to the system clipboard)
    (let ((a (make-sedit-state (loc-follow (parse-form "(list a b c)") '(1)))))  ; focus a
      (sedit-copy a))
    ;; paste in a DIFFERENT session, whose own clip is empty: it reads the system
    (let ((b (make-sedit-state (loc-follow (parse-form "(x y z)") '(1)))))       ; focus y
      (sedit-paste b)
      (is (equal '(:x :a :z) (tree->sexp (loc-root (sedit-state-loc b))))))))

(test null-provider-keeps-the-in-process-paste-behaviour
  (let ((*clipboard-provider* :null))
    ;; with :NULL, paste uses only the session clip — the pre-clipboard behaviour
    (let ((s (make-sedit-state (loc-follow (parse-form "(list a b c)") '(1)))))  ; focus a
      (sedit-copy s)
      (setf (sedit-state-loc s) (loc-right (sedit-state-loc s)))  ; -> b
      (sedit-paste s)
      (is (equal '(:list :a :a :c) (tree->sexp (loc-root (sedit-state-loc s))))))
    ;; and an empty clip still signals
    (signals error (sedit-paste (make-sedit-state (loc-follow (parse-form "(a)") '(0)))))))
