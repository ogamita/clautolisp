;;;; clautolisp/autolisp-inspect/tests/inspect-tests.lisp

(in-package #:clautolisp.inspect.tests)

(in-suite inspect-suite)

(test number-page-has-no-components
  (let ((page (clautolisp.inspect:inspect-page-for 42)))
    (is (string= "INT" (clautolisp.inspect:inspect-page-type-name page)))
    (is (null (clautolisp.inspect:inspect-page-components page)))))

(test string-page-exposes-chars-with-substr-accessors
  (let* ((page (clautolisp.inspect:inspect-page-for (rt-str "ab")))
         (components (clautolisp.inspect:inspect-page-components page)))
    (is (string= "STR" (clautolisp.inspect:inspect-page-type-name page)))
    (is (= 2 (length components)))
    ;; first char accessor is (SUBSTR _ 1 1) — AutoLISP is 1-based
    (is (string= "(SUBSTR _ 1 1)"
                 (princ-to-string (clautolisp.inspect:inspect-component-accessor
                                   (first components)))))))

(test cons-page-and-nested-path-expression
  (let* ((context (fresh-context))
         (value (clautolisp.autolisp-runtime:read-runtime-from-string "((1 2) 3)"))
         (session (clautolisp.inspect:inspect (first value)
                                              :origin (rt-sym "FOO") :context context)))
    (is (string= "LIST" (clautolisp.inspect:inspect-page-type-name
                         (clautolisp.inspect:session-page session))))
    ;; descend car → (1 2), then car → 1 : path (CAR (CAR FOO))
    (clautolisp.inspect:session-down session (component-index session "car"))
    (is (string= "(CAR FOO)" (path-string session)))
    (clautolisp.inspect:session-down session (component-index session "car"))
    (is (string= "(CAR (CAR FOO))" (path-string session)))
    (is (eql 1 (clautolisp.inspect:session-current session)))
    ;; up restores the parent
    (clautolisp.inspect:session-up session)
    (is (string= "(CAR FOO)" (path-string session)))))

(test nth-accessor-on-proper-list
  (let* ((context (fresh-context))
         (value (clautolisp.autolisp-runtime:read-runtime-from-string "(10 20 30)"))
         (session (clautolisp.inspect:inspect (first value)
                                              :origin (rt-sym "L") :context context)))
    (clautolisp.inspect:session-down session (component-index session "nth 1"))
    (is (eql 20 (clautolisp.inspect:session-current session)))
    (is (string= "(NTH 1 L)" (path-string session)))))

(test symbol-page-value-component
  (let* ((context (fresh-context)))
    (clautolisp.autolisp-runtime:set-variable (rt-sym "X") 7 context)
    (let ((session (clautolisp.inspect:inspect (rt-sym "X")
                                               :origin (rt-sym "X") :context context)))
      (is (string= "SYM" (clautolisp.inspect:inspect-page-type-name
                          (clautolisp.inspect:session-page session))))
      (clautolisp.inspect:session-down session (component-index session "value"))
      (is (eql 7 (clautolisp.inspect:session-current session)))
      (is (string= "(EVAL X)" (path-string session))))))

(test ename-page-group-code-path-expression
  ;; No host: stub ENTGET as a user function returning a canned DXF list,
  ;; so the ename page builds real group-code components and accessors.
  (let* ((context (fresh-context)))
    (load-source context "(defun entget (e) (quote ((0 . \"LINE\") (10 0.0 0.0 0.0))))")
    (let* ((ename (clautolisp.autolisp-runtime:make-autolisp-ename :value 42))
           (session (clautolisp.inspect:inspect ename
                                                :origin (rt-sym "EN") :context context))
           (index (component-index session "group 10")))
      (is (integerp index))
      (clautolisp.inspect:session-down session index)
      (is (string= "(CDR (ASSOC 10 (ENTGET EN)))" (path-string session))))))

(test opaque-descent-yields-partial-path
  (let ((session (clautolisp.inspect:inspect :a-cl-keyword :origin (rt-sym "Z"))))
    ;; the default page's sole component is opaque but descendable
    (clautolisp.inspect:session-down session 0)
    (multiple-value-bind (expr kind) (clautolisp.inspect:session-path-expression session)
      (is (string= "Z" (princ-to-string expr)))
      (is (eq :partial kind)))))

(test workspace-bind-and-eval
  (let* ((context (fresh-context))
         (value (clautolisp.autolisp-runtime:read-runtime-from-string "(0.0 0.0 0.0)"))
         (session (clautolisp.inspect:inspect (first value)
                                              :origin (rt-sym "PT") :context context)))
    (let ((slot (clautolisp.inspect:session-bind session :workspace)))
      (is (string= "$1" slot))
      (multiple-value-bind (v present) (clautolisp.inspect:workspace-ref
                                        (clautolisp.inspect:inspector-session-workspace session)
                                        slot)
        (is (not (null present)))
        (is (equal (first value) v)))
      ;; session-eval resolves $1 (and $0/*) inspector-side
      (is (equal (first value)
                 (clautolisp.inspect:session-eval session (rt-sym "$1"))))
      (is (equal (first value)
                 (clautolisp.inspect:session-eval session (rt-sym "$0")))))))

(test session-bind-setq-writes-the-variable
  (let* ((context (fresh-context))
         (session (clautolisp.inspect:inspect 99 :origin (rt-sym "N") :context context)))
    (clautolisp.inspect:session-bind session (list :setq (rt-sym "KEEP")))
    (multiple-value-bind (value bound)
        (clautolisp.autolisp-runtime:lookup-variable (rt-sym "KEEP") context)
      (is (not (null bound)))
      (is (eql 99 value)))))

(test frame-bind-uses-the-installed-writer
  (let* ((context (fresh-context))
         (recorded nil)
         (session (clautolisp.inspect:inspect 5 :origin (rt-sym "N") :context context
                                              :bind-frame-fn
                                              (lambda (frame symbol value)
                                                (setf recorded (list frame symbol value))
                                                :ok))))
    (is (eq :ok (clautolisp.inspect:session-bind session (list :frame :the-frame (rt-sym "V")))))
    (is (equal (list :the-frame (rt-sym "V") 5) recorded))))
