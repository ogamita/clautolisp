;;;; tests/file/vl-file.lsp -- VL-FILE-* family

(setq *aut-vlf-1* (strcat *autolisp-test-root* "results/.tmp-vlf-1.txt"))
(setq *aut-vlf-2* (strcat *autolisp-test-root* "results/.tmp-vlf-2.txt"))

(deftest-pred "vl-file-size-of-empty-is-zero"
  '((operator . "VL-FILE-SIZE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-vlf-1* "w"))
          (close fp)
          (vl-file-size *aut-vlf-1*))
  '(or (eq *result* 0) (eq *result* nil)))

(deftest "vl-file-delete-removes-existing"
  '((operator . "VL-FILE-DELETE") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-vlf-1* "w"))
          (close fp)
          (vl-file-delete *aut-vlf-1*))
  T)

(deftest "vl-file-delete-of-missing-returns-nil"
  '((operator . "VL-FILE-DELETE") (area . "file") (profile . strict))
  '(vl-file-delete "/no/such/file/anywhere/abc.xyz")
  nil)

(deftest-pred "vl-file-copy-then-readback"
  '((operator . "VL-FILE-COPY") (area . "file") (profile . strict))
  '(progn (setq fp (open *aut-vlf-1* "w"))
          (write-line "hello" fp)
          (close fp)
          (vl-file-copy *aut-vlf-1* *aut-vlf-2*)
          (setq fp (open *aut-vlf-2* "r"))
          (setq line (read-line fp))
          (close fp)
          line)
  '(equal *result* "hello"))
