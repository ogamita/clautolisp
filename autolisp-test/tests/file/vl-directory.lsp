;;;; tests/file/vl-directory.lsp -- VL-DIRECTORY-FILES, VL-FILE-DIRECTORY-P, VL-MKDIR

(setq *aut-vlmk-dir*
      (strcat *autolisp-test-root* "results/.tmp-vlmk-dir/"))

(deftest "vl-mkdir-creates-directory"
  '((operator . "VL-MKDIR") (area . "file") (profile . strict))
  '(vl-mkdir *aut-vlmk-dir*) T)

(deftest "vl-file-directory-p-true-for-tmp-dir"
  '((operator . "VL-FILE-DIRECTORY-P") (area . "file") (profile . strict))
  '(progn (vl-mkdir *aut-vlmk-dir*)
          (vl-file-directory-p *aut-vlmk-dir*))
  T)

(deftest "vl-file-directory-p-false-for-missing"
  '((operator . "VL-FILE-DIRECTORY-P") (area . "file") (profile . strict))
  '(vl-file-directory-p "/no/such/dir/anywhere/")
  nil)

(deftest-pred "vl-directory-files-returns-list"
  '((operator . "VL-DIRECTORY-FILES") (area . "file") (profile . strict))
  '(progn (vl-mkdir *aut-vlmk-dir*)
          (vl-directory-files *aut-vlmk-dir*))
  '(listp *result*))
