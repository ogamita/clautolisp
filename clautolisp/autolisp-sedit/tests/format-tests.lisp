;;;; clautolisp/autolisp-sedit/tests/format-tests.lisp
;;;;
;;;; Formatting (§5.2–§5.3) and the §6.7 formatting-fidelity invariant: a
;;;; parse/unparse round trip on clean source is byte-preserving; navigation
;;;; keeps verbatim text; an edited form re-lays-out from the indent rules;
;;;; comment objects classify and merge by level.

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

;;; --- §6.7 formatting fidelity: byte-preserving round trip -----------------

(test parse-unparse-is-byte-preserving
  (dolist (src (list
                (format nil ";;; header~%(defun foo (a b / s)   ; sum~%  (setq s (+ a b))~%  (* s s))~%")
                (format nil "(setq *x* '(1 2 3))~%(princ \"he\\\"llo\")~%")
                ";| a block |; (a . b) `(x ,y ,@z)"
                (format nil "~%~%(only)~%~%")
                ""))
    (is (equal src (unparse (parse-source src))))))

(test parsed-form-keeps-its-verbatim-text-and-structure
  (let ((form (parse-form (format nil "(defun foo (a b)~%  (+ a b))"))))
    (is (list-node-p form))
    (is (equal (format nil "(defun foo (a b)~%  (+ a b))") (unparse form)))   ; verbatim
    (is (equal '(:defun :foo (:a :b) (:+ :a :b)) (tree->sexp form)))))        ; structure

(test parse-classifies-and-keeps-comments
  (let ((form (parse-form (format nil "(a ; c~% b)"))))
    (is (= 3 (length (list-node-children form))))          ; a, comment, b
    (is (comment-node-p (second (list-node-children form))))
    (is (equal '(:a :b) (tree->sexp form)))))              ; comments dropped from the sexp

;;; --- navigation keeps verbatim text; editing reflows the touched form -----

(test navigation-preserves-verbatim-text
  (let* ((form (parse-form (format nil "(defun foo (a b)~%  (+ a b))")))
         (nav (loc-up (loc-down (node->loc form)))))       ; down and back up
    (is (equal (unparse form) (unparse (loc-focus nav))))))

(test editing-reflows-only-the-touched-form
  (let* ((form (parse-form "(foo a b)"))
         (loc (loc-skip (loc-down (node->loc form)) 1))    ; -> a (index 1)
         (edited (edit-replace loc (sexp->tree 'z))))
    ;; the rebuilt list lost its verbatim text and re-lays-out, but its untouched
    ;; leaf children keep theirs
    (is (equal "(foo z b)" (unparse (loc-root edited))))))

;;; --- the structural pretty-printer (§5.2 indentation rules) ----------------

(test structural-print-lays-a-constructed-form-out-by-indent-rules
  (let ((*print-width* 20)
        (tree (sexp->tree '(defun foo (a b) (setq s 1) (* s s)))))
    (is (equal (format nil "(defun foo (a b)~%  (setq s 1)~%  (* s s))")
               (unparse tree)))))

(test short-forms-print-on-one-line
  (is (equal "(+ 1 2)" (unparse (sexp->tree '(+ 1 2)))))
  (is (equal "()" (unparse (make-list-node '()))))         ; an empty list node
  (is (equal "nil" (unparse (sexp->tree '())))))           ; () reads as nil -> an atom

(test distinguished-arg-counts-drive-the-header-line
  (let ((*print-width* 8))
    ;; progn has 0 distinguished args: body starts on the next line
    (is (equal (format nil "(progn~%  a~%  b)")
               (unparse (sexp->tree '(progn a b)))))
    ;; if has 1: the test stays on the header line
    (is (equal (format nil "(if test~%  then~%  else)")
               (unparse (sexp->tree '(if test then else)))))))

;;; --- comment objects (§5.3) -----------------------------------------------

(test comment-level-classification
  (is (= 1 (comment-line-level "; margin")))
  (is (= 2 (comment-line-level ";; sub-form")))
  (is (= 3 (comment-line-level ";;; section")))
  (is (= 4 (comment-line-level ";;;; file")))
  (is (= 4 (comment-line-level ";;;;; capped at four")))
  (is (null (comment-line-level "not a comment")))
  (is (comment-block-p ";| block |;"))
  (is (not (comment-block-p ";; line")))
  (is (eq :block (comment-level (make-comment-node ";| b |;"))))
  (is (= 2 (comment-level (make-comment-node ";; two")))))

(test merge-contiguous-same-level-comments
  (let ((merged (merge-comments (list (make-comment-node ";; one")
                                      (make-comment-node ";; two")
                                      (make-comment-node "; other")
                                      (make-comment-node "; more")))))
    (is (= 2 (length merged)))                             ; two runs
    (is (equal (format nil ";; one~%;; two") (comment-node-text (first merged))))
    (is (equal (format nil "; other~%; more") (comment-node-text (second merged))))))

(test block-comments-never-merge
  (is (= 2 (length (merge-comments (list (make-comment-node ";| a |;")
                                         (make-comment-node ";| b |;")))))))

;;; --- configuration (§5.2–§5.3 `set' options) ------------------------------

(test formatting-config-defaults
  (is (= 40 *comment-column*))
  (is (eq :editor *text-editor*))
  (is (integerp *print-width*)))
