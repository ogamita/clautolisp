;;;; clautolisp/autolisp-sedit/tests/undo-tests.lisp
;;;;
;;;; The single-level undo (§6.4) and its §6.7 invariant: undo restores the
;;;; location (focus, context, selection) and is self-inverse (a second undo
;;;; redoes); navigation between a mutation and its undo is transparent; the
;;;; file-modified marker reverts and re-applies with the swap.

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

;;; --- recording (§6.4) -----------------------------------------------------

(test mutations-record-an-undo-point-with-a-descriptor
  (let ((st (make-sedit-state (loc-of '(a b c) 1))))   ; focus b
    (is (not (sedit-can-undo-p st)))                   ; empty slot at first
    (sedit-insert st (sexp->tree 'x))
    (is (sedit-can-undo-p st))
    (is (eq :insert (first (undo-record-op (sedit-state-undo st)))))
    (is (equal "insert" (sedit-undo-description st)))))

(test non-mutating-commands-leave-the-undo-slot-untouched
  (let ((st (make-sedit-state (loc-of '(foo (a b) c) 1))))  ; focus (a b)
    (sedit-wrap st)
    (let ((slot (sedit-state-undo st)))
      (sedit-copy st) (sedit-right st) (sedit-left st)
      (sedit-down st) (sedit-up st) (sedit-first st) (sedit-last st)
      (is (eq slot (sedit-state-undo st))))))          ; the same record object

;;; --- §6.7: undo restores, and is self-inverse -----------------------------

(test undo-restores-location-and-selection
  (let* ((st (make-sedit-state (loc-of '(foo (a b) baz) 1)))  ; focus (a b)
         (before (root-sexp (sedit-state-loc st)))
         (before-path (loc-path (sedit-state-loc st))))
    (sedit-wrap st)                                    ; (a b) -> ((a b))
    (is (equal '(foo ((a b)) baz) (root-sexp (sedit-state-loc st))))
    (sedit-undo st)
    (is (equal before (root-sexp (sedit-state-loc st))))   ; tree restored
    (is (equal before-path (loc-path (sedit-state-loc st)))) ; selection restored
    (is (equal '(a b) (focus-sexp (sedit-state-loc st))))))

(test undo-is-self-inverse-second-undo-redoes
  (let ((st (make-sedit-state (loc-of '(foo (a b) baz) 1))))
    (sedit-wrap st)
    (sedit-undo st)                                    ; undo
    (is (equal '(foo (a b) baz) (root-sexp (sedit-state-loc st))))
    (sedit-undo st)                                    ; redo
    (is (equal '(foo ((a b)) baz) (root-sexp (sedit-state-loc st))))
    (sedit-undo st)                                    ; undo again
    (is (equal '(foo (a b) baz) (root-sexp (sedit-state-loc st))))))

(test undo-works-for-every-mutation-kind
  ;; each §6.3 mutation, undone, returns exactly the prior tree and selection
  (flet ((check (build mutate)
           (let* ((st (funcall build))
                  (before (root-sexp (sedit-state-loc st)))
                  (path (loc-path (sedit-state-loc st))))
             (funcall mutate st)
             (sedit-undo st)
             (is (equal before (root-sexp (sedit-state-loc st))))
             (is (equal path (loc-path (sedit-state-loc st)))))))
    (check (lambda () (make-sedit-state (loc-of '(f a b) 1)))
           (lambda (s) (sedit-insert s (sexp->tree 'x))))
    (check (lambda () (make-sedit-state (loc-of '(f a b) 1)))
           (lambda (s) (sedit-add s (sexp->tree 'x))))
    (check (lambda () (make-sedit-state (loc-of '(f a b) 1)))
           #'sedit-delete)
    (check (lambda () (make-sedit-state (loc-of '(f (a b) c) 1)))
           #'sedit-wrap)
    (check (lambda () (make-sedit-state (loc-of '(f (a b) c) 1)))
           #'sedit-splice)
    (check (lambda () (make-sedit-state (loc-of '(f (a b) c d) 1)))
           #'sedit-slurp)
    (check (lambda () (make-sedit-state (loc-of '(f (a b c)) 1)))
           #'sedit-barf)
    (check (lambda () (make-sedit-state (loc-of '(progn (a b c d)) 1 2)))
           #'sedit-split)
    (check (lambda () (make-sedit-state (loc-of '(progn (a b) (c d)) 2)))
           #'sedit-join)
    (check (lambda () (make-sedit-state (loc-of '(list a b c) 2)))
           #'sedit-cut)))

;;; --- navigation between mutation and undo is transparent (§6.4/§6.7) -------

(test navigation-between-mutation-and-undo-is-transparent
  (let* ((st (make-sedit-state (loc-of '(foo (a b) baz) 1)))  ; focus (a b)
         (before (root-sexp (sedit-state-loc st)))
         (before-path (loc-path (sedit-state-loc st))))
    (sedit-wrap st)
    ;; wander around, and even copy, without mutating
    (sedit-down st) (sedit-up st) (sedit-first st) (sedit-last st) (sedit-copy st)
    (sedit-undo st)
    (is (equal before (root-sexp (sedit-state-loc st))))
    (is (equal before-path (loc-path (sedit-state-loc st))))))

;;; --- empty slot -----------------------------------------------------------

(test undo-on-an-empty-slot-is-a-noop
  (let ((st (make-sedit-state (loc-of '(a b c) 1))))
    (sedit-undo st)
    (is (eq 'b (tree->sexp (state-focus st))))
    (is (equal '(a b c) (root-sexp (sedit-state-loc st))))))

;;; --- a fresh mutation overwrites the one-level slot -----------------------

(test a-new-mutation-overwrites-the-single-undo-slot
  (let ((st (make-sedit-state (loc-of '(a b c) 1))))   ; focus b
    (sedit-replace st (sexp->tree 'x))                 ; (a x c)
    (sedit-replace st (sexp->tree 'y))                 ; (a y c) — slot now holds THIS
    (sedit-undo st)
    (is (equal '(a x c) (root-sexp (sedit-state-loc st))))   ; only the last is undone
    (sedit-undo st)                                    ; redo the last
    (is (equal '(a y c) (root-sexp (sedit-state-loc st))))))

;;; --- cut then undo restores the cut node ----------------------------------

(test undo-restores-a-cut-selection
  (let ((st (make-sedit-state (loc-of '(list a b c) 2))))  ; focus b
    (sedit-cut st)
    (is (equal '(list a c) (root-sexp (sedit-state-loc st))))
    (sedit-undo st)
    (is (equal '(list a b c) (root-sexp (sedit-state-loc st))))
    (is (eq 'b (tree->sexp (state-focus st))))))

;;; --- §6.4 file state: the modified marker reverts with the swap -----------

(test undo-reverts-and-reapplies-the-file-modified-marker
  (let* ((file (make-file-node "f.lsp" (list (sexp->tree '(a)) (sexp->tree '(b)))))
         (st (make-sedit-state (loc-down (node->loc file)))))  ; focus form (a)
    (is (not (file-node-modified (loc-root (sedit-state-loc st)))))
    (sedit-replace st (sexp->tree '(z)))               ; mutate a form -> file modified
    (is (file-node-modified (loc-root (sedit-state-loc st))))
    (sedit-undo st)                                    ; swap back
    (is (not (file-node-modified (loc-root (sedit-state-loc st)))))  ; marker reverts
    (sedit-undo st)                                    ; redo
    (is (file-node-modified (loc-root (sedit-state-loc st))))))
