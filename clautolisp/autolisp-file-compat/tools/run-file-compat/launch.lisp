(require :asdf)

;; Load quicklisp when the user has it, so ASDF can resolve the
;; third-party systems clautolisp depends on (babel and
;; trivial-gray-streams, for the host-independent code-page codec).
;; ASDF alone reports them as MISSING-DEPENDENCY: its quicklisp hook only
;; exists once quicklisp itself has been loaded. Absent quicklisp this is
;; a no-op and ASDF's own registry has the last word, exactly as before.
(let ((setup (merge-pathnames #P"quicklisp/setup.lisp"
                              (user-homedir-pathname))))
  (when (probe-file setup)
    (load setup)))

(let* ((getenv (symbol-function (find-symbol "GETENV" "UIOP/OS")))
       (load-asd (symbol-function (find-symbol "LOAD-ASD" "ASDF")))
       (load-system (symbol-function (find-symbol "LOAD-SYSTEM" "ASDF")))
       (root (or (funcall getenv "CLAUTOLISP_ROOT")
                 (error "CLAUTOLISP_ROOT is not set.")))
       (asd (merge-pathnames #P"clautolisp.asd" (pathname root)))
       (arguments-file (or (funcall getenv "CLAUTOLISP_FILE_COMPAT_ARGS_FILE")
                           (error "CLAUTOLISP_FILE_COMPAT_ARGS_FILE is not set."))))
  (funcall load-asd asd)
  (funcall load-system "clautolisp/run-file-compat")
  (let* ((main-symbol (find-symbol "MAIN"
                                   "CLAUTOLISP.AUTOLISP-FILE-COMPAT.TOOLS.RUN-FILE-COMPAT"))
         (arguments
           (with-open-file (stream arguments-file :direction :input)
             (loop for line = (read-line stream nil nil)
                   while line
                   collect line))))
    (apply (symbol-function main-symbol)
           (cons "run-file-compat" arguments))))
