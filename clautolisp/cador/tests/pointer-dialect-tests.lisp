(in-package #:clautolisp.cador.tests)

(in-suite cador-suite)

;;;; DXF pointer group codes per product dialect -- the behaviour MEASURED
;;;; on 2026-10-08 by probes/sources/probe-entget-pointers.lsp (jobs
;;;; 17026569911 AutoCAD 2022, 17026569912 BricsCAD V25 Windows,
;;;; 17026569913 BricsCAD V26 macOS).
;;;; issues/closed/cador-entget-pointer-codes-are-handle-strings.issue

(defun %pd-error-text (thunk)
  "The message of the AutoLISP runtime error THUNK signals, or :NO-ERROR."
  (handler-case (progn (funcall thunk) :no-error)
    (autolisp-runtime-error (e) (princ-to-string e))))

(defun %pd-mentions (text needle)
  (and (stringp text) (search needle text) t))

(defun %pd-xrecord (mock &rest groups)
  (host-entmakex mock (list* (cons 0 "XRECORD") (cons 100 "AcDbXrecord") groups)))

(defun %pd-line (mock)
  (host-entmakex mock (list (cons 0 "LINE") (cons 8 "0")
                            (cons 10 '(0.0d0 0.0d0 0.0d0))
                            (cons 11 '(1.0d0 1.0d0 0.0d0)))))

(defun %pd-stderr (thunk)
  "Everything THUNK writes to *ERROR-OUTPUT*."
  (with-output-to-string (*error-output*)
    (funcall thunk)))

;;; --- AutoCAD ------------------------------------------------------

(test autocad-dialect-pointer-codes-follow-autocad
  (%with-dialect (:autocad)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (h (autolisp-ename-value line)))
      ;; A handle STRING in a pointer code: "bad DXF group".
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 340 (mk-str h)))))
                        "bad DXF group: (340 . \""))
      ;; An ENAME in 320-329: refused too.
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 320 line))))
                        "bad DXF group: (320 . <Entity name: "))
      ;; 320 as a string is fine and reads back a string; 340 an ename.
      (let* ((x (%pd-xrecord mock (cons 340 line) (cons 320 (mk-str h))))
             (view (host-entget mock x)))
        (is (eq line (cdr (assoc 340 view))))
        (is (typep (cdr (assoc 320 view)) 'autolisp-string))
        ;; entmod with a string pointer: refused.
        (is (%pd-mentions (%pd-error-text
                           (lambda ()
                             (host-entmod mock (subst (cons 340 (mk-str h))
                                                      (assoc 340 view) view
                                                      :test #'equal))))
                          "bad DXF group")))
      ;; The null pointer: (330 . <Entity name: 0>), entget nil.
      (let ((owner (assoc 330 (host-entget mock (host-namedobjdict mock)))))
        (is (consp owner))
        (is (typep (cdr owner) 'autolisp-ename))
        (is (string= "0" (autolisp-ename-value (cdr owner))))
        (is (null (host-entget mock (cdr owner)))))
      ;; XRECORD without the AcDbXrecord marker: refused (nil).
      (is (null (host-entmakex mock (list (cons 0 "XRECORD") (cons 1 "C")))))
      ;; XRECORD with an explicit (280 . 0): kept as given.
      (let ((view (host-entget mock (%pd-xrecord mock (cons 280 0) (cons 1 "a")))))
        (is (equal '(280 . 0) (second (member 100 view :key #'car))))))))

;;; --- BricsCAD -----------------------------------------------------

(test bricscad-dialect-pointer-codes-follow-bricscad
  (%with-dialect (:bricscad)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (h (autolisp-ename-value line)))
      ;; A handle STRING in a pointer code, and in 320: expected ENTITYNAME.
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 340 (mk-str h)))))
                        "expected ENTITYNAME"))
      (is (%pd-mentions (%pd-error-text
                         (lambda () (%pd-xrecord mock (cons 320 (mk-str h)))))
                        "bad argument type <(320 . \""))
      ;; 320 as an ENAME reads back an ENAME (EQ).
      (let ((view (host-entget mock (%pd-xrecord mock (cons 320 line)))))
        (is (eq line (cdr (assoc 320 view)))))
      ;; The null pointer is omitted.
      (is (null (assoc 330 (host-entget mock (host-namedobjdict mock)))))
      ;; XRECORD without the marker: accepted, marker + (280 . 1) synthesised.
      (let ((x (host-entmakex mock (list (cons 0 "XRECORD") (cons 1 "C")))))
        (is (typep x 'autolisp-ename))
        (let ((tail (member 100 (host-entget mock x) :key #'car)))
          (is (string= "AcDbXrecord" (autolisp-string-value (cdr (first tail)))))
          (is (equal '(280 . 1) (second tail)))))
      ;; XRECORD with an explicit (280 . 0): no 280 listed at all.
      (let ((view (host-entget mock (%pd-xrecord mock (cons 280 0) (cons 1 "a")))))
        (is (null (assoc 280 view)))
        (is (eql 1 (car (second (member 100 view :key #'car))))))
      ;; ...and without it, (280 . 1).
      (let ((view (host-entget mock (%pd-xrecord mock (cons 1 "a")))))
        (is (equal '(280 . 1) (second (member 100 view :key #'car))))))))

;;; --- clautolisp / lax: accept, warn (or not) ----------------------

(test clautolisp-dialect-accepts-a-string-pointer-with-a-warning
  (%with-dialect (:clautolisp)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (x nil)
           (err (%pd-stderr (lambda ()
                              (setf x (%pd-xrecord mock (cons 340 (mk-str (autolisp-ename-value line)))))))))
      (is (%pd-mentions err "[entmake-pointer-value]"))
      (is (eq line (cdr (assoc 340 (host-entget mock x))))))))

(test lax-dialect-accepts-a-string-pointer-silently
  (%with-dialect (:lax)
    (let* ((mock (make-cador))
           (line (%pd-line mock))
           (x nil)
           (err (%pd-stderr (lambda ()
                              (setf x (%pd-xrecord mock (cons 340 (mk-str (autolisp-ename-value line)))))))))
      (is (string= "" err))
      (is (eq line (cdr (assoc 340 (host-entget mock x))))))))

(test erased-pointer-target-is-the-same-ename-on-both-products
  (dolist (dialect '(:autocad :bricscad))
    (%with-dialect (dialect)
      (let* ((mock (make-cador))
             (gone (%pd-line mock))
             (x (%pd-xrecord mock (cons 340 gone))))
        (host-entdel mock gone)
        (let ((p (cdr (assoc 340 (host-entget mock x)))))
          (is (eq gone p))
          (is (null (host-entget mock p))))))))
