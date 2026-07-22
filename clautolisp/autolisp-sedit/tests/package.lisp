;;;; clautolisp/autolisp-sedit/tests/package.lisp

(defpackage #:clautolisp.sedit.tests
  (:use #:cl #:clautolisp.sedit)
  (:import-from #:fiveam
                #:def-suite #:in-suite #:test #:is #:signals #:run #:explain! #:results-status)
  (:export #:run-all-tests))

(in-package #:clautolisp.sedit.tests)

(def-suite sedit-suite
  :description "clautolisp.sedit Phase 1: adorned trees, the Huet zipper, and the editing transitions.")

(defun run-all-tests ()
  ;; Force the :NULL clipboard provider so tests never touch a real system
  ;; clipboard (deterministic, no subprocesses); clipboard tests bind their own.
  (let ((clautolisp.sedit:*clipboard-provider* :null))
    (let ((results (run 'sedit-suite)))
      (explain! results)
      (unless (results-status results)
        (error "clautolisp.sedit tests failed.")))))

;;; --- fixtures -------------------------------------------------------------

(defun loc-of (sexp &rest path)
  "A location into (SEXP->TREE SEXP) at the given child-index PATH."
  (loc-follow (sexp->tree sexp) path))

(defun root-sexp (loc)
  "The plain sexp of LOC's whole tree (for structural comparison)."
  (tree->sexp (loc-root loc)))

(defun focus-sexp (loc)
  "The plain sexp of LOC's focus."
  (tree->sexp (loc-focus loc)))
