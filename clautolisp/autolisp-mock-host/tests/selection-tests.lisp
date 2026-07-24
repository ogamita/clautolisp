(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;; --- Phase 11: selection sets, tables, sysvars on MockHost --------

(defun ent-of (handle) (cdr (first handle)))

(defun seed-three-lines (mock)
  ;; Supply the vendor-required geometry codes so ENTMAKE's family
  ;; validation accepts these entities (LINE needs 10/11; CIRCLE 10/40).
  (let ((a (host-entmake mock (list (cons 0 "LINE") (cons 8 "L1")
                                    (cons 10 '(0.0d0 0.0d0 0.0d0))
                                    (cons 11 '(1.0d0 1.0d0 0.0d0)))))
        (b (host-entmake mock (list (cons 0 "LINE") (cons 8 "L2")
                                    (cons 10 '(0.0d0 0.0d0 0.0d0))
                                    (cons 11 '(2.0d0 2.0d0 0.0d0)))))
        (c (host-entmake mock (list (cons 0 "CIRCLE") (cons 8 "L1")
                                    (cons 10 '(0.0d0 0.0d0 0.0d0))
                                    (cons 40 1.0d0)))))
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

;;; ssget filter grammar: -4 relational / logical, -3 xdata ---------

(defun ss-x (mock filter)
  "Run (ssget \"X\" FILTER) on MOCK and return its member count (0 when
the result is nil)."
  (let ((set (host-ssget mock filter
                         :mode (clautolisp.autolisp-runtime:make-autolisp-string "X"))))
    (if set (host-sslength mock set) 0)))

(defun seed-mixed (mock)
  "Three LINEs with colour (62) 1/2/3 on layers WALL/WALL/DOOR, plus a
CIRCLE with xdata under application MYAPP."
  (host-entmake mock (list (cons 0 "LINE") (cons 8 "WALL") (cons 62 1)
                           (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 11 '(1.0d0 0.0d0 0.0d0))))
  (host-entmake mock (list (cons 0 "LINE") (cons 8 "WALL") (cons 62 2)
                           (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 11 '(2.0d0 0.0d0 0.0d0))))
  (host-entmake mock (list (cons 0 "LINE") (cons 8 "DOOR") (cons 62 3)
                           (cons 10 '(0.0d0 0.0d0 0.0d0)) (cons 11 '(3.0d0 0.0d0 0.0d0))))
  (let ((c (host-entmakex mock (list (cons 0 "CIRCLE") (cons 8 "DOOR")
                                     (cons 10 '(5.0d0 5.0d0 0.0d0)) (cons 40 1.0d0)))))
    (host-regapp mock (clautolisp.autolisp-runtime:make-autolisp-string "MYAPP"))
    ;; entmod the vendor way: append xdata to the full entget list so no
    ;; ordinary group code (here the layer 8) is dropped.
    (host-entmod mock (append (host-entget mock c)
                              (list (list -3 (list "MYAPP" (cons 1000 "tag")
                                                   (cons 1070 7))))))
    c))

(test ssget-comma-layer-list-matches-any
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    (is (= 2 (ss-x mock '((0 . "LINE") (8 . "WALL,SLAB")))))
    (is (= 4 (ss-x mock '((8 . "WALL,DOOR")))))))

(test ssget-or-logical-operator
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; colour 1 OR colour 3 -> two LINEs
    (is (= 2 (ss-x mock (list (cons 0 "LINE")
                              (cons -4 "<OR") (cons 62 1) (cons 62 3)
                              (cons -4 "OR>")))))))

(test ssget-and-not-logical-operators
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; LINEs that are NOT on layer WALL -> the single DOOR line
    (is (= 1 (ss-x mock (list (cons 0 "LINE")
                              (cons -4 "<NOT") (cons 8 "WALL") (cons -4 "NOT>")))))
    ;; explicit AND of type + layer
    (is (= 2 (ss-x mock (list (cons -4 "<AND") (cons 0 "LINE") (cons 8 "WALL")
                              (cons -4 "AND>")))))))

(test ssget-xor-logical-operator
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; XOR: on WALL xor colour 1. line1 (WALL,1)=T xor T = nil;
    ;; line2 (WALL,2)=T xor nil = T; line3 (DOOR,3)=nil xor nil = nil;
    ;; circle (DOOR) excluded by neither -> nil xor nil = nil.
    (is (= 1 (ss-x mock (list (cons -4 "<XOR") (cons 8 "WALL") (cons 62 1)
                              (cons -4 "XOR>")))))))

(test ssget-relational-comparisons
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; colour > 1  -> colours 2 and 3
    (is (= 2 (ss-x mock (list (cons 0 "LINE") (cons -4 ">") (cons 62 1)))))
    ;; colour <= 2 -> colours 1 and 2
    (is (= 2 (ss-x mock (list (cons 0 "LINE") (cons -4 "<=") (cons 62 2)))))
    ;; colour != 2 -> colours 1 and 3
    (is (= 2 (ss-x mock (list (cons 0 "LINE") (cons -4 "!=") (cons 62 2)))))))

(test ssget-xdata-application-filter
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; -3 MYAPP -> only the circle carries xdata for MYAPP
    (is (= 1 (ss-x mock (list (cons 0 "CIRCLE") (list -3 (list "MYAPP"))))))
    ;; -3 with a wildcard app name
    (is (= 1 (ss-x mock (list (list -3 (list "MY*"))))))
    ;; -3 for an application nobody registered data under -> empty
    (is (= 0 (ss-x mock (list (list -3 (list "OTHER"))))))))

(test ssget-handle-filter
  (let ((mock (make-mock-host)))
    (let ((e (host-entmakex mock (list (cons 0 "LINE")
                                       (cons 10 '(0.0d0 0.0d0 0.0d0))
                                       (cons 11 '(1.0d0 1.0d0 0.0d0))))))
      (let* ((data (host-entget mock e))
             (handle (autolisp-string-value (cdr (assoc 5 data)))))
        (is (= 1 (ss-x mock (list (cons 5 handle)))))))))

(test ssget-malformed-filter-tail-does-not-crash
  (let ((mock (make-mock-host)))
    (seed-mixed mock)
    ;; a dangling operator with no operand degrades gracefully
    (is (integerp (ss-x mock (list (cons 0 "LINE") (cons -4 ">")))))
    ;; an unmatched closer is skipped
    (is (= 3 (ss-x mock (list (cons 0 "LINE") (cons -4 "AND>")))))))

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
      ;; string values come back AutoLISP-wrapped (autolisp-string).
      (is (string= "0" (autolisp-string-value (cdr (assoc 2 data))))))
    (is (null (host-tblsearch mock "LAYER" "Nope")))))

(test tblnext-walks-and-rewinds
  (let ((mock (make-mock-host :populate-tables-p nil)))
    (mock-host-add-table-record mock (make-symbol-table-record :kind :layer :name "Alpha"
                                                                :data '((0 . "LAYER") (2 . "Alpha"))))
    (mock-host-add-table-record mock (make-symbol-table-record :kind :layer :name "Beta"
                                                                :data '((0 . "LAYER") (2 . "Beta"))))
    (let ((first (host-tblnext mock "LAYER" :rewind t)))
      (is (string= "Alpha" (autolisp-string-value (cdr (assoc 2 first))))))
    (let ((second (host-tblnext mock "LAYER")))
      (is (string= "Beta" (autolisp-string-value (cdr (assoc 2 second))))))
    (is (null (host-tblnext mock "LAYER")))
    ;; Rewind restarts.
    (let ((rewound (host-tblnext mock "LAYER" :rewind t)))
      (is (string= "Alpha" (autolisp-string-value (cdr (assoc 2 rewound))))))))

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
