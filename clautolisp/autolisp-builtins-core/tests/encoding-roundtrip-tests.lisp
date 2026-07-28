(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; test-file-encodings.issue part 3: run the pure-AutoLISP
;;;; encoding-roundtrip.lsp program through the engine and require its
;;;; ALL...PASSED line. It writes a fixture in each *AUTOLISP-FILE-ENCODING*
;;;; (open "w" + princ) and loads it back under the same encoding, asserting
;;;; the accents round-trip AND that the wrong-encoding loads fail to
;;;; decode. This exercises the engine's read+write encoding symmetry.

(defparameter *encoding-roundtrip-lsp*
  ;; Resolve the program path at COMPILE time (the source tree), the same
  ;; #. idiom alfe.conformance uses; the absolute path lands in the fasl.
  #.(namestring
     (merge-pathnames
      "../../autolisp-file-compat/scenarios/encodings/encoding-roundtrip.lsp"
      (or *compile-file-truename* *load-truename*)))
  "Absolute path to the encoding-roundtrip AutoLISP program.")

(defun %slurp-utf8 (path)
  (with-open-file (in path :external-format :utf-8)
    (with-output-to-string (out)
      (loop for ch = (read-char in nil nil) while ch do (write-char ch out)))))

(test encoding-file-roundtrip
  "Run encoding-roundtrip.lsp in a fresh temp directory (it writes + loads
real files) and require ALL ENCODING ROUNDTRIP PASSED."
  (let* ((src (%slurp-utf8 *encoding-roundtrip-lsp*))
         (dir (uiop:ensure-directory-pathname
               (merge-pathnames (format nil "clautolisp-enc-rt-~D/" (random 1000000))
                                (uiop:temporary-directory))))
         (out (make-string-output-stream)))
    (ensure-directories-exist dir)
    (unwind-protect
         (uiop:with-current-directory (dir)
           (reset-autolisp-symbol-table)
           (let ((*standard-output* out)
                 (*error-output* (make-string-output-stream)))
             (run-autolisp-string
              src
              :dialect (clautolisp.autolisp-reader:find-autolisp-dialect :clautolisp)
              :setup-fn #'%install-mock-host-and-core)))
      (ignore-errors (uiop:delete-directory-tree dir :validate t :if-does-not-exist :ignore)))
    (let ((s (get-output-stream-string out)))
      (is (search "ALL ENCODING ROUNDTRIP PASSED" s)
          "encoding-roundtrip.lsp did not pass. Output:~%~A" s))))
