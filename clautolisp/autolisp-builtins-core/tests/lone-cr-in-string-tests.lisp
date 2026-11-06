(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; A lone CR written literally inside a string literal
;;;; (issues/closed/lone-cr-in-string-literal.issue; probe
;;;; probes/sources/probe-multiline-string.lsp, run on AutoCAD 2022
;;;; Windows, BricsCAD V25 Windows and BricsCAD V26 macOS).
;;;;
;;;; READ keeps the CR in every vendor: common behaviour, no warning.
;;;; LOAD keeps it in AutoCAD and turns it into LF in BricsCAD, and no
;;;; vendor document settles it: an unresolved divergence (case 3), so
;;;; every dialect but --lax warns `[lone-cr-in-string]'.

(defun %lone-cr-set-dialect (name)
  (setup-mock-evaluation-context)
  (clautolisp.autolisp-runtime:set-runtime-session-dialect
   (clautolisp.autolisp-runtime:evaluation-context-session
    (clautolisp.autolisp-runtime:current-evaluation-context))
   (clautolisp.autolisp-reader:find-autolisp-dialect name)))

(defun %lone-cr-load (dialect separator)
  "LOAD a file whose last form is the string \"ab<SEPARATOR>cd\" under
DIALECT. => (values STRING-VALUE WARNING-TEXT)."
  (%lone-cr-set-dialect dialect)
  (let ((path (merge-pathnames
               (format nil "lone-cr-~36R.lsp" (random (expt 36 6)))
               (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (with-open-file (stream path :direction :output :if-exists :supersede
                                        :element-type 'character)
             (format stream "\"ab~Acd\"~C" separator #\Newline))
           (let* ((*error-output* (make-string-output-stream))
                  (value (clautolisp.autolisp-runtime:autolisp-load-file-in-context
                          path
                          (clautolisp.autolisp-runtime:current-evaluation-context))))
             (values (autolisp-string-value value)
                     (get-output-stream-string *error-output*))))
      (when (probe-file path) (delete-file path)))))

(test load-lone-cr-in-string-per-dialect
  (dolist (case '(("strict"       #\Return  t)
                  ("autocad-2026" #\Return  t)
                  ("autocad-2022" #\Return  t)
                  ("bricscad-v26" #\Newline t)
                  ("bricscad-v25" #\Newline t)
                  ("clautolisp"   #\Return  t)
                  ("lax"          #\Return  nil)))
    (destructuring-bind (dialect expected warn-p) case
      (multiple-value-bind (value warning)
          (%lone-cr-load dialect (string #\Return))
        (is (string= (format nil "ab~Ccd" expected) value)
            "~A: LOAD should give ~S, got ~S" dialect (format nil "ab~Ccd" expected) value)
        (if warn-p
            (is (search "[lone-cr-in-string]" warning)
                "~A: LOAD should warn, got ~S" dialect warning)
            (is (zerop (length warning))
                "~A: LOAD should be silent, got ~S" dialect warning))))))

(test load-crlf-in-string-is-a-line-feed-and-silent
  (dolist (dialect '("strict" "autocad-2026" "bricscad-v26" "clautolisp" "lax"))
    (multiple-value-bind (value warning)
        (%lone-cr-load dialect (coerce '(#\Return #\Newline) 'string))
      (is (string= (format nil "ab~Ccd" #\Newline) value) "~A: ~S" dialect value)
      (is (zerop (length warning)) "~A: ~S" dialect warning))))

(test read-keeps-a-lone-cr-in-every-dialect-silently
  (dolist (dialect '("strict" "autocad-2026" "bricscad-v26" "clautolisp" "lax"))
    (%lone-cr-set-dialect dialect)
    (let* ((*error-output* (make-string-output-stream))
           (value (clautolisp.autolisp-builtins-core::builtin-read
                   (clautolisp.autolisp-runtime:make-autolisp-string
                    (format nil "\"ab~Ccd\"" #\Return))))
           (warning (get-output-stream-string *error-output*)))
      (is (string= (format nil "ab~Ccd" #\Return) (autolisp-string-value value))
          "~A: READ should keep the CR" dialect)
      (is (zerop (length warning)) "~A: READ should be silent, got ~S" dialect warning))))
