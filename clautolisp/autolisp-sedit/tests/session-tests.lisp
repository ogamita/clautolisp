;;;; clautolisp/autolisp-sedit/tests/session-tests.lisp
;;;;
;;;; The sedit session (§2), REPL source recording (§3), storage save/load
;;;; (§5.7–§5.8), and the filesystem level (§5.9).

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

(defmacro with-temp-dir ((var) &body body)
  "Bind VAR to a fresh temporary directory namestring, removed afterwards."
  `(let ((,var (namestring
                (ensure-directories-exist
                 (merge-pathnames (format nil "sedit-test-~A/" (gensym "D"))
                                  (uiop:temporary-directory))))))
     (unwind-protect (progn ,@body)
       (ignore-errors (uiop:delete-directory-tree
                       (uiop:ensure-directory-pathname ,var) :validate t)))))

;;; --- REPL source recording (§3) -------------------------------------------

(test definition-name-extracts-the-bound-name
  (is (equal "FOO"  (definition-name (parse-form "(defun foo (x) x)"))))
  (is (equal "FOO"  (definition-name (parse-form "(defun-q foo (x) x)"))))
  (is (equal "VOO"  (definition-name (parse-form "(setq voo 3)"))))
  (is (null (definition-name (parse-form "(princ 3)"))))       ; not a definition
  (is (null (definition-name (parse-form "42")))))             ; not even a list

(test recording-records-definitions-and-the-log
  (let ((rec (make-recording)))
    (record-form rec (parse-form "(defun foo () 1)"))
    (record-form rec (parse-form "(setq x 2)"))
    (record-form rec (parse-form "(princ x)"))                 ; non-definition
    ;; recall by name, case-insensitively
    (is (equal '(:defun :foo () 1) (tree->sexp (recorded-definition rec "FOO"))))
    (is (equal '(:defun :foo () 1) (tree->sexp (recorded-definition rec 'foo))))
    (is (equal '(:setq :x 2) (tree->sexp (recorded-definition rec "x"))))
    (is (null (recorded-definition rec "nope")))
    ;; the log keeps ALL forms in evaluation order
    (is (= 3 (length (recording-forms rec))))))

(test re-definition-updates-and-session-source-keeps-the-last
  (let ((rec (make-recording)))
    (record-form rec (parse-form "(defun foo () 1)"))
    (record-form rec (parse-form "(setq x 2)"))
    (record-form rec (parse-form "(defun foo () 99)"))         ; redefine foo
    ;; recall returns the latest definition
    (is (equal '(:defun :foo () 99) (tree->sexp (recorded-definition rec "FOO"))))
    ;; session-source drops the earlier foo, keeping the last at its position
    (let ((src (mapcar #'tree->sexp (session-source rec))))
      (is (equal '((:setq :x 2) (:defun :foo () 99)) src)))))

;;; --- the §2 session entry points ------------------------------------------

(test open-nil-is-a-standalone-nil
  (let ((s (sedit-open nil)))
    (is (eq :standalone (sedit-session-origin s)))
    (is (null (tree->sexp (state-focus (sedit-session-state s)))))   ; nil selected
    (is (eq *clal-sedit-initial-form* (sedit-session-initial s)))))

(test open-a-node-edits-it-standalone
  (let* ((tree (sexp->tree '(a b c)))
         (s (sedit-open tree)))
    (is (eq :standalone (sedit-session-origin s)))
    (is (eq tree (state-focus (sedit-session-state s))))))

(test open-a-symbol-recalls-its-recorded-form
  (let ((rec (make-recording)))
    (record-form rec (parse-form "(defun foo (x) x)"))
    (let ((s (sedit-open 'foo :recording rec)))
      (is (equal '(:symbol "FOO") (sedit-session-origin s)))
      (is (equal '(:defun :foo (:x) :x) (tree->sexp (state-focus (sedit-session-state s))))))
    ;; an unrecorded name opens a fresh stand-alone nil, ready to define
    (let ((s (sedit-open 'nope :recording rec)))
      (is (equal '(:symbol "NOPE") (sedit-session-origin s)))
      (is (null (tree->sexp (state-focus (sedit-session-state s))))))))

(test open-a-file-path-selects-the-first-top-level-form
  (with-temp-dir (dir)
    (let ((path (namestring (merge-pathnames "foo.lsp" dir))))
      (sedit-save (parse-source (format nil "(defun a () 1)~%(defun b () 2)~%")) path)
      (let ((s (sedit-open path)))
        (is (equal (list :file path) (sedit-session-origin s)))
        (is (file-node-p (sedit-session-initial s)))
        (is (equal '(:defun :a () 1) (tree->sexp (state-focus (sedit-session-state s)))))))))

(test open-a-directory-path-lists-its-entries
  (with-temp-dir (dir)
    (sedit-fs-new-file dir "one.lsp")
    (let ((s (sedit-open dir)))
      (is (equal (list :dir dir) (sedit-session-origin s)))
      (is (dir-node-p (sedit-session-initial s)))
      ;; first entry is the ".." pseudo-entry
      (is (equal ".." (dir-node-name (state-focus (sedit-session-state s))))))))

;;; --- the §2 result table --------------------------------------------------

(test result-is-the-top-level-form-the-selection-is-in
  ;; a constructed (sexp->tree) tree carries plain symbols, not the parser's
  ;; keywords. Navigate deep into it; the result is the whole top-level sexp.
  (let* ((s (sedit-open (sexp->tree '(defun foo (x) (+ x 1)))))
         (st (sedit-session-state s)))
    (sedit-down st)          ; -> defun (index 0)
    (sedit-skip st 3)        ; -> (+ x 1)  (index 3)
    (sedit-down st)          ; -> +        (index 0)
    (sedit-skip st 1)        ; -> x        (index 1)
    (is (eq 'x (tree->sexp (loc-focus (sedit-state-loc st)))))          ; deep selection
    (is (equal '(defun foo (x) (+ x 1)) (tree->sexp (session-result s))))
    (is (eq *clal-sedit-last-result* (session-result s)))))

(test result-for-a-file-is-the-containing-top-level-form
  (with-temp-dir (dir)
    (let ((path (namestring (merge-pathnames "foo.lsp" dir))))
      (sedit-save (parse-source (format nil "(defun a () 1)~%(defun b (y) (* y y))~%")) path)
      (let* ((s (sedit-open path))
             (st (sedit-session-state s)))
        (sedit-skip st 1)                        ; second top-level form (defun b …)
        (sedit-down st) (sedit-skip st 3)        ; into (* y y)
        (is (equal '(:* :y :y) (tree->sexp (loc-focus (sedit-state-loc st)))))
        ;; the result is the whole second form, NOT the file
        (is (equal '(:defun :b (:y) (:* :y :y)) (tree->sexp (session-result s))))))))

;;; --- storage: save / load round trip (§5.7–§5.8) --------------------------

(test save-load-round-trip-is-byte-preserving
  (with-temp-dir (dir)
    (let ((path (namestring (merge-pathnames "clean.lsp" dir)))
          (src (format nil ";;; a file~%(defun foo (a b)   ; sum~%  (+ a b))~%")))
      (sedit-save (parse-source src :file path) path)
      (is (equal src (uiop:read-file-string path)))           ; on disk = original
      (is (equal src (unparse (sedit-load path)))))))          ; reloaded round-trips

(test save-refuses-to-overwrite-when-asked
  (with-temp-dir (dir)
    (let ((path (namestring (merge-pathnames "x.lsp" dir))))
      (sedit-save (sexp->tree '(a)) path)
      (signals error (sedit-save (sexp->tree '(b)) path :if-exists :error)))))

;;; --- the filesystem level (§5.9) ------------------------------------------

(test filesystem-new-rename-delete
  (with-temp-dir (dir)
    (let ((created (sedit-fs-new-file dir "a.lsp")))
      (is (probe-file created))
      (let ((renamed (sedit-fs-rename created "b.lsp")))
        (is (not (probe-file created)))
        (is (probe-file renamed))
        (is (sedit-fs-delete renamed))
        (is (not (probe-file renamed)))))))

(test read-directory-lists-dotdot-subdirs-and-files
  (with-temp-dir (dir)
    (ensure-directories-exist (merge-pathnames "sub/" dir))
    (sedit-fs-new-file dir "z.lsp")
    (let* ((d (read-directory dir))
           (names (mapcar (lambda (e) (if (dir-node-p e) (dir-node-name e) (file-node-name e)))
                          (dir-node-entries d))))
      (is (dir-node-p d))
      (is (member ".." names :test #'equal))
      (is (member "sub" names :test #'equal))
      (is (member "z.lsp" names :test #'equal)))))

;;; --- save-on-leave policy (§5.8) ------------------------------------------

(test auto-saving-policy
  (is (eq :disable *auto-saving*))                            ; default
  (is (should-auto-save-p :sexp :sexp))
  (is (should-auto-save-p :file :sexp))
  (is (not (should-auto-save-p :sexp :file)))
  (is (should-auto-save-p :file :file))
  (is (not (should-auto-save-p :sexp :disable)))
  (is (not (should-auto-save-p :file :disable))))
