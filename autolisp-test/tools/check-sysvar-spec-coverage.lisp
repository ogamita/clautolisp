;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; autolisp-test/tools/check-sysvar-spec-coverage.lisp
;;;;
;;;; Spec-coverage gate for the system-variables Phase 4 deliverable.
;;;; Asserts the three-way invariant:
;;;;
;;;;   1. every sysvar named in autolisp-spec/documentation/
;;;;      autolisp-visual-lisp-specification-draft.org §16 ~** System
;;;;      Variable Entry: NAME~ heading has a matching record in
;;;;      autolisp-spec/documentation/system-variables-inventory.sexp;
;;;;
;;;;   2. every inventory record has a matching cell in the mock-host
;;;;      catalogue clautolisp/autolisp-mock-host/source/sysvar-
;;;;      catalogue.lisp (i.e. *full-sysvar-catalogue*);
;;;;
;;;;   3. every cell in the catalogue has a matching inventory record
;;;;      (no orphans -- guards against an out-of-date generated file).
;;;;
;;;; Returns a non-zero exit code if any invariant is broken.
;;;;
;;;; Usage:
;;;;
;;;;   sbcl --noinform --non-interactive \
;;;;        --load autolisp-test/tools/check-sysvar-spec-coverage.lisp \
;;;;        --eval '(check-coverage :exit-on-failure t)'

(in-package #:cl-user)

(defun read-inventory (path)
  (with-open-file (s path :external-format :utf-8)
    (loop for form = (read s nil :eof) until (eq form :eof) collect form)))

(defun extract-spec-sysvar-names (org-path)
  "Return a sorted list of unique NAMEs that appear as
~** System Variable Entry: NAME~ headings in the spec."
  (let ((names '()))
    (with-open-file (s org-path :external-format :utf-8)
      (loop for line = (read-line s nil :eof)
            until (eq line :eof) do
              (let ((prefix "** System Variable Entry: "))
                (when (and (>= (length line) (length prefix))
                           (string= prefix line :end2 (length prefix)))
                  (push (string-trim " " (subseq line (length prefix)))
                        names)))))
    (sort (delete-duplicates names :test #'string=) #'string<)))

(defun extract-catalogue-names (catalogue-path)
  "Pull NAMEs from *full-sysvar-catalogue* in sysvar-catalogue.lisp."
  ;; The catalogue file uses (in-package ...) which we'd rather not
  ;; eval here. Parse the five-tuple lines instead.
  (let ((names '()))
    (with-open-file (s catalogue-path :external-format :utf-8)
      (loop for line = (read-line s nil :eof)
            until (eq line :eof) do
              (when (and (search "(\"" line)
                         (search "\" :" line))
                (let* ((open (position #\" line))
                       (close (and open (position #\" line :start (1+ open)))))
                  (when (and open close)
                    (push (subseq line (1+ open) close) names))))))
    (sort (delete-duplicates names :test #'string=) #'string<)))

(defun extract-inventory-names (records)
  (sort (mapcar (lambda (r) (getf r :name)) records) #'string<))

(defun set-difference-string (a b)
  (sort (set-difference a b :test #'string=) #'string<))

(defun check-coverage (&key
                        (spec      "autolisp-spec/documentation/autolisp-visual-lisp-specification-draft.org")
                        (inventory "autolisp-spec/documentation/system-variables-inventory.sexp")
                        (catalogue "clautolisp/autolisp-mock-host/source/sysvar-catalogue.lisp")
                        (exit-on-failure nil))
  (let* ((spec-names (extract-spec-sysvar-names spec))
         (inv-records (read-inventory inventory))
         (inv-names  (extract-inventory-names inv-records))
         (cat-names  (extract-catalogue-names catalogue))
         (spec-only       (set-difference-string spec-names inv-names))
         (inv-only-vs-spec (set-difference-string inv-names spec-names))
         (inv-only-vs-cat (set-difference-string inv-names cat-names))
         (cat-only-vs-inv (set-difference-string cat-names inv-names))
         (ok t))
    (format t "~%[spec-coverage] System-variables three-way invariant check~%")
    (format t "  spec (§16)        : ~D entries~%" (length spec-names))
    (format t "  inventory         : ~D records~%" (length inv-names))
    (format t "  mock catalogue    : ~D cells~%" (length cat-names))
    (when spec-only
      (setf ok nil)
      (format t "~%[FAIL] In spec but missing from inventory (~D):~%" (length spec-only))
      (dolist (n (subseq spec-only 0 (min 20 (length spec-only))))
        (format t "    ~A~%" n))
      (when (> (length spec-only) 20)
        (format t "    ... and ~D more~%" (- (length spec-only) 20))))
    (when inv-only-vs-spec
      (setf ok nil)
      (format t "~%[FAIL] In inventory but missing from spec §16 (~D):~%" (length inv-only-vs-spec))
      (dolist (n (subseq inv-only-vs-spec 0 (min 20 (length inv-only-vs-spec))))
        (format t "    ~A~%" n))
      (when (> (length inv-only-vs-spec) 20)
        (format t "    ... and ~D more~%" (- (length inv-only-vs-spec) 20))))
    (when inv-only-vs-cat
      (setf ok nil)
      (format t "~%[FAIL] In inventory but missing from mock catalogue (~D):~%" (length inv-only-vs-cat))
      (dolist (n (subseq inv-only-vs-cat 0 (min 20 (length inv-only-vs-cat))))
        (format t "    ~A~%" n)))
    (when cat-only-vs-inv
      (setf ok nil)
      (format t "~%[FAIL] In mock catalogue but missing from inventory (~D):~%" (length cat-only-vs-inv))
      (dolist (n (subseq cat-only-vs-inv 0 (min 20 (length cat-only-vs-inv))))
        (format t "    ~A~%" n)))
    (cond
      (ok (format t "~%[spec-coverage] PASS: all three sets agree on ~D sysvars.~%" (length spec-names)))
      (t  (format t "~%[spec-coverage] FAIL: sets disagree -- see above.~%")
          (when exit-on-failure
            #+sbcl (sb-ext:exit :code 2)
            #-sbcl (error "spec-coverage check failed."))))
    (values ok
            :spec-only spec-only
            :inv-only-vs-spec inv-only-vs-spec
            :inv-only-vs-cat inv-only-vs-cat
            :cat-only-vs-inv cat-only-vs-inv)))
