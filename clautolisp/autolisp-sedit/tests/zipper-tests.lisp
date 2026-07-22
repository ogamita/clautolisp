;;;; clautolisp/autolisp-sedit/tests/zipper-tests.lisp
;;;;
;;;; The adorned-tree domain (§6.1) and the Huet zipper motions (§6.2), plus the
;;;; §6.7 motion invariants (totality within a form; right/left inverse; down/up
;;;; inverse).

(in-package #:clautolisp.sedit.tests)

(in-suite sedit-suite)

;;; --- domain (§6.1) --------------------------------------------------------

(test sexp-tree-roundtrip
  (let ((s '(defun foo (a b) (+ a b) "hi" 3)))
    (is (equal s (tree->sexp (sexp->tree s))))))

(test branch-and-leaf-classification
  (is (branch-node-p (sexp->tree '(a b))))
  (is (not (branch-node-p (sexp->tree 'a))))
  (is (branch-node-p (make-file-node "f.lsp" '())))
  (is (branch-node-p (make-dir-node "d" '())))
  (is (not (branch-node-p (make-comment-node ";; hi")))))

(test node-with-children-preserves-labels
  (let* ((f (make-file-node "f.lsp" (list (sexp->tree 'a)) :modified t))
         (g (node-with-children f (list (sexp->tree 'b) (sexp->tree 'c)))))
    (is (equal "f.lsp" (file-node-name g)))
    (is (file-node-modified g))                 ; PLATE keeps the modified flag
    (is (equal '(b c) (tree->sexp g)))))

;;; --- primitive motions (§6.2) ---------------------------------------------

(test down-into-first-child-and-up-is-identity
  (let* ((loc (loc-of '(a b c)))
         (d (loc-down loc)))
    (is (eq 'a (focus-sexp d)))
    (is (equal '(0) (loc-path d)))
    (let ((u (loc-up d)))
      (is (equal '(a b c) (focus-sexp u)))       ; back to the whole form
      (is (null (loc-path u))))))

(test down-on-leaf-or-empty-list-is-nil
  (is (null (loc-down (loc-of 'x))))                       ; an atom: no descent
  (is (null (loc-down (node->loc (make-list-node '())))))) ; an empty list: none

(test right-and-left-are-inverse-in-the-middle
  (let* ((b (loc-of '(a b c d) 1)))
    (is (eq 'b (focus-sexp b)))
    (let* ((c (loc-right b)) (b* (loc-left c)))
      (is (eq 'c (focus-sexp c)))
      (is (equal '(2) (loc-path c)))
      (is (eq 'b (focus-sexp b*)))
      (is (equal '(1) (loc-path b*))))))

(test right-past-last-ascends
  (let* ((c (loc-of '(a b c) 2))
         (up (loc-right c)))
    (is (equal '(a b c) (focus-sexp up)))        ; ascended to the parent
    (is (null (loc-path up)))))

(test left-before-first-ascends
  (let* ((a (loc-of '(a b c) 0))
         (up (loc-left a)))
    (is (equal '(a b c) (focus-sexp up)))
    (is (null (loc-path up)))))

(test first-last-and-skip
  (let ((b (loc-of '(a b c d e) 1)))
    (is (eq 'a (focus-sexp (loc-first b))))
    (is (eq 'e (focus-sexp (loc-last b))))
    (is (eq 'd (focus-sexp (loc-skip b 2))))
    (is (eq 'a (focus-sexp (loc-skip b -3))))
    (is (eq 'e (focus-sexp (loc-skip b 99))))    ; clamps at the last
    (is (eq 'a (focus-sexp (loc-skip b -99)))))) ; clamps at the first

(test first-and-last-are-identity-at-root
  (let ((r (loc-of '(a b c))))
    (is (null (loc-path (loc-first r))))
    (is (null (loc-path (loc-last r))))
    (is (null (loc-path (loc-skip r 5))))))

;;; --- level tags (§6.2) ----------------------------------------------------

(test level-tags-across-boundaries
  (is (eq :root (loc-level (loc-of '(a b)))))
  (is (eq :sexp (loc-level (loc-of '(a b) 0))))  ; inside a list
  (let* ((file (make-file-node "f.lsp" (list (sexp->tree '(a)) (sexp->tree '(b)))))
         (form (loc-down (node->loc file))))
    (is (eq :form (loc-level form)))             ; a file's children are forms
    (is (eq :sexp (loc-level (loc-down form))))) ; descending a form -> sexps
  (let* ((dir (make-dir-node "d" (list (make-file-node "a.lsp" '())
                                       (make-file-node "b.lsp" '()))))
         (entry (loc-down (node->loc dir))))
    (is (eq :file (loc-level entry)))))          ; a directory's children are files

;;; --- path round-trip ------------------------------------------------------

(test path-and-follow-roundtrip
  (let* ((s '(a (b (c d) e) f))
         (deep (loc-of s 1 1 0)))                ; -> c
    (is (eq 'c (focus-sexp deep)))
    (is (equal '(1 1 0) (loc-path deep)))
    (is (eq 'c (focus-sexp (loc-follow (sexp->tree s) (loc-path deep)))))))

;;; --- §6.7 motion totality within a form -----------------------------------

(test motion-totality-visits-every-child-in-order
  ;; iterating loc-right from the first child visits every child in reading
  ;; order, then ascends (right past the last one)
  (let* ((root (loc-of '(a b c d)))
         (foci '()))
    (loop for l = (loc-down root) then (loc-right l)
          while (loc-ctx l)                      ; stop once it ascends to the root
          do (push (focus-sexp l) foci))
    (is (equal '(a b c d) (nreverse foci)))))

(test down-up-inverse-at-depth
  ;; down then up returns the same tree and selection at every navigable node
  (let ((deep (loc-of '(f (g h) i) 1 0)))        ; -> g
    (is (eq 'g (focus-sexp deep)))
    ;; up then re-descend to the same index restores the selection
    (let* ((parent (loc-up deep))
           (again (loc-skip (loc-down parent) 0)))
      (is (eq 'g (focus-sexp again)))
      (is (equal (loc-path deep) (loc-path again))))))
