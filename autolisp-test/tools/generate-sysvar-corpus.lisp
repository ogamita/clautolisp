;;;; -*- Mode: Lisp; coding: utf-8 -*-
;;;; autolisp-test/tools/generate-sysvar-corpus.lisp
;;;;
;;;; Read autolisp-spec/documentation/system-variables-inventory.sexp
;;;; and emit AutoLISP conformance .lsp files into autolisp-test/tests/
;;;; sysvar/. The output is checked in: run this tool whenever the
;;;; inventory changes and commit the regenerated .lsp.
;;;;
;;;; Output files:
;;;;
;;;;   tests/sysvar/inventory-coverage.lsp
;;;;     One deftest per inventory entry asserting that getvar
;;;;     returns the documented AutoLISP type. For non-host-derived
;;;;     literals the test also asserts the documented default value.
;;;;     For read-only entries the test asserts that setvar signals.
;;;;
;;;; Usage:
;;;;
;;;;   sbcl --noinform --non-interactive \
;;;;        --load autolisp-test/tools/generate-sysvar-corpus.lisp \
;;;;        --eval '(generate :inventory "autolisp-spec/documentation/system-variables-inventory.sexp" :out-dir "autolisp-test/tests/sysvar/")'

(in-package #:cl-user)

(defun read-inventory (path)
  (with-open-file (s path :external-format :utf-8)
    (loop for form = (read s nil :eof) until (eq form :eof) collect form)))

(defun inv-type->autolisp-type (kw)
  "Inventory :type -> the symbol returned by (type ...) in AutoLISP."
  (case kw
    (:integer 'int)
    (:short   'int)
    (:real    'real)
    (:string  'str)
    (:point   'list)
    (:point3d 'list)
    (:symbol  'sym)
    (:ename   'ename)
    (t        'str)))

(defun host-derived-default-p (default)
  (and (consp default)
       (member (car default)
               '(:host-specific :drawing :session :registry
                 :preference :unknown :workspace))))

(defun literal-default-form (default type-kw)
  "Return an AutoLISP expression evaluating to the documented
default, or NIL when no literal can be expressed."
  (cond
    ((host-derived-default-p default) nil)
    ((eq type-kw :string)
     (and (stringp default) `(quote ,default)))
    ((eq type-kw :real)
     (and (floatp default) default))
    ((or (eq type-kw :integer) (eq type-kw :short))
     (and (integerp default) default))
    ((or (eq type-kw :point) (eq type-kw :point3d))
     (and (consp default) (every #'numberp default)
          `(quote ,default)))
    (t nil)))

(defun escape-lsp-string (s)
  (with-output-to-string (out)
    (loop for c across s do
      (case c
        (#\\ (write-string "\\\\" out))
        (#\" (write-string "\\\"" out))
        (#\Newline (write-string "\\n" out))
        (t (write-char c out))))))

(defun lsp-render-value (form)
  "Render FORM as an AutoLISP source string."
  (cond
    ((null form) "nil")
    ((symbolp form) (format nil "'~A" (string-downcase (symbol-name form))))
    ((stringp form) (format nil "\"~A\"" (escape-lsp-string form)))
    ((integerp form) (format nil "~D" form))
    ((floatp form) (format nil "~F" form))
    ((and (consp form) (eq (car form) 'quote))
     ;; (quote X) in CL -> 'X in AutoLISP
     (let ((arg (cadr form)))
       (cond
         ((stringp arg) (format nil "\"~A\"" (escape-lsp-string arg)))
         ((consp arg) (format nil "'(~{~A~^ ~})"
                              (mapcar (lambda (x)
                                        (cond ((floatp x) (format nil "~F" x))
                                              ((integerp x) (format nil "~D" x))
                                              (t (lsp-render-value x))))
                                      arg)))
         (t (format nil "'~A" arg)))))
    (t (format nil "~A" form))))

(defun emit-coverage-entry (out rec)
  (let* ((name      (getf rec :name))
         (type-kw   (getf rec :type))
         (default   (getf rec :default))
         (read-only (getf rec :read-only))
         (vendor    (getf rec :vendor))
         (al-type   (inv-type->autolisp-type type-kw))
         (test-name-base (string-downcase name))
         (profile (if (eq vendor :bricscad) 'bricscad 'strict)))
    ;; All but the most ill-formed entries get a type-of-getvar test.
    (format out "(deftest ~S~%" (format nil "sysvar-~A-getvar-type"
                                        test-name-base))
    (format out "  '((operator . ~S) (area . \"sysvar\") (profile . ~A))~%"
            name profile)
    (format out "  '(type (getvar ~S))~%" name)
    (format out "  '~A)~%~%" (string-downcase (symbol-name al-type)))
    ;; Read-only sysvars: assert setvar signals.
    (when read-only
      (format out "(deftest-error ~S~%"
              (format nil "sysvar-~A-setvar-readonly-signals"
                      test-name-base))
      (format out "  '((operator . ~S) (area . \"sysvar\") (profile . ~A))~%"
              name profile)
      ;; setvar takes a value of the right shape; use a safe
      ;; placeholder per type.
      (let ((placeholder (ecase al-type
                           (int  "0")
                           (real "0.0")
                           (str  "\"\"")
                           (list "'(0.0 0.0)")
                           (sym  "'NIL")
                           (ename "(handent \"00\")"))))
        (format out "  '(setvar ~S ~A)~%" name placeholder)
        (format out "  '~A)~%~%" "sysvar-read-only")))
    ;; Literal-default round-trip when the inventory has one.
    (let ((lit (literal-default-form default type-kw)))
      (when (and lit (not read-only))
        ;; getvar -> documented default (only when the inventory says
        ;; the default is a fixed constant, not host-derived).
        ;; We don't claim vendor-exact-default for divergent records.
        (let ((divergence (getf rec :divergence)))
          (when (or (null divergence) (eq divergence nil))
            (format out "(deftest ~S~%"
                    (format nil "sysvar-~A-getvar-default"
                            test-name-base))
            (format out "  '((operator . ~S) (area . \"sysvar\") (profile . ~A))~%"
                    name profile)
            (format out "  '(getvar ~S)~%" name)
            (format out "  ~A)~%~%" (lsp-render-value lit))))))))

(defun emit-coverage-file (records out-path)
  (with-open-file (out out-path
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create
                       :external-format :utf-8)
    (format out ";;;; -*- Mode: Lisp; coding: utf-8 -*-~%")
    (format out ";;;; tests/sysvar/inventory-coverage.lsp~%")
    (format out ";;;;~%")
    (format out ";;;; THIS FILE IS GENERATED. Regenerate by running~%")
    (format out ";;;;   sbcl --non-interactive --load autolisp-test/tools/generate-sysvar-corpus.lisp \\~%")
    (format out ";;;;        --eval '(generate)'~%")
    (format out ";;;;~%")
    (format out ";;;; Source: autolisp-spec/documentation/system-variables-inventory.sexp~%")
    (format out ";;;; Records: ~D~%" (length records))
    (format out ";;;;~%")
    (format out ";;;; Per inventory entry we emit:~%")
    (format out ";;;;   - a sysvar-NAME-getvar-type test asserting (type (getvar \"NAME\"))~%")
    (format out ";;;;     matches the inventory's :type field;~%")
    (format out ";;;;   - a sysvar-NAME-setvar-readonly-signals test for read-only cells,~%")
    (format out ";;;;     asserting setvar signals :sysvar-read-only;~%")
    (format out ";;;;   - a sysvar-NAME-getvar-default test asserting the documented~%")
    (format out ";;;;     default value, but ONLY when the :default is a fixed literal~%")
    (format out ";;;;     (host-derived markers like (:host-specific) / (:drawing) are~%")
    (format out ";;;;     not asserted -- the value varies per the vendor docs).~%")
    (format out ";;;;~%")
    (format out ";;;; Profile defaults to STRICT for vendor :both / :autocad entries,~%")
    (format out ";;;; BRICSCAD for vendor :bricscad. Selection happens at run time via~%")
    (format out ";;;; the harness's --profile flag.~%~%")
    (let ((emitted 0))
      (dolist (rec records)
        (emit-coverage-entry out rec)
        (incf emitted))
      (format t "  inventory-coverage.lsp: ~D records emitted~%" emitted))))

(defun generate (&key
                   (inventory "autolisp-spec/documentation/system-variables-inventory.sexp")
                   (out-dir "autolisp-test/tests/sysvar/"))
  (ensure-directories-exist out-dir)
  (let ((records (read-inventory inventory)))
    (format t "Read ~D records from ~A~%" (length records) inventory)
    (emit-coverage-file records (merge-pathnames "inventory-coverage.lsp" out-dir))))
