(in-package #:clautolisp.drawing.tests)

(in-suite drawing-suite)

;;;; Pure-CL model tests for the named-object dictionary tree,
;;;; xrecord/object handling, graphical classification and REGAPP/APPID
;;;; registration added for the SCHMS drawing-data-structures parity.

;;; --- Graphical classification -----------------------------------

(test graphical-entity-p-distinguishes-drawables
  (let ((d (make-drawing)))
    (let ((line (add-entity d (list (cons 0 "LINE") (cons 10 '(0.0 0.0 0.0))
                                    (cons 11 '(1.0 1.0 0.0)))))
          (dict (add-entity d (list (cons 0 "DICTIONARY"))))
          (xrec (add-entity d (list (cons 0 "XRECORD"))))
          (unknown (add-entity d (list (cons 0 "WHATSIT")))))
      (is (graphical-entity-p line))
      (is (not (graphical-entity-p dict)))
      (is (not (graphical-entity-p xrec)))
      ;; Unknown types are treated as graphical (permissive).
      (is (graphical-entity-p unknown)))))

;;; --- Root dictionary --------------------------------------------

(test ensure-root-dictionary-is-idempotent
  (let ((d (make-drawing)))
    (let ((r1 (ensure-root-dictionary d))
          (r2 (ensure-root-dictionary d)))
      (is (dictionary-entity-p r1))
      (is (eq r1 r2))                            ; same object, cached
      (is (string= (entity-handle-id r1) (drawing-root-dictionary-handle d)))
      ;; Exactly one dictionary object exists.
      (let ((n 0))
        (map-entities (lambda (e) (when (dictionary-entity-p e) (incf n))) d)
        (is (= 1 n))))))

;;; --- Dictionary add / search / remove / rename ------------------

(defun %make-xrecord (drawing)
  (entity-handle-id (add-entity drawing (list (cons 0 "XRECORD")
                                              (cons 100 "AcDbXrecord")
                                              (cons 1 "payload")))))

(test dictionary-add-search-remove-lifecycle
  (let ((d (make-drawing)))
    (let* ((root (entity-handle-id (ensure-root-dictionary d)))
           (x1 (%make-xrecord d))
           (x2 (%make-xrecord d)))
      ;; add two entries
      (is (string= x1 (dictionary-add-entry d root "ALPHA" x1)))
      (is (string= x2 (dictionary-add-entry d root "BETA" x2)))
      ;; duplicate key fails (case-insensitive)
      (is (null (dictionary-add-entry d root "alpha" x2)))
      ;; search (case-insensitive)
      (is (string= x1 (dictionary-member-handle d root "ALPHA")))
      (is (string= x1 (dictionary-member-handle d root "alpha")))
      (is (string= x2 (dictionary-member-handle d root "BETA")))
      (is (null (dictionary-member-handle d root "GAMMA")))
      ;; ownership: the member's group 330 points back at the dict
      (let ((m (find-entity d x1)))
        (is (string-equal root (cdr (assoc 330 (entity-handle-data m))))))
      ;; membership set (order-independent)
      (let ((keys (mapcar #'car (dictionary-object-entries d root))))
        (is (null (set-difference keys '("ALPHA" "BETA") :test #'string-equal)))
        (is (null (set-difference '("ALPHA" "BETA") keys :test #'string-equal))))
      ;; remove
      (is (string= x1 (dictionary-remove-entry d root "ALPHA")))
      (is (null (dictionary-member-handle d root "ALPHA")))
      (is (null (dictionary-remove-entry d root "ALPHA")))  ; absent -> nil
      ;; rename
      (is (string= x2 (dictionary-rename-entry d root "BETA" "GAMMA")))
      (is (string= x2 (dictionary-member-handle d root "GAMMA")))
      (is (null (dictionary-member-handle d root "BETA"))))))

(test dictionary-preserves-insertion-order
  (let ((d (make-drawing)))
    (let ((root (entity-handle-id (ensure-root-dictionary d))))
      (dolist (k '("K1" "K2" "K3"))
        (dictionary-add-entry d root k (%make-xrecord d)))
      (is (equal '("K1" "K2" "K3")
                 (mapcar #'car (dictionary-object-entries d root)))))))

(test find-dictionary-rejects-non-dictionary
  (let ((d (make-drawing)))
    (let ((line (add-entity d (list (cons 0 "LINE") (cons 10 '(0.0 0.0 0.0))
                                    (cons 11 '(1.0 1.0 0.0))))))
      (is (null (find-dictionary d (entity-handle-id line))))
      (is (null (dictionary-add-entry d (entity-handle-id line) "X"
                                      (%make-xrecord d)))))))

;;; --- Nested (sub-)dictionaries ----------------------------------

(test nested-sub-dictionary-tree
  (let ((d (make-drawing)))
    (let* ((root (entity-handle-id (ensure-root-dictionary d)))
           (sub  (entity-handle-id (add-entity d (list (cons 0 "DICTIONARY")))))
           (leaf (%make-xrecord d)))
      (is (string= sub (dictionary-add-entry d root "SUBDICT" sub)))
      (is (string= leaf (dictionary-add-entry d sub "LEAF" leaf)))
      ;; walk root -> sub -> leaf
      (let ((sub-again (dictionary-member-handle d root "SUBDICT")))
        (is (string= sub sub-again))
        (is (string= leaf (dictionary-member-handle d sub-again "LEAF")))))))

;;; --- REGAPP / APPID ---------------------------------------------

(test register-appid-once-and-duplicate
  (let ((d (make-drawing)))
    (is (not (appid-registered-p d "SCHMS")))
    (is (string= "SCHMS" (register-appid d "SCHMS")))
    (is (appid-registered-p d "SCHMS"))
    ;; case-insensitive: already registered -> nil
    (is (null (register-appid d "schms")))
    (is (null (register-appid d "SCHMS")))
    ;; a second, distinct application registers fine
    (is (string= "SCHMSPLUS" (register-appid d "SCHMSPLUS")))
    (is (typep (find-table-record d :appid "SCHMS") 'symbol-table-record))))

;;; --- copy-drawing carries the dictionary tree -------------------

(test copy-drawing-preserves-root-and-entries
  (let ((d (make-drawing)))
    (let ((root (entity-handle-id (ensure-root-dictionary d))))
      (dictionary-add-entry d root "K" (%make-xrecord d))
      (let ((c (copy-drawing d)))
        (is (string= root (drawing-root-dictionary-handle c)))
        (is (string= (dictionary-member-handle d root "K")
                     (dictionary-member-handle c root "K")))
        ;; independence: mutating the copy leaves the original intact
        (dictionary-remove-entry c root "K")
        (is (dictionary-member-handle d root "K"))
        (is (null (dictionary-member-handle c root "K")))))))
