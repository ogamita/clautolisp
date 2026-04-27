(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;; --- Phase 11: selection sets, tables, sysvars on MockHost --------

(defun ent-of (handle) (cdr (first handle)))

(defun seed-three-lines (mock)
  (let ((a (host-entmake mock (list (cons 0 "LINE") (cons 8 "L1"))))
        (b (host-entmake mock (list (cons 0 "LINE") (cons 8 "L2"))))
        (c (host-entmake mock (list (cons 0 "CIRCLE") (cons 8 "L1")))))
    (values (ent-of a) (ent-of b) (ent-of c))))

;;; ssget -----------------------------------------------------------

(test ssget-x-without-filter-returns-pickset-of-all-entities
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (declare (ignore a b c))
      (let ((set (host-ssget mock nil :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
        (is (typep set 'clautolisp.autolisp-runtime:autolisp-pickset))
        (is (eql 3 (host-sslength mock set)))))))

(test ssget-x-with-type-filter-returns-only-matches
  (let ((mock (make-mock-host)))
    (seed-three-lines mock)
    (let ((set (host-ssget mock '((0 . "LINE"))
                                :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
      (is (eql 2 (host-sslength mock set))))))

(test ssget-x-with-layer-filter-honours-string-match
  (let ((mock (make-mock-host)))
    (seed-three-lines mock)
    (let ((set (host-ssget mock '((8 . "L1"))
                                :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
      (is (eql 2 (host-sslength mock set))))))

(test ssget-x-with-comma-alternation-matches-any
  (let ((mock (make-mock-host)))
    (seed-three-lines mock)
    (let ((set (host-ssget mock '((0 . "LINE,CIRCLE"))
                                :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
      (is (eql 3 (host-sslength mock set))))))

(test ssget-x-with-wildcard-matches-prefix
  (let ((mock (make-mock-host)))
    (seed-three-lines mock)
    (let ((set (host-ssget mock '((8 . "L*"))
                                :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
      (is (eql 3 (host-sslength mock set))))))

(test ssget-empty-result-returns-nil
  (let ((mock (make-mock-host)))
    (seed-three-lines mock)
    (let ((set (host-ssget mock '((0 . "ARC"))
                                :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
      (is (null set)))))

(test ssget-without-mode-signals-host-not-supported
  (let ((mock (make-mock-host)))
    (handler-case (host-ssget mock nil)
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported (autolisp-runtime-error-code condition)))))))

(test ssget-with-unsupported-mode-signals
  (let ((mock (make-mock-host)))
    (handler-case (host-ssget mock nil :mode (clautolisp.autolisp-runtime:make-autolisp-string "L"))
      (autolisp-runtime-error (condition)
        (is (eq :unsupported-ssget-mode
                (autolisp-runtime-error-code condition)))))))

;;; ssadd / ssdel / ssname / sslength / ssmemb -----------------------

(test ssadd-creates-and-extends-pickset
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (declare (ignore c))
      (let* ((empty (host-ssadd mock nil nil))
             (with-a (host-ssadd mock nil a)))
        (is (eql 0 (host-sslength mock empty)))
        (is (eql 1 (host-sslength mock with-a)))
        (host-ssadd mock with-a b)
        (is (eql 2 (host-sslength mock with-a)))))))

(test ssdel-removes-when-present-and-nil-otherwise
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (declare (ignore c))
      (let ((set (host-ssadd mock nil a)))
        (host-ssadd mock set b)
        (is (eq set (host-ssdel mock set a)))
        (is (eql 1 (host-sslength mock set)))
        ;; Removing again: returns nil.
        (is (null (host-ssdel mock set a)))))))

(test ssname-returns-ename-by-zero-based-index
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (declare (ignore c))
      (let* ((set (host-ssadd mock nil a)))
        (host-ssadd mock set b)
        (is (string= (clautolisp.autolisp-runtime:autolisp-ename-value a)
                     (clautolisp.autolisp-runtime:autolisp-ename-value
                      (host-ssname mock set 0))))
        (is (string= (clautolisp.autolisp-runtime:autolisp-ename-value b)
                     (clautolisp.autolisp-runtime:autolisp-ename-value
                      (host-ssname mock set 1))))
        (is (null (host-ssname mock set 99)))))))

(test ssmemb-distinguishes-members-from-non-members
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (let ((set (host-ssadd mock nil a)))
        (host-ssadd mock set b)
        (is (eq a (host-ssmemb mock set a)))
        (is (null (host-ssmemb mock set c)))))))

(test ssgetfirst-and-sssetfirst-round-trip
  (let ((mock (make-mock-host)))
    (multiple-value-bind (a b c) (seed-three-lines mock)
      (declare (ignore b c))
      (is (null (host-ssgetfirst mock)))
      (let ((set (host-ssadd mock nil a)))
        (host-sssetfirst mock set)
        (let ((got (host-ssgetfirst mock)))
          (is (and (consp got) (typep (second got)
                                       'clautolisp.autolisp-runtime:autolisp-pickset))))))))

;;; tblsearch / tblnext / tblobjname --------------------------------

(test tblsearch-finds-default-records
  (let ((mock (make-mock-host)))
    (let ((data (host-tblsearch mock "LAYER" "0")))
      (is (consp data))
      (is (string= "0" (cdr (assoc 2 data)))))
    (is (null (host-tblsearch mock "LAYER" "Nope")))))

(test tblnext-walks-and-rewinds
  (let ((mock (make-mock-host :populate-tables-p nil)))
    (mock-host-add-table-record mock (make-symbol-table-record :kind :layer :name "Alpha"
                                                                :data '((0 . "LAYER") (2 . "Alpha"))))
    (mock-host-add-table-record mock (make-symbol-table-record :kind :layer :name "Beta"
                                                                :data '((0 . "LAYER") (2 . "Beta"))))
    (let ((first (host-tblnext mock "LAYER" :rewind t)))
      (is (string= "Alpha" (cdr (assoc 2 first)))))
    (let ((second (host-tblnext mock "LAYER")))
      (is (string= "Beta" (cdr (assoc 2 second)))))
    (is (null (host-tblnext mock "LAYER")))
    ;; Rewind restarts.
    (let ((rewound (host-tblnext mock "LAYER" :rewind t)))
      (is (string= "Alpha" (cdr (assoc 2 rewound)))))))

(test tblobjname-returns-an-ename-for-known-records
  (let ((mock (make-mock-host)))
    (let ((ename (host-tblobjname mock "LAYER" "0")))
      (is (typep ename 'clautolisp.autolisp-runtime:autolisp-ename)))
    (is (null (host-tblobjname mock "LAYER" "Nope")))))

;;; getvar / setvar ------------------------------------------------

(test getvar-returns-cell-value-with-string-wrapping
  (let ((mock (make-mock-host)))
    (let ((cmdecho (host-getvar mock "CMDECHO")))
      (is (eql 1 cmdecho)))
    (let ((clayer (host-getvar mock "CLAYER")))
      (is (typep clayer 'clautolisp.autolisp-runtime:autolisp-string))
      (is (string= "0"
                   (clautolisp.autolisp-runtime:autolisp-string-value clayer))))))

(test getvar-on-unknown-name-returns-nil
  (let ((mock (make-mock-host)))
    (is (null (host-getvar mock "DOES-NOT-EXIST")))))

(test setvar-coerces-and-mutates-writable-cells
  (let ((mock (make-mock-host)))
    (host-setvar mock "CMDECHO" 0)
    (is (eql 0 (host-getvar mock "CMDECHO")))
    (host-setvar mock "ANGBASE" 1.5)
    (is (= 1.5d0 (host-getvar mock "ANGBASE")))
    (host-setvar mock "CLAYER"
                 (clautolisp.autolisp-runtime:make-autolisp-string "Drafting"))
    (is (string= "Drafting"
                 (clautolisp.autolisp-runtime:autolisp-string-value
                  (host-getvar mock "CLAYER"))))))

(test setvar-rejects-read-only-and-unknown
  (let ((mock (make-mock-host)))
    (handler-case
        (host-setvar mock "DWGNAME"
                     (clautolisp.autolisp-runtime:make-autolisp-string "Other"))
      (autolisp-runtime-error (condition)
        (is (eq :sysvar-read-only
                (autolisp-runtime-error-code condition)))))
    (handler-case (host-setvar mock "NO-SUCH" 1)
      (autolisp-runtime-error (condition)
        (is (eq :unknown-sysvar
                (autolisp-runtime-error-code condition)))))))

(test setvar-rejects-type-mismatch
  (let ((mock (make-mock-host)))
    (handler-case
        (host-setvar mock "CLAYER" 42)
      (autolisp-runtime-error (condition)
        (is (eq :invalid-sysvar-value
                (autolisp-runtime-error-code condition)))))))
