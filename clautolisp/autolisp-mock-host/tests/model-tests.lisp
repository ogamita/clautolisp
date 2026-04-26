(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;; --- Class hierarchy ----------------------------------------------

(test mock-host-is-a-host
  (let ((mock (make-mock-host)))
    (is (typep mock 'mock-host))
    (is (typep mock 'host))
    (is (string= "mock-host" (host-name mock)))))

(test make-mock-host-accepts-custom-name
  (let ((mock (make-mock-host :name "fixture")))
    (is (string= "fixture" (host-name mock)))))

;;; --- Empty fixture ------------------------------------------------

(test empty-mock-host-has-empty-handle-tables
  (let ((mock (make-mock-host :populate-tables-p nil
                              :populate-sysvars-p nil)))
    (is (zerop (hash-table-count (mock-host-entities mock))))
    (is (zerop (hash-table-count (mock-host-picksets mock))))
    (is (zerop (hash-table-count (mock-host-tables mock))))
    (is (zerop (hash-table-count (mock-host-sysvars mock))))
    (is (typep (mock-host-named-object-dictionary mock) 'dictionary))
    (is (null (mock-host-pickfirst mock)))))

;;; --- Default tables -----------------------------------------------

(test default-mock-host-has-standard-tables
  (let ((mock (make-mock-host)))
    (let ((layer-table (mock-host-table mock :layer)))
      (is (typep layer-table 'hash-table))
      (let ((zero (gethash "0" layer-table)))
        (is (typep zero 'symbol-table-record))
        (is (string= "0" (symbol-table-record-name zero)))
        (is (eq :layer (symbol-table-record-kind zero)))))
    (is (typep (mock-host-find-table-record mock :ltype "BYBLOCK")
               'symbol-table-record))
    (is (typep (mock-host-find-table-record mock :ltype "BYLAYER")
               'symbol-table-record))
    (is (typep (mock-host-find-table-record mock :ltype "Continuous")
               'symbol-table-record))
    (is (typep (mock-host-find-table-record mock :block-record "*Model_Space")
               'symbol-table-record))
    (is (typep (mock-host-find-table-record mock :style "Standard")
               'symbol-table-record))
    (is (typep (mock-host-find-table-record mock :appid "ACAD")
               'symbol-table-record))
    (is (null (mock-host-find-table-record mock :layer "Nope")))))

(test mock-host-add-table-record-installs-record
  (let* ((mock (make-mock-host))
         (rec  (make-symbol-table-record :kind :layer :name "Mine"
                                          :data '((0 . "LAYER") (2 . "Mine")))))
    (mock-host-add-table-record mock rec)
    (is (eq rec (mock-host-find-table-record mock :layer "Mine")))))

;;; --- Default sysvars ----------------------------------------------

(test default-mock-host-has-conservative-sysvars
  (let ((mock (make-mock-host)))
    (let ((cmdecho (mock-host-sysvar mock "CMDECHO")))
      (is (typep cmdecho 'sysvar-cell))
      (is (eq :integer (sysvar-cell-kind cmdecho)))
      (is (eql 1 (sysvar-cell-value cmdecho))))
    (let ((clayer (mock-host-sysvar mock "CLAYER")))
      (is (string= "0" (sysvar-cell-value clayer))))
    (let ((angbase (mock-host-sysvar mock "ANGBASE")))
      (is (eq :real (sysvar-cell-kind angbase)))
      (is (zerop (sysvar-cell-value angbase))))
    (let ((useri1 (mock-host-sysvar mock "USERI1"))
          (userr5 (mock-host-sysvar mock "USERR5"))
          (users3 (mock-host-sysvar mock "USERS3")))
      (is (eql 0 (sysvar-cell-value useri1)))
      (is (zerop (sysvar-cell-value userr5)))
      (is (string= "" (sysvar-cell-value users3))))
    (let ((dwgname (mock-host-sysvar mock "DWGNAME")))
      (is (sysvar-cell-read-only-p dwgname)))))

(test mock-host-set-sysvar-mutates-writable-cells
  (let ((mock (make-mock-host)))
    (mock-host-set-sysvar mock "CLAYER" "Drafting")
    (is (string= "Drafting"
                 (sysvar-cell-value (mock-host-sysvar mock "CLAYER"))))))

(test mock-host-set-sysvar-rejects-read-only
  (let ((mock (make-mock-host)))
    (handler-case
        (progn (mock-host-set-sysvar mock "DWGNAME" "Other.dwg")
               (is nil))
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported
                (autolisp-runtime-error-code condition)))))))

(test sysvar-name-lookup-is-case-insensitive
  (let ((mock (make-mock-host)))
    (is (typep (mock-host-sysvar mock "clayer") 'sysvar-cell))
    (is (typep (mock-host-sysvar mock "Clayer") 'sysvar-cell))
    (is (typep (mock-host-sysvar mock "CLAYER") 'sysvar-cell))))

;;; --- Snapshot / restore -------------------------------------------

(test mock-host-snapshot-is-deterministic-and-self-restoring
  (let* ((mock (make-mock-host))
         (entity (make-entity-handle
                  :kind :line
                  :data '((0 . "LINE") (8 . "0") (10 0.0d0 0.0d0 0.0d0)
                          (11 5.0d0 5.0d0 0.0d0)))))
    ;; Install one entity, mutate one sysvar, set pickfirst.
    (setf (gethash (clautolisp.autolisp-mock-host::entity-handle-id entity)
                   (mock-host-entities mock))
          entity)
    (mock-host-set-sysvar mock "CMDECHO" 0)
    (let ((snap-1 (mock-host-snapshot mock)))
      (is (eq :integer
              (getf (cdr (assoc "CMDECHO"
                                (getf snap-1 :sysvars)
                                :test #'string=))
                    :kind)))
      (is (string= "0" (sysvar-cell-value (mock-host-sysvar mock "CLAYER"))))
      ;; Mutate further, then restore.
      (mock-host-set-sysvar mock "CLAYER" "Different")
      (let ((entity-count-before-restore
             (hash-table-count (mock-host-entities mock))))
        (declare (ignorable entity-count-before-restore)))
      (mock-host-restore mock snap-1)
      (is (string= "0" (sysvar-cell-value (mock-host-sysvar mock "CLAYER"))))
      (is (= 1 (hash-table-count (mock-host-entities mock))))
      (is (eql 0 (sysvar-cell-value (mock-host-sysvar mock "CMDECHO")))))))

;;; --- Slot defaults exist for prompt + display log -----------------

(test mock-host-has-prompt-output-and-display-log
  (let ((mock (make-mock-host)))
    (is (output-stream-p (mock-host-prompt-output mock)))
    (is (null (mock-host-display-log mock)))
    (push :grdraw-1 (mock-host-display-log mock))
    (is (equal '(:grdraw-1) (mock-host-display-log mock)))))

;;; --- Phase-9 contract: host operations on a default MockHost -----
;;;
;;; MockHost in Phase 9 has only the data carriers; all host
;;; operations still fall through to the base-class fallback methods
;;; on `host` and signal :host-not-supported. Phase 10 fills these
;;; in.

(test mock-host-operations-error-with-host-not-supported-when-not-yet-implemented
  ;; Phase 10/11/12 implemented the entity, sysvar, and prompt
  ;; surfaces. Graphics (grdraw / grtext / grvecs / grclear /
  ;; grread / redraw) and the command dispatcher remain inherited
  ;; from the base-class :host-not-supported fallback until later
  ;; phases fill them in.
  (let ((mock (make-mock-host)))
    (handler-case (host-grdraw mock '(0 0) '(1 1) 7 nil)
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported (autolisp-runtime-error-code condition)))))))

;;; --- Sanity: pickset / dictionary / sysvar-cell shapes ------------

(test pickset-construction-and-membership
  (let* ((p (make-pickset))
         (e (make-entity-handle :kind :line)))
    (push e (clautolisp.autolisp-mock-host::pickset-members p))
    (is (member e (clautolisp.autolisp-mock-host::pickset-members p)))))

(test dictionary-entries-are-a-hash-table
  (let ((d (make-dictionary)))
    (is (typep (dictionary-entries d) 'hash-table))
    (setf (gethash "FOO" (dictionary-entries d)) :bar)
    (is (eq :bar (gethash "FOO" (dictionary-entries d))))))
