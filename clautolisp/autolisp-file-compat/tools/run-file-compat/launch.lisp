(require :asdf)

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
