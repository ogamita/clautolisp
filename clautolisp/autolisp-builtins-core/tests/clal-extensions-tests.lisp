(in-package #:clautolisp.autolisp-builtins-core.tests)

(in-suite autolisp-builtins-core-suite)

;;;; Tests for the CLAL-* clautolisp extensions.
;;;;
;;;; See autolisp-spec §16 ~clautolisp Extensions~ for the normative
;;;; entries.

(defun setup-mock-host-context ()
  (clautolisp.autolisp-runtime:reset-default-evaluation-context)
  (let* ((session (clautolisp.autolisp-runtime:evaluation-context-session
                   (clautolisp.autolisp-runtime:current-evaluation-context)))
         (mock    (clautolisp.autolisp-mock-host:make-mock-host)))
    (setf (clautolisp.autolisp-runtime.internal::runtime-session-host session)
          mock)
    (clautolisp.autolisp-runtime:current-evaluation-context)))

;;; --- clal-sysvar-list ---------------------------------------------

(test clal-sysvar-list-returns-1836-entries-on-default-mock
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list)))
    (is (listp result))
    (is (= 1836 (length result)))
    (is (every (lambda (x)
                 (typep x 'clautolisp.autolisp-runtime:autolisp-string))
               result))))

(test clal-sysvar-list-is-sorted-lexicographically
  (setup-mock-host-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (is (equal values (sort (copy-list values) #'string<)))))

(test clal-sysvar-list-includes-well-known-names
  (setup-mock-host-context)
  (let* ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-list))
         (values (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                         result)))
    (dolist (n '("ANGBASE" "CMDECHO" "ERRNO" "LISPSYS" "OSMODE"
                 "PROJECTAWARE" "TRUSTEDPATHS" "USERI1"))
      (is (member n values :test #'string=)
          "expected ~A in CLAL-SYSVAR-LIST" n))))

;;; --- clal-sysvar-apropos ------------------------------------------

(test clal-sysvar-apropos-ang-matches-angle-family
  (setup-mock-host-context)
  (let* ((pattern (clautolisp.autolisp-runtime:make-autolisp-string "ANG"))
         (result  (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos pattern))
         (values  (mapcar #'clautolisp.autolisp-runtime:autolisp-string-value
                          result)))
    (is (member "ANGBASE" values :test #'string=))
    (is (member "ANGDIR"  values :test #'string=))
    ;; AUNITS does NOT contain the substring "ANG"; assert it's
    ;; excluded so the apropos result isn't an everything-fallthrough.
    (is (null (member "AUNITS" values :test #'string=)))))

(test clal-sysvar-apropos-is-case-insensitive
  (setup-mock-host-context)
  (let* ((upper (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ANG")))
         (lower (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "ang")))
         (mixed (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string "Ang"))))
    (is (= (length upper) (length lower)))
    (is (= (length upper) (length mixed)))))

(test clal-sysvar-apropos-empty-string-returns-all-1836
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string ""))))
    (is (= 1836 (length result)))))

(test clal-sysvar-apropos-no-match-returns-nil
  (setup-mock-host-context)
  (let ((result (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos
                 (clautolisp.autolisp-runtime:make-autolisp-string
                  "DEFINITELY_NOT_A_SUBSTRING_OF_ANY_NAME_xyzzy"))))
    (is (null result))))

(test clal-sysvar-apropos-rejects-non-string-pattern
  (setup-mock-host-context)
  (let ((signalled-p nil))
    (handler-case
        (clautolisp.autolisp-builtins-core::builtin-clal-sysvar-apropos 42)
      (autolisp-runtime-error (c)
        (declare (ignore c))
        (setf signalled-p t)))
    (is (eq signalled-p t))))
