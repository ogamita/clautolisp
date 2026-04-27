(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;; --- Phase 10: entity API on MockHost -----------------------------

(defun make-line-data (&key (layer "0") (start '(0.0d0 0.0d0 0.0d0)) (end '(1.0d0 1.0d0 0.0d0)))
  (list (cons 0 "LINE")
        (cons 8 layer)
        (cons 10 start)
        (cons 11 end)))

(test entmake-allocates-handle-and-injects-bookkeeping
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data))))
    (is (consp data))
    ;; First entry is the (-1 . ENAME) injected by the host.
    (let ((head (first data)))
      (is (and (consp head) (eql -1 (car head))))
      (is (typep (cdr head) 'autolisp-ename)))
    ;; Second entry is the (5 . HANDLE) string.
    (let ((second (second data)))
      (is (and (consp second) (eql 5 (car second))))
      (is (stringp (cdr second)))
      (is (string= "10" (cdr second))))
    ;; entlast surfaces the same ename as the entry just made.
    (let ((last-ename (host-entlast mock)))
      (is (typep last-ename 'autolisp-ename))
      (is (string= "10" (autolisp-ename-value last-ename))))))

(test entget-returns-the-stored-data-list
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data)))
         (round-trip (host-entget mock ename)))
    (is (consp round-trip))
    ;; The returned list is the same object the host stored.
    (is (eq data round-trip))
    ;; Group code 8 (layer) survives the round trip.
    (is (string= "0" (cdr (assoc 8 round-trip))))))

(test entget-on-deleted-entity-returns-nil
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data))))
    (host-entdel mock ename)
    (is (null (host-entget mock ename)))))

(test entdel-toggles-undelete
  ;; Calling entdel a second time un-deletes the entity, mirroring
  ;; AutoLISP's documented within-command toggle behaviour.
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data))))
    (host-entdel mock ename)
    (is (null (host-entget mock ename)))
    (host-entdel mock ename)
    (is (consp (host-entget mock ename)))))

(test entmod-replaces-data-and-keeps-bookkeeping
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data))))
    ;; Build a new data list that changes the layer to "Mine".
    (let ((updated (cons (cons -1 ename)
                         (list (cons 0 "LINE")
                               (cons 8 "Mine")
                               (cons 10 '(0.0d0 0.0d0 0.0d0))
                               (cons 11 '(2.0d0 2.0d0 0.0d0))))))
      (host-entmod mock updated)
      (let ((after (host-entget mock ename)))
        (is (string= "Mine" (cdr (assoc 8 after))))
        ;; The host still injected its (-1 . ename) and (5 . handle).
        (is (eql -1 (car (first after))))
        (is (eql 5 (car (second after))))))))

(test entlast-and-entnext-walk-creation-order
  (let* ((mock (make-mock-host))
         (a (cdr (first (host-entmake mock (make-line-data :layer "L1")))))
         (b (cdr (first (host-entmake mock (make-line-data :layer "L2")))))
         (c (cdr (first (host-entmake mock (make-line-data :layer "L3"))))))
    (is (string= "12" (autolisp-ename-value (host-entlast mock))))
    (let ((first-ename (host-entnext mock nil)))
      (is (string= "10" (autolisp-ename-value first-ename))))
    (let ((second (host-entnext mock a)))
      (is (string= "11" (autolisp-ename-value second))))
    (let ((third (host-entnext mock b)))
      (is (string= "12" (autolisp-ename-value third))))
    ;; Past the end -> nil.
    (is (null (host-entnext mock c)))))

(test entlast-skips-deleted-entities
  (let* ((mock (make-mock-host))
         (a (cdr (first (host-entmake mock (make-line-data :layer "L1")))))
         (b (cdr (first (host-entmake mock (make-line-data :layer "L2"))))))
    (host-entdel mock b)
    ;; Each call returns a fresh ENAME wrapper around the same hex
    ;; handle string; compare by value, not identity.
    (let ((last (host-entlast mock)))
      (is (typep last 'autolisp-ename))
      (is (string= (autolisp-ename-value a)
                   (autolisp-ename-value last))))))

(test handent-resolves-known-handle
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (handle (cdr (second data)))
         (ename (host-handent mock handle)))
    (is (typep ename 'autolisp-ename))
    (is (string= handle (autolisp-ename-value ename)))
    (is (null (host-handent mock "DEADBEEF")))))

(test entupd-returns-ename-for-live-entity-and-nil-for-deleted
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data))))
    (is (eq ename (host-entupd mock ename)))
    (host-entdel mock ename)
    (is (null (host-entupd mock ename)))))

(test entmake-rejects-data-without-group-zero
  (let ((mock (make-mock-host)))
    (handler-case
        (host-entmake mock '((8 . "0") (10 0 0 0)))
      (autolisp-runtime-error (condition)
        (is (eq :invalid-entity-data
                (autolisp-runtime-error-code condition)))))))

(test entget-rejects-non-ename
  (let ((mock (make-mock-host)))
    (handler-case
        (host-entget mock "not-an-ename")
      (autolisp-runtime-error (condition)
        (is (eq :invalid-ename
                (autolisp-runtime-error-code condition)))))))
