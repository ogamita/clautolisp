;;;; clautolisp/tools/clautolisp/tests/aldo-conf-tests.lisp
;;;;
;;;; (clal-save-aldo-configuration) must write the SAME self-documenting
;;;; aldo.conf that `,settings save' writes
;;;; (clal-save-aldo-configuration-undocumented-file.issue). Two commands
;;;; write one file, and saving from AutoLISP used to strip the header and
;;;; the commented defaults out of a file the user may be editing by hand.
;;;;
;;;; The test lives in the TOOL's suite, not in the builtins', because the
;;;; wiring does: the builtin cannot call the debug UI's writer (the
;;;; dependency runs the other way), so the tool installs a hook at
;;;; start-up. Testing it here tests the arrangement that actually ships.

(in-package #:clautolisp.tools.clautolisp.tests)

(in-suite clautolisp-tool-suite)

(defun %with-documented-aldo-writer (thunk)
  "Run THUNK with the same *ALDO-CONFIGURATION-WRITER* main.lisp installs."
  (let ((clautolisp.autolisp-builtins-core::*aldo-configuration-writer*
          (lambda (stream)
            (clautolisp.debug.ui:write-aldo-configuration
             stream (clautolisp.debug.ui:read-config-variable)))))
    (funcall thunk)))

(defun %save-aldo-conf-to-string (config)
  "Set the AutoLISP configuration variable to CONFIG, save through the
AutoLISP-side saver, and return the file's contents."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.debug.ui:write-config-variable config)
  (let ((path (merge-pathnames "aldo-conf-test.conf" (uiop:temporary-directory))))
    (unwind-protect
         (progn
           (%with-documented-aldo-writer
            (lambda ()
              (clautolisp.autolisp-builtins-core::save-aldo-configuration-to path)))
           (with-open-file (in path)
             (let ((text (make-string (file-length in))))
               (subseq text 0 (read-sequence text in)))))
      (ignore-errors (delete-file path)))))

(test aldo-conf-saved-from-autolisp-is-self-documenting
  "The header and the commented defaults are there — the documentation the
bare serialiser used to drop."
  (let ((text (%save-aldo-conf-to-string '((:pager-height . 42)))))
    (is (search ";;;; clautolisp aldo.conf" text)
        "no header in ~S" text)
    (is (search ";;(navigator . sexp)" text)
        "no commented default in ~S" text)
    (is (search "sexp | line" text)
        "the accepted values must be shown, or the file is not editable ~
without the manual beside it")))

(test aldo-conf-saved-from-autolisp-keeps-the-settings-that-were-set
  "The documentation must not cost the data: a setting the user set is
written as LIVE data, not as one more comment."
  (let ((text (%save-aldo-conf-to-string '((:pager-height . 42)))))
    (is (search "(pager-height . 42)" text))
    ;; and it is live, not commented out
    (is (not (search ";;(pager-height . 42)" text)))))

(test aldo-conf-saved-from-autolisp-reads-back-unchanged
  "The whole point of the commented form: the file still reads back as
exactly the configuration it was saved from — the defaults stay comments
and do not become explicit settings."
  (let* ((text (%save-aldo-conf-to-string '((:pager-height . 42))))
         (back (with-input-from-string (in text)
                 (clautolisp.debug.ui:read-aldo-configuration in))))
    (is (eql 42 (cdr (assoc :pager-height back))))
    (is (eql 1 (length back))
        "the documented defaults must not read back as settings; got ~S"
        back)))

(test aldo-conf-without-the-hook-still-writes-a-readable-file
  "A build with no debugger UI has no writer to delegate to, and must
still produce a file that reads back — the bare form is a fallback, not a
failure."
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (clautolisp.debug.ui:write-config-variable '((:pager-height . 42)))
  (let ((path (merge-pathnames "aldo-conf-bare.conf" (uiop:temporary-directory)))
        (clautolisp.autolisp-builtins-core::*aldo-configuration-writer* nil))
    (unwind-protect
         (progn
           (clautolisp.autolisp-builtins-core::save-aldo-configuration-to path)
           (with-open-file (in path)
             (let ((back (clautolisp.debug.ui:read-aldo-configuration in)))
               (is (eql 42 (cdr (assoc :pager-height back)))))))
      (ignore-errors (delete-file path)))))
