(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;; --- Class hierarchy ----------------------------------------------

(test cador-is-a-host
  (let ((mock (make-cador)))
    (is (typep mock 'cador))
    (is (typep mock 'host))
    (is (string= "cador" (host-name mock)))))

(test make-cador-accepts-custom-name
  (let ((mock (make-cador :name "fixture")))
    (is (string= "fixture" (host-name mock)))))

;;; --- Empty fixture ------------------------------------------------

(test empty-cador-has-empty-handle-tables
  (let ((mock (make-cador :populate-tables-p nil
                              :populate-sysvars-p nil)))
    (is (zerop (hash-table-count (cador-entities mock))))
    (is (zerop (hash-table-count (cador-picksets mock))))
    (is (zerop (hash-table-count (cador-tables mock))))
    (is (zerop (hash-table-count (cador-sysvars mock))))
    (is (typep (cador-named-object-dictionary mock) 'dictionary))
    (is (null (cador-pickfirst mock)))))

;;; --- Default tables -----------------------------------------------

(test default-cador-has-standard-tables
  (let ((mock (make-cador)))
    (let ((layer-table (cador-table mock :layer)))
      (is (typep layer-table 'hash-table))
      (let ((zero (gethash "0" layer-table)))
        (is (typep zero 'symbol-table-record))
        (is (string= "0" (symbol-table-record-name zero)))
        (is (eq :layer (symbol-table-record-kind zero)))))
    (is (typep (cador-find-table-record mock :ltype "BYBLOCK")
               'symbol-table-record))
    (is (typep (cador-find-table-record mock :ltype "BYLAYER")
               'symbol-table-record))
    (is (typep (cador-find-table-record mock :ltype "Continuous")
               'symbol-table-record))
    (is (typep (cador-find-table-record mock :block-record "*Model_Space")
               'symbol-table-record))
    (is (typep (cador-find-table-record mock :style "Standard")
               'symbol-table-record))
    (is (typep (cador-find-table-record mock :appid "ACAD")
               'symbol-table-record))
    (is (null (cador-find-table-record mock :layer "Nope")))))

(test cador-add-table-record-installs-record
  (let* ((mock (make-cador))
         (rec  (make-symbol-table-record :kind :layer :name "Mine"
                                          :data '((0 . "LAYER") (2 . "Mine")))))
    (cador-add-table-record mock rec)
    (is (eq rec (cador-find-table-record mock :layer "Mine")))))

;;; --- Default sysvars ----------------------------------------------

(test default-cador-has-conservative-sysvars
  (let ((mock (make-cador)))
    (let ((cmdecho (cador-sysvar mock "CMDECHO")))
      (is (typep cmdecho 'sysvar-cell))
      (is (eq :integer (sysvar-cell-kind cmdecho)))
      (is (eql 1 (sysvar-cell-value cmdecho))))
    (let ((clayer (cador-sysvar mock "CLAYER")))
      (is (string= "0" (sysvar-cell-value clayer))))
    (let ((angbase (cador-sysvar mock "ANGBASE")))
      (is (eq :real (sysvar-cell-kind angbase)))
      (is (zerop (sysvar-cell-value angbase))))
    (let ((useri1 (cador-sysvar mock "USERI1"))
          (userr5 (cador-sysvar mock "USERR5"))
          (users3 (cador-sysvar mock "USERS3")))
      (is (eql 0 (sysvar-cell-value useri1)))
      (is (zerop (sysvar-cell-value userr5)))
      (is (string= "" (sysvar-cell-value users3))))
    (let ((dwgname (cador-sysvar mock "DWGNAME")))
      (is (sysvar-cell-read-only-p dwgname)))))

(test cador-set-sysvar-mutates-writable-cells
  (let ((mock (make-cador)))
    (cador-set-sysvar mock "CLAYER" "Drafting")
    (is (string= "Drafting"
                 (sysvar-cell-value (cador-sysvar mock "CLAYER"))))))

(test cador-set-sysvar-rejects-read-only
  (let ((mock (make-cador)))
    (handler-case
        (progn (cador-set-sysvar mock "DWGNAME" "Other.dwg")
               (is nil))
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported
                (autolisp-runtime-error-code condition)))))))

(test sysvar-name-lookup-is-case-insensitive
  (let ((mock (make-cador)))
    (is (typep (cador-sysvar mock "clayer") 'sysvar-cell))
    (is (typep (cador-sysvar mock "Clayer") 'sysvar-cell))
    (is (typep (cador-sysvar mock "CLAYER") 'sysvar-cell))))

;;; --- Snapshot / restore -------------------------------------------

(test cador-snapshot-is-deterministic-and-self-restoring
  (let* ((mock (make-cador))
         (entity (make-entity-handle
                  :kind :line
                  :data '((0 . "LINE") (8 . "0") (10 0.0d0 0.0d0 0.0d0)
                          (11 5.0d0 5.0d0 0.0d0)))))
    ;; Install one entity, mutate one sysvar, set pickfirst.
    (setf (gethash (clautolisp.cador::entity-handle-id entity)
                   (cador-entities mock))
          entity)
    (cador-set-sysvar mock "CMDECHO" 0)
    (let ((snap-1 (cador-snapshot mock)))
      (is (eq :integer
              (getf (cdr (assoc "CMDECHO"
                                (getf snap-1 :sysvars)
                                :test #'string=))
                    :kind)))
      (is (string= "0" (sysvar-cell-value (cador-sysvar mock "CLAYER"))))
      ;; Mutate further, then restore.
      (cador-set-sysvar mock "CLAYER" "Different")
      (let ((entity-count-before-restore
             (hash-table-count (cador-entities mock))))
        (declare (ignorable entity-count-before-restore)))
      (cador-restore mock snap-1)
      (is (string= "0" (sysvar-cell-value (cador-sysvar mock "CLAYER"))))
      (is (= 1 (hash-table-count (cador-entities mock))))
      (is (eql 0 (sysvar-cell-value (cador-sysvar mock "CMDECHO")))))))

;;; --- Slot defaults exist for prompt + display log -----------------

(test cador-has-prompt-output-and-display-log
  (let ((mock (make-cador)))
    (is (output-stream-p (cador-prompt-output mock)))
    (is (null (cador-display-log mock)))
    (push :grdraw-1 (cador-display-log mock))
    (is (equal '(:grdraw-1) (cador-display-log mock)))))

;;; --- Phase-9 contract: host operations on a default MockHost -----
;;;
;;; MockHost in Phase 9 has only the data carriers; all host
;;; operations still fall through to the base-class fallback methods
;;; on `host` and signal :host-not-supported. Phase 10 fills these
;;; in.

(test cador-operations-error-with-host-not-supported-when-not-yet-implemented
  ;; Phase 10/11/12 implemented the entity, sysvar, and prompt
  ;; surfaces. Graphics (grdraw / grtext / grvecs / grclear /
  ;; grread / redraw) and the command dispatcher remain inherited
  ;; from the base-class :host-not-supported fallback until later
  ;; phases fill them in.
  (let ((mock (make-cador)))
    (handler-case (host-grdraw mock '(0 0) '(1 1) 7 nil)
      (autolisp-runtime-error (condition)
        (is (eq :host-not-supported (autolisp-runtime-error-code condition)))))))

;;; --- Sanity: pickset / dictionary / sysvar-cell shapes ------------

(test pickset-construction-and-membership
  (let* ((p (make-pickset))
         (e (make-entity-handle :kind :line)))
    (push e (clautolisp.cador::pickset-members p))
    (is (member e (clautolisp.cador::pickset-members p)))))

(test dictionary-entries-are-a-hash-table
  (let ((d (make-dictionary)))
    (is (typep (dictionary-entries d) 'hash-table))
    (setf (gethash "FOO" (dictionary-entries d)) :bar)
    (is (eq :bar (gethash "FOO" (dictionary-entries d))))))
