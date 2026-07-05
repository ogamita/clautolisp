;;;; clautolisp/autolisp-sedit/tests/edit-tests.lisp
;;;;
;;;; Editing transitions (§6.3) and the §6.7 round-trip invariants:
;;;; wrap/splice, slurp/barf, split/join are inverse; every mutation selects its
;;;; result; a mutation inside a File marks it modified.

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

;;; --- insert / add / replace / delete (§6.3) -------------------------------

(test insert-add-replace-select-their-result
  (let ((loc (loc-of '(list nil) 1)))            ; focus nil
    ;; replace nil -> (a b c)
    (let ((r (edit-replace loc (sexp->tree '(a b c)))))
      (is (equal '(a b c) (focus-sexp r)))
      (is (equal '(list (a b c)) (root-sexp r)))
      ;; insert (1 2 3) before, selecting it
      (let ((i (edit-insert r (sexp->tree '(1 2 3)))))
        (is (equal '(1 2 3) (focus-sexp i)))
        (is (equal '(list (1 2 3) (a b c)) (root-sexp i)))
        ;; add hello after, selecting it
        (let ((a (edit-add i (sexp->tree 'hello))))
          (is (eq 'hello (focus-sexp a)))
          (is (equal '(list (1 2 3) hello (a b c)) (root-sexp a))))))))

(test insert-and-add-need-a-container
  (signals error (edit-insert (loc-of 'x) (sexp->tree 'y)))
  (signals error (edit-add (loc-of '(a)) (sexp->tree 'y))))  ; root form: no siblings

(test replace-works-at-the-root
  (let ((r (edit-replace (loc-of '(a b)) (sexp->tree 'z))))
    (is (eq 'z (focus-sexp r)))
    (is (eq 'z (root-sexp r)))))

(test delete-selects-next-sibling-then-parent
  (let* ((b (loc-of '(a b c) 1))
         (d (edit-delete b)))
    (is (eq 'c (focus-sexp d)))                   ; next sibling selected
    (is (equal '(a c) (root-sexp d))))
  (let* ((c (loc-of '(a b c) 2))                  ; last element
         (d (edit-delete c)))
    (is (equal '(a b) (focus-sexp d)))            ; no next -> the parent
    (is (null (loc-path d)))))

;;; --- §6.7 round-trips -----------------------------------------------------

(test wrap-then-splice-is-identity
  (let ((loc (loc-of '(foo (a b) baz) 1)))        ; focus (a b)
    (let ((w (edit-wrap loc)))
      (is (equal '((a b)) (focus-sexp w)))        ; wrap selects the new list
      (is (equal '(foo ((a b)) baz) (root-sexp w)))
      (let ((s (edit-splice w)))
        (is (equal '(a b) (focus-sexp s)))
        (is (equal '(foo (a b) baz) (root-sexp s)))
        (is (equal (loc-path loc) (loc-path s)))))))

(test slurp-then-barf-is-identity-for-a-list
  (let ((loc (loc-of '(foo (a b) c d) 1)))        ; focus the list (a b)
    (let ((sl (edit-slurp loc)))
      (is (equal '(a b c) (focus-sexp sl)))       ; slurped the next sibling in
      (is (equal '(foo (a b c) d) (root-sexp sl)))
      (let ((ba (edit-barf sl)))
        (is (equal '(a b) (focus-sexp ba)))
        (is (equal '(foo (a b) c d) (root-sexp ba)))
        (is (equal (loc-path loc) (loc-path ba)))))))

(test slurp-wraps-a-non-list-first
  (let ((loc (loc-of '(foo a b) 1)))              ; focus the atom a
    (let ((sl (edit-slurp loc)))
      (is (equal '(a b) (focus-sexp sl)))         ; a was wrapped, then b slurped
      (is (equal '(foo (a b)) (root-sexp sl))))))

(test split-then-join-is-identity
  (let ((loc (loc-of '(progn (a b c d e)) 1 2)))  ; focus c, parent (a b c d e)
    (is (eq 'c (focus-sexp loc)))
    (let ((sp (edit-split loc)))
      (is (eq 'c (focus-sexp sp)))                ; c stays selected in the 2nd list
      (is (equal '(progn (a b) (c d e)) (root-sexp sp)))
      (let ((jo (edit-join sp)))
        (is (eq 'c (focus-sexp jo)))
        (is (equal '(progn (a b c d e)) (root-sexp jo)))
        (is (equal (loc-path loc) (loc-path jo)))))))

(test split-at-first-makes-no-empty-list
  (let ((loc (loc-of '(progn (a b c)) 1 0)))      ; focus a (first child)
    (let ((sp (edit-split loc)))
      (is (equal '(progn (a b c)) (root-sexp sp)))))) ; nothing to the left: no split

(test join-a-selected-list-with-its-left-sibling
  (let ((loc (loc-of '(progn (a b) (c d)) 2)))    ; focus the list (c d)
    (is (equal '(c d) (focus-sexp loc)))
    (let ((jo (edit-join loc)))
      (is (equal '(a b c d) (focus-sexp jo)))     ; merged list selected
      (is (equal '(progn (a b c d)) (root-sexp jo))))))

;;; --- clipboard: copy / cut / paste (§6.3) ---------------------------------

(test copy-and-paste-replaces-selection
  ;; children of (list a b c): index 1 = a, 2 = b, 3 = c
  (let ((st (make-sedit-state (loc-of '(list a b c) 1))))  ; focus a
    (sedit-copy st)
    (setf (sedit-state-loc st) (loc-right (sedit-state-loc st)))  ; -> b
    (sedit-paste st)                                    ; b := clipboard (a)
    (is (eq 'a (tree->sexp (state-focus st))))          ; state-focus is a NODE
    (is (equal '(list a a c) (root-sexp (sedit-state-loc st))))))

(test cut-removes-and-holds-the-selection
  (let ((st (make-sedit-state (loc-of '(list a b c) 2))))  ; focus b (index 2)
    (sedit-cut st)
    (is (eq 'b (tree->sexp (sedit-state-clip st))))    ; clipboard holds b's node
    (is (eq 'c (tree->sexp (state-focus st))))          ; next sibling selected
    (is (equal '(list a c) (root-sexp (sedit-state-loc st))))
    (sedit-paste st)                                   ; paste b over c
    (is (equal '(list a b) (root-sexp (sedit-state-loc st))))))

(test paste-on-empty-clipboard-signals
  (signals error (sedit-paste (make-sedit-state (loc-of '(a) 0)))))

;;; --- file-modified marking (§6.3) -----------------------------------------

(test mutation-inside-a-file-marks-it-modified
  (let* ((file (make-file-node "f.lsp" (list (sexp->tree '(defun foo () 1))
                                             (sexp->tree '(setq x 2)))))
         (form (loc-down (node->loc file)))        ; first top-level form
         (edited (edit-replace form (sexp->tree '(defun foo () 42))))
         (up (loc-up edited)))
    (is (not (file-node-modified file)))            ; the original is untouched
    (is (file-node-p (loc-focus up)))
    (is (file-node-modified (loc-focus up)))        ; the rebuilt file is modified
    (is (equal '((defun foo () 42) (setq x 2)) (tree->sexp (loc-focus up))))))

(test deep-mutation-inside-a-file-still-marks-it
  (let* ((file (make-file-node "f.lsp" (list (sexp->tree '(setq x (+ 1 2))))))
         ;; descend file -> form (setq x (+ 1 2)) -> (+ 1 2) -> 1
         (deep (loc-skip (loc-down (loc-skip (loc-down (loc-down (node->loc file))) 2)) 1))
         (edited (edit-replace deep (sexp->tree '99)))
         (file* (loc-root edited)))
    (is (eq 99 (focus-sexp edited)))
    (is (file-node-modified file*))
    (is (not (file-node-modified file)))))
