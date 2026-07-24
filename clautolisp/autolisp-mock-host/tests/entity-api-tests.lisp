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
    ;; Second entry is the (5 . HANDLE) string. The host wraps string
    ;; values as autolisp-strings at the boundary (REVIEW-1); the
    ;; drawing stores a pure CL string.
    (let ((second (second data)))
      (is (and (consp second) (eql 5 (car second))))
      (is (typep (cdr second) 'autolisp-string))
      (is (string= "10" (autolisp-string-value (cdr second)))))
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
    ;; entget now reconstructs the AutoLISP view at the boundary
    ;; (REVIEW-1), so it is a fresh list each call — equal in content,
    ;; not eq, to entmake's return.
    (is (not (eq data round-trip)))
    (is (equalp data round-trip))
    ;; Group code 8 (layer) survives the round trip, wrapped as an
    ;; autolisp-string.
    (is (string= "0" (autolisp-string-value (cdr (assoc 8 round-trip)))))))

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
        (is (string= "Mine" (autolisp-string-value (cdr (assoc 8 after)))))
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
         (handle (cdr (second data)))            ; an autolisp-string now
         (ename (host-handent mock handle)))
    (is (typep ename 'autolisp-ename))
    (is (string= (autolisp-string-value handle) (autolisp-ename-value ename)))
    (is (null (host-handent mock "DEADBEEF")))))

(test entupd-returns-ename-for-live-entity-and-nil-for-deleted
  (let* ((mock (make-mock-host))
         (data (host-entmake mock (make-line-data)))
         (ename (cdr (first data))))
    (is (eq ename (host-entupd mock ename)))
    (host-entdel mock ename)
    (is (null (host-entupd mock ename)))))

(test entmake-rejects-data-without-group-zero
  ;; Vendor parity: ENTMAKE on a group-code list that does not describe
  ;; a creatable entity (here: no (0 . "TYPE") marker) returns nil — it
  ;; does NOT raise. The builtin maps that nil to ERRNO 36.
  (let ((mock (make-mock-host)))
    (is (null (host-entmake mock '((8 . "0") (10 0 0 0)))))))

(test entmake-rejects-family-missing-required-code
  ;; CIRCLE requires the 40 (radius) group; omitting it fails the create.
  (let ((mock (make-mock-host)))
    (is (null (host-entmake mock (list (cons 0 "CIRCLE")
                                       (cons 10 '(0.0d0 0.0d0 0.0d0))))))
    ;; With the radius it succeeds.
    (is (consp (host-entmake mock (list (cons 0 "CIRCLE")
                                        (cons 10 '(0.0d0 0.0d0 0.0d0))
                                        (cons 40 1.0d0)))))))

(test entmakex-returns-ename-not-list
  ;; The distinguishing ENTMAKEX contract (issue entmakex-returns-list):
  ;; ENTMAKEX hands back the new entity's ENAME, feedable straight into
  ;; entget / entmod / entdel — NOT the entget-style DXF list.
  (let* ((mock (make-mock-host))
         (result (host-entmakex mock (make-line-data))))
    (is (typep result 'autolisp-ename))
    ;; The ename resolves: entget on it round-trips a data list.
    (is (consp (host-entget mock result)))
    ;; It is the same entity entlast reports.
    (is (string= (autolisp-ename-value result)
                 (autolisp-ename-value (host-entlast mock))))))

(test entmakex-defaults-layer-and-stamps-subclass
  ;; ENTMAKEX normalises: a LINE with no (8 . layer) gets the "0"
  ;; default, and the AcDbEntity/AcDbLine subclass markers appear.
  (let* ((mock (make-mock-host))
         (ename (host-entmakex mock (list (cons 0 "LINE")
                                          (cons 10 '(0.0d0 0.0d0 0.0d0))
                                          (cons 11 '(1.0d0 1.0d0 0.0d0)))))
         (data (host-entget mock ename)))
    (is (string= "0" (autolisp-string-value (cdr (assoc 8 data)))))
    (is (member "AcDbLine"
                (loop for (code . val) in data
                      when (and (eql code 100) (typep val 'autolisp-string))
                        collect (autolisp-string-value val))
                :test #'string=))))

(test entget-rejects-non-ename
  (let ((mock (make-mock-host)))
    (handler-case
        (host-entget mock "not-an-ename")
      (autolisp-runtime-error (condition)
        (is (eq :invalid-ename
                (autolisp-runtime-error-code condition)))))))

;;; --- XData (extended data) filtering -----------------------------

(defun %assoc-code (code data)
  (find-if (lambda (p) (and (consp p) (eql code (car p)))) data))

(test entget-suppresses-xdata-without-applist-and-returns-it-with
  ;; entget without an application list hides xdata; with a matching
  ;; application name it appends the (-3 ...) group; a non-matching name
  ;; yields no xdata.
  (let* ((mock (make-mock-host))
         (ename (host-entmakex mock (make-line-data))))
    ;; Attach xdata via entmod (the -1 head names the entity).
    (host-entmod mock
                 (list (cons -1 ename)
                       (cons 0 "LINE")
                       (cons 10 '(0.0d0 0.0d0 0.0d0))
                       (cons 11 '(1.0d0 1.0d0 0.0d0))
                       (cons -3 (list (list (make-autolisp-string "MYAPP")
                                            (cons 1000 (make-autolisp-string "tag"))
                                            (cons 1070 7))))))
    ;; No applist -> no (-3 ...) cell.
    (is (null (%assoc-code -3 (host-entget mock ename))))
    ;; Matching applist -> the (-3 ...) cell appears.
    (let* ((data (host-entget mock ename
                              (list (make-autolisp-string "MYAPP"))))
           (xd (%assoc-code -3 data)))
      (is (not (null xd)))
      (let ((grp (first (cdr xd))))
        (is (string= "MYAPP" (autolisp-string-value (first grp))))
        (is (string= "tag" (autolisp-string-value (cdr (assoc 1000 (rest grp))))))))
    ;; Non-matching applist -> no xdata surfaced.
    (is (null (%assoc-code -3 (host-entget mock ename
                                           (list (make-autolisp-string "OTHER"))))))
    ;; Wildcard "*" surfaces all.
    (is (not (null (%assoc-code -3 (host-entget mock ename
                                                (list (make-autolisp-string "*")))))))))

;;; --- Complex-entity subentity ownership (group 330) --------------

(test entmake-sequence-links-subentity-owners-and-entnext-walks-them
  ;; A POLYLINE opens a run; its VERTEX subentities get their owner
  ;; (330) set to the polyline handle; the SEQEND closes the run.
  ;; ENTNEXT walks header -> vertices -> seqend in creation order.
  (let* ((mock (make-mock-host))
         (poly (host-entmakex mock (list (cons 0 "POLYLINE") (cons 70 1))))
         (poly-handle (autolisp-ename-value poly))
         (v1 (host-entmakex mock (list (cons 0 "VERTEX")
                                       (cons 10 '(0.0d0 0.0d0 0.0d0)))))
         (v2 (host-entmakex mock (list (cons 0 "VERTEX")
                                       (cons 10 '(1.0d0 0.0d0 0.0d0)))))
         (seq (host-entmakex mock (list (cons 0 "SEQEND")))))
    ;; Each VERTEX's 330 owner is the polyline's handle.
    (dolist (v (list v1 v2))
      (let ((owner (cdr (assoc 330 (host-entget mock v)))))
        (is (string= poly-handle (autolisp-string-value owner)))))
    ;; SEQEND is owned by the polyline too.
    (is (string= poly-handle
                 (autolisp-string-value (cdr (assoc 330 (host-entget mock seq))))))
    ;; A LINE created after the SEQEND does NOT get an owner (run closed).
    (let ((line (host-entmakex mock (make-line-data))))
      (is (null (assoc 330 (host-entget mock line)))))
    ;; ENTNEXT walks the whole structure in creation order.
    (is (string= poly-handle (autolisp-ename-value (host-entnext mock nil))))
    (is (string= (autolisp-ename-value v1)
                 (autolisp-ename-value (host-entnext mock poly))))
    (is (string= (autolisp-ename-value seq)
                 (autolisp-ename-value (host-entnext mock v2))))))

(test entmake-explicit-owner-330-is-respected
  ;; A caller-supplied 330 owner is not overwritten by the auto-linker.
  (let* ((mock (make-mock-host))
         (poly (host-entmakex mock (list (cons 0 "POLYLINE") (cons 70 1))))
         (v (host-entmakex mock (list (cons 0 "VERTEX")
                                      (cons 10 '(0.0d0 0.0d0 0.0d0))
                                      (cons 330 (make-autolisp-string "FADE"))))))
    (declare (ignore poly))
    (is (string= "FADE"
                 (autolisp-string-value (cdr (assoc 330 (host-entget mock v))))))))
