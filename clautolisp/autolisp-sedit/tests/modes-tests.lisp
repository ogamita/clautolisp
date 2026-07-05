;;;; clautolisp/autolisp-sedit/tests/modes-tests.lisp
;;;;
;;;; The two-mode machine and the command set (§1, §5, §6.6): mode transitions,
;;;; the revised commands, the stacked debugger dictionary via the hook, the
;;;; marked-selection render, and the interactive driver.

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

(defun set-nav (session)
  (setf (sedit-state-mode (sedit-session-state session)) :nav) session)
(defun mode-of (session) (sedit-state-mode (sedit-session-state session)))
(defun focus-of (session) (tree->sexp (loc-focus (sedit-state-loc (sedit-session-state session)))))
(defun root-of (session) (tree->sexp (loc-root (sedit-state-loc (sedit-session-state session)))))

;;; --- the transition machine (§6.6) ----------------------------------------

(test editing-command-in-nav-switches-to-edit-and-runs
  (let ((s (set-nav (sedit-open (sexp->tree '(foo (a b) baz))))))
    (sedit-command s "d")               ; -> foo   (motion keeps NAV)
    (is (eq :nav (mode-of s)))
    (sedit-command s ">")               ; -> (a b)
    (sedit-command s "wrap")            ; an editing word in NAV -> EDIT + wrap
    (is (eq :edit (mode-of s)))
    (is (equal '(foo ((a b)) baz) (root-of s)))))

(test explicit-edit-and-nav-switch-modes
  (let ((s (set-nav (sedit-open (sexp->tree '(a))))))
    (sedit-command s "edit") (is (eq :edit (mode-of s)))
    (sedit-command s "nav")  (is (eq :nav (mode-of s)))))

(test debug-prefix-runs-a-command-and-returns-to-nav
  (let* ((calls '())
         (hook (lambda (cmd) (push cmd calls) :continue))
         (s (sedit-open (sexp->tree '(a)))))          ; clal-sedit starts in EDIT
    (is (eq :edit (mode-of s)))
    (multiple-value-bind (_ action) (sedit-command s "debug next" :debug-hook hook)
      (declare (ignore _))
      (is (equal '("next") calls))                    ; the hook ran the command
      (is (eq :continue action))                      ; its directive propagated
      (is (eq :nav (mode-of s))))))                   ; and we returned to NAV

(test bare-debugger-command-runs-directly-in-nav
  (let* ((calls '())
         (hook (lambda (cmd) (push cmd calls) nil))
         (s (set-nav (sedit-open (sexp->tree '(a))))))
    ;; `lb' (list breakpoints) is a debugger command, not a sedit one (note `b'
    ;; alone is now sedit's backward motion)
    (sedit-command s "lb" :debug-hook hook)           ; not a sedit command -> debugger
    (is (equal '("lb") calls))
    (is (eq :nav (mode-of s)))))                       ; stays in NAV

(test bare-debugger-command-in-edit-needs-the-prefix
  (let ((s (sedit-open (sexp->tree '(a)))))            ; EDIT
    (multiple-value-bind (_ action) (sedit-command s "lb")
      (declare (ignore _))
      (is (eq :unknown action)))))

(test motions-and-load-keep-the-mode
  (let ((s (set-nav (sedit-open (parse-form "(a b c)")))))
    (sedit-command s "d")  (is (eq :nav (mode-of s)))
    (sedit-command s ">")  (is (eq :nav (mode-of s)))
    (sedit-command s "load" :load-hook (lambda (p) (declare (ignore p))))
    (is (eq :nav (mode-of s)))))

(test quit-and-help-actions
  (let ((s (sedit-open (sexp->tree '(a)))))
    (multiple-value-bind (_ action) (sedit-command s "q") (declare (ignore _))
      (is (eq :quit action)))
    (multiple-value-bind (_ action) (sedit-command s "?") (declare (ignore _))
      (is (eq :help action)))))

;;; --- the command set (§5) -------------------------------------------------

(test insert-add-replace-from-the-command-line
  (let ((s (sedit-open (parse-form "(list nil)"))))
    (sedit-command s "d") (sedit-command s ">")        ; -> nil
    (sedit-command s "replace (a b c)")
    (is (equal '(:list (:a :b :c)) (root-of s)))
    (sedit-command s "insert (1 2 3)")
    (is (equal '(:list (1 2 3) (:a :b :c)) (root-of s)))
    (sedit-command s "add hello")
    (is (equal '(:list (1 2 3) :hello (:a :b :c)) (root-of s)))))

(test undo-command-reverts
  (let ((s (sedit-open (parse-form "(a b c)"))))
    (sedit-command s "d") (sedit-command s "wrap")     ; a -> (a)
    (is (equal '((:a) :b :c) (root-of s)))
    (sedit-command s "z")                              ; undo
    (is (equal '(:a :b :c) (root-of s)))))

(test clipboard-copy-paste-commands
  (let ((s (sedit-open (parse-form "(list a b c)"))))
    (sedit-command s "d") (sedit-command s ">")        ; -> a
    (sedit-command s "c")                              ; copy a
    (sedit-command s ">")                              ; -> b
    (sedit-command s "v")                              ; paste a over b
    (is (equal '(:list :a :a :c) (root-of s)))))

(test structural-word-commands
  (let ((s (sedit-open (parse-form "(foo (a b) c d)"))))
    (sedit-command s "d") (sedit-command s ">")        ; -> (a b)
    (sedit-command s "slurp")
    (is (equal '(:foo (:a :b :c) :d) (root-of s)))
    (sedit-command s "barf")
    (is (equal '(:foo (:a :b) :c :d) (root-of s)))))

(test motions-and-signed-skip
  (let ((s (sedit-open (parse-form "(a b c d e)"))))
    (sedit-command s "d")                              ; -> a
    (sedit-command s "+3") (is (eq :d (focus-of s)))   ; skip 3
    (sedit-command s "<<") (is (eq :a (focus-of s)))
    (sedit-command s ">>") (is (eq :e (focus-of s)))
    (sedit-command s "-2") (is (eq :c (focus-of s)))))

(test f-and-b-alias-forward-and-backward
  ;; f / b are aliases for > / < (§5)
  (let ((s (sedit-open (parse-form "(a b c)"))))
    (sedit-command s "d")                              ; -> a
    (sedit-command s "f") (is (eq :b (focus-of s)))    ; forward
    (sedit-command s "f") (is (eq :c (focus-of s)))
    (sedit-command s "b") (is (eq :b (focus-of s)))    ; backward
    (sedit-command s "b") (is (eq :a (focus-of s)))))

(test comment-insert-command
  (let ((s (sedit-open (parse-form "(a b)"))))
    (sedit-command s "d")                              ; -> a
    (sedit-command s "ac ; note")                      ; add a comment after a
    (is (comment-node-p (loc-focus (sedit-state-loc (sedit-session-state s)))))
    (is (equal '(:a :b) (root-of s)))))                ; comment dropped from the sexp

;;; --- marked-selection render (§2/§5.2) ------------------------------------

(test render-brackets-the-selection
  (let ((s (sedit-open (parse-form "(list nil)"))))
    (sedit-command s "d") (sedit-command s ">")        ; -> nil
    (is (equal "(list [nil])"
               (render-selection (sedit-state-loc (sedit-session-state s)))))))

;;; --- the interactive driver -----------------------------------------------

(test sedit-run-drives-an-editing-session-to-its-result
  (let* ((s (sedit-open (parse-form "(list nil)")))
         (in (make-string-input-stream (format nil "d~%>~%replace (a b c)~%q~%")))
         (out (make-string-output-stream))
         (result (sedit-run s :input in :output out)))
    (is (equal '(:list (:a :b :c)) (tree->sexp result)))   ; §2 result
    (is (search "[" (get-output-stream-string out)))))     ; rendered the selection

;;; --- directory r / x / n are object-exclusive (§5) ------------------------

(test directory-rename-and-new-via-object-exclusive-keys
  (with-temp-dir (dir)
    (sedit-fs-new-file dir "a.lsp")
    (let ((s (sedit-open dir)))                        ; EDIT, dir session, focus ".."
      (sedit-command s ">")                            ; -> a.lsp entry
      (is (equal "a.lsp" (file-node-name (loc-focus (sedit-state-loc (sedit-session-state s))))))
      (sedit-command s "r b.lsp")                      ; r on a dir entry = rename
      (is (not (probe-file (merge-pathnames "a.lsp" (uiop:ensure-directory-pathname dir)))))
      (is (probe-file (merge-pathnames "b.lsp" (uiop:ensure-directory-pathname dir))))
      (sedit-command s "n c.lsp")                      ; n = new file
      (is (probe-file (merge-pathnames "c.lsp" (uiop:ensure-directory-pathname dir)))))))
