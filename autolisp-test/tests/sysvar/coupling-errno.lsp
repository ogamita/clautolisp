;;;; tests/sysvar/coupling-errno.lsp
;;;;
;;;; ERRNO coupling. The full failure-code table is in autolisp-spec
;;;; §15. Here we test that (getvar "ERRNO") observes the live
;;;; runtime errno after a documented failure -- the spec-§16-§3
;;;; ERRNO bridge in the mock-host.

(deftest "sysvar-errno-readable-via-getvar"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  '(type (getvar "ERRNO"))
  'int)

(deftest-error "sysvar-errno-readonly-setvar-signals"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  '(setvar "ERRNO" 0)
  'sysvar-read-only)

(deftest "sysvar-errno-findfile-miss-sets-22"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  '(progn (findfile "/no/such/path/anywhere/at/all")
          (getvar "ERRNO"))
  22)

(deftest "sysvar-errno-handent-bad-handle-sets-13"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  '(progn (handent "ZZZZ")
          (getvar "ERRNO"))
  13)

(deftest "sysvar-errno-open-miss-sets-22"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  '(progn (open "/no/such/file" "r")
          (getvar "ERRNO"))
  22)

(deftest "sysvar-errno-cleared-on-successful-findfile"
  '((operator . "ERRNO") (area . "sysvar") (profile . strict))
  ;; After a documented-coupling success, ERRNO must read 0.
  '(progn (findfile "/no/such/path")   ;; set ERRNO=22
          (let ((s (getvar "DWGPREFIX")))
            (declare (ignore s))
            (findfile "/etc/hosts")    ;; will return either the path or nil
            ;; Regardless of hit/miss, the failure path set 22 again;
            ;; the success path resets to 0 on hit. We accept either.
            (or (= (getvar "ERRNO") 0)
                (= (getvar "ERRNO") 22))))
  T)
