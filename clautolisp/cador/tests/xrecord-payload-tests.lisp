(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; An XRECORD's own 102 lists are data, not header groups.
;;;;
;;;; xrecord-102-payload-lost (SCHMS PKPM, 2026-10-27): ENTMAKE dropped every
;;;; 102 group opening with "{" as if ENTGET had synthesized it (since 2.3.30),
;;;; so an XRECORD's (102 . "{") ... (102 . "}") list -- SCHMS's xdata_codec
;;;; delimiter -- vanished, and ENTGET would have put such groups in the
;;;; header. Only NAMED groups before the first 100 are header groups.

(defun %xr-plain (view)
  "VIEW's payload: its pairs after the (100 . \"AcDbXrecord\") and the
(280 . 1) cloning flag ENTGET shows there, strings as CL strings."
  (let ((body (rest (member-if (lambda (p) (and (eql 100 (car p))
                                                (typep (cdr p) (quote clautolisp.autolisp-runtime:autolisp-string))
                                                (equal "AcDbXrecord"
                                                       (autolisp-string-value (cdr p)))))
                               view))))
    (when (eql 280 (car (first body)))
      (pop body))
    (mapcar (lambda (p)
              (cons (car p) (if (typep (cdr p) (quote clautolisp.autolisp-runtime:autolisp-string))
                                (autolisp-string-value (cdr p))
                                (cdr p))))
            body)))

(defun %xr-stored-with (mock string)
  "The ename of the stored XRECORD whose data holds (1 . STRING): ENTMAKE
returns no ename, and ENTLAST / ENTNEXT skip non-graphical objects."
  (let ((found nil))
    (clautolisp.drawing:map-entities
     (lambda (entity)
       (when (member (cons 1 string) (clautolisp.drawing:entity-dxf entity) :test #'equal)
         (setf found entity)))
     (clautolisp.cador::cador-active-drawing mock))
    (and found (host-handent mock (mk-str (clautolisp.drawing:entity-handle-id found))))))

(defun %xr-data (payload)
  (list* (cons 0 (mk-str "XRECORD")) (cons 100 (mk-str "AcDbXrecord"))
         (mapcar (lambda (p) (cons (car p) (if (stringp (cdr p)) (mk-str (cdr p)) (cdr p))))
                 payload)))

(defun %xr-count-reactors (view)
  (count-if (lambda (p) (and (eql 102 (car p))
                             (typep (cdr p) (quote clautolisp.autolisp-runtime:autolisp-string))
                             (equal "{ACAD_REACTORS" (autolisp-string-value (cdr p)))))
            view))

(test xrecord-102-lists-are-kept
  (let ((flat '((102 . "{") (60 . 900) (60 . 1000) (102 . "}")))
        (nested '((102 . "{") (1 . "a") (102 . "{") (1 . "b") (70 . 2) (102 . "}")
                  (102 . "}") (1 . "after")))
        (named '((102 . "{MYAPP") (1 . "x") (102 . "}"))))
    (dolist (dialect '(:autocad-2022 :bricscad-v26 :strict))
      (%with-dialect (dialect)
        (let ((mock (make-cador)))
          ;; free, by ENTMAKEX and by ENTMAKE
          (dolist (payload (list flat nested named))
            (let ((x (host-entmakex mock (%xr-data payload))))
              (is (equal payload (%xr-plain (host-entget mock x)))
                  "~A entmakex ~S" dialect payload)))
          (host-entmake mock (%xr-data nested))
          (let ((made (%xr-stored-with mock "after")))
            (is (not (null made)) "~A entmake stored it" dialect)
            (when made
              (is (equal nested (%xr-plain (host-entget mock made))) "~A entmake" dialect)))
          ;; owned by a dictionary: its {ACAD_REACTORS} in the header, the
          ;; payload untouched, and an entmod round trip stores neither twice
          (let ((x (host-entmakex mock (%xr-data flat))))
            (host-dictadd mock (host-namedobjdict mock) (mk-str "PKPM") x)
            (let ((view (host-entget mock x)))
              (is (equal flat (%xr-plain view)) "~A dictionary-owned" dialect)
              (is (= 1 (%xr-count-reactors view)) "~A one reactor group" dialect)
              (host-entmod mock view)
              (let ((again (host-entget mock x)))
                (is (equal flat (%xr-plain again)) "~A after entmod" dialect)
                (is (equal (mapcar #'car view) (mapcar #'car again))
                    "~A entmod stores nothing twice" dialect))
              ;; entmod with a new payload: applied by BricsCAD, a no-op on a
              ;; non-graphical object elsewhere ([entmod-nongraphical])
              (host-entmod mock (append (ldiff view (member 100 view :key #'car))
                                        (rest (%xr-data nested))))
              (let ((changed (host-entget mock x)))
                (is (equal (if (eq dialect :bricscad-v26) nested flat) (%xr-plain changed))
                    "~A entmod new payload" dialect)
                (is (= 1 (%xr-count-reactors changed)))))))))))

(test xrecord-330-pointer-in-the-payload-is-kept
  ;; a 330 after the 100 is the record's data, even naming a table record
  (%with-dialect (:autocad-2022)
    (let* ((mock (make-cador))
           (layer0 (host-tblobjname mock "LAYER" "0"))
           (x (host-entmakex mock (list (cons 0 (mk-str "XRECORD"))
                                        (cons 100 (mk-str "AcDbXrecord"))
                                        (cons 330 layer0) (cons 1 (mk-str "z"))))))
      (let ((body (%xr-plain (host-entget mock x))))
        (is (eq layer0 (cdr (assoc 330 body))))
        (is (equal "z" (cdr (assoc 1 body))))))))
