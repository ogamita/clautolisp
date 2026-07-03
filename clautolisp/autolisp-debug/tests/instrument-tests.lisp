;;;; clautolisp/autolisp-debug/tests/instrument-tests.lisp

(in-package #:clautolisp.debug.tests)

(in-suite debug-suite)

(defparameter +frob-source+
  ;; line 1: (defun id (a) a)
  ;; line 2: (defun frob (x / z)
  ;; line 3:   (setq z (id x))
  ;; line 4:   z)
  (format nil "(defun id (a) a)~%(defun frob (x / z)~%  (setq z (id x))~%  z)"))

(test instrument-builds-metadata-and-body
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB"))))
    (let ((usubr (usubr-named context "FROB")))
      (is (clautolisp.debug:instrumentedp usubr))
      ;; idempotent: re-instrumenting returns the same metadata
      (is (eq metadata (clautolisp.debug:instrument-usubr usubr)))
      ;; bound-names = formals + /-locals, in binding order: X then Z
      (is (equal '("X" "Z")
                 (mapcar #'clautolisp.autolisp-runtime:autolisp-symbol-name
                         (clautolisp.debug:function-debug-metadata-bound-names metadata))))
      ;; form-id 0 is the function wrapper (entry/exit)
      (is (eq :function-entry (clautolisp.debug:form-id-kind metadata 0)))
      ;; there is more than one poll point (entry + statements/sub-forms)
      (is (> (clautolisp.debug:function-debug-metadata-poll-point-count metadata) 1)))))

(test instrument-resolves-source-positions
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB")))
         ;; the (id x) call is on line 3
         (form-id (clautolisp.debug:find-form-id-at-line metadata 3)))
    (is (integerp form-id))
    (let ((position (clautolisp.debug:form-id-position metadata form-id)))
      (is (clautolisp.source:source-position-p position))
      (is (= 3 (clautolisp.source:source-position-start-line position))))))

(test registry-maps-function-id-to-metadata
  (let* ((context (fresh-context))
         (metadata (first (define-and-instrument context +frob-source+ "FROB")))
         (fid (clautolisp.debug:function-debug-metadata-function-id metadata)))
    (is (eq metadata (clautolisp.debug:metadata-for-function-id fid)))
    (is (eq metadata (clautolisp.debug:metadata-for-usubr (usubr-named context "FROB"))))))

(test quote-data-is-not-instrumented
  ;; A quoted list must survive instrumentation intact — the instrumenter
  ;; must not weave poll points into data.
  (let* ((context (fresh-context)))
    (define-and-instrument context "(defun q () (quote (a b c)))" "Q")
    ;; runs to the literal list under debugging without corruption
    (let ((result (clautolisp.debug:with-debugging ()
                    (eval-call context "Q"))))
      (is (equal '("A" "B" "C")
                 (mapcar #'clautolisp.autolisp-runtime:autolisp-symbol-name result))))))

;;; --- ensure-metadata-for-name: instrument on demand (aldo-pre-debug.issue) ---

(test ensure-metadata-instruments-a-loaded-but-uncalled-function
  ;; A function defined/loaded but never called has no metadata yet;
  ;; ensure-metadata-for-name must instrument it on demand so pre-debug
  ;; navigation and breakpoints work.
  (let ((context (fresh-context)))
    (load-tracked context +frob-source+)
    (let ((usubr (usubr-named context "FROB")))
      (is (not (clautolisp.debug:instrumentedp usubr)))       ; not yet instrumented
      (is (null (clautolisp.debug:metadata-for-name "FROB"))) ; not registered
      (let ((metadata (clautolisp.debug:ensure-metadata-for-name "FROB" context)))
        (is (not (null metadata)))
        (is (clautolisp.debug:instrumentedp usubr))            ; now instrumented
        (is (eq metadata (clautolisp.debug:metadata-for-name "FROB")))
        ;; case-insensitive, and idempotent (returns the same metadata)
        (is (eq metadata (clautolisp.debug:ensure-metadata-for-name "frob" context)))))))

(test ensure-metadata-returns-nil-for-unknown-name
  (let ((context (fresh-context)))
    (load-tracked context +frob-source+)
    (is (null (clautolisp.debug:ensure-metadata-for-name "NOSUCHFN" context)))))
