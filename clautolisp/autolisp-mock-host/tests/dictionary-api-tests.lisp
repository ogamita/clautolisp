(in-package #:clautolisp.autolisp-mock-host.tests)

(in-suite autolisp-mock-host-suite)

;;;; MockHost adapter tests for the named-object dictionary tree,
;;;; xrecord lifecycle and REGAPP registration.

(defun mk-str (s) (make-autolisp-string s))

(defun make-xrecord-ename (mock &optional (tag "payload"))
  (host-entmakex mock (list (cons 0 "XRECORD")
                            (cons 100 "AcDbXrecord")
                            (cons 1 tag))))

;;; --- namedobjdict / dictadd / dictsearch ------------------------

(test namedobjdict-returns-a-stable-ename
  (let ((mock (make-mock-host)))
    (let ((r1 (host-namedobjdict mock))
          (r2 (host-namedobjdict mock)))
      (is (typep r1 'autolisp-ename))
      (is (string= (autolisp-ename-value r1) (autolisp-ename-value r2))))))

(test dictadd-and-dictsearch-round-trip-an-xrecord
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock))
          (x   (make-xrecord-ename mock "hello")))
      (is (eq x (host-dictadd mock nod (mk-str "MYREC") x)))
      (let ((found (host-dictsearch mock nod (mk-str "MYREC"))))
        (is (consp found))
        ;; entget-style: (-1 . ename) head + (0 . "XRECORD")
        (is (typep (cdr (assoc -1 found)) 'autolisp-ename))
        (is (string-equal "XRECORD" (autolisp-string-value (cdr (assoc 0 found)))))
        (is (string= "hello" (autolisp-string-value (cdr (assoc 1 found))))))
      ;; absent key -> nil (soft failure, no condition)
      (is (null (host-dictsearch mock nod (mk-str "NOPE"))))
      ;; duplicate key -> nil
      (is (null (host-dictadd mock nod (mk-str "MYREC") (make-xrecord-ename mock)))))))

(test dictobjname-returns-member-ename
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock))
          (x   (make-xrecord-ename mock)))
      (host-dictadd mock nod (mk-str "K") x)
      (is (string= (autolisp-ename-value x)
                   (autolisp-ename-value (host-dictobjname mock nod (mk-str "K")))))
      (is (null (host-dictobjname mock nod (mk-str "ABSENT")))))))

(test dictsearch-object-feeds-entmod-and-entget
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock))
          (x   (make-xrecord-ename mock "v1")))
      (host-dictadd mock nod (mk-str "K") x)
      ;; entget on the xrecord ename works
      (is (consp (host-entget mock x)))
      ;; entmod the xrecord's group 1 value
      (host-entmod mock (list (cons -1 x) (cons 0 "XRECORD")
                              (cons 100 "AcDbXrecord") (cons 1 "v2")))
      (is (string= "v2" (autolisp-string-value
                         (cdr (assoc 1 (host-entget mock x)))))))))

;;; --- dictnext enumeration ---------------------------------------

(test dictnext-enumerates-all-members-then-nil
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock)))
      (host-dictadd mock nod (mk-str "A") (make-xrecord-ename mock "a"))
      (host-dictadd mock nod (mk-str "B") (make-xrecord-ename mock "b"))
      (host-dictadd mock nod (mk-str "C") (make-xrecord-ename mock "c"))
      (let ((seen '()))
        (loop for e = (host-dictnext mock nod :rewind t) then (host-dictnext mock nod)
              while e
              do (push (autolisp-string-value (cdr (assoc 1 e))) seen))
        ;; membership, order-independent
        (is (null (set-difference seen '("a" "b" "c") :test #'string=)))
        (is (= 3 (length seen)))))))

;;; --- dictremove / dictrename ------------------------------------

(test dictremove-detaches-and-returns-ename
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock))
          (x   (make-xrecord-ename mock)))
      (host-dictadd mock nod (mk-str "K") x)
      (is (string= (autolisp-ename-value x)
                   (autolisp-ename-value (host-dictremove mock nod (mk-str "K")))))
      (is (null (host-dictsearch mock nod (mk-str "K"))))
      (is (null (host-dictremove mock nod (mk-str "K")))))))

(test dictrename-changes-the-key
  (let ((mock (make-mock-host)))
    (let ((nod (host-namedobjdict mock))
          (x   (make-xrecord-ename mock)))
      (host-dictadd mock nod (mk-str "OLD") x)
      (is (string= "NEW" (autolisp-string-value
                          (host-dictrename mock nod (mk-str "OLD") (mk-str "NEW")))))
      (is (null (host-dictsearch mock nod (mk-str "OLD"))))
      (is (consp (host-dictsearch mock nod (mk-str "NEW")))))))

;;; --- ssget must never return dictionaries / xrecords ------------

(test ssget-x-excludes-non-graphical-objects
  (let ((mock (make-mock-host)))
    (host-entmake mock (list (cons 0 "LINE") (cons 10 '(0.0d0 0.0d0 0.0d0))
                             (cons 11 '(1.0d0 1.0d0 0.0d0))))
    (host-namedobjdict mock)                       ; creates the root DICTIONARY
    (make-xrecord-ename mock)                       ; an XRECORD object
    (let ((set (host-ssget mock nil :mode (mk-str "X"))))
      ;; only the one LINE, not the dictionary or the xrecord
      (is (eql 1 (host-sslength mock set))))))

;;; --- REGAPP ------------------------------------------------------

(test regapp-registers-and-rejects-duplicates
  (let ((mock (make-mock-host)))
    (is (string= "SCHMS" (autolisp-string-value (host-regapp mock (mk-str "SCHMS")))))
    (is (null (host-regapp mock (mk-str "SCHMS"))))          ; already registered
    (is (typep (mock-host-find-table-record mock :appid "SCHMS")
               'symbol-table-record))))

;;; --- Session isolation: fresh host = fresh drawing --------------

(test dictionaries-are-isolated-between-fresh-hosts
  (let ((m1 (make-mock-host))
        (m2 (make-mock-host)))
    (host-dictadd m1 (host-namedobjdict m1) (mk-str "K") (make-xrecord-ename m1))
    ;; m2's fresh root dictionary has no such entry
    (is (null (host-dictsearch m2 (host-namedobjdict m2) (mk-str "K"))))))
