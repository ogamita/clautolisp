;;;; scripts/verify-vl-registry.lisp
;;;;
;;;; Platform verification for the vl-registry backends (vl-registry.issue):
;;;; exercises the REAL platform store — the Windows registry (reg.exe), the
;;;; macOS defaults database, or the unix sexp store — through the host
;;;; protocol, then cleans up after itself. Run from the repo root:
;;;;   sbcl --non-interactive --load scripts/verify-vl-registry.lisp
;;;; Exits 0 on success, 1 on a failed check, 2 when the system cannot load.
(require :asdf)
(let ((ql (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file ql) (load ql)))
(handler-case
    (progn
      (asdf:load-asd (truename (merge-pathnames "clautolisp/clautolisp.asd"
                                                (uiop:getcwd))))
      (asdf:load-system "clautolisp/autolisp-mock-host"))
  (error (e) (format t "~&LOAD FAILED: ~A~%" e) (uiop:quit 2)))
(let* ((root "HKCU\\Software\\clautolisp-vlreg-test")
       (key  (concatenate 'string root "\\Sub"))
       (host (clautolisp.autolisp-mock-host:make-mock-host))
       (fails 0))
  (flet ((chk (label ok)
           (format t "~&~:[FAIL~;ok  ~]  ~A~%" ok label)
           (unless ok (incf fails))))
    (clautolisp.autolisp-host:host-registry-write host key "k1" "v1")
    (chk "write/read round trip"
         (equal "v1" (clautolisp.autolisp-host:host-registry-read host key "k1")))
    (chk "value names list k1"
         (member "k1" (clautolisp.autolisp-host:host-registry-descendents host key t)
                 :test #'string-equal))
    (chk "sub-keys list Sub"
         (member "Sub" (clautolisp.autolisp-host:host-registry-descendents host root nil)
                 :test #'string-equal))
    (chk "delete the value"
         (clautolisp.autolisp-host:host-registry-delete host key "k1"))
    (chk "value gone"
         (null (clautolisp.autolisp-host:host-registry-read host key "k1")))
    ;; cleanup: remove the test keys entirely
    (clautolisp.autolisp-host:host-registry-delete host key nil)
    (clautolisp.autolisp-host:host-registry-delete host root nil)
    (if (zerop fails)
        (progn (format t "~&vl-registry platform verification: OK (~A)~%"
                       (or #+(or win32 windows mswindows os-windows) "windows registry"
                           #+darwin "macOS defaults"
                           "unix sexp store"))
               (uiop:quit 0))
        (uiop:quit 1))))
