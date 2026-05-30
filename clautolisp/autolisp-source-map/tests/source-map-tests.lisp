;;;; clautolisp/autolisp-source-map/tests/source-map-tests.lisp

(in-package #:clautolisp.source.tests)

(in-suite source-map-suite)

(test source-position-equal-compares-by-value
  (let ((a (make-source-position :file "f.lsp" :start-line 1 :start-column 2
                                 :end-line 1 :end-column 5))
        (b (make-source-position :file "f.lsp" :start-line 1 :start-column 2
                                 :end-line 1 :end-column 5))
        (c (make-source-position :file "f.lsp" :start-line 9 :start-column 2
                                 :end-line 9 :end-column 5)))
    (is (source-position-equal a a))
    (is (source-position-equal a b))
    (is (not (source-position-equal a c)))
    (is (source-position-equal nil nil))
    (is (not (source-position-equal a nil)))))

(test note-and-position-of-round-trip
  (clear-source-positions)
  (let ((object (list :x :y))
        (span (clautolisp.autolisp-reader.internal::make-source-span
               :source-name "demo.lsp" :start-line 3 :start-column 4
               :end-line 3 :end-column 10)))
    (is (null (position-of object)))
    (let ((position (note-position object span)))
      (is (source-position-p position))
      (is (string= "demo.lsp" (source-position-file position)))
      (is (= 3 (source-position-start-line position)))
      (is (= 4 (source-position-start-column position)))
      (is (source-position-equal position (position-of object))))))

(test note-position-of-nil-span-is-noop
  (clear-source-positions)
  (let ((object (list :z)))
    (is (null (note-position object nil)))
    (is (null (position-of object)))))

(test tracking-flag-gates-runtime-recording
  ;; With tracking on, a freshly lowered compound form carries a position;
  ;; with tracking off (the default), it does not.
  (clear-source-positions)
  (let ((forms (with-source-tracking ()
                 (clautolisp.autolisp-runtime:read-runtime-from-string
                  "(setq x (foo 1 2))" :source-name "t.lsp"))))
    (let* ((top (first forms))                 ; (SETQ X (FOO 1 2))
           (position (position-of top)))
      (is (source-position-p position))
      (is (string= "t.lsp" (source-position-file position)))
      (is (= 1 (source-position-start-line position)))
      ;; the nested call (FOO 1 2) is the value form, also recorded
      (let ((inner (third top)))
        (is (consp inner))
        (is (source-position-p (position-of inner))))))
  (clear-source-positions)
  (let* ((forms (clautolisp.autolisp-runtime:read-runtime-from-string
                 "(setq x (foo 1 2))" :source-name "t.lsp"))
         (top (first forms)))
    (is (null (position-of top)))))

(test lines-of-reads-file-lines
  (let ((path (merge-pathnames
               (format nil "clautolisp-source-lines-~D.lsp" (random 1000000))
               (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (out path :direction :output :if-exists :supersede)
             (write-line "(defun a () 1)" out)
             (write-line "(defun b () 2)" out))
           (let ((lines (lines-of path)))
             (is (= 2 (length lines)))
             (is (string= "(defun a () 1)" (aref lines 0)))
             (is (string= "(defun b () 2)" (aref lines 1)))))
      (ignore-errors (delete-file path)))
    (is (= 0 (length (lines-of (merge-pathnames "does-not-exist-xyz.lsp"
                                                (uiop:temporary-directory))))))))
