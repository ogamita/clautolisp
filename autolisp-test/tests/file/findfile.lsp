;;;; tests/file/findfile.lsp -- FINDFILE / FINDTRUSTEDFILE

(setq *aut-find-file*
      (strcat *autolisp-test-root* "results/.tmp-findfile.txt"))

(deftest-pred "findfile-existing-returns-non-nil"
  '((operator . "FINDFILE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-find-file* "w"))
          (write-line "ok" fp)
          (close fp)
          (findfile *aut-find-file*))
  '(not (null *result*)))

(deftest "findfile-of-non-existing-returns-nil"
  '((operator . "FINDFILE") (area . "file") (profile . strict))
  '(findfile "/this/path/should/not/exist/anywhere.xyz")
  nil)

(deftest "findfile-empty-string-returns-nil"
  '((operator . "FINDFILE") (area . "file") (profile . strict))
  '(findfile "")
  nil)
